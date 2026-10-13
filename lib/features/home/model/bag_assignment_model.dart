class BagAssignmentModel {
  final int collectorId;
  final String collectorName;
  final String date;
  final int assignedBags;
  final int remainingBags;
  final String district;
  final String localBody;

  const BagAssignmentModel({
    required this.collectorId,
    required this.collectorName,
    required this.date,
    required this.assignedBags,
    required this.remainingBags,
    required this.district,
    required this.localBody,
  });

  factory BagAssignmentModel.fromJson(Map<String, dynamic> json) {
    return BagAssignmentModel(
      collectorId: (json['collector_id'] as num?)?.toInt() ?? 0,
      collectorName: json['collector_name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      assignedBags: (json['assigned_bags'] as num?)?.toInt() ?? 0,
      remainingBags: (json['remaining_bags'] as num?)?.toInt() ?? 0,
      district: json['district']?.toString() ?? '',
      localBody: json['local_body']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'BagAssignmentModel(collectorId: $collectorId, assignedBags: $assignedBags, remainingBags: $remainingBags, district: $district, localBody: $localBody)';
}
