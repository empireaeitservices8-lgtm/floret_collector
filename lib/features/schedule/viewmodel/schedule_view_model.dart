import 'package:floret_collector/features/home/model/location_pickup_model.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../model/schedule_filter_model.dart';
import '../repos/schedule_repository.dart';

class ScheduleViewModel extends ViewModel {
  final ScheduleRepository _repository;

  ScheduleFilterModel _filter = const ScheduleFilterModel();
  List<String> _availableDates = [];
  String _selectedDate = '';
  List<LocationPickupModel> _allPickups = [];

  ScheduleViewModel({ScheduleRepository? repository})
      : _repository = repository ?? ScheduleRepository() {
    loadSchedule();
  }

  ScheduleFilterModel get filter => _filter;
  List<String> get availableDates => _availableDates;
  String get selectedDate => _selectedDate;

  /// Returns today formatted as "YYYY-MM-DD"
  static String get todayDateStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Label for selected date in progress card: "Today's progress"
  String get progressHeaderTitle {
    return "Today's progress";
  }

  /// Pickups for the currently selected date (sorted so completed/arrived/picked are last)
  List<LocationPickupModel> get pickupsForSelectedDate {
    if (_selectedDate.isEmpty) return [];

    final list = _allPickups.where((p) {
      if (p.pickupDate.isEmpty) return false;
      return p.pickupDate.length >= 10 &&
          p.pickupDate.substring(0, 10) == _selectedDate;
    }).toList();

    list.sort((a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));
    return list;
  }

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

  bool _isCompleted(String status) {
    final s = status.toLowerCase();
    return s == 'picked' ||
        s == 'collected' ||
        s == 'completed' ||
        s == 'arrived';
  }

  /// Filtered list of pickups according to filter bottom sheet
  List<LocationPickupModel> get filteredPickups {
    final base = pickupsForSelectedDate;
    if (base.isEmpty) return [];

    return base.where((p) {
      // 1. Waste type filter
      if (_filter.pickupType == PickupTypeFilter.sanitary) {
        if (!p.wasteType.toLowerCase().contains('sanitary')) {
          return false;
        }
      } else if (_filter.pickupType == PickupTypeFilter.scrap) {
        if (!p.wasteType.toLowerCase().contains('scrap')) {
          return false;
        }
      }

      // 2. Collection status filter
      if (_filter.collectionStatus == CollectionStatusFilter.pending) {
        if (_isCompleted(p.status)) return false;
      } else if (_filter.collectionStatus == CollectionStatusFilter.completed) {
        if (!_isCompleted(p.status)) return false;
      }

      return true;
    }).toList();
  }

  /// Total count for selected date
  int get totalPickupsCount => pickupsForSelectedDate.length;

  /// Completed count for selected date
  int get completedPickupsCount =>
      pickupsForSelectedDate.where((p) => _isCompleted(p.status)).length;

  /// Sanitary pickups ratio string e.g. "1/3" or "0/1"
  String get sanitaryPickupsText {
    final sanitaryList = pickupsForSelectedDate
        .where((p) => p.wasteType.toLowerCase().contains('sanitary'))
        .toList();
    final total = sanitaryList.length;
    final done = sanitaryList.where((p) => _isCompleted(p.status)).length;
    return '$done/$total';
  }

  /// Scrap pickups ratio string e.g. "0/0"
  String get scrapPickupsText {
    final scrapList = pickupsForSelectedDate
        .where((p) => p.wasteType.toLowerCase().contains('scrap'))
        .toList();
    final total = scrapList.length;
    final done = scrapList.where((p) => _isCompleted(p.status)).length;
    return '$done/$total';
  }

  /// Progress fraction (0.0 to 1.0)
  double get progressFraction {
    if (totalPickupsCount == 0) return 0.0;
    return completedPickupsCount / totalPickupsCount;
  }

  /// Progress text e.g. "1 of 3 completed" or "0 of 1 completed"
  String get progressText {
    return '$completedPickupsCount of $totalPickupsCount completed';
  }

  /// Header text for waste type
  String get wasteTypeDisplay {
    if (_filter.pickupType == PickupTypeFilter.sanitary) {
      return 'Sanitary waste';
    } else if (_filter.pickupType == PickupTypeFilter.scrap) {
      return 'Scrap waste';
    }
    return 'Sanitary & Scrap waste';
  }

  /// Format date string "YYYY-MM-DD" for UI pill
  String formatPillDate(String dateStr) {
    return ScheduleRepository.formatDateString(dateStr);
  }

  /// Select a date pill
  void selectDate(String dateStr) {
    if (_selectedDate != dateStr) {
      _selectedDate = dateStr;
      notifyListeners();
    }
  }

  void setFilter(ScheduleFilterModel newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void resetFilter() {
    _filter = const ScheduleFilterModel();
    notifyListeners();
  }

  Future<void> loadSchedule() async {
    isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchCollectorPickupDates(),
        _repository.fetchLocations(),
      ]);

      final fetchedDates = results[0] as List<String>;
      final fetchedPickups = results[1] as List<LocationPickupModel>;

      _allPickups = fetchedPickups;

      // Extract all unique dates from pickups as well
      final pickupDatesSet = <String>{};
      for (final p in fetchedPickups) {
        if (p.pickupDate.isNotEmpty && p.pickupDate.length >= 10) {
          pickupDatesSet.add(p.pickupDate.substring(0, 10));
        }
      }

      // Merge dates from collector-pickup-dates and pickups, ensuring today is included
      final todayStr = todayDateStr;
      final mergedDates = <String>{todayStr, ...fetchedDates, ...pickupDatesSet}
          .where((d) => d.compareTo(todayStr) >= 0)
          .toList();

      // Sort dates chronologically
      mergedDates.sort((a, b) => a.compareTo(b));
      _availableDates = mergedDates;

      // Default selection to today if available, or first date
      if (_selectedDate.isEmpty || !_availableDates.contains(_selectedDate)) {
        if (_availableDates.contains(todayStr)) {
          _selectedDate = todayStr;
        } else if (_availableDates.isNotEmpty) {
          _selectedDate = _availableDates.first;
        }
      }
    } catch (e) {
      // fallback
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
