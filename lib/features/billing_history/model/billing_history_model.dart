import 'package:intl/intl.dart';

class BillItemModel {
  final String id;
  final String stopId;
  final String stopName;
  final String weight;
  final String rate;
  final String amount;
  final String method; // 'Cash' or 'Online'
  final String status; // 'Paid' or 'Pending'
  final String date;
  final String? transactionId;
  final String? subtotal;
  final String? gstAmount;
  final String? remarks;
  final String? gateway;

  const BillItemModel({
    required this.id,
    required this.stopId,
    required this.stopName,
    required this.weight,
    required this.rate,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    this.transactionId,
    this.subtotal,
    this.gstAmount,
    this.remarks,
    this.gateway,
  });

  String get effectiveGateway {
    if (gateway != null && gateway!.trim().isNotEmpty) {
      return gateway!.trim();
    }
    return method.toLowerCase() == 'cash' ? 'cash' : 'razorpay';
  }

  String get effectiveTransactionId {
    if (transactionId != null && transactionId!.trim().isNotEmpty) {
      return transactionId!.trim();
    }
    return method.toLowerCase() == 'cash' ? 'BILL-$id' : 'N/A';
  }

  String get formattedRate {
    final clean = rate
        .replaceAll('₹', '')
        .replaceAll('/kg', '')
        .replaceAll('/ kg', '')
        .trim();
    return '₹$clean / kg';
  }

  String get formattedWeight {
    final clean = weight
        .replaceAll('Kgs', '')
        .replaceAll('kgs', '')
        .replaceAll('kg', '')
        .replaceAll('Kg', '')
        .trim();
    return '$clean Kgs';
  }

  String get formattedAmount {
    final clean = amount.replaceAll('₹', '').trim();
    final parsed = double.tryParse(clean);
    if (parsed != null) {
      return parsed.toStringAsFixed(2);
    }
    return clean;
  }

  factory BillItemModel.fromJson(Map<String, dynamic> json) {
    final rawMethod = json['payment_method']?.toString() ?? 'Cash';
    final formattedMethod = rawMethod.isEmpty
        ? 'Cash'
        : (rawMethod.toLowerCase() == 'cash'
            ? 'Cash'
            : (rawMethod.toLowerCase() == 'online'
                ? 'Online'
                : '${rawMethod[0].toUpperCase()}${rawMethod.substring(1)}'));

    final rawStatus = json['payment_status']?.toString() ?? 'Paid';
    final formattedStatus = rawStatus.isEmpty
        ? 'Paid'
        : '${rawStatus[0].toUpperCase()}${rawStatus.substring(1).toLowerCase()}';

    final idStr = (json['id'] ?? '').toString();
    final txnId = json['transaction_id']?.toString() ??
        (formattedMethod.toLowerCase() == 'cash' ? 'BILL-$idStr' : null);

    return BillItemModel(
      id: idStr,
      stopId: (json['pickup_id'] ?? '').toString(),
      stopName: (json['user_name'] ?? '').toString(),
      weight: (json['weight'] ?? '0.00').toString(),
      rate: (json['rate'] ?? '0.00').toString(),
      amount: (json['total_amount'] ?? json['subtotal'] ?? '0.00').toString(),
      method: formattedMethod,
      status: formattedStatus,
      date: _formatDate(json['created_at']),
      transactionId: txnId,
      subtotal: json['subtotal']?.toString(),
      gstAmount: json['gst_amount']?.toString(),
      remarks: json['remarks']?.toString(),
      gateway: json['gateway']?.toString() ?? json['payment_gateway']?.toString(),
    );
  }

  static String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dateTime = DateTime.tryParse(createdAt.toString());
      if (dateTime != null) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
      }
    } catch (_) {}
    return createdAt.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickup_id': stopId,
      'user_name': stopName,
      'weight': weight,
      'rate': rate,
      'total_amount': amount,
      'payment_method': method,
      'payment_status': status,
      'created_at': date,
      'transaction_id': transactionId,
      'subtotal': subtotal,
      'gst_amount': gstAmount,
      'remarks': remarks,
    };
  }
}
