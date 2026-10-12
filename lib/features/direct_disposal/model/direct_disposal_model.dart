import 'package:intl/intl.dart';

class DirectDisposalLogModel {
  final String id;
  final String customerName;
  final String phone;
  final String customerAddress;
  final String disposalType;
  final String wasteType;
  final String wasteDescription;
  final double weight;
  final double rate;
  final double gstRatePercent;
  final double gstAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String formattedDate;

  const DirectDisposalLogModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.customerAddress,
    required this.disposalType,
    required this.wasteType,
    required this.wasteDescription,
    required this.weight,
    required this.rate,
    required this.gstRatePercent,
    required this.gstAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.formattedDate,
  });

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';

  factory DirectDisposalLogModel.fromJson(Map<String, dynamic> json) {
    final parsedWeight =
        double.tryParse(json['weight']?.toString() ?? '') ?? 0.0;
    final parsedRate = double.tryParse(
            (json['disposal_rate'] ?? json['rate'])?.toString() ?? '') ??
        0.0;
    final parsedSubtotal =
        double.tryParse(json['subtotal']?.toString() ?? '') ??
            (parsedWeight * parsedRate);
    final parsedGstAmount =
        double.tryParse(json['gst_amount']?.toString() ?? '') ?? 0.0;
    final parsedTotalAmount =
        double.tryParse(json['total_amount']?.toString() ?? '') ??
            (parsedSubtotal + parsedGstAmount);
    final parsedGstPercent = parsedSubtotal > 0
        ? ((parsedGstAmount / parsedSubtotal) * 100).roundToDouble()
        : 5.0;

    final dateStr = json['disposal_date']?.toString() ??
        json['created_at']?.toString() ??
        '';
    final timeStr = json['disposal_time']?.toString() ?? '';
    String formattedDate = '';
    if (json['created_at'] != null) {
      try {
        final dt = DateTime.parse(json['created_at'].toString()).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {}
    }
    if (formattedDate.isEmpty && dateStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(
            '$dateStr ${timeStr.isNotEmpty ? timeStr : "00:00:00"}');
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        formattedDate = dateStr;
      }
    }
    if (formattedDate.isEmpty) {
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    }

    return DirectDisposalLogModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      phone: (json['customer_phone'] ?? json['phone'])?.toString() ?? '',
      customerAddress:
          (json['customer_address'] ?? json['address'])?.toString() ?? '',
      disposalType:
          (json['disposal_type'] ?? 'direct').toString().toUpperCase(),
      wasteType: json['waste_type']?.toString() ?? '',
      wasteDescription: json['waste_description']?.toString() ?? '',
      weight: parsedWeight,
      rate: parsedRate,
      gstRatePercent: parsedGstPercent,
      gstAmount: parsedGstAmount,
      totalAmount: parsedTotalAmount,
      paymentMethod:
          (json['payment_method'] ?? 'CASH').toString().toUpperCase(),
      paymentStatus:
          (json['payment_status'] ?? 'PENDING').toString().toUpperCase(),
      formattedDate: formattedDate,
    );
  }
}
