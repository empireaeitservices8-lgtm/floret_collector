import 'package:floret_collector/providers/view_model.dart';
import '../model/billing_history_model.dart';
import '../repos/billing_history_repository.dart';

class BillingHistoryViewModel extends ViewModel {
  final BillingHistoryRepository _repository;

  List<BillItemModel> _allBills = [];
  String _searchQuery = '';
  String _selectedMethod = 'All';
  String _selectedStatus = 'All';

  final List<String> methodOptions = const ['All', 'Cash', 'Online'];
  final List<String> statusOptions = const ['All', 'Paid', 'Pending'];

  BillingHistoryViewModel({BillingHistoryRepository? repository})
      : _repository = repository ?? BillingHistoryRepository() {
    loadBills();
  }

  String get searchQuery => _searchQuery;
  String get selectedMethod => _selectedMethod;
  String get selectedStatus => _selectedStatus;

  List<BillItemModel> get filteredBills {
    return _allBills.where((bill) {
      // Method filter: All, Cash, Online
      if (_selectedMethod != 'All' &&
          bill.method.toLowerCase() != _selectedMethod.toLowerCase()) {
        return false;
      }

      // Status filter: All, Paid, Pending
      if (_selectedStatus != 'All' &&
          bill.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }

      // Search query filter: by Bill ID, Stop ID, or Stop Name
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesId = bill.id.toLowerCase().contains(query);
        final matchesStopId = bill.stopId.toLowerCase().contains(query);
        final matchesStopName = bill.stopName.toLowerCase().contains(query);
        final matchesCombined =
            '#${bill.stopId} • ${bill.stopName}'.toLowerCase().contains(query);

        if (!matchesId && !matchesStopId && !matchesStopName && !matchesCombined) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> loadBills() async {
    isLoading = true;
    notifyListeners();

    _allBills = await _repository.fetchBills();

    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedMethod(String method) {
    if (_selectedMethod != method) {
      _selectedMethod = method;
      notifyListeners();
    }
  }

  void setSelectedStatus(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      notifyListeners();
    }
  }
}
