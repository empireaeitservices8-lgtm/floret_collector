import 'package:floret_collector/features/home/model/bag_assignment_model.dart';
import 'package:floret_collector/features/home/model/bag_model.dart';
import 'package:floret_collector/features/home/model/location_pickup_model.dart';
import 'package:flutter/foundation.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/core/storage/collection_metrics_storage.dart';
import 'package:floret_collector/features/home/model/pickup_slot_model.dart';

import '../repos/home_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;
  final CollectorLocalStorage _collectorLocalStorage;
  final CollectionMetricsStorage _metricsStorage;

  HomeViewModel({
    required HomeRepository repository,
    required CollectorLocalStorage collectorLocalStorage,
    CollectionMetricsStorage? metricsStorage,
  })  : _repository = repository,
        _collectorLocalStorage = collectorLocalStorage,
        _metricsStorage = metricsStorage ?? CollectionMetricsStorage() {
    _metricsStorage.addListener(_onMetricsChanged);
    _metricsStorage.loadTodayMetrics();
  }

  void _onMetricsChanged() {
    notifyListeners();
  }

  // Variables
  bool _isLoading = false;
  String? _errorMessage;
  List<PickupSlotModel> _slots = [];
  String _collectorName = '';
  String _collectorId = '';
  List<BagModel> _bags = [];
  BagAssignmentModel? _bagAssignment;
  List<LocationPickupModel> _locations = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PickupSlotModel> get slots => List.unmodifiable(_slots);
  String get collectorName => _collectorName;
  List<BagModel> get bags => List.unmodifiable(_bags);
  BagAssignmentModel? get bagAssignment => _bagAssignment;
  List<LocationPickupModel> get locations => List.unmodifiable(_locations);

  // Daily collection metrics
  double get todayWeight => _metricsStorage.todayWeight;
  double get todayAmount => _metricsStorage.todayAmount;
  String get formattedWeight => _metricsStorage.formattedWeight;
  String get formattedCollectedAmount => _metricsStorage.formattedAmount;

  // Load collector details from SharedPrefs
  Future<void> loadCollector() async {
    final collector = await _collectorLocalStorage.getCollector();
    debugPrint('Collector Details ${collector.toString()}');

    final name = collector?['name']?.toString() ?? collector?['username']?.toString();
    _collectorName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : await _collectorLocalStorage.getUsername();
    _collectorId = collector?['id']?.toString() ?? '';

    notifyListeners();
  }

  // Load pickup slots from API
  Future<void> loadPickupSlots({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _repository.getPickupSlots();
      debugPrint('Pickups ${response.toString()}');
      _slots = response.slots;
    } catch (e) {
      _errorMessage = 'Unable to load pickup slots';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // Refresh all home data
  Future<void> refresh() async {
    await Future.wait([
      loadCollector().then((_) => loadBagAssignment()),
      loadLocations(),
      loadBags(),
      loadPickupSlots(showLoading: false),
      _metricsStorage.loadTodayMetrics(),
    ]);
  }

  // Load bag assignment (remaining covers, local body info)
  Future<void> loadBagAssignment() async {
    try {
      final id = _collectorId.isNotEmpty
          ? _collectorId
          : await _collectorLocalStorage.getCollectorId();
      _bagAssignment = await _repository.getBagAssignment(id);
      debugPrint('Bag assignment: $_bagAssignment');
      notifyListeners();
    } catch (e) {
      debugPrint('Unable to load bag assignment: $e');
    }
  }

  // Load today's locations/pickups
  Future<void> loadLocations() async {
    try {
      _locations = await _repository.getLocations();
      debugPrint('Locations loaded: ${_locations.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Unable to load locations: $e');
    }
  }

  // Filter today's pickup slots
  List<PickupSlotModel> get todaySlots {
    final now = DateTime.now();

    return _slots.where((slot) {
      return slot.date.year == now.year &&
          slot.date.month == now.month &&
          slot.date.day == now.day;
    }).toList();
  }

  // Status priority: arrived first (ready to collect!), in-progress/pending next, completed/picked last
  int _statusOrder(String status) {
    switch (status.toLowerCase()) {
      case 'arrived':
        return 0;
      case 'in_progress':
      case 'in progress':
        return 1;
      case 'pending':
        return 2;
      case 'picked':
      case 'collected':
      case 'completed':
        return 3;
      default:
        return 2;
    }
  }

  // Today's pickups from locations API — arrived first, completed last
  List<LocationPickupModel> get todayLocations {
    final list = _locations.where((loc) => loc.isToday).toList();
    list.sort((a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));
    return list;
  }

  // Pending pickups for today (includes arrived pickups awaiting collection)
  List<LocationPickupModel> get todayPendingLocations {
    return todayLocations
        .where((loc) {
          final s = loc.status.toLowerCase();
          return s == 'arrived' ||
              s == 'pending' ||
              s == 'in_progress' ||
              s == 'in progress';
        })
        .toList();
  }

  // First pickup to act on: arrived pickups are top priority, then pending
  LocationPickupModel? get nextPickup {
    if (todayPendingLocations.isNotEmpty) return todayPendingLocations.first;
    return null;
  }

  bool get hasArrivedPickup =>
      todayPendingLocations.any((l) => l.status.toLowerCase() == 'arrived');

  String get todayArea {
    if (todaySlots.isEmpty) return 'N/A';
    return todaySlots.map((s) => s.localBody).toSet().join(', ');
  }

  String get homeLocation {
    final loc = todayLocations.isNotEmpty
        ? todayLocations.first
        : (_locations.isNotEmpty ? _locations.first : null);
    if (loc != null) {
      if (loc.localBody.isNotEmpty && loc.district.isNotEmpty) {
        return '${loc.localBody}, ${loc.district}';
      }
      if (loc.district.isNotEmpty) return loc.district;
      if (loc.localBody.isNotEmpty) return loc.localBody;
    }
    if (_bagAssignment != null) {
      if (_bagAssignment!.localBody.isNotEmpty && _bagAssignment!.district.isNotEmpty) {
        return '${_bagAssignment!.localBody}, ${_bagAssignment!.district}';
      }
      if (_bagAssignment!.district.isNotEmpty) return _bagAssignment!.district;
    }
    return todayDistrict;
  }

  String get todayWard {
    final loc = todayLocations.isNotEmpty
        ? todayLocations.first
        : (_locations.isNotEmpty ? _locations.first : null);
    if (loc != null && loc.ward.isNotEmpty) {
      return loc.ward;
    }
    return '';
  }

  String get todayDistrict {
    final loc = todayLocations.isNotEmpty
        ? todayLocations.first
        : (_locations.isNotEmpty ? _locations.first : null);
    if (loc != null && loc.district.isNotEmpty) {
      return loc.district;
    }
    // Prefer bag assignment district
    if (_bagAssignment != null && _bagAssignment!.district.isNotEmpty) {
      return _bagAssignment!.district;
    }
    if (todaySlots.isNotEmpty) return todaySlots.first.district;
    if (_slots.isNotEmpty) return _slots.first.district;
    return 'N/A';
  }

  String get localBodyName {
    final loc = todayLocations.isNotEmpty
        ? todayLocations.first
        : (_locations.isNotEmpty ? _locations.first : null);
    if (loc != null && loc.localBody.isNotEmpty) {
      return loc.localBody;
    }
    // Prefer bag assignment local body
    if (_bagAssignment != null && _bagAssignment!.localBody.isNotEmpty) {
      return _bagAssignment!.localBody;
    }
    if (todaySlots.isNotEmpty) return todaySlots.first.localBody;
    return 'N/A';
  }

  int get remainingBags => _bagAssignment?.remainingBags ?? 0;
  int get assignedBags => _bagAssignment?.assignedBags ?? 0;

  // Sanitary pickups count for today — only picked/collected/completed count as done (arrived is still to be collected)
  int get todaySanitaryTotal => todayLocations.length;
  int get todaySanitaryCompleted => todayLocations
      .where((l) {
        final s = l.status.toLowerCase();
        return s == 'picked' || s == 'collected' || s == 'completed';
      })
      .length;

  int get todayTotalSpots =>
      todaySlots.fold<int>(0, (sum, s) => sum + s.availableSpots);

  Future<void> loadBags() async {
    try {
      _bags = await _repository.getBags();
      debugPrint('response ${bags.toString()} ');
      notifyListeners();
    } catch (e) {
      debugPrint('Unable to load bags: $e');
    }
  }

  @override
  void dispose() {
    _metricsStorage.removeListener(_onMetricsChanged);
    super.dispose();
  }
}
