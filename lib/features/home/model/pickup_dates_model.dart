class CollectorPickupDatesModel {
  final int collectorId;
  final String collectorName;
  final List<String> pickupDates;

  const CollectorPickupDatesModel({
    required this.collectorId,
    required this.collectorName,
    required this.pickupDates,
  });

  factory CollectorPickupDatesModel.fromJson(Map<String, dynamic> json) {
    return CollectorPickupDatesModel(
      collectorId: (json['collector_id'] as num?)?.toInt() ?? 0,
      collectorName: json['collector_name']?.toString() ?? '',
      pickupDates: (json['pickup_dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'CollectorPickupDatesModel(collectorId: $collectorId, collectorName: $collectorName, pickupDates: $pickupDates)';
}
