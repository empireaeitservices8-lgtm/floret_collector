import 'package:intl/intl.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../model/direct_disposal_model.dart';
import '../repos/direct_disposal_repository.dart';

enum DirectDisposalTab { newRecord, disposalLogs }

class DirectDisposalViewModel extends ViewModel {
  final DirectDisposalRepository _repository;

  DirectDisposalTab _selectedTab = DirectDisposalTab.newRecord;
  List<DirectDisposalLogModel> _logs = [];
  String _searchQuery = '';

  // Form Fields
  String _customerName = '';
  String _phone = '';
  String _customerAddress = '';
  String _disposalType = 'WALK IN';
  String _wasteType = 'MIXED WASTE';
  String _wasteDescription = '';
  double _weight = 0.0;
  double _rate = 2.00;
  String _paymentMethod = 'CASH';
  String _paymentStatus = 'PAID';
  String _gstRateOption = '5% GST (Standard)';

  // Validation Errors
  String? _nameError;
  String? _phoneError;
  String? _addressError;
  String? _weightError;
  bool _hasAttemptedSubmit = false;

  DirectDisposalViewModel({DirectDisposalRepository? repository})
      : _repository = repository ?? DirectDisposalRepository() {
    loadLogs();
  }

  DirectDisposalTab get selectedTab => _selectedTab;
  List<DirectDisposalLogModel> get logs => _logs;
  String get searchQuery => _searchQuery;

  String get customerName => _customerName;
  String get phone => _phone;
  String get customerAddress => _customerAddress;
  String get disposalType => _disposalType;
  String get wasteType => _wasteType;
  String get wasteDescription => _wasteDescription;
  double get weight => _weight;
  double get rate => _rate;
  String get paymentMethod => _paymentMethod;
  String get paymentStatus => _paymentStatus;
  String get gstRateOption => _gstRateOption;

  String? get nameError => _nameError;
  String? get phoneError => _phoneError;
  String? get addressError => _addressError;
  String? get weightError => _weightError;
  bool get hasAttemptedSubmit => _hasAttemptedSubmit;

  // Options
  final List<String> disposalTypeOptions = const [
    'WALK IN',
    'COLLECTION',
    'TRANSFER'
  ];
  final List<String> wasteTypeOptions = const [
    'MIXED WASTE',
    'BIO WASTE',
    'SANITARY WASTE',
    'HOUSEHOLD',
    'DRY WASTE',
    'WET WASTE',
    'HAZARDOUS',
  ];
  final List<String> paymentMethodOptions = const ['CASH', 'ONLINE'];
  final List<String> paymentStatusOptions = const ['PAID', 'PENDING'];
  final List<String> gstRateOptions = const [
    '5% GST (Standard)',
    '12% GST',
    '18% GST',
    '0% (Exempt)',
  ];

  // Dynamic Financial Calculations
  double get subtotal => _weight * _rate;

  double get gstPercentage {
    if (_gstRateOption.contains('5%')) return 5.0;
    if (_gstRateOption.contains('12%')) return 12.0;
    if (_gstRateOption.contains('18%')) return 18.0;
    return 0.0;
  }

  double get gstAmount => subtotal * (gstPercentage / 100.0);
  double get totalAmount => subtotal + gstAmount;

  List<DirectDisposalLogModel> get filteredLogs {
    if (_searchQuery.trim().isEmpty) return _logs;
    final query = _searchQuery.trim().toLowerCase();
    return _logs.where((item) {
      final nameMatches = item.customerName.toLowerCase().contains(query);
      final phoneMatches = item.phone.toLowerCase().contains(query);
      final wasteMatches = item.wasteType.toLowerCase().contains(query);
      return nameMatches || phoneMatches || wasteMatches;
    }).toList();
  }

  Future<void> loadLogs() async {
    _logs = await _repository.fetchLogs();
    notifyListeners();
  }

  void setSelectedTab(DirectDisposalTab tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Field Setters with Real-time Validation Updates if user already attempted submit
  void setCustomerName(String val) {
    _customerName = val;
    if (_hasAttemptedSubmit) {
      _nameError = val.trim().isEmpty ? 'Name is required' : null;
    }
    notifyListeners();
  }

  void setPhone(String val) {
    _phone = val;
    if (_hasAttemptedSubmit) {
      _phoneError = val.trim().isEmpty ? 'Phone number is required' : null;
    }
    notifyListeners();
  }

  void setCustomerAddress(String val) {
    _customerAddress = val;
    if (_hasAttemptedSubmit) {
      _addressError = val.trim().isEmpty ? 'Address is required' : null;
    }
    notifyListeners();
  }

  void setDisposalType(String val) {
    _disposalType = val;
    notifyListeners();
  }

  void setWasteType(String val) {
    _wasteType = val;
    notifyListeners();
  }

  void setWasteDescription(String val) {
    _wasteDescription = val;
    notifyListeners();
  }

  void setWeight(double val) {
    _weight = val;
    if (_hasAttemptedSubmit) {
      _weightError = val <= 0 ? 'Weight required' : null;
    }
    notifyListeners();
  }

  void setRate(double val) {
    _rate = val;
    notifyListeners();
  }

  void setPaymentMethod(String val) {
    _paymentMethod = val;
    notifyListeners();
  }

  void setPaymentStatus(String val) {
    _paymentStatus = val;
    notifyListeners();
  }

  void setGstRateOption(String val) {
    _gstRateOption = val;
    notifyListeners();
  }

  bool validateForm() {
    _hasAttemptedSubmit = true;
    bool isValid = true;

    if (_customerName.trim().isEmpty) {
      _nameError = 'Name is required';
      isValid = false;
    } else {
      _nameError = null;
    }

    if (_phone.trim().isEmpty) {
      _phoneError = 'Phone number is required';
      isValid = false;
    } else {
      _phoneError = null;
    }

    if (_customerAddress.trim().isEmpty) {
      _addressError = 'Address is required';
      isValid = false;
    } else {
      _addressError = null;
    }

    if (_weight <= 0.0) {
      _weightError = 'Weight required';
      isValid = false;
    } else {
      _weightError = null;
    }

    notifyListeners();
    return isValid;
  }

  Future<bool> submitRecord() async {
    final isValid = validateForm();
    if (!isValid) return false;

    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(now);

    final newLog = DirectDisposalLogModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      customerName: _customerName.trim(),
      phone: _phone.trim(),
      customerAddress: _customerAddress.trim(),
      disposalType: _disposalType,
      wasteType: _wasteType,
      wasteDescription: _wasteDescription.trim(),
      weight: _weight,
      rate: _rate,
      gstRatePercent: gstPercentage,
      gstAmount: gstAmount,
      totalAmount: totalAmount,
      paymentMethod: _paymentMethod,
      paymentStatus: _paymentStatus,
      formattedDate: formattedDate,
    );

    await _repository.addLog(newLog);
    await loadLogs();

    // Reset Form
    resetForm();

    // Switch to Disposal Logs tab to see the newly added log
    _selectedTab = DirectDisposalTab.disposalLogs;
    notifyListeners();

    return true;
  }

  void resetForm() {
    _customerName = '';
    _phone = '';
    _customerAddress = '';
    _disposalType = 'WALK IN';
    _wasteType = 'MIXED WASTE';
    _wasteDescription = '';
    _weight = 0.0;
    _rate = 2.00;
    _paymentMethod = 'CASH';
    _paymentStatus = 'PAID';
    _gstRateOption = '5% GST (Standard)';

    _nameError = null;
    _phoneError = null;
    _addressError = null;
    _weightError = null;
    _hasAttemptedSubmit = false;
    notifyListeners();
  }
}
