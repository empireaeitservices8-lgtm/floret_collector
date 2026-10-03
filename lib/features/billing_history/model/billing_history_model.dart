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
  });
}
