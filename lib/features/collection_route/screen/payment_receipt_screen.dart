import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentReceiptScreen extends StatelessWidget {
  static const String routeName = '/PaymentReceiptScreen';

  final double totalAmount;
  final String paymentMode;
  final String transactionId;
  final DateTime dateTime;
  final int bagsCollected;
  final double disposalWeight;

  const PaymentReceiptScreen({
    super.key,
    this.totalAmount = 0,
    this.paymentMode = '',
    this.transactionId = '',
    DateTime? dateTime,
    this.bagsCollected = 0,
    this.disposalWeight = 5.0,
  }) : dateTime = dateTime ?? const _DefaultDateTime();

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);

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
          'Payment Receipt',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Green Success Badge with Aura
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Successful!
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Garbage collected and payment logged\nsuccessfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Receipt Details Card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow(
                      'Total Amount',
                      '₹${totalAmount.toStringAsFixed(2)}',
                      isBoldValue: true,
                    ),
                    const SizedBox(height: 14),
                    _buildReceiptRow('Payment Mode', paymentMode),
                    const SizedBox(height: 14),
                    _buildReceiptRow('Transaction ID', transactionId),
                    const SizedBox(height: 14),
                    _buildReceiptRow('Date & Time', formattedDate),
                    const SizedBox(height: 14),
                    _buildReceiptRow(
                      'Bags Collected',
                      '$bagsCollected Bags',
                    ),
                    const SizedBox(height: 14),
                    _buildReceiptRow(
                      'Disposal Weight',
                      '${disposalWeight.toStringAsFixed(1)} Kgs',
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // "Ok, Proceed to Next Stop" button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Return true to indicate progressing to next stop
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ok, Proceed to Next Stop',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBoldValue ? 16 : 14,
            fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  DateTime get _now => DateTime.now();

  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  bool get isUtc => false;

  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);
  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;
  @override
  int get weekday => _now.weekday;
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
}
