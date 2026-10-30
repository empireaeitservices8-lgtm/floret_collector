import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:floret_collector/features/collection_route/repository/collection_history_repository.dart';
import 'package:floret_collector/core/storage/collection_metrics_storage.dart';

class VerificationPhotoItem {
  final File file;
  final String name;
  String status; // 'ready', 'uploading', 'uploaded', 'error'
  String? error;

  VerificationPhotoItem({
    required this.file,
    required this.name,
    this.status = 'ready',
    this.error,
  });

  bool get isUploading => status == 'uploading';
  bool get isUploaded => status == 'uploaded';
  bool get isError => status == 'error';

  Color get statusColor {
    if (isUploaded) return const Color(0xFF16A34A);
    if (isUploading) return const Color(0xFF2563EB);
    if (isError) return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  String get statusText {
    if (isUploaded) return 'Uploaded';
    if (isUploading) return 'Uploading...';
    if (isError) return error != null ? 'Upload failed' : 'Upload error';
    return 'Ready to upload';
  }
}

class ConfirmAndPayViewModel extends ChangeNotifier {
  final WardRouteRepository _repository = WardRouteRepository();
  final ImagePicker _imagePicker = ImagePicker();

  // ── Constructor inputs ──────────────────────
  final int pickupId;
  final int collectorId;
  final String initialAddress;
  final String initialWasteType;
  final String initialLocalBody;
  final double? initialDisposalRate;

  ConfirmAndPayViewModel({
    required this.pickupId,
    required this.collectorId,
    this.initialAddress = '',
    this.initialWasteType = '',
    this.initialLocalBody = '',
    this.initialDisposalRate,
  }) {
    _address = initialAddress;
    _wasteType = initialWasteType;
    _localBody = initialLocalBody;
    _disposalRate = (initialDisposalRate != null && initialDisposalRate! > 0)
        ? initialDisposalRate!
        : 42.0;
  }

  // ── State ───────────────────────────────────
  bool _isFetchingInitialData = true;
  bool _isLoading = false;

  String _address = '';
  String _userName = '';
  String _userPhone = '';
  String _wasteType = '';
  String _localBody = '';
  double _disposalRate = 42.00;

  int _bagQuantity = 0;
  final double _bagPrice = 7.00;
  double _wasteWeight = 5.0;

  final bool _redeemWallet = false;
  final bool _applyCoupon = false;

  String _selectedPaymentOption = 'Cash'; // 'Cash', 'Online (QR)'
  final List<VerificationPhotoItem> _verificationPhotos = [];

  String? _lastUploadMessage;
  bool _lastUploadSuccess = false;
  Map<String, dynamic> _paymentReceiptArguments = {};

  // ── Getters ─────────────────────────────────
  bool get isFetchingInitialData => _isFetchingInitialData;
  bool get isLoading => _isLoading;

  String get address => _address;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get wasteType => _wasteType;
  String get localBody => _localBody;
  double get disposalRate => _disposalRate;

  int get bagQuantity => _bagQuantity;
  double get bagPrice => _bagPrice;
  double get wasteWeight => _wasteWeight;

  bool get redeemWallet => _redeemWallet;
  bool get applyCoupon => _applyCoupon;

  String get selectedPaymentOption => _selectedPaymentOption;
  bool get isOnlinePayment => _selectedPaymentOption == 'Online (QR)';

  List<VerificationPhotoItem> get verificationPhotos =>
      List.unmodifiable(_verificationPhotos);
  bool get hasMaxPhotos => _verificationPhotos.length >= 5;
  bool get canAddMorePhotos => _verificationPhotos.length < 5;

  String? get lastUploadMessage => _lastUploadMessage;
  bool get lastUploadSuccess => _lastUploadSuccess;
  Map<String, dynamic> get paymentReceiptArguments => _paymentReceiptArguments;

  // ── Calculations (isolated completely from UI) ──
  double get bagsCost => _bagQuantity * _bagPrice;
  double get disposalFee => _wasteWeight * _disposalRate;
  double get subtotal => bagsCost + disposalFee;
  double get gst => subtotal * 0.18;
  double get grossTotal => subtotal + gst;
  double get totalPayable => grossTotal;

  // ── Formatted display strings (Zero UI string math) ──
  String get addressDisplay => _address.isNotEmpty ? _address : initialAddress;
  String get userSubtitleDisplay =>
      _userName.isNotEmpty ? '$_userName • $_userPhone' : addressDisplay;

  String get bagPriceLabel => 'Price: ₹${_bagPrice.toInt()} per bag';
  String get localBodySummaryLabel =>
      '${_localBody.isNotEmpty ? _localBody : initialLocalBody} (Rate: ₹${_disposalRate.toStringAsFixed(2)}/kg)';

  String get bagsCostSummaryLabel =>
      'Waste Bags cost ($_bagQuantity × ₹${_bagPrice.toInt()})';
  String get formattedBagsCost => '₹${bagsCost.toStringAsFixed(2)}';

