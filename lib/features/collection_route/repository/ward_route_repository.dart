import 'package:dio/dio.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

class WardPickup {
  final int id;
  final int pickupId;
  final String name;
  final String address;
  final String pickupDate;
  final String pickupTimeSlot;
  final String status;
  final String wasteType;
  final String? collector;
  final String? collectorVehicle;
  final String? ward;
  final String? localBody;
  final String? district;
  final String? contactNumber;
  final String? email;
  final String placement;

  const WardPickup({
    required this.id,
    required this.pickupId,
    required this.name,
    required this.address,
    required this.pickupDate,
    required this.pickupTimeSlot,
    required this.status,
    required this.wasteType,
    this.collector,
    this.collectorVehicle,
    this.ward,
    this.localBody,
    this.district,
    this.contactNumber,
    this.email,
    this.placement = 'Outside',
  });

  factory WardPickup.fromJson(
    Map<String, dynamic> json, {
    String? ward,
    String? localBody,
    String? district,
  }) {
    final rawId = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final rawPickupId =
        int.tryParse(json['pickup_id']?.toString() ?? '') ?? rawId;

    return WardPickup(
      id: rawId,
      pickupId: rawPickupId,
      name: (json['user_name']?.toString() ?? json['name']?.toString() ?? '')
          .trim(),
      address: (json['address']?.toString() ?? '').trim(),
      pickupDate: json['pickup_date']?.toString() ?? '',
      pickupTimeSlot: json['pickup_time_slot']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      wasteType: json['waste_type']?.toString() ?? '',
      collector: json['collector']?.toString(),
      collectorVehicle: json['collector_vehicle']?.toString(),
      ward: ward ?? json['ward']?.toString(),
      localBody: localBody ?? json['local_body']?.toString(),
      district: district ?? json['district']?.toString(),
      contactNumber: json['contact_number']?.toString() ??
          json['phone']?.toString() ??
          json['contact']?.toString() ??
          json['user_phone']?.toString(),
      email: json['email']?.toString() ?? json['user_email']?.toString(),
      placement: json['placement']?.toString() ??
          json['garbage_placement']?.toString() ??
          'Outside',
    );
  }
}

class WardRoute {
  final String ward;
  final String? localBody;
  final String? district;
  final List<WardPickup> pickups;

  const WardRoute({
    required this.ward,
    this.localBody,
    this.district,
    required this.pickups,
  });

