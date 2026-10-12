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
  CollectionSummaryModel _baseSummary = const CollectionSummaryModel(
    totalStops: 348,
    totalWeight: 19104.0,
    totalAmount: 786223.0,
  );
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

    // When empty (e.g. Bio waste selected in Image 4)
    if (list.isEmpty) {
      return const CollectionSummaryModel(
        totalStops: 0,
        totalWeight: 0.0,
        totalAmount: 0.0,
      );
    }

    // When user has active filters or search applied
    if (_filter.hasFilters || _searchQuery.trim().isNotEmpty) {
      final totalWeight = list.fold<double>(0.0, (sum, i) => sum + i.weight);
      final totalAmount = list.fold<double>(0.0, (sum, i) => sum + i.amount);
      return CollectionSummaryModel(
        totalStops: list.length,
        totalWeight: totalWeight,
        totalAmount: totalAmount,
      );
    }

    // Default when no filters applied (Image 1, Image 2)
    return _baseSummary;
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
      final result =
          await _repository.fetchHistory(simulateTimeout: simulateTimeout);
      if (loadId != _currentLoadId) return;
      _allHistory = result.items;
      _baseSummary = result.summary;
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