  String get disposalFeeSummaryLabel =>
      'Disposal Fee (${_wasteWeight.toStringAsFixed(1)} Kgs at ₹${_disposalRate.toStringAsFixed(2)}/kg)';
  String get formattedDisposalFee => '₹${disposalFee.toStringAsFixed(2)}';

  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';
  String get formattedGst => '₹${gst.toStringAsFixed(2)}';
  String get formattedGrossTotal => '₹${grossTotal.toStringAsFixed(2)}';
  String get formattedTotalPayable => '₹${totalPayable.toStringAsFixed(2)}';

  String get qrPreviewText =>
      'Generate dynamic UPI QR code for ₹${totalPayable.toStringAsFixed(2)}. Customer can scan with GPay, PhonePe, Paytm, or BHIM to pay instantly.';

  String get confirmButtonText {
    if (isOnlinePayment) {
      return 'Generate Razorpay QR (₹${totalPayable.toStringAsFixed(2)})';
    }
    if (totalPayable > 0) {
      return 'Confirm Payment (₹${totalPayable.toStringAsFixed(2)})';
    }
    return 'Confirm Payment (Fully Covered)';
  }

  String get photoCountLabel =>
      'Add Verification Photo (${_verificationPhotos.length}/5)';

  // ── Mutators ────────────────────────────────
  void incrementBagQuantity() {
    _bagQuantity++;
    notifyListeners();
  }

  void decrementBagQuantity() {
    if (_bagQuantity > 0) {
      _bagQuantity--;
      notifyListeners();
    }
  }

  void setWasteWeightFromString(String text) {
    final val = double.tryParse(text.trim()) ?? 0.0;
    if (val != _wasteWeight) {
      _wasteWeight = val;
      notifyListeners();
    }
  }

  void setSelectedPaymentOption(String option) {
    if (option != _selectedPaymentOption) {
      _selectedPaymentOption = option;
      notifyListeners();
    }
  }

