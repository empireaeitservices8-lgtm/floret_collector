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
}
