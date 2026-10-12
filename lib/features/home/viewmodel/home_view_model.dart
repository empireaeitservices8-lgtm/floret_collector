import 'package:floret_collector/features/home/model/bag_model.dart';
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
  List<BagModel> _bags = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PickupSlotModel> get slots => List.unmodifiable(_slots);
  String get collectorName => _collectorName;
  List<BagModel> get bags => List.unmodifiable(_bags);

  // Load collector details from SharedPrefs
  Future<void> loadCollector() async {
    final collector = await _collectorLocalStorage.getCollector();
    debugPrint("Collector Details ${collector.toString()}");

    _collectorName = collector?['name']?.toString() ?? '';

    notifyListeners();
  }

  // Load pickup slots from API
  Future<void> loadPickupSlots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getPickupSlots();
      debugPrint("Pickups ${response.toString()}");
      _slots = response.slots;
    } catch (e) {
      _errorMessage = 'Unable to load pickup slots';
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<void> loadBags() async {
    try {
      _bags = await _repository.getBags();
      debugPrint("response ${bags.toString()} ");
      notifyListeners();
    } catch (e) {
      debugPrint('Unable to load bags: $e');
    }
  }
}
