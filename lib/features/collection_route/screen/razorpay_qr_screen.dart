import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:floret_collector/features/collection_route/repository/collection_history_repository.dart';
import 'package:floret_collector/core/storage/collection_metrics_storage.dart';

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
    this.address = '',
    this.userName = '',
    this.userPhone = '',
    this.wasteWeight = 0,
    this.bagQuantity = 0,
    this.disposalRate = 0.0,
    this.redeemWallet = false,
    this.applyCoupon = false,
  });

  @override
  State<RazorpayQRScreen> createState() => _RazorpayQRScreenState();
}

class _RazorpayQRScreenState extends State<RazorpayQRScreen> {
  final WardRouteRepository _repository = WardRouteRepository();

  Uint8List? _qrImageBytes;
  String _orderId = '';
  int? _billId;
  String? _errorMessage;
  bool _isLoadingQR = false;

  static const Color _navy = Color(0xFF0F1E36);
  static const Color _text = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF64748B);

  Timer? _paymentStatusTimer;
  bool _isCheckingPayment = false;
  bool _paymentCompleted = false;
  bool _isConfirming = false;
  String _paymentStatusText = 'Waiting for payment confirmation ...';

  @override
  void initState() {
    super.initState();
    _billId = widget.billId;
    _loadQRCode();
  }

  Future<int?> _ensureBillId() async {
    if (_billId != null && _billId! > 0) return _billId;
    try {
      final billBody = {
        'pickup_id': widget.pickupId,
        'weight': widget.wasteWeight,
        'rate': widget.disposalRate,
        'total_amount': double.parse(widget.amount.toStringAsFixed(2)),
        'payment_method': 'online',
        'transaction_id': 'RZP-${DateTime.now().millisecondsSinceEpoch}',
        'payment_gateway': 'razorpay',
        'payment_status': 'pending',
        'remarks': 'Razorpay QR waste collection bill',
      };
      debugPrint('Generating bill for Razorpay QR in screen: $billBody');
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
    } catch (e) {
      debugPrint('Error generating bill in RazorpayQRScreen: $e');
    }
    return _billId;
  }

  Future<void> _loadQRCode() async {
    if (!mounted || _isLoadingQR || _paymentCompleted) return;

    _paymentStatusTimer?.cancel();

    setState(() {
      _isLoadingQR = true;
      _errorMessage = null;
      _qrImageBytes = null;
      _orderId = '';
    });

    try {
      // 1. Generate bill if not already provided
      await _ensureBillId();

      // 2. Generate Razorpay QR code
      final response = await _repository.generateRazorpayQR(
        amount: widget.amount,
        pickupId: widget.pickupId,
      );

      if (response == null) {
        throw const FormatException('No QR response received.');
      }

      final rawQRCode = response['qr_code'];

      if (rawQRCode is! String || rawQRCode.trim().isEmpty) {
        throw const FormatException('QR image missing from response.');
      }

      final imageBytes = _decodeQRImage(rawQRCode);

      if (!mounted) return;

      setState(() {
        _qrImageBytes = imageBytes;
        _orderId = response['order_id']?.toString() ?? '';
      });
    } catch (error) {
      debugPrint('Failed to load payment QR: $error');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load payment QR. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingQR = false;
        });

        if (_qrImageBytes != null && _orderId.isNotEmpty) {
          _startPaymentStatusChecking();
        }
      }
    }
  }

  //
  void _startPaymentStatusChecking() {
    _paymentStatusTimer?.cancel();

    final currentBillId = _billId ?? widget.billId;

    if (_orderId.isEmpty || currentBillId == null || currentBillId <= 0) {
      setState(() {
        _paymentStatusText =
            'Payment status unavailable: missing order ID or bill ID.';
      });
      return;
    }

    _checkPaymentStatus();

    _paymentStatusTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkPaymentStatus(),
    );
  }

  Future<void> _checkPaymentStatus() async {
    if (!mounted ||
        _isCheckingPayment ||
        _paymentCompleted ||
        _isLoadingQR ||
        _isConfirming) {
      return;
    }

    final currentBillId = _billId ?? widget.billId;
    final orderId = _orderId;

    if (currentBillId == null || currentBillId <= 0 || orderId.isEmpty) return;

    _isCheckingPayment = true;

    try {
      final response = await _repository.razorpayVerify(
        orderId: orderId,
        billId: currentBillId,
      );

      // Ignore a response for an older QR after regeneration.
      if (!mounted ||
          orderId != _orderId ||
          _paymentCompleted ||
          _isConfirming) {
        return;
      }

      final status =
          response?['payment_status']?.toString().trim().toLowerCase() ?? '';

      if (status == 'paid') {
        final transactionId = response?['razorpay_payment_id']?.toString() ??
            response?['transaction_id']?.toString() ??
            'BILL-$currentBillId';

        await _finalizePayment(transactionId: transactionId);
      } else {
        setState(() {
          _paymentStatusText = 'Waiting for payment confirmation...';
        });
      }
    } catch (error) {
      debugPrint('Payment status check failed: $error');

      if (mounted &&
          orderId == _orderId &&
          !_paymentCompleted &&
          !_isConfirming) {
        setState(() {
          _paymentStatusText = 'Unable to check payment. Retrying...';
        });
      }
    } finally {
      _isCheckingPayment = false;
    }
  }

  Future<void> _finalizePayment({String? transactionId}) async {
    if (!mounted || _isConfirming || _paymentCompleted) return;

    _paymentStatusTimer?.cancel();

    setState(() {
      _isConfirming = true;
      _paymentStatusText = 'Confirming payment...';
    });

    try {
      final currentBillId = await _ensureBillId() ?? widget.billId;
      final txId = transactionId ??
          (_orderId.isNotEmpty
              ? _orderId
              : (currentBillId != null
                  ? 'BILL-$currentBillId'
                  : 'ONLINE-${widget.pickupId}'));

      // Finalize pickup status and cumulative metrics on backend
      try {
        await _repository.processPayment(
          pickupId: widget.pickupId,
          paymentMethod: 'online',
        );
        await _repository.confirmAndPay(body: {
          'pickup_id': widget.pickupId,
          'collector_id': widget.collectorId,
          'weight': widget.wasteWeight,
          'payment_method': 'online',
          'redeem_wallet': widget.redeemWallet,
          'wallet_redeemed': widget.redeemWallet,
          'apply_voucher': widget.applyCoupon,
          'transaction_id': txId,
          if (currentBillId != null) 'bill_id': currentBillId,
        });
        await _repository.updatePickupStatus(
          pickupId: widget.pickupId,
          status: 'completed',
        );
        await _repository.collectPickup(
          pickupId: widget.pickupId,
          collectorId: widget.collectorId,
        );
        await CollectionMetricsStorage().recordCollection(
          pickupId: widget.pickupId > 0
              ? widget.pickupId
              : DateTime.now().millisecondsSinceEpoch,
          weight: widget.wasteWeight,
          amount: widget.amount,
        );
      } catch (e) {
        debugPrint('Error finalizing collection after Razorpay payment: $e');
      }

      _paymentCompleted = true;

      if (!mounted) return;

      setState(() {
        _paymentStatusText = 'Payment confirmed successfully';
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Payment Successful'),
          content: Text(
            'Payment has been confirmed.\n'
            'Transaction: $txId',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error in _finalizePayment: $e');
      if (mounted) {
        setState(() {
          _paymentStatusText = 'Waiting for payment confirmation ...';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment confirmation failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _paymentStatusTimer?.cancel();
    super.dispose();
  }

  Uint8List _decodeQRImage(String rawQRCode) {
    final value = rawQRCode.trim();
    late final String encodedImage;

    if (value.startsWith('data:')) {
      final commaIndex = value.indexOf(',');

      if (commaIndex == -1) {
        throw const FormatException('Invalid QR image data.');
      }

      final metadata = value.substring(0, commaIndex).toLowerCase();

      if (!metadata.startsWith('data:image/') ||
          !metadata.contains(';base64')) {
        throw const FormatException('Expected a base64 image.');
      }

      encodedImage = value.substring(commaIndex + 1);
    } else {
      encodedImage = value;
    }

    final bytes = base64Decode(
      encodedImage.replaceAll(RegExp(r'\s+'), ''),
    );

    if (bytes.isEmpty) {
      throw const FormatException('QR image is empty.');
    }

    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = '₹${widget.amount.toStringAsFixed(2)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _text,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment QR',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            _buildMerchantHeader(formattedAmount),
            const SizedBox(height: 24),
            _buildQRCard(formattedAmount),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Ask the customer to scan this QR code to pay '
                '$formattedAmount.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: _muted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed:
                      (_isLoadingQR || _isConfirming) ? null : _loadQRCode,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Generate New QR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _paymentStatusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _paymentCompleted ? Colors.green : Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (_isConfirming || _paymentCompleted)
                      ? null
                      : () => _finalizePayment(),
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isConfirming ? 'Confirming...' : 'Confirm payment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF16A34A).withOpacity(0.6),
                    disabledForegroundColor: Colors.white70,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isConfirming ? null : () => Navigator.pop(context),
              child: const Text(
                'Go Back',
                style: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantHeader(String formattedAmount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF071F3D),
            Color(0xFF0D325E),
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Floret Waste Management',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Amount to Pay',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formattedAmount,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (_orderId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Order: $_orderId',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQRCard(String formattedAmount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          if (widget.userName.trim().isNotEmpty) ...[
            Text(
              widget.userName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (widget.address.trim().isNotEmpty) ...[
            Text(
              widget.address,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _muted,
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Scan to Pay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: _buildQRContent(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            formattedAmount,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRContent() {
    if (_isLoadingQR) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: _navy,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            'Loading payment QR...',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return _buildErrorContent(_errorMessage!);
    }

    final bytes = _qrImageBytes;

    if (bytes == null) {
      return _buildErrorContent('QR image unavailable.');
    }

    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      semanticLabel: 'Payment QR code',
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorContent(
          'The API returned an invalid QR image.',
        );
      },
    );
  }

  Widget _buildErrorContent(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 36,
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: _muted,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isLoadingQR ? null : _loadQRCode,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
