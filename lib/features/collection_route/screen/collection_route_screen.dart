import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:floret_collector/features/collection_route/repository/ward_route_repository.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:url_launcher/url_launcher.dart';
import 'confirm_and_pay_screen.dart';
import 'mark_completed_with_warning_screen.dart';

class CollectionRouteScreen extends StatefulWidget {
  static const String routeName = '/CollectionRouteScreen';

  final String? routeNameParam;
  final String? pickupType;
  final String? address;
  final String? timeSlot;
  final double? latitude;
  final double? longitude;
  final int? pickupId;
  final bool? hasArrived;

  const CollectionRouteScreen({
    super.key,
    this.routeNameParam = '',
    this.pickupType = '',
    this.address = '',
    this.timeSlot = '',
    this.latitude,
    this.longitude,
    this.pickupId,
    this.hasArrived,
  });

  @override
  State<CollectionRouteScreen> createState() => _CollectionRouteScreenState();
}

class _CollectionRouteScreenState extends State<CollectionRouteScreen> {
  bool _isMapView = true;
  MapType _currentMapType = MapType.normal;
  GoogleMapController? _mapController;

  // Navigation & arrival state
  bool _isNavigating = false;
  bool _isNavigationLoading =
      false; // true while making the 3 startup API calls
  bool _hasArrived = false; // true once confirmReached succeeds
  bool _isConfirmingReached = false; // true while calling confirm-reached API
  bool _isCollecting = false; // true while collection is in progress
  bool _isVoiceEnabled = true; // toggles voice guidance
  int _currentStopIndex = 0;

  bool get _isCurrentStopArrived {
    if (_pickupStops.isEmpty) return false;
    final status = (_currentStop['status'] as String? ?? '').toLowerCase();
    return _hasArrived || status == 'arrived';
  }

  // Collector info (read from local storage)
  int _collectorId = 0;

  // Location update timer (fires every 5 s while navigating)
  Timer? _locationTimer;

  // API data
  final _repository = WardRouteRepository();
  final _collectorStorage = CollectorLocalStorage();
  bool _isLoading = true;
  String? _errorMessage;

  // Stops along the route (populated from API)
  List<Map<String, dynamic>> _pickupStops = [];

  // Current device location (null until resolved)
  LatLng? _currentLocation;

  // Road routing & live navigation
  List<LatLng> _routePoints = [];
  String _routeDistance = '';
  String _routeEta = '';
  double _collectorHeading = 0.0;
  bool _isCameraFollowing = true;
  StreamSubscription<Position>? _positionStreamSub;

  // Fallback centre used only when GPS is unavailable
  static const LatLng _fallbackPosition = LatLng(9.9816, 76.2798);

  /// Computed camera target:
  ///  1. The selected stop's position when stops are loaded.
  ///  2. The live GPS position when no stops are available.
  ///  3. The hardcoded fallback as a last resort.
  LatLng get _targetPosition {
    if (_pickupStops.isNotEmpty) {
      return _pickupStops[_currentStopIndex]['position'] as LatLng;
    }

    return _currentLocation ?? _fallbackPosition;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Load collector ID and request location permission in parallel
    final idStr = await _collectorStorage.getCollectorId();
    _collectorId = int.tryParse(idStr) ?? 0;

    // Request location permission and get current position
    await _resolveCurrentLocation();

    await _fetchTodaysPickups();

    // Fetch road navigation route from collector location to pickup
    _fetchRoadRoute();
  }

