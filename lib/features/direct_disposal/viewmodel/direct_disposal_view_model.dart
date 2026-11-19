import 'package:dio/dio.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/providers/view_model.dart';
import 'package:flutter/material.dart';
import '../model/direct_disposal_model.dart';
import '../repos/direct_disposal_repository.dart';

enum DirectDisposalTab { newRecord, disposalLogs }

class DirectDisposalViewModel extends ViewModel {
  final DirectDisposalRepository _repository;

  DirectDisposalTab _selectedTab = DirectDisposalTab.newRecord;
  List<DirectDisposalLogModel> _logs = [];
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  bool _isExporting = false;

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
  // String _gstRateOption = '5% GST (Standard)';
  String _gstRateOption = '18% GST';
  // Bag Selection State
  int _bagQuantity = 1;

  // Validation Errors
  String? _nameError;
  String? _phoneError;
  String? _addressError;
  String? _weightError;
  bool _hasAttemptedSubmit = false;

  DirectDisposalViewModel({
    DirectDisposalRepository? repository,
  }) : _repository = repository ??
            (getIt.isRegistered<DirectDisposalRepository>()
                ? getIt<DirectDisposalRepository>()
                : DirectDisposalRepository()) {
    loadLogs();
  }

  DirectDisposalTab get selectedTab => _selectedTab;
  List<DirectDisposalLogModel> get logs => _logs;
  String get searchQuery => _searchQuery;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  bool get isExporting => _isExporting;

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

  // Bag Getters

  int get bagQuantity => _bagQuantity;

  double get disposalFee => _weight * _rate;

  String? get nameError => _nameError;
  String? get phoneError => _phoneError;
  String? get addressError => _addressError;
  String? get weightError => _weightError;
  bool get hasAttemptedSubmit => _hasAttemptedSubmit;

  // Options
  // final List<String> disposalTypeOptions = const [
  //   'WALK IN',
  //   'COLLECTION',
  //   'TRANSFER'
  // ];
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
    // '5% GST (Standard)',
    // '12% GST',
    '18% GST',
    // '0% (Exempt)',
  ];

  // Dynamic Financial Calculations
  double get subtotal => (_weight * _rate);

  double get gstPercentage {
    // if (_gstRateOption.contains('5%')) return 5.0;
    // if (_gstRateOption.contains('12%')) return 12.0;
    if (_gstRateOption.contains('18%')) return 18.0;
    return 0.0;
  }

  double get gstAmount => subtotal * (gstPercentage / 100.0);
  double get totalAmount => subtotal + gstAmount;

  List<DirectDisposalLogModel> get filteredLogs {
    final query = _searchQuery.trim().toLowerCase();
    return _logs.where((item) {
      if (query.isNotEmpty) {
        final nameMatches = item.customerName.toLowerCase().contains(query);
        final phoneMatches = item.phone.toLowerCase().contains(query);
        final wasteMatches = item.wasteType.toLowerCase().contains(query);
        if (!nameMatches && !phoneMatches && !wasteMatches) {
          return false;
        }
      }

      if (_selectedDateRange != null) {
        final date = item.dateValue;
        if (date != null) {
          final start = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final end = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23,
            59,
            59,
            999,
          );
          if (date.isBefore(start) || date.isAfter(end)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  Future<void> loadLogs() async {
    _logs = await _repository.fetchLogs();
    notifyListeners();
  }

  Future<Response?> exportLogs({String? collectorId}) async {
    _isExporting = true;
    notifyListeners();
    try {
      return await _repository.exportDisposalLogs(collectorId: collectorId);
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<Response?> downloadLogs(String savePath, {String? collectorId}) async {
    _isExporting = true;
    notifyListeners();
    try {
      return await _repository.downloadDisposalLogs(savePath,
          collectorId: collectorId);
    } finally {
      _isExporting = false;
      notifyListeners();
    }
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

  void setSelectedDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
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
      if (val.trim().isEmpty) {
        _phoneError = 'Phone number is required';
      } else if (!RegExp(r'^[0-9]{10}$').hasMatch(val.trim())) {
        _phoneError = 'Enter a valid 10-digit phone number';
      } else {
        _phoneError = null;
      }
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

  // Bag Mutators

  void setBagQuantity(int val) {
    _bagQuantity = val;
    notifyListeners();
  }

  void incrementBagQuantity() {
    _bagQuantity++;
    notifyListeners();
  }

  void decrementBagQuantity() {
    if (_bagQuantity > 1) {
      _bagQuantity--;
      notifyListeners();
    }
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
    } else if (!RegExp(r'^[0-9]{10}$').hasMatch(_phone.trim())) {
      _phoneError = 'Enter a valid 10-digit phone number';
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

    String mappedDisposalType =
        _disposalType.toLowerCase().replaceAll(' ', '_');
    if (mappedDisposalType == 'walk_in' || mappedDisposalType.isEmpty) {
      mappedDisposalType = 'direct';
    }

    String mappedWasteType = _wasteType.toLowerCase().replaceAll(' waste', '');
    if (mappedWasteType.isEmpty) {
      mappedWasteType = 'plastic';
    }

    await _repository.recordDisposal(
      customerName: _customerName.trim(),
      customerPhone: _phone.trim(),
      customerAddress: _customerAddress.trim(),
      disposalType: mappedDisposalType,
      wasteType: mappedWasteType,
      wasteDescription: _wasteDescription.trim().isEmpty
          ? 'Mixed waste'
          : _wasteDescription.trim(),
      weight: _weight,
      disposalRate: _rate,
      paymentStatus: _paymentStatus,
      bagCount: _bagQuantity,
    );
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
    _gstRateOption = '18% GST';
    _bagQuantity = 1;

    _nameError = null;
    _phoneError = null;
    _addressError = null;
    _weightError = null;
    _hasAttemptedSubmit = false;
    notifyListeners();
  }
}
