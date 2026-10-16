import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:floret_collector/features/collection_route/repository/ward_route_repository.dart';
import 'package:floret_collector/core/storage/collection_metrics_storage.dart';
import 'payment_receipt_screen.dart';

class RazorpayQRScreen extends StatefulWidget {
  static const String routeName = '/RazorpayQRScreen';

  final int pickupId;
  final int collectorId;
  final double amount;
  final int? billId;
  final String address;
  final String userName;
  final String userPhone;
  final double wasteWeight;
  final int bagQuantity;
  final double disposalRate;
  final bool redeemWallet;
  final bool applyCoupon;

  const RazorpayQRScreen({
    super.key,
    required this.pickupId,
    required this.collectorId,
    required this.amount,
    this.billId,
    this.address = 'Main Road',
    this.userName = '',
    this.userPhone = '',
    this.wasteWeight = 5.0,
    this.bagQuantity = 0,
    this.disposalRate = 42.0,
    this.redeemWallet = false,
    this.applyCoupon = false,
  });

  @override
  State<RazorpayQRScreen> createState() => _RazorpayQRScreenState();
}

class _RazorpayQRScreenState extends State<RazorpayQRScreen>
    with SingleTickerProviderStateMixin {
  final _repository = WardRouteRepository();

  int? _billId;
  String _orderId = '';
  String _paymentLinkUrl = '';
  String _transactionId = '';
  String _qrData = '';

  Uint8List? _qrImageBytes;
  bool _isLoadingQR = true;

  int _remainingSeconds = 300; // 5 minutes
  Timer? _countdownTimer;

  bool _isVerifying = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _billId = widget.billId;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.85, end: 1.0).animate(_pulseController);

    _initRazorpayQR();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Flow:
  /// 1. If bill_id is not yet available, calls POST /api/generate-bill/ to get bill_id
  /// 2. Calls POST /api/razorpay/generate-qr/ with {"amount": amount, "bill_id": billId, "currency": "INR"}
  /// 3. Extracts base64 qr_code, order_id, payment_link_url, etc.
  Future<void> _initRazorpayQR({bool isRefresh = false}) async {
    setState(() {
      _isLoadingQR = true;
    });

    try {
      final now = DateTime.now();
      _transactionId = 'RZP-${now.millisecondsSinceEpoch}';

      // 1. Generate Bill if not already provided
      if (_billId == null || _billId! <= 0) {
        final billBody = {
          'pickup_id': widget.pickupId,
          'weight': widget.wasteWeight,
          'rate': widget.disposalRate,
          'total_amount': double.parse(widget.amount.toStringAsFixed(2)),
          'payment_method': 'online',
          'transaction_id': _transactionId,
          'payment_gateway': 'razorpay',
          'payment_status': 'pending',
          'remarks': 'Razorpay QR waste collection bill',
        };

        debugPrint('Generating bill for Razorpay QR...');
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
      }

      final billIdToUse = _billId ?? widget.pickupId;
      debugPrint('Calling /api/razorpay/generate-qr/ with bill_id=$billIdToUse, amount=${widget.amount}');

      // 2. Call POST /api/razorpay/generate-qr/
      // Body: {"amount": amount, "bill_id": billId, "currency": "INR"}
      final qrRes = await _repository.generateRazorpayQR(
        amount: widget.amount,
        billId: billIdToUse,
        currency: 'INR',
      );

      if (qrRes != null) {
        _orderId = qrRes['order_id']?.toString() ??
            'order_rzp_${widget.pickupId}_${now.millisecondsSinceEpoch % 100000}';
        _paymentLinkUrl = qrRes['payment_link_url']?.toString() ?? '';

        final rawQrCode = qrRes['qr_code']?.toString() ?? '';
        if (rawQrCode.isNotEmpty) {
          try {
            final base64Clean = rawQrCode.contains(',')
                ? rawQrCode.split(',').last.trim()
                : rawQrCode.trim();
            _qrImageBytes = base64Decode(base64Clean);
          } catch (e) {
            debugPrint('Failed to decode base64 qr image: $e');
            _qrImageBytes = null;
          }
        }

        // UPI string fallback
        final amountStr = widget.amount.toStringAsFixed(2);
        _qrData = _paymentLinkUrl.isNotEmpty
            ? _paymentLinkUrl
            : 'upi://pay?pa=florettech@razorpay&pn=Floret%20Waste%20Management&am=$amountStr&cu=INR&tn=Pickup_${widget.pickupId}&tr=$_orderId';

        _startTimer();
      } else {
        // Fallback to local UPI QR if API is unavailable
        _generateFallbackQR();
        _startTimer();
      }
    } catch (e) {
      debugPrint('Error generating Razorpay QR: $e');
      _generateFallbackQR();
      _startTimer();
    } finally {
      if (mounted) {
        setState(() => _isLoadingQR = false);
      }
    }
  }

  void _generateFallbackQR() {
    final now = DateTime.now();
    _orderId =
        'order_rzp_${widget.pickupId}_${now.millisecondsSinceEpoch % 100000}';
    _transactionId = 'RZP-${now.millisecondsSinceEpoch}';
    final amountStr = widget.amount.toStringAsFixed(2);
    _qrData =
        'upi://pay?pa=florettech@razorpay&pn=Floret%20Waste%20Management&am=$amountStr&cu=INR&tn=Pickup_${widget.pickupId}&tr=$_transactionId';
    _qrImageBytes = null;
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _remainingSeconds = 300;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _refreshQR() {
    _initRazorpayQR(isRefresh: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshed Razorpay QR Code'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerifyPayment() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    final txnId = _orderId.isNotEmpty ? _orderId : _transactionId;

    try {
      // 1. Process Payment
      await _repository.processPayment(
        pickupId: widget.pickupId,
        paymentMethod: 'online',
      );

      // 2. Confirm and Pay
      final confirmPayBody = {
        'pickup_id': widget.pickupId,
        'collector_id': widget.collectorId,
        'weight': widget.wasteWeight,
        'payment_method': 'online',
        'redeem_wallet': widget.redeemWallet,
        'wallet_redeemed': widget.redeemWallet,
        'apply_voucher': widget.applyCoupon,
        'transaction_id': txnId,
        if (_billId != null) 'bill_id': _billId,
      };
      await _repository.confirmAndPay(body: confirmPayBody);

      // 3. Update Pickup Status to completed
      await _repository.updatePickupStatus(
        pickupId: widget.pickupId,
        status: 'completed',
      );

      // 4. Collect Pickup
      await _repository.collectPickup(
        pickupId: widget.pickupId,
        collectorId: widget.collectorId,
      );

      // 5. Record collection metrics to cumulative storage (updates Home screen containers)
      await CollectionMetricsStorage().recordCollection(
        pickupId: widget.pickupId > 0
            ? widget.pickupId
            : DateTime.now().millisecondsSinceEpoch,
        weight: widget.wasteWeight,
        amount: widget.amount,
      );

      if (!mounted) return;

      // Show Payment Success Dialog
      await _showPaymentSuccessDialog(txnId);

      if (!mounted) return;

      // Navigate to Payment Receipt Screen
      await Navigator.pushNamed(
        context,
        PaymentReceiptScreen.routeName,
        arguments: {
          'totalAmount': widget.amount,
          'paymentMode': 'Razorpay UPI QR',
          'transactionId': txnId,
          'dateTime': DateTime.now(),
          'bagsCollected': widget.bagQuantity,
          'disposalWeight': widget.wasteWeight,
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error verifying Razorpay QR payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification issue: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _showPaymentSuccessDialog(String txnId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Payment Verified!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${widget.amount.toStringAsFixed(2)} received successfully via Razorpay UPI QR.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ref: $txnId',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dlgContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1E36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View Receipt',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlternativeCheckoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Razorpay Payment Options',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1E36),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SECURE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'If customer cannot scan QR, choose an alternative:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              if (_paymentLinkUrl.isNotEmpty) ...[
                _buildCheckoutOptionTile(
                  icon: Icons.link_rounded,
                  title: 'Open Razorpay Payment Link',
                  subtitle: _paymentLinkUrl,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse(_paymentLinkUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
              _buildCheckoutOptionTile(
                icon: Icons.alternate_email_rounded,
                title: 'Enter Customer UPI ID',
                subtitle: 'Send collect request to GPay/PhonePe',
                onTap: () {
                  Navigator.pop(ctx);
                  _showEnterUpiIdDialog();
                },
              ),
              const SizedBox(height: 10),
              _buildCheckoutOptionTile(
                icon: Icons.credit_card_rounded,
                title: 'Debit / Credit Card',
                subtitle: 'Visa, MasterCard, RuPay accepted',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleVerifyPayment();
                },
              ),
              const SizedBox(height: 10),
              _buildCheckoutOptionTile(
                icon: Icons.account_balance_rounded,
                title: 'NetBanking / Mobile Wallet',
                subtitle: 'All major Indian banks supported',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleVerifyPayment();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _showEnterUpiIdDialog() {
    final upiCtrl = TextEditingController(text: 'customer@okaxis');
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Send UPI Collect Request',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter customer UPI ID (VPA):',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: upiCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                hintText: 'e.g. mobile@upi',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF0F1E36), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Payment collect request sent to ${upiCtrl.text.trim()}'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F1E36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send Request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = '₹${widget.amount.toStringAsFixed(2)}';
    final isExpired = _remainingSeconds <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2_rounded, color: Color(0xFF0F1E36), size: 22),
            SizedBox(width: 8),
            Text(
              'Razorpay UPI QR',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E36),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Color(0xFF10B981), size: 6),
                SizedBox(width: 5),
                Text(
                  'SECURE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Razorpay Navy Gradient Merchant Header
            _buildMerchantHeader(formattedAmount),

            const SizedBox(height: 18),

            // 2. High Resolution Dynamic QR Code Card
            _buildQRCodeCard(formattedAmount, isExpired),

            const SizedBox(height: 18),

            // 3. Supported UPI Apps Row
            _buildSupportedUPIAppsCard(),

            const SizedBox(height: 18),

            // 4. Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Primary: Verify & Confirm Payment
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isVerifying || isExpired || _isLoadingQR)
                          ? null
                          : _handleVerifyPayment,
                      icon: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 20),
                      label: Text(
                        _isVerifying
                            ? 'Verifying with Razorpay...'
                            : 'Verify & Confirm Payment',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor: const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Alternative Checkout Options
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _showAlternativeCheckoutModal,
                      icon: const Icon(Icons.payment_rounded,
                          size: 18, color: Color(0xFF0F1E36)),
                      label: const Text(
                        'Other Payment Options',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFCBD5E1), width: 1.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Cancel / Change payment mode
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel & Choose Cash / Wallet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantHeader(String formattedAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF071F3D),
            Color(0xFF0D325E),
          ],
        ),
      ),
      child: Row(
        children: [
          // Floret Logo
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/floret_logo.png',
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_florist_rounded,
                color: Color(0xFF10B981),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Merchant & Order
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Floret Waste Mgmt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.verified_rounded,
                        color: Color(0xFF38BDF8), size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _orderId.isNotEmpty ? 'Order: $_orderId' : 'Floret Collection',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedAmount,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'via Razorpay',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard(String formattedAmount, bool isExpired) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Customer & Weight badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.address} • ${widget.wasteWeight.toStringAsFixed(1)} kg',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Text(
                  formattedAmount,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // QR Code Frame or Loader
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 234,
                height: 234,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: _isLoadingQR
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0F1E36)),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Generating Razorpay QR...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      )
                    : (_qrImageBytes != null
                        ? Image.memory(
                            _qrImageBytes!,
                            width: 210,
                            height: 210,
                            fit: BoxFit.contain,
                          )
                        : QrImageView(
                            data: _qrData,
                            version: QrVersions.auto,
                            size: 210,
                            gapless: false,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF071F3D),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF071F3D),
                            ),
                            embeddedImage: const AssetImage(
                                'assets/images/floret_logo.png'),
                            embeddedImageStyle: const QrEmbeddedImageStyle(
                              size: Size(34, 34),
                            ),
                          )),
              ),

              // Expired overlay if timer is 0
              if (isExpired && !_isLoadingQR)
                Container(
                  width: 234,
                  height: 234,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_off_rounded,
                          size: 42, color: Color(0xFFDC2626)),
                      const SizedBox(height: 10),
                      const Text(
                        'QR Code Expired',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap below to regenerate',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _refreshQR,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Regenerate QR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F1E36),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Scan Instruction
          const Text(
            'Scan with GPay, PhonePe, Paytm, or any UPI App',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 12),

          // Timer Pill & Refresh Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isExpired
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpired
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isExpired)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.error_outline,
                      size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Text(
                  isExpired
                      ? 'Expired'
                      : 'QR valid for ${_formatTimer(_remainingSeconds)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isExpired
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _refreshQR,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 15, color: Color(0xFF2563EB)),
                      SizedBox(width: 3),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_paymentLinkUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(_paymentLinkUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_new_rounded,
                        size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    const Text(
                      'Open Payment Link',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: _paymentLinkUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment link copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy_rounded,
                          size: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportedUPIAppsCard() {
    final apps = [
      {'name': 'Google Pay', 'color': const Color(0xFF4285F4), 'symbol': 'G'},
      {'name': 'PhonePe', 'color': const Color(0xFF6739B7), 'symbol': 'Pe'},
      {'name': 'Paytm', 'color': const Color(0xFF00BAF2), 'symbol': 'P'},
      {'name': 'BHIM UPI', 'color': const Color(0xFF00897B), 'symbol': 'UPI'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Supported UPI Applications',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                'Instant Settlement',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: apps.map((app) {
              final color = app['color'] as Color;
              final name = app['name'] as String;
              final symbol = app['symbol'] as String;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