  /// Asks for location permission (if not already granted) and stores the
  /// device's current GPS position in [_currentLocation].
  Future<void> _resolveCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[CollectionRoute] Location service disabled.');
        _showSnack("Please turn on location");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[CollectionRoute] Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[CollectionRoute] Location permission permanently denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          if (pos.heading >= 0) {
            _collectorHeading = pos.heading;
          }
        });
      }
    } catch (e) {
      debugPrint('[CollectionRoute] Could not resolve location: $e');
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _positionStreamSub?.cancel();
    super.dispose();
  }

  /// Tries to geocode [rawAddress] into a [LatLng].
  /// Attempts in order:
  ///   1. The address as-is
  ///   2. The address with ", Kerala, India" appended
  ///   3. The address with ", India" appended
  /// Returns null if all attempts fail.
  Future<LatLng?> _geocodeAddress(String rawAddress) async {
    final candidates = [
      rawAddress,
      '$rawAddress, Kerala, India',
      '$rawAddress, India',
    ];
    for (final query in candidates) {
      try {
        final results = await locationFromAddress(query);
        if (results.isNotEmpty) {
          debugPrint('[CollectionRoute] Geocoded "$query" → '
              '${results.first.latitude}, ${results.first.longitude}');
          return LatLng(results.first.latitude, results.first.longitude);
        }
      } catch (_) {
        // Try next candidate
      }
    }
    debugPrint(
        '[CollectionRoute] Geocoding failed for all candidates of "$rawAddress"');
    return null;
  }

  Future<void> _fetchTodaysPickups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pickups = await _repository.fetchTodaysPickups();

      if (!mounted) return;

      if (pickups.isEmpty) {
        setState(() {
          _isLoading = false;
          _pickupStops = [];
        });
        return;
      }

      // Exclude already-picked stops
      final filteredPickups =
          pickups.where((p) => p.status.toLowerCase() != 'picked').toList();

      final centre = _currentLocation ?? _fallbackPosition;

      // Geocode each pickup address to get the real lat/lng for the marker.
      // Falls back to a slight offset from the collector's position if all
      // geocoding attempts fail so the map still shows something.
      final stops = <Map<String, dynamic>>[];
      for (int idx = 0; idx < filteredPickups.length; idx++) {
        final p = filteredPickups[idx];

        final address = p.address.isNotEmpty ? p.address : p.name;
        final type = p.wasteType.isNotEmpty ? p.wasteType : 'Scheduled pickup';
        final timeSlot = p.pickupTimeSlot.isNotEmpty ? p.pickupTimeSlot : 'N/A';

        // Build enriched address with ward, local body, district for accurate geocoding
        final fullAddrParts = [
          if (address.isNotEmpty) address,
          if (p.ward != null && p.ward!.isNotEmpty) p.ward!,
          if (p.localBody != null && p.localBody!.isNotEmpty) p.localBody!,
          if (p.district != null && p.district!.isNotEmpty) p.district!,
        ];
        final enrichedAddress = fullAddrParts.join(', ');

        LatLng position;
        final geocoded = await _geocodeAddress(
            enrichedAddress.isNotEmpty ? enrichedAddress : address);
        if (geocoded != null) {
          position = geocoded;
        } else {
          // All geocoding failed: use widget-supplied coords for first stop
          // if available, otherwise offset from current location so markers
          // don't stack on top of each other.
          if (idx == 0 && widget.latitude != null && widget.longitude != null) {
            position = LatLng(widget.latitude!, widget.longitude!);
          } else {
            position = LatLng(
              centre.latitude + idx * 0.002,
              centre.longitude + idx * 0.002,
            );
          }
        }

        final pStatus = p.status.toLowerCase();
        final isCompleted = pStatus == 'picked' ||
            pStatus == 'collected' ||
            pStatus == 'completed';

        stops.add(<String, dynamic>{
          'id': 'stop_${p.id}',
          'pickup_id': p.pickupId,
          'pickupId': p.pickupId,
          'route_id': p.id,
          'title': address,
          'name': p.name,
          'type': type,
          'position': position,
          'isNext': false,
          'isCompleted': isCompleted,
          'time': timeSlot,
          'distance': '—',
          'status': p.status,
          'geocoded': geocoded != null, // flag: was this actually geocoded?
          'contact_number': p.contactNumber,
          'phone': p.contactNumber,
          'email': p.email,
          'placement': p.placement,
          'ward': p.ward,
          'localBody': p.localBody,
          'district': p.district,
        });
      }

      if (!mounted) return;

      int selectedIdx = 0;
      if (stops.isNotEmpty) {
        // If a specific pickupId was requested, select it
        if (widget.pickupId != null && widget.pickupId! > 0) {
          final targetIdx = stops.indexWhere((s) =>
              (s['pickup_id'] as num?)?.toInt() == widget.pickupId ||
              (s['pickupId'] as num?)?.toInt() == widget.pickupId);
          if (targetIdx != -1) {
            selectedIdx = targetIdx;
          }
        } else {
          // Default to the first uncompleted stop (giving priority to arrived stops ready to collect)
          final arrivedIdx = stops.indexWhere((s) =>
              !(s['isCompleted'] as bool) &&
              (s['status'] as String? ?? '').toLowerCase() == 'arrived');
          if (arrivedIdx != -1) {
            selectedIdx = arrivedIdx;
          } else {
            final uncompletedIdx =
                stops.indexWhere((s) => !(s['isCompleted'] as bool));
            if (uncompletedIdx != -1) {
              selectedIdx = uncompletedIdx;
            }
          }
        }

        for (int i = 0; i < stops.length; i++) {
          stops[i]['isNext'] = i == selectedIdx;
        }
      }

      final initialStatus = stops.isNotEmpty
          ? (stops[selectedIdx]['status'] as String? ?? '').toLowerCase()
          : '';
      final initialArrived =
          widget.hasArrived == true || initialStatus == 'arrived';

      setState(() {
        _isLoading = false;
        _pickupStops = stops;
        _currentStopIndex = selectedIdx;
        _hasArrived = initialArrived;
      });

      // Animate camera to fit markers
      if (_pickupStops.isNotEmpty) {
        _zoomToFitMarkers();
        _enrichPickupDetails(selectedIdx).then((_) {
          _enrichAllPickupsDetails();
        });
      }
    } catch (e, stack) {
      if (!mounted) return;
      String msg = 'Failed to load today\'s pickups.';
      if (e is DioException) {
        final status = e.response?.statusCode;
        final body = e.response?.data?.toString() ?? '';
        msg = 'Server error ($status).\n$body';
        debugPrint('[WardRoute] DioException: $status\n$body\n$stack');
      } else {
        debugPrint('[WardRoute] Error: $e\n$stack');
        msg = '$msg\n${e.toString()}';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
    }
  }

  /// Fetches additional details for a specific stop (e.g. user_phone, user_name)
  /// using GET /api/pickup-details/?pickup_id=$pickupId
  Future<void> _enrichPickupDetails(int stopIndex) async {
    if (stopIndex < 0 || stopIndex >= _pickupStops.length) return;
    final stop = _pickupStops[stopIndex];
    final pickupId = (stop['pickup_id'] as num?)?.toInt() ??
        (stop['pickupId'] as num?)?.toInt() ??
        0;
    if (pickupId <= 0) return;

    try {
      final res = await _repository.fetchPickupDetails(pickupId: pickupId);
      if (res != null && mounted) {
        final details = res['pickup_details'] as Map<String, dynamic>?;
        if (details != null && stopIndex < _pickupStops.length) {
          final userPhone = details['user_phone']?.toString() ??
              details['contact_number']?.toString() ??
              details['phone']?.toString();
          final userName = details['user_name']?.toString() ??
              details['name']?.toString();
          final userEmail = details['user_email']?.toString() ??
              details['email']?.toString();

          setState(() {
            if (userPhone != null &&
                userPhone.isNotEmpty &&
                userPhone.toLowerCase() != 'null') {
              _pickupStops[stopIndex]['contact_number'] = userPhone;
              _pickupStops[stopIndex]['phone'] = userPhone;
            }
            if (userName != null && userName.isNotEmpty) {
              _pickupStops[stopIndex]['name'] = userName;
            }
            if (userEmail != null && userEmail.isNotEmpty) {
              _pickupStops[stopIndex]['email'] = userEmail;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error enriching pickup details for stop $stopIndex: $e');
    }
  }

  /// Lazily fetches details for all stops in the route that lack contact details
  Future<void> _enrichAllPickupsDetails() async {
    for (int i = 0; i < _pickupStops.length; i++) {
      if (!mounted) return;
      final currentPhone = _pickupStops[i]['contact_number']?.toString() ??
          _pickupStops[i]['phone']?.toString();
      if (currentPhone == null ||
          currentPhone.isEmpty ||
          currentPhone.toLowerCase() == 'null') {
        await _enrichPickupDetails(i);
      }
    }
  }

  Map<String, dynamic> get _currentStop =>
      _pickupStops.isNotEmpty ? _pickupStops[_currentStopIndex] : {};

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // ── Collector "You are here" marker ────────────────────────────────────
    // Only show when we have a confirmed GPS fix so the collector can clearly
    // see their own position alongside the pickup pin(s).
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('collector_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          rotation: _collectorHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(
            title: '📍 You are here',
            snippet: 'Collector Live Position',
          ),
          zIndexInt: 2,
        ),
      );
    }

    // ── Pickup stop markers ─────────────────────────────────────────────────
    for (int i = 0; i < _pickupStops.length; i++) {
      final stop = _pickupStops[i];
      final isNext = stop['isNext'] as bool;
      final isCompleted = stop['isCompleted'] as bool;
      final pos = stop['position'] as LatLng;
      final title = stop['title'] as String;
      final wasGeooded = stop['geocoded'] as bool? ?? false;

      final status = (stop['status'] as String? ?? '').toLowerCase();
      final isArrived = status == 'arrived';

      BitmapDescriptor icon;
      if (isCompleted) {
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else if (isArrived) {
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      } else if (isNext) {
        icon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      } else {
        icon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      }

      // Build a clear info-window title that identifies this as a PICKUP pin
      final infoTitle = isCompleted
          ? '✅ Collected: $title'
          : isArrived
              ? '📍 Arrived (Ready to Collect): $title'
              : isNext
                  ? '🏠 Pickup: $title'
                  : '🏠 Stop ${i + 1}: $title';

      final snippet = wasGeooded
          ? (stop['type'] as String?)
          : '⚠️ Approx. location – GPS address unavailable';

      markers.add(
        Marker(
          markerId: MarkerId(stop['id'] as String),
          position: pos,
          icon: icon,
          infoWindow: InfoWindow(
            title: infoTitle,
            snippet: snippet,
          ),
          zIndexInt: (isNext || isArrived) ? 1 : 0,
          onTap: () {
            setState(() {
              _currentStopIndex = i;
              for (int k = 0; k < _pickupStops.length; k++) {
                _pickupStops[k]['isNext'] = k == i;
              }
              final sStatus =
                  (_pickupStops[i]['status'] as String? ?? '').toLowerCase();
              _hasArrived = sStatus == 'arrived';
              _routePoints = [];
            });
            _fetchRoadRoute();
            _enrichPickupDetails(i);
          },
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_currentLocation == null || _pickupStops.isEmpty) return {};
    final points = _routePoints.isNotEmpty
        ? _routePoints
        : [_currentLocation!, _targetPosition];

    return {
      // Outline polyline for map contrast
      Polyline(
        polylineId: const PolylineId('collector_route_outline'),
        points: points,
        color: const Color(0xFF1E3A8A),
        width: 7,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      // Primary road navigation polyline
      Polyline(
        polylineId: const PolylineId('collector_to_pickup_route'),
        points: points,
        color: const Color(0xFF2563EB),
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  /// Fetches real road navigation route coordinates between collector and current pickup stop
  /// using the free OSRM (Open Source Routing Machine) API.
  Future<void> _fetchRoadRoute() async {
    if (_currentLocation == null || _pickupStops.isEmpty) return;
    final start = _currentLocation!;
    final end = _targetPosition;

    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      final res = await dio.get(url);
      if (res.statusCode == 200 && res.data is Map) {
        final routes = res.data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;
          if (coords != null && coords.isNotEmpty) {
            final points = coords.map((c) {
              final pair = c as List<dynamic>;
              return LatLng(
                (pair[1] as num).toDouble(),
                (pair[0] as num).toDouble(),
              );
            }).toList();

            final distMeters =
                (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
            final durationSecs =
                (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

            if (mounted) {
              setState(() {
                _routePoints = points;
                _routeDistance = distMeters >= 1000
                    ? '${(distMeters / 1000).toStringAsFixed(1)} km'
                    : '${distMeters.round()} m';
                final minutes = (durationSecs / 60).ceil();
                _routeEta = minutes > 0 ? '$minutes mins' : '1 min';
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[CollectionRoute] OSRM routing error: $e');
    }

    if (mounted && _routePoints.isEmpty) {
      setState(() {
        _routePoints = [start, end];
      });
    }
  }

  void _onToggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  Future<void> _zoomToFitMarkers() async {
    if (_mapController == null) return;
    if (_isCameraFollowing) {
      setState(() => _isCameraFollowing = false);
    }

    // If we know the collector's position AND there's a pickup stop, fit both
    // in the viewport so the collector can see where they are and where to go.
    if (_currentLocation != null && _pickupStops.isNotEmpty) {
      final pickupPos = _targetPosition;
      final collectorPos = _currentLocation!;

      // Build a bounding box that includes both points + some padding
      final swLat = pickupPos.latitude < collectorPos.latitude
          ? pickupPos.latitude
          : collectorPos.latitude;
      final swLng = pickupPos.longitude < collectorPos.longitude
          ? pickupPos.longitude
          : collectorPos.longitude;
      final neLat = pickupPos.latitude > collectorPos.latitude
          ? pickupPos.latitude
          : collectorPos.latitude;
      final neLng = pickupPos.longitude > collectorPos.longitude
          ? pickupPos.longitude
          : collectorPos.longitude;

      // If the two points are very close (< ~50m) just centre on pickup at zoom 17
      final latDiff = (neLat - swLat).abs();
      final lngDiff = (neLng - swLng).abs();
      if (latDiff < 0.0005 && lngDiff < 0.0005) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(pickupPos, 17.0),
        );
        return;
      }

      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(swLat, swLng),
              northeast: LatLng(neLat, neLng),
            ),
            80, // padding in logical pixels
          ),
        );
        return;
      } catch (_) {
        final centerLat = (swLat + neLat) / 2;
        final centerLng = (swLng + neLng) / 2;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(centerLat, centerLng), 14.0),
        );
        return;
      }
    }

    // Fallback: just zoom to the pickup/target position
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _targetPosition,
          zoom: 16.0,
        ),
      ),
    );
  }

  Future<void> _centerOnCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _zoomToFitMarkers();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _zoomToFitMarkers();
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16.0,
        ),
      );
    } catch (_) {
      _zoomToFitMarkers();
    }
  }

  Future<void> _startNavigation() async {
    if (_pickupStops.isEmpty) return;
    debugPrint('[CollectionRoute] Starting navigation for stop: $_currentStop');
    final pickupId = (_currentStop['pickup_id'] as num?)?.toInt() ??
        (_currentStop['pickupId'] as num?)?.toInt() ??
        0;
    if (pickupId == 0) {
      _showSnack('No pickup ID for this stop.', isError: true);
      return;
    }

    setState(() => _isNavigationLoading = true);

    try {
      // ── Step 1: start-tracking ─────────────────
      final trackingRes = await _repository.startTracking(
        pickupId: pickupId,
        collectorId: _collectorId,
      );
      if (!mounted) return;
      if (trackingRes == null) {
        _showSnack('Could not start tracking. Please retry.', isError: true);
        setState(() => _isNavigationLoading = false);
        return;
      }

      // Update stop with precise location from tracking response if available
      final locData = trackingRes['location'] as Map<String, dynamic>?;
      if (locData != null) {
        final street = locData['street']?.toString() ?? '';
        final landmark = locData['landmark']?.toString() ?? '';
        final city = locData['city']?.toString() ?? '';
        final district = locData['district']?.toString() ?? '';
        final state = locData['state']?.toString() ?? '';
        final zipCode = locData['zip_code']?.toString() ?? '';

        final lat = (locData['latitude'] as num?)?.toDouble() ??
            (locData['pickup_latitude'] as num?)?.toDouble() ??
            (locData['lat'] as num?)?.toDouble();
        final lng = (locData['longitude'] as num?)?.toDouble() ??
            (locData['pickup_longitude'] as num?)?.toDouble() ??
            (locData['lng'] as num?)?.toDouble();

        LatLng? pickupPos;
        if (lat != null && lng != null) {
          pickupPos = LatLng(lat, lng);
        } else {
          final fullAddr = [
            if (street.isNotEmpty) street,
            if (landmark.isNotEmpty) landmark,
            if (city.isNotEmpty) city,
            if (district.isNotEmpty) district,
            if (state.isNotEmpty) state,
            if (zipCode.isNotEmpty) zipCode,
            'India',
          ].join(', ');
          pickupPos = await _geocodeAddress(fullAddr);
        }

        if (pickupPos != null && mounted) {
          setState(() {
            _pickupStops[_currentStopIndex]['position'] = pickupPos;
            _pickupStops[_currentStopIndex]['geocoded'] = true;
            if (street.isNotEmpty) {
              _pickupStops[_currentStopIndex]['title'] = street;
            }
            final phone = locData['contact_number']?.toString() ??
                locData['phone']?.toString();
            if (phone != null && phone.isNotEmpty) {
              _pickupStops[_currentStopIndex]['contact_number'] = phone;
              _pickupStops[_currentStopIndex]['phone'] = phone;
            }
            final email = locData['email']?.toString() ??
                locData['user_email']?.toString();
            if (email != null && email.isNotEmpty) {
              _pickupStops[_currentStopIndex]['email'] = email;
            }
            final userName =
                locData['name']?.toString() ?? locData['user_name']?.toString();
            if (userName != null && userName.isNotEmpty) {
              _pickupStops[_currentStopIndex]['name'] = userName;
            }
          });
        }
      }

      // ── Step 2: confirm-route-start ────────────
      final confirmOk = await _repository.confirmRouteStart(
        pickupId: pickupId,
        collectorId: _collectorId,
      );
      if (!mounted) return;
      if (!confirmOk) {
        _showSnack('Could not confirm route. Please retry.', isError: true);
        setState(() => _isNavigationLoading = false);
        return;
      }

      // ── Step 3: start-navigate ─────────────────
      final navData = await _repository.startNavigate(
        pickupId: pickupId,
        collectorId: _collectorId,
      );
      if (!mounted) return;

      // navData contains map_data → collector_location, user_location, etc.
      if (navData != null) {
        final mapData = navData['map_data'] as Map<String, dynamic>?;
        if (mapData != null) {
          final collLoc =
              mapData['collector_location'] as Map<String, dynamic>?;
          if (collLoc != null) {
            final lat = (collLoc['latitude'] as num?)?.toDouble();
            final lng = (collLoc['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              setState(() {
                _currentLocation = LatLng(lat, lng);
              });
            }
          }
        }
      }

      // ── Enter navigating state & start location updates ──
      setState(() {
        _isNavigating = true;
        _isNavigationLoading = false;
        _isCameraFollowing = true;
      });
      _fetchRoadRoute();
      _startLocationUpdates(pickupId: pickupId);

      if (_currentLocation != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLocation!,
              zoom: 17.5,
              tilt: 45.0,
              bearing: _collectorHeading,
            ),
          ),
        );
      } else {
        _zoomToFitMarkers();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isNavigationLoading = false);
      _showSnack('Navigation error: $e', isError: true);
    }
  }

  /// Starts high-frequency live GPS tracking and periodic server sync.
  void _startLocationUpdates({required int pickupId}) {
    _locationTimer?.cancel();
    _positionStreamSub?.cancel();

    // 1. High-accuracy live position stream for smooth navigation and camera tracking
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Updates whenever moved by 3 meters
      ),
    ).listen((Position pos) {
      if (!mounted) return;
      final newLoc = LatLng(pos.latitude, pos.longitude);
      final heading = pos.heading >= 0 ? pos.heading : _collectorHeading;

      setState(() {
        _currentLocation = newLoc;
        _collectorHeading = heading;
      });

      // In live navigation mode, smoothly animate camera following the collector
      if (_isNavigating && _mapController != null && _isCameraFollowing) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newLoc,
              zoom: 17.5,
              tilt: 45.0,
              bearing: heading,
            ),
          ),
        );
      }
    });

    // 2. Periodic location sync to server every 5 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
        await _repository.updateCollectorLocation(
          pickupId: pickupId,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );

        // Dynamically refresh road route & ETA while travelling
        _fetchRoadRoute();
      } catch (_) {
        // Silently ignore individual location update failures
      }
    });
  }

  /// Stops all location updates and GPS streams.
  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  /// Launches external turn-by-turn navigation in Google Maps / default maps app.
  Future<void> _openExternalNavigation() async {
    final target = _targetPosition;
    final lat = target.latitude;
    final lng = target.longitude;

    final googleNavUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final webMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleNavUri)) {
        await launchUrl(googleNavUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(webMapsUri)) {
        await launchUrl(webMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (mounted) {
        _showSnack('Could not launch maps application', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error opening navigation: $e', isError: true);
      }
    }
  }

  void _advanceToNextStop() {
    // Stop broadcasting location for the completed stop
    _stopLocationUpdates();

    setState(() {
      _isNavigating = false;
      _hasArrived = false;
      _pickupStops[_currentStopIndex]['isCompleted'] = true;
      _pickupStops[_currentStopIndex]['status'] = 'completed';
      _pickupStops[_currentStopIndex]['isNext'] = false;

      // Find next uncompleted stop, giving priority to already arrived stops
      int nextIdx = -1;
      for (int i = _currentStopIndex + 1; i < _pickupStops.length; i++) {
        if (!(_pickupStops[i]['isCompleted'] as bool)) {
          nextIdx = i;
          break;
        }
      }
      if (nextIdx == -1) {
        for (int i = 0; i < _currentStopIndex; i++) {
          if (!(_pickupStops[i]['isCompleted'] as bool)) {
            nextIdx = i;
            break;
          }
        }
      }

      if (nextIdx != -1) {
        _currentStopIndex = nextIdx;
        _pickupStops[_currentStopIndex]['isNext'] = true;
        final nextStatus =
            (_pickupStops[_currentStopIndex]['status'] as String? ?? '')
                .toLowerCase();
        _hasArrived = nextStatus == 'arrived';
      } else {
        // All stops completed
        _currentStopIndex = 0;
        for (var stop in _pickupStops) {
          stop['isCompleted'] = false;
          stop['isNext'] = false;
        }
        _pickupStops.first['isNext'] = true;
      }
      _routePoints = [];
    });
    _enrichPickupDetails(_currentStopIndex);

    _zoomToFitMarkers();
    _fetchRoadRoute();

    _showSnack('Moved to next pickup: ${_currentStop['title']}');
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Header Bar
            _buildHeader(context),
            const SizedBox(height: 14),

            // Segmented Switcher (Map vs Pickup points list)
            _buildSegmentedSwitcher(),
            const SizedBox(height: 10),

            // Content: Loading / Error / Map / List
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E293B)),
            SizedBox(height: 16),
            Text(
              "Loading today's pickups…",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Resolving pickup locations on the map…",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchTodaysPickups,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pickupStops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy_rounded,
                  size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              const Text(
                'No pickups scheduled for today.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check back tomorrow or contact your supervisor.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchTodaysPickups,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isMapView ? _buildMapStack() : _buildPickupListView();
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Circular Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Collection route',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildSegmentedSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF5),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            // Map Button
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isMapView = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _isMapView
                        ? const Color(0xFF1E293B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 19,
                        color:
                            _isMapView ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Map',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _isMapView
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pickup points list Button
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isMapView = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: !_isMapView
                        ? const Color(0xFF1E293B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        size: 19,
                        color: !_isMapView
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup points list',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: !_isMapView
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStack() {
    return Stack(
      children: [
        // Google Map View
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _targetPosition,
            zoom: 15.5,
          ),
          mapType: _currentMapType,
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            // Animate to the live GPS position once the map is ready
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(_targetPosition, 15.5),
            );
          },
        ),

        // Top Destination Header Card (matches uploaded design)
        Positioned(
          top: 16,
          left: 16,
          right: 76,
          child: _buildTopLocationHeader(),
        ),

        // Floating Action Buttons (Top Right)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildFloatingCircleButton(
                icon: Icons.layers_outlined,
                onTap: _onToggleMapType,
              ),
              const SizedBox(height: 12),
              _buildFloatingCircleButton(
                icon: Icons.search_rounded,
                onTap: _zoomToFitMarkers,
              ),
              const SizedBox(height: 12),
              _buildFloatingCircleButton(
                icon: _isCameraFollowing
                    ? Icons.navigation_rounded
                    : Icons.my_location_rounded,
                iconColor: _isCameraFollowing
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1E293B),
                backgroundColor:
                    _isCameraFollowing ? const Color(0xFFECFDF5) : Colors.white,
                onTap: () {
                  setState(() => _isCameraFollowing = true);
                  _centerOnCurrentLocation();
                  _showSnack('Centered and tracking live location');
                },
              ),
              const SizedBox(height: 12),
              _buildFloatingCircleButton(
                icon: _isVoiceEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                onTap: () {
                  setState(() => _isVoiceEnabled = !_isVoiceEnabled);
                  _showSnack(_isVoiceEnabled
                      ? 'Voice guidance enabled'
                      : 'Voice guidance muted');
                },
              ),
            ],
          ),
        ),

        // Bottom Pickup Card:
        // Before arrival -> floating card with margins.
        // After arrival -> docked bottom sheet (matches screenshot).
        Positioned(
          left: _isCurrentStopArrived ? 0 : 16,
          right: _isCurrentStopArrived ? 0 : 16,
          bottom: _isCurrentStopArrived ? 0 : 16,
          child: _buildNextPickupCard(),
        ),
      ],
    );
  }

  Widget _buildTopLocationHeader() {
    if (_pickupStops.isEmpty) return const SizedBox.shrink();

    final title = (_currentStop['title'] as String?)?.isNotEmpty == true
        ? (_currentStop['title'] as String)
        : 'Main Road';
    final name = (_currentStop['name'] as String?)?.isNotEmpty == true
        ? (_currentStop['name'] as String)
        : title;

    return InkWell(
      onTap: _showStopsPicker,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 22,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showStopsPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Pickup Points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _pickupStops.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final stop = _pickupStops[idx];
                  final isSelected = idx == _currentStopIndex;
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                    ),
                    title: Text(
                      stop['title'] as String,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    subtitle: Text(
                      '${stop['name']} • ${stop['type']}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF10B981))
                        : null,
                    onTap: () {
                      setState(() {
                        _currentStopIndex = idx;
                        for (int k = 0; k < _pickupStops.length; k++) {
                          _pickupStops[k]['isNext'] = k == idx;
                        }
                        final sStatus =
                            (_pickupStops[idx]['status'] as String? ?? '')
                                .toLowerCase();
                        _hasArrived = sStatus == 'arrived';
                        _isNavigating = false;
                      });
                      Navigator.pop(ctx);
                      _zoomToFitMarkers();
                      _fetchRoadRoute();
                      _enrichPickupDetails(idx);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF1E293B)),
              title: const Text('Center on my location',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              onTap: () {
                Navigator.pop(ctx);
                _centerOnCurrentLocation();
              },
            ),
            if (!_isNavigating)
              ListTile(
                leading: _isNavigationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.navigation_outlined,
                        color: Color(0xFF10B981)),
                title: const Text('Start Navigation & Live Tracking',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                onTap: _isNavigationLoading
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _startNavigation();
                      },
              ),
            ListTile(
              leading: const Icon(Icons.directions, color: Color(0xFF2563EB)),
              title: const Text('Open in Google Maps',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
              onTap: () {
                Navigator.pop(ctx);
                _openExternalNavigation();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 21,
          color: iconColor ?? const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildNextPickupCard() {
    if (_pickupStops.isEmpty) return const SizedBox.shrink();
    print("pickups");
    print(_pickupStops);
    final title = (_currentStop['title'] as String?)?.isNotEmpty == true
        ? (_currentStop['title'] as String)
        : 'Main Road';
    final type = (_currentStop['type'] as String?)?.isNotEmpty == true
        ? (_currentStop['type'] as String)
        : 'Scheduled pickup';
    final distance = (_currentStop['distance'] as String?) ?? '—';
    final placement = (_currentStop['placement'] as String?)?.isNotEmpty == true
        ? (_currentStop['placement'] as String)
        : 'Outside';

    if (!_isCurrentStopArrived) {
      return _buildPreArrivalCard(title, type, distance);
    }

    return _buildArrivedCard(title, placement);
  }

  Widget _buildPreArrivalCard(String title, String type, String distance) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: "Next pickup" & Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Next pickup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                distance,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type Row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              const Text(
                'Type:  ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              const Text(
                'Address:  ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Live Road Navigation Info Banner
          if (_isNavigating) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_rounded,
                      color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _routeDistance.isNotEmpty
                              ? 'Live Route: $_routeDistance'
                              : 'Live GPS Navigation Active',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        if (_routeEta.isNotEmpty)
                          Text(
                            'Estimated Time: $_routeEta',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF047857),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // if (_isCameraFollowing)
                  //   Container(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 8, vertical: 4),
                  //     decoration: BoxDecoration(
                  //       color: const Color(0xFF10B981),
                  //       borderRadius: BorderRadius.circular(20),
                  //     ),
                  //     child: const Row(
                  //       children: [
                  //         Icon(Icons.gps_fixed, size: 12, color: Colors.white),
                  //         SizedBox(width: 4),
                  //         Text(
                  //           'TRACKINGg',
                  //           style: TextStyle(
                  //             fontSize: 10,
                  //             fontWeight: FontWeight.w800,
                  //             color: Colors.white,
                  //             letterSpacing: 0.5,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action Buttons:
          // If not navigating: [Start navigate] & [Google Maps icon] & [Arrived]
          // If navigating: [I have arrived (Confirm Reached)] & [Google Maps icon]
          if (!_isNavigating)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isNavigationLoading ? null : _startNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        disabledBackgroundColor: const Color(0xFF475569),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isNavigationLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.navigation_outlined,
                                    size: 18, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Start navigate',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                // const SizedBox(width: 8),
                // SizedBox(
                //   height: 50,
                //   width: 50,
                //   child: OutlinedButton(
                //     onPressed: _openExternalNavigation,
                //     style: OutlinedButton.styleFrom(
                //       padding: EdgeInsets.zero,
                //       side: const BorderSide(color: Color(0xFFCBD5E1)),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(14),
                //       ),
                //     ),
                //     child: const Icon(Icons.assistant_direction_rounded,
                //         color: Color(0xFF1E293B), size: 22),
                //   ),
                // ),
                // const SizedBox(width: 8),
                // Expanded(
                //   flex: 2,
                //   child: SizedBox(
                //     height: 50,
                //     child: OutlinedButton(
                //       onPressed:
                //           _isConfirmingReached ? null : _handleArrival,
                //       style: OutlinedButton.styleFrom(
                //         side: const BorderSide(
                //             color: Color(0xFF10B981), width: 1.5),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(14),
                //         ),
                //       ),
                //       child: _isConfirmingReached
                //           ? const SizedBox(
                //               height: 18,
                //               width: 18,
                //               child: CircularProgressIndicator(
                //                 strokeWidth: 2,
                //                 color: Color(0xFF10B981),
                //               ),
                //             )
                //           : const Text(
                //               'Arrived',
                //               style: TextStyle(
                //                 fontSize: 14,
                //                 fontWeight: FontWeight.w700,
                //                 color: Color(0xFF10B981),
                //               ),
                //             ),
                //     ),
                //   ),
                // ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isConfirmingReached ? null : _handleArrival,
                      icon: _isConfirmingReached
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.pin_drop_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                      label: Text(
                        _isConfirmingReached
                            ? 'Confirming Arrival'
                            : 'I have arrived',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // SizedBox(
                //   height: 52,
                //   width: 52,
                //   child: OutlinedButton(
                //     onPressed: _openExternalNavigation,
                //     style: OutlinedButton.styleFrom(
                //       padding: EdgeInsets.zero,
                //       side: const BorderSide(color: Color(0xFFCBD5E1)),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(14),
                //       ),
                //     ),
                //     child: const Icon(Icons.assistant_direction_rounded,
                //         color: Color(0xFF1E293B), size: 24),
                //   ),
                // ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildArrivedCard(String title, String placement) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header title: "Arrived at: <Address>"
            Text(
              'Arrived at: $title',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Subtitle 1: "Garbage placed: Outside"
            Row(
              children: [
                const Text(
                  'Garbage placed: ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  placement,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Subtitle 2: "Select pickup status below"
            const Text(
              'Select pickup status below',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),

            // 1. Collect Button (Green)
            _buildActionButton(
              label: 'Collect',
              icon: Icons.check_circle_outline_rounded,
              backgroundColor: const Color(0xFF10B981),
              textColor: Colors.white,
              iconColor: Colors.white,
              isLoading: _isCollecting,
              onTap: _handleCollect,
            ),
            const SizedBox(height: 12),

            // 2. Issue reported Button (Red)
            _buildActionButton(
              label: 'Issue reported',
              icon: Icons.warning_amber_rounded,
              backgroundColor: const Color(0xFFEF4444),
              textColor: Colors.white,
              iconColor: Colors.white,
              onTap: _handleReportIssue,
            ),
            const SizedBox(height: 12),

            // 3. Reschedule Button (Amber/Yellow)
            _buildActionButton(
              label: 'Reschedule',
              icon: Icons.calendar_today_outlined,
              backgroundColor: const Color(0xFFFBBF24),
              textColor: Colors.white,
              iconColor: Colors.white,
              onTap: _handleReschedule,
            ),
            const SizedBox(height: 12),

            // 4. Contact disposer Button (White with border)
            _buildActionButton(
              label: 'Contact disposer',
              icon: Icons.phone_outlined,
              backgroundColor: Colors.white,
              textColor: const Color(0xFF1E293B),
              iconColor: const Color(0xFF1E293B),
              borderColor: const Color(0xFFE2E8F0),
              onTap: _handleContactDisposer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    Color? borderColor,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1.5)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleArrival() async {
    if (_pickupStops.isEmpty) return;

    final pickupId = (_currentStop['pickup_id'] as num?)?.toInt() ??
        (_currentStop['pickupId'] as num?)?.toInt() ??
        0;

    if (pickupId == 0) {
      _showSnack('No pickup ID available.', isError: true);
      return;
    }

    setState(() => _isConfirmingReached = true);

    try {
      if (_collectorId <= 0) {
        final idStr = await _collectorStorage.getCollectorId();
        _collectorId = int.tryParse(idStr) ?? 0;
      }

      // If not yet started tracking, trigger start-tracking & confirm-route-start first
      if (!_isNavigating) {
        await _repository.startTracking(
          pickupId: pickupId,
          collectorId: _collectorId,
        );
        await _repository.confirmRouteStart(
          pickupId: pickupId,
          collectorId: _collectorId,
        );
      }

      // Call confirm-reached API: POST /api/confirm-reached/ with {"pickup_id":..., "collector_id":...}
      final res = await _repository.confirmReached(
        pickupId: pickupId,
        collectorId: _collectorId,
      );

      if (!mounted) return;
      setState(() => _isConfirmingReached = false);

      if (res != null) {
        setState(() {
          _hasArrived = true;
        });
      } else {
        _showSnack('Could not confirm arrival. Please retry.', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirmingReached = false);
        _showSnack('Error confirming arrival: $e', isError: true);
      }
    }
  }

  Future<void> _handleCollect() async {
    if (_pickupStops.isEmpty) return;

    final pickupId = (_currentStop['pickup_id'] as num?)?.toInt() ??
        (_currentStop['pickupId'] as num?)?.toInt() ??
        0;

    setState(() => _isCollecting = true);

    try {
      // 1. Ensure collector ID is loaded
      if (_collectorId <= 0) {
        final idStr = await _collectorStorage.getCollectorId();
        _collectorId = int.tryParse(idStr) ?? 0;
      }

      // If arrival was not confirmed yet, call confirm-reached API
      if (!_hasArrived && pickupId > 0 && _collectorId > 0) {
        final res = await _repository.confirmReached(
          pickupId: pickupId,
          collectorId: _collectorId,
        );
        if (res != null && mounted) {
          setState(() => _hasArrived = true);
        }
      }

      if (!mounted) return;

      // Navigate to ConfirmAndPayScreen
      final result = await Navigator.pushNamed(
        context,
        ConfirmAndPayScreen.routeName,
        arguments: {
          'pickupId': pickupId,
          'collectorId': _collectorId,
          'address': _currentStop['title'] ?? '',
          'wasteType': _currentStop['type'] ?? '',
          'localBody': _currentStop['localBody'] ?? 'Nedumangadu Municipality',
        },
      );

      if (result == true && mounted) {
        _advanceToNextStop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error proceeding to collection: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCollecting = false);
      }
    }
  }

  Future<void> _handleReportIssue() async {
    final pickupId = (_currentStop['pickup_id'] as num?)?.toInt() ??
        (_currentStop['pickupId'] as num?)?.toInt() ??
        0;

    final result = await Navigator.pushNamed(
      context,
      MarkCompletedWithWarningScreen.routeName,
      arguments: {
        'pickupId': pickupId,
        'userName': _currentStop['name'] ?? '',
        'userEmail': _currentStop['email'] ?? '',
        'userPhone':
            _currentStop['contact_number'] ?? _currentStop['phone'] ?? '',
        'placeName': _currentStop['title'] ?? '',
        'address': _currentStop['title'] ?? '',
      },
    );

    if (result == true && mounted) {
      _advanceToNextStop();
    }
  }

  Future<void> _handleReschedule() async {
    final pickupId = (_currentStop['pickup_id'] as num?)?.toInt() ??
        (_currentStop['pickupId'] as num?)?.toInt() ??
        0;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E293B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final formatted =
        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';

    try {
      if (pickupId > 0) {
        await _repository.updatePickupStatus(
          pickupId: pickupId,
          status: 'rescheduled',
          reason: 'Rescheduled to $formatted',
        );
      }
      if (mounted) {
        _showSnack('Pickup rescheduled to $formatted');
        _advanceToNextStop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to reschedule: $e', isError: true);
      }
    }
  }

  Future<void> _handleContactDisposer() async {
    var rawPhone = _currentStop['contact_number']?.toString() ??
        _currentStop['phone']?.toString();
    var phone = (rawPhone ?? '').trim();

    // If phone is missing, try fetching details on the fly
    if (phone.isEmpty || phone.toLowerCase() == 'null') {
      final pickupId = (_currentStop['pickup_id'] as num?)?.toInt() ??
          (_currentStop['pickupId'] as num?)?.toInt() ??
          0;
      if (pickupId > 0) {
        await _enrichPickupDetails(_currentStopIndex);
        rawPhone = _currentStop['contact_number']?.toString() ??
            _currentStop['phone']?.toString();
        phone = (rawPhone ?? '').trim();
      }
    }

    if (phone.isEmpty || phone.toLowerCase() == 'null') {
      if (mounted) {
        _showSnack('No contact number available', isError: true);
      }
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      if (mounted) {
        _showSnack('No contact number available', isError: true);
      }
      return;
    }

    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        _showSnack('Could not open phone dialer', isError: true);
      }
    }
  }

  Widget _buildPickupListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _pickupStops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final stop = _pickupStops[index];
        final isNext = stop['isNext'] as bool;
        final isCompleted = stop['isCompleted'] as bool;
        final status = (stop['status'] as String? ?? '').toLowerCase();
        final isArrived = status == 'arrived';

        return InkWell(
          onTap: () {
            setState(() {
              _currentStopIndex = index;
              for (int k = 0; k < _pickupStops.length; k++) {
                _pickupStops[k]['isNext'] = k == index;
              }
              _hasArrived = isArrived;
              _isMapView = true;
            });
            _zoomToFitMarkers();
            _fetchRoadRoute();
            _enrichPickupDetails(index);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isArrived
                    ? const Color(0xFF10B981)
                    : (isNext
                        ? const Color(0xFF1E293B)
                        : (isCompleted
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE2E8F0))),
                width: (isArrived || isNext) ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFDCFCE7)
                        : (isArrived
                            ? const Color(0xFFDCFCE7)
                            : (isNext
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFF1F5F9))),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : (isArrived
                              ? Icons.pin_drop_rounded
                              : (isNext
                                  ? Icons.location_on
                                  : Icons.home_rounded)),
                      size: 20,
                      color: isCompleted
                          ? const Color(0xFF16A34A)
                          : (isArrived
                              ? const Color(0xFF10B981)
                              : (isNext
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF475569))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop['title'] as String,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stop['type']} • ${stop['time']}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if ((stop['status'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Status: ${stop['status']}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isArrived
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                            fontWeight:
                                isArrived ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        "Name : ${stop['name']}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  )
                else if (isArrived)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _currentStopIndex = index;
                        for (int k = 0; k < _pickupStops.length; k++) {
                          _pickupStops[k]['isNext'] = k == index;
                        }
                        _hasArrived = true;
                      });
                      _handleCollect();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2210B981),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Collect',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isNext)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