  factory WardRoute.fromJson(Map<String, dynamic> json) {
    final rawPickups = json['pickups'] as List<dynamic>? ?? [];
    final ward = json['ward']?.toString() ?? '';
    final localBody = json['local_body']?.toString();
    final district = json['district']?.toString();

    return WardRoute(
      ward: ward,
      localBody: localBody,
      district: district,
      pickups: rawPickups
          .map((p) => WardPickup.fromJson(
                p as Map<String, dynamic>,
                ward: ward,
                localBody: localBody,
                district: district,
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────

class WardRouteRepository {
  Dio? _dio;

  /// Lazily creates (and caches) a Dio instance with the auth token injected.
  Future<Dio> _client() async {
    if (_dio != null) return _dio!;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('KEY_TOKEN') ?? '';
    _dio = Dio(
      BaseOptions(
        baseUrl: APIEndPoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Token $token',
        },
      ),
    );
    return _dio!;
  }

  // ── Ward collection routes ──────────────────

  /// Fetches ward routes and returns only pickups for today.
  Future<List<WardPickup>> fetchTodaysPickups() async {
    final dio = await _client();
    final response = await dio.get(APIEndPoints.wardCollectionRoutes);
    final data = response.data;
    debugPrint('ward-collection-routes data: $data');
    if (data is! Map) {
      throw Exception('Unexpected response format from ward-collection-routes');
    }
    final rawWards = (data['ward_routes'] as List<dynamic>?) ?? [];
    final today = _todayString();
    final result = <WardPickup>[];
    for (final rawWard in rawWards) {
      if (rawWard is! Map<String, dynamic>) continue;
      for (final pickup in WardRoute.fromJson(rawWard).pickups) {
        if (pickup.pickupDate == today) result.add(pickup);
        //  print(result.toString());
      }
    }
    return result;
  }

  // @override
  // String toString() =>
  //     'BagAssignmentModel(pickupId: $';
  // ── Navigation API calls ────────────────────

  /// Step 1 – called when "Start navigate" is tapped.
  /// POST /api/start-tracking/ with {"pickup_id": pickupId, "collector_id": collectorId}
  /// Returns response map containing location details if successful.
  Future<Map<String, dynamic>?> startTracking({
    required int pickupId,
    required int collectorId,
  }) async {
    try {
      final dio = await _client();
      final body = {'pickup_id': pickupId, 'collector_id': collectorId};
      debugPrint(
          'POST start-tracking to ${APIEndPoints.baseUrl}${APIEndPoints.startTrackingRoute} with body: $body');
      final res = await dio.post(APIEndPoints.startTrackingRoute, data: body);
      debugPrint(
          'Start Tracking Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.data is Map<String, dynamic>) {
          return res.data as Map<String, dynamic>;
        }
        return {'message': 'Tracking started successfully'};
      }
      return null;
    } catch (e) {
      debugPrint('start-tracking error: $e');
      return null;
    }
  }

  /// Step 2 – called right after startTracking succeeds.
  /// POST /api/confirm-route-start/
  Future<bool> confirmRouteStart({
    required int pickupId,
    required int collectorId,
  }) async {
    try {
      final dio = await _client();
      final body = {'pickup_id': pickupId, 'collector_id': collectorId};
      debugPrint(
          'POST confirm-route-start to ${APIEndPoints.baseUrl}/api/confirm-route-start/ with body: $body');
      final res = await dio.post('/api/confirm-route-start/', data: body);
      debugPrint(
          'Confirm Route Start Response Status: ${res.statusCode}, Body: ${res.data}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('confirm-route-start error: $e');
      return false;
    }
  }

  /// Step 3 – called after confirmRouteStart succeeds.
  /// POST /api/start-navigate/
  Future<Map<String, dynamic>?> startNavigate({
    required int pickupId,
    required int collectorId,
  }) async {
    try {
      final dio = await _client();
      final body = {'pickup_id': pickupId, 'collector_id': collectorId};
      debugPrint(
          'POST start-navigate to ${APIEndPoints.baseUrl}/api/start-navigate/ with body: $body');
      final res = await dio.post('/api/start-navigate/', data: body);
      debugPrint(
          'Start Navigate Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200) return res.data as Map<String, dynamic>;
      return null;
    } catch (e) {
      debugPrint('start-navigate error: $e');
      return null;
    }
  }

  /// Periodic location update during navigation.
  /// POST /api/update-collector-location/
  Future<bool> updateCollectorLocation({
    required int pickupId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final dio = await _client();
      final body = {
        'pickup_id': pickupId,
        'latitude': latitude,
        'longitude': longitude,
      };
      debugPrint(
          'POST location update to ${APIEndPoints.baseUrl}/api/update-collector-location/ with body: $body');
      final res = await dio.post('/api/update-collector-location/', data: body);
      debugPrint(
          'Location Update Response Status: ${res.statusCode}, Body: ${res.data}');
      final success = res.statusCode == 200;
      debugPrint(
          'Updated location to API: latitude=$latitude, longitude=$longitude, success=$success');
      return success;
    } catch (e) {
      debugPrint('update-collector-location error: $e');
      return false;
    }
  }

  /// Step 4 – called when collector arrives at pickup location.
  /// POST /api/confirm-reached/
  Future<Map<String, dynamic>?> confirmReached({
    required int pickupId,
    required int collectorId,
  }) async {
    try {
      final dio = await _client();
      final body = {'pickup_id': pickupId, 'collector_id': collectorId};
      debugPrint(
          'POST confirm-reached to ${APIEndPoints.baseUrl}${APIEndPoints.confirmReached} with body: $body');
      final res = await dio.post(APIEndPoints.confirmReached, data: body);
      debugPrint(
          'Confirm Reached Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('confirm-reached error: $e');
      return null;
    }
  }

  /// GET /api/pickup-details/?pickup_id=$pickupId
  Future<Map<String, dynamic>?> fetchPickupDetails({
    required int pickupId,
  }) async {
    try {
      final dio = await _client();
      final url = '${APIEndPoints.pickupDetails}?pickup_id=$pickupId';
      debugPrint('GET pickup-details from ${APIEndPoints.baseUrl}$url');
      final res = await dio.get(url);
      debugPrint(
          'Fetch Pickup Details Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('pickup-details error: $e');
      return null;
    }
  }

  /// Step 5 – Fetch data for Confirm & Pay screen.
  /// GET /api/confirm-and-pay-data/?pickup_id=$pickupId
  Future<Map<String, dynamic>?> fetchConfirmAndPayData({
    required int pickupId,
  }) async {
    try {
      final dio = await _client();
      final url = '${APIEndPoints.confirmAndPayData}?pickup_id=$pickupId';
      debugPrint('GET confirm-and-pay-data from ${APIEndPoints.baseUrl}$url');
      final res = await dio.get(url);
      debugPrint(
          'Fetch Confirm and Pay Screen Data Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('confirm-and-pay-data error: $e');
      return null;
    }
  }

  /// Step 6 – Fetch disposal rate for a local body.
  /// GET /api/disposal-rates/?local_body_id=$localBodyId
  Future<double?> fetchDisposalRate({
    required int localBodyId,
  }) async {
    try {
      final dio = await _client();
      final url = '${APIEndPoints.disposalRates}?local_body_id=$localBodyId';
      debugPrint('GET disposal-rates from ${APIEndPoints.baseUrl}$url');
      final res = await dio.get(url);
      debugPrint(
          'Fetch Disposal Rates Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 &&
          res.data is List &&
          (res.data as List).isNotEmpty) {
        final first = (res.data as List).first;
        if (first is Map<String, dynamic>) {
          return double.tryParse(first['rate_per_kg']?.toString() ?? '');
        }
      }
      return null;
    } catch (e) {
      debugPrint('disposal-rates error: $e');
      return null;
    }
  }

  /// Step 7 – Generate Bill.
  /// POST /api/generate-bill/
  Future<Map<String, dynamic>?> generateBill({
    required Map<String, dynamic> body,
  }) async {
    try {
      final dio = await _client();
      debugPrint(
          'POST generate-bill to ${APIEndPoints.baseUrl}${APIEndPoints.generateBill} with body: $body');
      final res = await dio.post(APIEndPoints.generateBill, data: body);
      debugPrint(
          'Generate Bill Response Status: ${res.statusCode}, Body: ${res.data}');
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('generate-bill error: $e');
      return null;
    }
  }

  /// Razorpay Dynamic QR Generation.
  /// POST /api/razorpay/generate-qr/
  /// Body: {"amount": amount, "bill_id": billId, "currency": "INR"}
  Future<Map<String, dynamic>?> generateRazorpayQR({
    required double amount,
    required int billId,
    String currency = 'INR',
  }) async {
    try {
      final dio = await _client();
      final body = {
        'amount': amount,
        'bill_id': billId,
        'currency': currency,
      };
      debugPrint(
          'POST generate-qr to ${APIEndPoints.baseUrl}${APIEndPoints.razorpayGenerateQr} with body: $body');
      final res = await dio.post(APIEndPoints.razorpayGenerateQr, data: body);
      debugPrint(
          'Generate QR Response Status: ${res.statusCode}, Body: ${res.data}');
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('generateRazorpayQR error: $e');
      return null;
    }
  }

  /// Step 8 – Process Payment.
  /// POST /api/process-payment/
  Future<Map<String, dynamic>?> processPayment({
    required int pickupId,
    required String paymentMethod,
  }) async {
    try {
      final dio = await _client();
      final body = {
        'pickup_id': pickupId,
        'payment_method': paymentMethod.toLowerCase(),
      };
      debugPrint(
          'POST process-payment to ${APIEndPoints.baseUrl}${APIEndPoints.processPayment} with body: $body');
      final res = await dio.post(APIEndPoints.processPayment, data: body);
      debugPrint(
          'Process Payment Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('process-payment error (handled gracefully): $e');
      return null;
    }
  }

  /// Step 9 – Confirm and Pay.
  /// POST /api/confirm-and-pay/
  Future<Map<String, dynamic>?> confirmAndPay({
    required Map<String, dynamic> body,
  }) async {
    try {
      final dio = await _client();
      debugPrint(
          'POST confirm-and-pay to ${APIEndPoints.baseUrl}${APIEndPoints.confirmAndPay} with body: $body');
      final res = await dio.post(APIEndPoints.confirmAndPay, data: body);
      debugPrint(
          'Confirm and Pay Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('confirm-and-pay error (handled gracefully): $e');
      return null;
    }
  }

  /// Step 10 – Update pickup status.
  /// POST /api/update-pickup-status/
  Future<bool> updatePickupStatus({
    required int pickupId,
    required String status,
    String? reason,
  }) async {
    try {
      final dio = await _client();
      final body = {
        'pickup_id': pickupId,
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };
      debugPrint(
          'POST update-pickup-status to ${APIEndPoints.baseUrl}${APIEndPoints.updatePickupStatus} with body: $body');
      final res = await dio.post(APIEndPoints.updatePickupStatus, data: body);
      debugPrint(
          'Status Update Response Status: ${res.statusCode}, Body: ${res.data}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('update-pickup-status error: $e');
      return false;
    }
  }

  /// Step 11 – Finalize Waste Collection.
  /// POST /api/collect-pickup/
  Future<Map<String, dynamic>?> collectPickup({
    required int pickupId,
    required int collectorId,
  }) async {
    try {
      final dio = await _client();
      final body = {'pickup_id': pickupId, 'collector_id': collectorId};
      debugPrint(
          'POST collect-pickup to ${APIEndPoints.baseUrl}${APIEndPoints.collectPickup} with body: $body');
      final res = await dio.post(APIEndPoints.collectPickup, data: body);
      debugPrint(
          'Collect Pickup Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('collect-pickup error: $e');
      return null;
    }
  }

  /// Step 12 – Report Issue (Warning).
  /// POST /api/report-issue/
  Future<Map<String, dynamic>?> reportIssue({
    required String userName,
    required String userEmail,
    required String userPhone,
    required int pickupId,
    required String issueType,
    required String subject,
    required String description,
  }) async {
    try {
      final dio = await _client();
      final body = {
        'user_name': userName,
        'user_email': userEmail,
        'user_phone': userPhone,
        'pickup_id': pickupId,
        'issue_type': issueType,
        'subject': subject,
        'description': description,
      };
//
      debugPrint(
          'POST report issue to ${APIEndPoints.baseUrl}${APIEndPoints.reportIssue} with body: $body');
      final res = await dio.post(APIEndPoints.reportIssue, data: body);
      debugPrint(
          'Report Issue Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.data is Map<String, dynamic>) {
          return res.data as Map<String, dynamic>;
        }
        return {'message': 'Issue reported successfully'};
      }
      return null;
    } catch (e) {
      debugPrint('report-issue error: $e');
      return null;
    }
  }

  /// Step 13 – Upload Waste Photo (Weighing Machine Verification).
  /// POST /api/upload-waste-photo/
  Future<Map<String, dynamic>?> uploadWastePhoto({
    required int pickupId,
    required String photoBase64,
  }) async {
    try {
      final dio = await _client();
      final body = {
        'pickup_id': pickupId,
        'photo': photoBase64,
        'waste_photo': photoBase64,
      };
      debugPrint(
          'POST upload waste photo to ${APIEndPoints.baseUrl}${APIEndPoints.uploadWastePhoto} (excluding raw photo string length)');
      final res = await dio.post(APIEndPoints.uploadWastePhoto, data: body);
      debugPrint(
          'Upload Waste Photo Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.data is Map<String, dynamic>) {
          return res.data as Map<String, dynamic>;
        }
        return {'message': 'Waste photo uploaded successfully'};
      }
      return null;
    } on DioException catch (e) {
      debugPrint(
          'Upload Waste Photo Response Status: ${e.response?.statusCode}, Body: ${e.response?.data}');
      debugPrint('Error uploading photo to server: $e');
      final errorData = e.response?.data;
      String errorMsg = 'Failed to upload photo';
      if (errorData is Map && errorData.containsKey('error')) {
        errorMsg = errorData['error'].toString();
      } else if (errorData is String) {
        errorMsg = errorData;
      }
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('Error uploading photo to server: $e');
      rethrow;
    }
  }

  //reshedule
  Future<Map<String, dynamic>?> reschedulePickup({
    required int pickupId,
    required String newDate,
  }) async {
    try {
      final dio = await _client();

      final body = {
        'pickup_id': pickupId,
        "new_date": newDate,
        "new_time_slot": "9:00 AM – 12:00 PM",
        "reason": "Door closed"
      };
      debugPrint(
          'POST update-pickup-status to ${APIEndPoints.baseUrl}${APIEndPoints.reschedule} with body: $body');
      final res = await dio.post(APIEndPoints.reschedule, data: body);
      debugPrint(
          'Status Update Response Status: ${res.statusCode}, Body: ${res.data}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (res.data is Map<String, dynamic>) {
          return res.data as Map<String, dynamic>;
        }
        return {'message': 'Rescheduled successfully'};
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Body: ${e.response?.data}');

      throw Exception(e.message);
    } catch (e) {
      debugPrint('Error uploading photo to server: $e');
      rethrow;
    }
  }

  // ── Helpers ─────────────────────────────────

  String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void debugPrint(String msg) {
    // ignore: avoid_print
    print(msg);
  }
}
