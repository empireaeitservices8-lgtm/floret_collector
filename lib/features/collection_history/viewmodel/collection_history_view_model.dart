import 'package:intl/intl.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../model/collection_history_model.dart';
import '../repos/collection_history_repository.dart';

class CollectionHistoryViewModel extends ViewModel {
  final CollectionHistoryRepository _repository;

  bool _isShimmering = true;
  bool _isTimeoutError = false;
  String _errorMessage = '';
  List<CollectionItemModel> _allHistory = [];
  CollectionSummaryModel _baseSummary = const CollectionSummaryModel();
  String _searchQuery = '';
  CollectionFilterModel _filter = CollectionFilterModel.empty;

  CollectionHistoryViewModel({CollectionHistoryRepository? repository})
      : _repository = repository ??
            (getIt.isRegistered<CollectionHistoryRepository>()
                ? getIt<CollectionHistoryRepository>()
                : CollectionHistoryRepository()) {
    loadHistory();
  }

  bool get isShimmering => _isShimmering;
  bool get isTimeoutError => _isTimeoutError;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  CollectionFilterModel get filter => _filter;

  List<CollectionItemModel> get filteredHistory {
    if (_isTimeoutError) return [];

    return _allHistory.where((item) {
      // Waste Type filter
      if (_filter.wasteType != 'All' &&
          item.wasteType.toLowerCase() != _filter.wasteType.toLowerCase()) {
        return false;
      }

      // Payment Status filter
      if (_filter.paymentStatus != 'All' &&
          item.status.toLowerCase() != _filter.paymentStatus.toLowerCase()) {
        return false;
      }

      // Payment Method filter
      if (_filter.paymentMethod != 'All' &&
          item.paymentMethod.toLowerCase() !=
              _filter.paymentMethod.toLowerCase()) {
        return false;
      }

      // Date Range filter
      if (_filter.dateRange != null && item.dateTime != null) {
        final start = DateTime(
          _filter.dateRange!.start.year,
          _filter.dateRange!.start.month,
          _filter.dateRange!.start.day,
        );
        final end = DateTime(
          _filter.dateRange!.end.year,
          _filter.dateRange!.end.month,
          _filter.dateRange!.end.day,
          23,
          59,
          59,
        );
        if (item.dateTime!.isBefore(start) || item.dateTime!.isAfter(end)) {
          return false;
        }
      }

      // Search Query filter: by Stop ID, Stop Name, or Waste Type
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesStopId = item.stopId.toLowerCase().contains(query);
        final matchesHashStopId =
            '#${item.stopId}'.toLowerCase().contains(query);
        final matchesStopName = item.stopName.toLowerCase().contains(query);
        final matchesWasteType = item.wasteType.toLowerCase().contains(query);
        final matchesCombined =
            '#${item.stopId} • ${item.stopName}'.toLowerCase().contains(query);

        if (!matchesStopId &&
            !matchesHashStopId &&
            !matchesStopName &&
            !matchesWasteType &&
            !matchesCombined) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  CollectionSummaryModel get effectiveSummary {
    if (_isTimeoutError) {
      return const CollectionSummaryModel(
        totalStops: 0,
        totalWeight: 0.0,
        totalAmount: 0.0,
      );
    }

    final list = filteredHistory;

    // Filter items till today
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final tillTodayList = list.where((item) {
      if (item.dateTime == null) return true;
      return item.dateTime!.isBefore(endOfToday) ||
          item.dateTime!.isAtSameMomentAs(endOfToday);
    }).toList();

    // When empty
    if (tillTodayList.isEmpty) {
      if (!_filter.hasFilters && _searchQuery.trim().isEmpty) {
        return _baseSummary;
      }
      return const CollectionSummaryModel(
        totalStops: 0,
        totalWeight: 0.0,
        totalAmount: 0.0,
      );
    }

    if (!_filter.hasFilters &&
        _searchQuery.trim().isEmpty &&
        _baseSummary.totalStops > 0) {
      return _baseSummary;
    }

    final totalWeight =
        tillTodayList.fold<double>(0.0, (sum, i) => sum + i.weight);
    final totalAmount =
        tillTodayList.fold<double>(0.0, (sum, i) => sum + i.amount);

    return CollectionSummaryModel(
      totalStops: tillTodayList.length,
      totalWeight: totalWeight,
      totalAmount: totalAmount,
    );
  }

  int _currentLoadId = 0;

  Future<void> loadHistory({bool simulateTimeout = false}) async {
    final loadId = ++_currentLoadId;
    _isShimmering = true;
    _isTimeoutError = false;
    _errorMessage = '';
    notifyListeners();

    // 1. Shimmer effect must run for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (loadId != _currentLoadId) return;

    try {
      final now = DateTime.now();
      final defaultDateTo = DateFormat('yyyy-MM-dd').format(now);
      final defaultDateFrom =
          DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month - 1, 1));

      final dateFrom = _filter.dateRange != null
          ? DateFormat('yyyy-MM-dd').format(_filter.dateRange!.start)
          : defaultDateFrom;
      final dateTo = _filter.dateRange != null
          ? DateFormat('yyyy-MM-dd').format(_filter.dateRange!.end)
          : defaultDateTo;
      final wasteType = _filter.wasteType != 'All' ? _filter.wasteType : null;
      final paymentStatus =
          _filter.paymentStatus != 'All' ? _filter.paymentStatus : null;

      final result = await _repository.fetchHistory(
        dateFrom: dateFrom,
        dateTo: dateTo,
        wasteType: wasteType,
        paymentStatus: paymentStatus,
        simulateTimeout: simulateTimeout,
      );
      if (loadId != _currentLoadId) return;
      _allHistory = result.items;
      _baseSummary = result.summary;
      if (_baseSummary.totalStops == 0 && result.items.isNotEmpty) {
        final totalWeight =
            result.items.fold<double>(0.0, (sum, i) => sum + i.weight);
        final totalAmount =
            result.items.fold<double>(0.0, (sum, i) => sum + i.amount);
        _baseSummary = CollectionSummaryModel(
          totalStops: result.items.length,
          totalWeight: totalWeight,
          totalAmount: totalAmount,
        );
      }
      _isTimeoutError = false;
    } catch (e) {
      if (loadId != _currentLoadId) return;
      _isTimeoutError = true;
      _errorMessage = e.toString();
    } finally {
      if (loadId == _currentLoadId) {
        _isShimmering = false;
        notifyListeners();
      }
    }
  }

  void retry() {
    loadHistory(simulateTimeout: false);
  }

  void toggleTimeoutForTesting() {
    if (_isTimeoutError) {
      loadHistory(simulateTimeout: false);
    } else {
      loadHistory(simulateTimeout: true);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void applyFilters(CollectionFilterModel newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void removeWasteTypeFilter() {
    _filter = _filter.copyWith(wasteType: 'All');
    notifyListeners();
  }

  void removeStatusFilter() {
    _filter = _filter.copyWith(paymentStatus: 'All');
    notifyListeners();
  }

  void removeMethodFilter() {
    _filter = _filter.copyWith(paymentMethod: 'All');
    notifyListeners();
  }

  void removeDateRangeFilter() {
    _filter = _filter.copyWith(clearDateRange: true);
    notifyListeners();
  }

  void clearAllFilters() {
    _filter = CollectionFilterModel.empty;
    _searchQuery = '';
    notifyListeners();
  }
}