  // ── Load initial data from API ──────────────
  // Note: disposal rate is NOT fetched here; it is passed from the route screen when Collect was pressed!
  Future<void> loadInitialData() async {
    if (pickupId <= 0) {
      _isFetchingInitialData = false;
      notifyListeners();
      return;
    }

    try {
      final data = await _repository.fetchConfirmAndPayData(
        pickupId: pickupId,
      );

      if (data != null) {
        final pickupData = data['pickup_data'] as Map<String, dynamic>?;
        if (pickupData != null) {
          _address = pickupData['address']?.toString() ?? _address;
          _userName = pickupData['user_name']?.toString() ?? '';
          _userPhone = pickupData['user_phone']?.toString() ?? '';
          _wasteType = pickupData['waste_type']?.toString() ?? _wasteType;
          final serverLocalBody = pickupData['local_body']?.toString();
          if (serverLocalBody != null &&
              serverLocalBody.isNotEmpty &&
              _localBody.isEmpty) {
            _localBody = serverLocalBody;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading confirm & pay data: $e');
    } finally {
      _isFetchingInitialData = false;
      notifyListeners();
    }
  }

  // ── Payment API processing (Zero API response in UI) ──
  Future<bool> confirmPayment() async {
    _isLoading = true;
    notifyListeners();

    String billTransactionId = 'CASH-${DateTime.now().millisecondsSinceEpoch}';
    String billId = '${DateTime.now().millisecondsSinceEpoch % 1000}';

    try {
      final methodStr = _selectedPaymentOption.toLowerCase().contains('online')
          ? 'online'
          : (_selectedPaymentOption.toLowerCase().contains('wallet')
              ? 'wallet'
              : 'cash');

      // 1. POST /api/generate-bill/
      final billBody = {
        'pickup_id': pickupId,
        'weight': _wasteWeight,
        'rate': _disposalRate,
        'total_amount': double.parse(totalPayable.toStringAsFixed(2)),
        'payment_method': methodStr,
        'transaction_id': billTransactionId,
        'payment_gateway': methodStr == 'online' ? 'online' : 'cash',
        'payment_status': 'paid',
        'remarks': 'Waste collection payment',
      };
      final billRes = await _repository.generateBill(body: billBody);
      if (billRes != null) {
        final billData = billRes['bill'] as Map<String, dynamic>?;
        if (billData != null) {
          billId = billData['id']?.toString() ?? billId;
          billTransactionId =
              billData['transaction_id']?.toString() ?? billTransactionId;
        }
      }

      // 2. POST /api/process-payment/
      await _repository.processPayment(
        pickupId: pickupId,
        paymentMethod: methodStr,
      );

      // 3. POST /api/confirm-and-pay/
      final confirmPayBody = {
        'pickup_id': pickupId,
        'collector_id': collectorId,
        'weight': _wasteWeight,
        'payment_method': methodStr,
        'redeem_wallet': _redeemWallet,
        'wallet_redeemed': _redeemWallet,
        'apply_voucher': _applyCoupon,
        'transaction_id': 'BILL-$billId',
      };
      await _repository.confirmAndPay(body: confirmPayBody);

      // 4. POST /api/update-pickup-status/
      await _repository.updatePickupStatus(
        pickupId: pickupId,
        status: 'completed',
      );

      // 5. POST /api/collect-pickup/
      await _repository.collectPickup(
        pickupId: pickupId,
        collectorId: collectorId,
      );

      // 6. Record collection metrics
      await CollectionMetricsStorage().recordCollection(
        pickupId:
            pickupId > 0 ? pickupId : DateTime.now().millisecondsSinceEpoch,
        weight: _wasteWeight,
        amount: totalPayable,
      );

      // Prepare navigation arguments inside ViewModel
      _paymentReceiptArguments = {
        'totalAmount': totalPayable,
        'paymentMode': _selectedPaymentOption,
        'transactionId': 'BILL-$billId',
        'dateTime': DateTime.now(),
        'bagsCollected': _bagQuantity,
        'disposalWeight': _wasteWeight,
      };

      return true;
    } catch (e) {
      debugPrint('Confirm & pay processing error: $e');
      _paymentReceiptArguments = {
        'totalAmount': totalPayable,
        'paymentMode': _selectedPaymentOption,
        'transactionId': 'BILL-$billId',
        'dateTime': DateTime.now(),
        'bagsCollected': _bagQuantity,
        'disposalWeight': _wasteWeight,
      };
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int? _billId;
  int? get billId => _billId;

  Future<int?> ensureBillGenerated() async {
    if (_billId != null && _billId! > 0) return _billId;
    try {
      final billBody = {
        'pickup_id': pickupId,
        'weight': _wasteWeight,
        'rate': _disposalRate,
        'total_amount': double.parse(totalPayable.toStringAsFixed(2)),
        'payment_method': 'online',
        'transaction_id': 'RZP-${DateTime.now().millisecondsSinceEpoch}',
        'payment_gateway': 'razorpay',
        'payment_status': 'pending',
        'remarks': 'Razorpay QR waste collection bill',
      };
      final billRes = await _repository.generateBill(body: billBody);
      if (billRes != null) {
        if (billRes['bill'] is Map) {
          _billId = (billRes['bill']['id'] as num?)?.toInt() ??
              int.tryParse(billRes['bill']['id']?.toString() ?? '');
        }
        _billId ??= (billRes['id'] as num?)?.toInt() ??
            (billRes['bill_id'] as num?)?.toInt() ??
            int.tryParse(billRes['id']?.toString() ?? '') ??
            int.tryParse(billRes['bill_id']?.toString() ?? '');
      }
      return _billId;
    } catch (e) {
      debugPrint('Error generating bill for online payment: $e');
      return null;
    }
  }

  // ── Razorpay QR arguments ───────────────────
  Map<String, dynamic> get razorpayQRArguments => {
        'pickupId': pickupId,
        'collectorId': collectorId,
        'amount': totalPayable,
        if (_billId != null) 'billId': _billId,
        'address': _address,
        'userName': _userName,
        'userPhone': _userPhone,
        'wasteWeight': _wasteWeight,
        'bagQuantity': _bagQuantity,
        'disposalRate': _disposalRate,
        'redeemWallet': _redeemWallet,
        'applyCoupon': _applyCoupon,
      };

  // ── Photo verification ──────────────────────
  Future<bool> pickVerificationPhoto() async {
    if (_verificationPhotos.length >= 5) {
      return false;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked != null) {
        _verificationPhotos.add(
          VerificationPhotoItem(
            file: File(picked.path),
            name: picked.name,
          ),
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Could not open camera: $e');
      rethrow;
    }
    return false;
  }

  Future<bool> uploadPhoto(int index) async {
    if (index < 0 || index >= _verificationPhotos.length) return false;
    final photo = _verificationPhotos[index];

    photo.status = 'uploading';
    photo.error = null;
    notifyListeners();

    try {
      final bytes = await photo.file.readAsBytes();
      final base64String = base64Encode(bytes);

      final res = await _repository.uploadWastePhoto(
        pickupId: pickupId,
        photoBase64: base64String,
      );

      if (res != null) {
        photo.status = 'uploaded';
        _lastUploadSuccess = true;
        _lastUploadMessage = 'Waste photo uploaded successfully';
        notifyListeners();
        return true;
      } else {
        photo.status = 'error';
        photo.error = 'Upload failed';
        _lastUploadSuccess = false;
        _lastUploadMessage = 'Failed to upload photo to server';
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      photo.status = 'error';
      photo.error = errorMsg;
      _lastUploadSuccess = false;
      _lastUploadMessage = 'Error uploading photo to server: $errorMsg';
      notifyListeners();
      return false;
    }
  }

  void deletePhoto(int index) {
    if (index < 0 || index >= _verificationPhotos.length) return;
    _verificationPhotos.removeAt(index);
    notifyListeners();
  }
}
