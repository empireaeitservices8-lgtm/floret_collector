import 'package:floret_collector/features/home/model/bag_assignment_model.dart';
import 'package:floret_collector/features/home/model/bag_model.dart';
import 'package:floret_collector/features/home/model/location_pickup_model.dart';
import 'package:flutter/foundation.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/features/home/model/pickup_slot_model.dart';

import '../repos/home_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repository;
  final CollectorLocalStorage _collectorLocalStorage;

  HomeViewModel({
    required HomeRepository repository,
    required CollectorLocalStorage collectorLocalStorage,
  })  : _repository = repository,
        _collectorLocalStorage = collectorLocalStorage;

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

  // Load collector details from SharedPrefs
  Future<void> loadCollector() async {
    final collector = await _collectorLocalStorage.getCollector();
    debugPrint('Collector Details ${collector.toString()}');

    _collectorName = collector?['name']?.toString() ?? '';
    _collectorId = collector?['id']?.toString() ?? '';

    notifyListeners();
  }

  // Load pickup slots from API
  Future<void> loadPickupSlots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getPickupSlots();
      debugPrint('Pickups ${response.toString()}');
      _slots = response.slots;
    } catch (e) {
      _errorMessage = 'Unable to load pickup slots';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  // Status priority: pending/in-progress first, picked/collected/arrived last
  int _statusOrder(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'in_progress':
      case 'in progress':
        return 1;
      case 'arrived':
        return 2;
      case 'picked':
      case 'collected':
      case 'completed':
        return 3;
      default:
        return 1;
    }
  }

  // Today's pickups from locations API — picked/collected shown last
  List<LocationPickupModel> get todayLocations {
    final list = _locations.where((loc) => loc.isToday).toList();
    list.sort((a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));
    return list;
  }

  // Pending pickups for today (not yet picked/collected)
  List<LocationPickupModel> get todayPendingLocations {
    return todayLocations
        .where((loc) {
          final s = loc.status.toLowerCase();
          return s == 'pending' || s == 'in_progress' || s == 'in progress';
        })
        .toList();
  }

  // First strictly-pending pickup for "Next collection route".
  // Returns null when all today's pickups are picked/collected.
  LocationPickupModel? get nextPickup {
    if (todayPendingLocations.isNotEmpty) return todayPendingLocations.first;
    return null;
  }

  String get todayArea {
    if (todaySlots.isEmpty) return 'N/A';
    return todaySlots.map((s) => s.localBody).toSet().join(', ');
  }

  String get todayDistrict {
    // Prefer bag assignment district
    if (_bagAssignment != null && _bagAssignment!.district.isNotEmpty) {
      return _bagAssignment!.district;
    }
    if (todaySlots.isNotEmpty) return todaySlots.first.district;
    if (_slots.isNotEmpty) return _slots.first.district;
    return 'N/A';
  }

  String get localBodyName {
    // Prefer bag assignment local body
    if (_bagAssignment != null && _bagAssignment!.localBody.isNotEmpty) {
      return _bagAssignment!.localBody;
    }
    if (todaySlots.isNotEmpty) return todaySlots.first.localBody;
    return 'N/A';
  }

  int get remainingBags => _bagAssignment?.remainingBags ?? 0;
  int get assignedBags => _bagAssignment?.assignedBags ?? 0;

  // Sanitary pickups count for today — picked/arrived/collected all count as done
  int get todaySanitaryTotal => todayLocations.length;
  int get todaySanitaryCompleted => todayLocations
      .where((l) {
        final s = l.status.toLowerCase();
        return s == 'picked' ||
            s == 'collected' ||
            s == 'completed' ||
            s == 'arrived';
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
}
