import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:floret_collector/features/collection_route/repository/ward_route_repository.dart';
import 'package:floret_collector/core/storage/collection_metrics_storage.dart';
import 'payment_receipt_screen.dart';
import 'available_coupons_vouchers_screen.dart';
import 'razorpay_qr_screen.dart';

class ConfirmAndPayScreen extends StatefulWidget {
  static const String routeName = '/ConfirmAndPayScreen';

  final int pickupId;
  final int collectorId;
  final String address;
  final String wasteType;
  final String localBody;
  final double disposalRate;

  const ConfirmAndPayScreen({
    super.key,
    this.pickupId = 0,
    this.collectorId = 0,
    this.address = 'Main Road',
    this.wasteType = 'Scheduled pickup',
    this.localBody = 'Nedumangadu Municipality',
    this.disposalRate = 42.00,
  });

  @override
  State<ConfirmAndPayScreen> createState() => _ConfirmAndPayScreenState();
}

class _ConfirmAndPayScreenState extends State<ConfirmAndPayScreen> {
  final _repository = WardRouteRepository();
  final _imagePicker = ImagePicker();
  bool _isFetchingInitialData = true;
  bool _isLoading = false;

  String _address = '';
  String _userName = '';
  String _userPhone = '';
  String _wasteType = '';
  String _localBody = '';
  double _disposalRate = 42.00;
  double _walletBalance = 0.0;
  List<Map<String, dynamic>> _vouchers = [];
  Map<String, dynamic>? _selectedVoucher;

  int _bagQuantity = 0;
  final double _bagPrice = 7.00;
  final TextEditingController _weightController =
      TextEditingController(text: '5.0');
  double _wasteWeight = 5.0;

  bool _redeemWallet = false;
  bool _applyCoupon = false;

  String _selectedPaymentOption = 'Cash'; // 'Cash', 'Online (QR)', 'Wallet'
  final List<Map<String, dynamic>> _verificationPhotos = [];

  @override
  void initState() {
    super.initState();
    _address = widget.address;
    _wasteType = widget.wasteType;
    _localBody = widget.localBody;
    _disposalRate = widget.disposalRate;

    _weightController.addListener(() {
      final val = double.tryParse(_weightController.text.trim()) ?? 0.0;
      if (val != _wasteWeight) {
        setState(() {
          _wasteWeight = val;
        });
      }
    });

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.pickupId <= 0) {
      if (mounted) setState(() => _isFetchingInitialData = false);
      return;
    }

