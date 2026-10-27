class CollectionItemModel {
  final String id;
  final String stopId;
  final String stopName;
  final String address;
  final String wasteType;

  /// Payment status: 'Paid', 'Pending', etc.
  final String status;

  /// Collection status: 'completed', etc.
  final String collectionStatus;

  final double weight;
  final double rate;
  final double amount;
  final String date;
  final DateTime? dateTime;
  final String paymentMethod;

  const CollectionItemModel({
    required this.id,
    required this.stopId,
    required this.stopName,
    this.address = '',
    required this.wasteType,
    required this.status,
    this.collectionStatus = '',
    required this.weight,
    required this.rate,
    required this.amount,
    required this.date,
    this.dateTime,
    required this.paymentMethod,
  });

  factory CollectionItemModel.fromJson(Map<String, dynamic> json) {
    final where = _asMap(json['where']);
    final when = _asMap(json['when']);
    final details = _asMap(json['collection_details']);
    final dateString = when['collection_date']?.toString().trim() ?? '';

    return CollectionItemModel(
      id: json['history_id']?.toString() ?? '',
      stopId: json['pickup_id']?.toString() ?? '',
      stopName: where['user_name']?.toString() ?? '',
      address: where['user_address']?.toString() ?? '',
      wasteType: details['waste_type']?.toString() ?? '',
      status: _formatPaymentStatus(details['payment_status']),
      collectionStatus: details['status']?.toString() ?? '',
      weight: _asDouble(details['weight_collected']),
      amount: _asDouble(details['amount_earned']),
      date: dateString,
      dateTime: DateTime.tryParse(dateString),

      // These fields are not supplied by this API response.
      rate: 0.0,
      paymentMethod: '',
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return <String, dynamic>{};
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().trim() ?? '') ?? 0.0;
  }

  static String _formatPaymentStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase() ?? '';

    if (status.isEmpty) return 'Unknown';

    // Converts 'paid' → 'Paid' for existing UI comparisons.
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }
}