    try {
      final data = await _repository.fetchConfirmAndPayData(
        pickupId: widget.pickupId,
      );
      if (data != null && mounted) {
        final pickupData = data['pickup_data'] as Map<String, dynamic>?;
        if (pickupData != null) {
          _address = pickupData['address']?.toString() ?? _address;
          _userName = pickupData['user_name']?.toString() ?? '';
          _userPhone = pickupData['user_phone']?.toString() ?? '';
          _wasteType = pickupData['waste_type']?.toString() ?? _wasteType;
        }

        final billingData = data['billing_data'] as Map<String, dynamic>?;
        if (billingData != null) {
          final rate = (billingData['rate_per_kg'] as num?)?.toDouble();
          if (rate != null && rate > 0) {
            _disposalRate = rate;
          }
        }

        final walletData = data['wallet_data'] as Map<String, dynamic>?;
        if (walletData != null) {
          _walletBalance =
              (walletData['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        }

        final rawVouchers = data['swipe_vouchers'] as List<dynamic>?;
        if (rawVouchers != null) {
          _vouchers = rawVouchers.whereType<Map<String, dynamic>>().toList();
        }

        // Fetch disposal rate from local_body if available
        final localBodyId = (data['local_body_id'] as num?)?.toInt() ?? 43;
        final dRate =
            await _repository.fetchDisposalRate(localBodyId: localBodyId);
        if (dRate != null && dRate > 0) {
          _disposalRate = dRate;
        }
      }
    } catch (e) {
      debugPrint('Error loading confirm & pay data: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingInitialData = false);
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  double get _bagsCost => _bagQuantity * _bagPrice;
  double get _disposalFee => _wasteWeight * _disposalRate;
  double get _subtotal => _bagsCost + _disposalFee;
  double get _gst => _subtotal * 0.18;
  double get _grossTotal => _subtotal + _gst;
  double get _totalPayable => _grossTotal;

  Future<void> _handleConfirmPayment() async {
    setState(() => _isLoading = true);

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
        'pickup_id': widget.pickupId,
        'weight': _wasteWeight,
        'rate': _disposalRate,
        'total_amount': double.parse(_totalPayable.toStringAsFixed(2)),
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

      // 2. POST /api/process-payment/ (handled gracefully)
      await _repository.processPayment(
        pickupId: widget.pickupId,
        paymentMethod: methodStr,
      );

      // 3. POST /api/confirm-and-pay/ (handled gracefully)
      final confirmPayBody = {
        'pickup_id': widget.pickupId,
        'collector_id': widget.collectorId,
        'weight': _wasteWeight,
        'payment_method': methodStr,
        'redeem_wallet': _redeemWallet,
        'wallet_redeemed': _redeemWallet,
        'apply_voucher': _applyCoupon,
        'transaction_id': 'BILL-$billId',
      };
      await _repository.confirmAndPay(body: confirmPayBody);

      // 4. POST /api/update-pickup-status/ (status: completed)
      await _repository.updatePickupStatus(
        pickupId: widget.pickupId,
        status: 'completed',
      );

      // 5. POST /api/collect-pickup/ (status: picked)
      await _repository.collectPickup(
        pickupId: widget.pickupId,
        collectorId: widget.collectorId,
      );

      // 6. Record collection metrics for Home page containers
      await CollectionMetricsStorage().recordCollection(
        pickupId: widget.pickupId > 0
            ? widget.pickupId
            : DateTime.now().millisecondsSinceEpoch,
        weight: _wasteWeight,
        amount: _totalPayable,
      );
    } catch (e) {
      debugPrint('Confirm & pay processing error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    final result = await Navigator.pushNamed(
      context,
      PaymentReceiptScreen.routeName,
      arguments: {
        'totalAmount': _totalPayable,
        'paymentMode': _selectedPaymentOption,
        'transactionId': 'BILL-$billId',
        'dateTime': DateTime.now(),
        'bagsCollected': _bagQuantity,
        'disposalWeight': _wasteWeight,
      },
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingInitialData || _isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Confirm & Pay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1E293B),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm & Pay',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Address Card
            _buildAddressCard(),
            const SizedBox(height: 18),

            // Section 1: Choose Waste Bag Quantity
            _buildSectionHeader('1. Choose Waste Bag Quantity'),
            const SizedBox(height: 8),
            _buildBagQuantityCard(),
            const SizedBox(height: 18),

            // Section 2: Localbody Disposal Location & Weight
            _buildSectionHeader('2. Localbody Disposal Location & Weight'),
            const SizedBox(height: 8),
            _buildLocalbodyCard(),
            const SizedBox(height: 10),
            _buildWasteWeightInputCard(),
            const SizedBox(height: 10),
            _buildWalletCard(),
            const SizedBox(height: 10),
            _buildCouponsCard(),
            const SizedBox(height: 18),

            // Section 3: Payment Option
            _buildSectionHeader('3. Payment Option'),
            const SizedBox(height: 8),
            _buildPaymentOptions(),
            if (_selectedPaymentOption == 'Online (QR)') ...[
              _buildRazorpayQRPreviewCard(),
            ],
            const SizedBox(height: 18),

            // Section 4: Weighing Machine Verification Photo
            _buildSectionHeader('4. Weighing Machine Verification Photo'),
            const SizedBox(height: 8),
            _buildPhotoVerificationSection(),
            const SizedBox(height: 18),

            // Collection Summary
            _buildCollectionSummaryCard(),
            const SizedBox(height: 20),

            // Confirm Payment / Generate QR Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedPaymentOption == 'Online (QR)'
                    ? _handleGenerateRazorpayQR
                    : _handleConfirmPayment,
                icon: Icon(
                  _selectedPaymentOption == 'Online (QR)'
                      ? Icons.qr_code_2_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  _selectedPaymentOption == 'Online (QR)'
                      ? 'Generate Razorpay QR (₹${_totalPayable.toStringAsFixed(2)})'
                      : (_totalPayable > 0
                          ? 'Confirm Payment (₹${_totalPayable.toStringAsFixed(2)})'
                          : 'Confirm Payment (Fully Covered)'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPaymentOption == 'Online (QR)'
                      ? const Color(0xFF0F1E36)
                      : const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF1E293B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _address.isNotEmpty ? _address : widget.address,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userName.isNotEmpty
                      ? '$_userName • $_userPhone'
                      : (_address.isNotEmpty ? _address : widget.address),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.edit_outlined, size: 14, color: Color(0xFF1E293B)),
                SizedBox(width: 4),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBagQuantityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Waste Bag',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Price: ₹7 per bag',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _bagQuantity > 0
                    ? () => setState(() => _bagQuantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline, size: 24),
                color: const Color(0xFF1E293B),
                disabledColor: const Color(0xFFCBD5E1),
              ),
              Text(
                '$_bagQuantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _bagQuantity++),
                icon: const Icon(Icons.add_circle_outline, size: 24),
                color: const Color(0xFF1E293B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalbodyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Assigned Localbody',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              '${_localBody.isNotEmpty ? _localBody : widget.localBody} (Rate: ₹${_disposalRate.toStringAsFixed(2)}/kg)',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteWeightInputCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Waste Weight (Kgs)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.scale_outlined,
                size: 20,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(
                width: 2,
              ),
              const Text(
                'Kg',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Redeem Wallet Balance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Available Balance: ₹${_walletBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _walletBalance > 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: false,
            onChanged: null,
            // value: _redeemWallet,
            // activeThumbColor: const Color(0xFF1E293B),
            // onChanged: (val) => setState(() => _redeemWallet = val),
          ),
        ],
      ),
    );
  }

  Future<void> _openCouponsScreen() async {
    final selected = await Navigator.pushNamed(
      context,
      AvailableCouponsVouchersScreen.routeName,
      arguments: {
        'userPoints': _walletBalance.toInt(),
        'vouchers': _vouchers,
      },
    );
    if (selected != null && selected is Map<String, dynamic> && mounted) {
      setState(() {
        _selectedVoucher = selected;
        _applyCoupon = true;
      });
    }
  }

  Widget _buildCouponsCard() {
    final activeVoucher =
        _selectedVoucher ?? (_vouchers.isNotEmpty ? _vouchers.first : null);
    final voucherCode = activeVoucher?['code']?.toString() ??
        activeVoucher?['voucher_code']?.toString() ??
        'FLT-250';
    final voucherStatus = activeVoucher?['status']?.toString() ?? 'INACTIVE';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _openCouponsScreen,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.confirmation_num_outlined,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Coupons & Vouchers',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Text(
                  'View all coupons >',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    voucherCode,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    voucherStatus,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: false,
                  onChanged: null,
                  // value: _applyCoupon,
                  // activeThumbColor: const Color(0xFF1E293B),
                  // onChanged: (val) => setState(() => _applyCoupon = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    final options = [
      {'title': 'Cash', 'icon': Icons.payments_outlined},
      {'title': 'Online (QR)', 'icon': Icons.qr_code_2_rounded},
      {'title': 'Wallet', 'icon': Icons.account_balance_wallet_outlined},
    ];

    return Row(
      children: options.map((opt) {
        final title = opt['title'] as String;
        final icon = opt['icon'] as IconData;
        final isSelected = _selectedPaymentOption == title;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPaymentOption = title),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRazorpayQRPreviewCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1E36),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Razorpay Dynamic QR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F1E36),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded,
                        size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'SECURE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Generate dynamic UPI QR code for ₹${_totalPayable.toStringAsFixed(2)}. Customer can scan with GPay, PhonePe, Paytm, or BHIM to pay instantly.',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleGenerateRazorpayQR,
              icon: const Icon(Icons.qr_code_rounded,
                  size: 18, color: Colors.white),
              label: const Text(
                'Generate Razorpay QR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1E36),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGenerateRazorpayQR() async {
    final result = await Navigator.pushNamed(
      context,
      RazorpayQRScreen.routeName,
      arguments: {
        'pickupId': widget.pickupId,
        'collectorId': widget.collectorId,
        'amount': _totalPayable,
        'address': _address,
        'userName': _userName,
        'userPhone': _userPhone,
        'wasteWeight': _wasteWeight,
        'bagQuantity': _bagQuantity,
        'disposalRate': _disposalRate,
        'redeemWallet': _redeemWallet,
        'applyCoupon': _applyCoupon,
      },
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handlePickVerificationPhoto() async {
    if (_verificationPhotos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 verification photos allowed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _verificationPhotos.add({
            'file': File(picked.path),
            'name': picked.name,
            'status': 'ready', // 'ready', 'uploading', 'uploaded', 'error'
            'error': null,
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open camera: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto(int index) async {
    if (index < 0 || index >= _verificationPhotos.length) return;
    final photo = _verificationPhotos[index];
    final file = photo['file'] as File;

    setState(() {
      photo['status'] = 'uploading';
      photo['error'] = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      final res = await _repository.uploadWastePhoto(
        pickupId: widget.pickupId,
        photoBase64: base64String,
      );

      if (!mounted) return;

      if (res != null) {
        setState(() {
          photo['status'] = 'uploaded';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waste photo uploaded successfully'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          photo['status'] = 'error';
          photo['error'] = 'Upload failed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload photo to server'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          photo['status'] = 'error';
          photo['error'] = errorMsg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo to server: $errorMsg'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deletePhoto(int index) {
    if (index < 0 || index >= _verificationPhotos.length) return;
    setState(() {
      _verificationPhotos.removeAt(index);
    });
  }

  Widget _buildPhotoItemCard(int index, Map<String, dynamic> photo) {
    final file = photo['file'] as File;
    final name = photo['name']?.toString() ??
        file.path.split(Platform.pathSeparator).last;
    final status = photo['status']?.toString() ?? 'ready';
    final isUploading = status == 'uploading';
    final isUploaded = status == 'uploaded';

    Color statusColor;
    String statusText;
    if (isUploaded) {
      statusColor = const Color(0xFF16A34A);
      statusText = 'Uploaded';
    } else if (isUploading) {
      statusColor = const Color(0xFF2563EB);
      statusText = 'Uploading...';
    } else if (status == 'error') {
      statusColor = const Color(0xFFEF4444);
      statusText = photo['error'] != null ? 'Upload failed' : 'Upload error';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Ready to upload';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              file,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 58,
                height: 58,
                color: const Color(0xFFF1F5F9),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action Buttons: Upload & Delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUploaded)
                InkWell(
                  onTap: isUploading ? null : () => _uploadPhoto(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isUploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Upload',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFF16A34A),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Uploaded',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _deletePhoto(index),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 15,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: _handlePickVerificationPhoto,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 22,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Verification Photo (${_verificationPhotos.length}/5)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Capture weighing machine display showing weight',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoVerificationSection() {
    return Column(
      children: [
        for (int i = 0; i < _verificationPhotos.length; i++)
          _buildPhotoItemCard(i, _verificationPhotos[i]),
        if (_verificationPhotos.length < 5) _buildAddPhotoCard(),
      ],
    );
  }

  Widget _buildCollectionSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            'Waste Bags cost ($_bagQuantity × ₹${_bagPrice.toInt()})',
            '₹${_bagsCost.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Disposal Fee (${_wasteWeight.toStringAsFixed(1)} Kgs at ₹${_disposalRate.toStringAsFixed(2)}/kg)',
            '₹${_disposalFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          _buildSummaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('GST (18%)', '₹${_gst.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Gross Total (incl. GST)',
            '₹${_grossTotal.toStringAsFixed(2)}',
            isBold: true,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount Payable',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '₹${_totalPayable.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
