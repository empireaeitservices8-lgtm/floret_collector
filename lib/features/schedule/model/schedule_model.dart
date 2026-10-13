import 'package:floret_collector/features/home/model/pickup_slot_model.dart';

class ScheduleModel {
  final String dateText;
  final String progressText;
  final String sanitaryPickups;
  final String scrapPickups;
  final String wasteType;
  final double progressPercent;
  final List<PickupSlotModel> pickups;

  const ScheduleModel({
    required this.dateText,
    this.progressText = '0 of 0 completed',
    this.sanitaryPickups = '0/0',
    this.scrapPickups = '0/0',
    this.wasteType = 'Sanitary & Scrap waste',
    this.progressPercent = 0.0,
    this.pickups = const [],
  });

  ScheduleModel copyWith({
    String? dateText,
    String? progressText,
    String? sanitaryPickups,
    String? scrapPickups,
    String? wasteType,
    double? progressPercent,
    List<PickupSlotModel>? pickups,
  }) {
    return ScheduleModel(
      dateText: dateText ?? this.dateText,
      progressText: progressText ?? this.progressText,
      sanitaryPickups: sanitaryPickups ?? this.sanitaryPickups,
      scrapPickups: scrapPickups ?? this.scrapPickups,
      wasteType: wasteType ?? this.wasteType,
      progressPercent: progressPercent ?? this.progressPercent,
      pickups: pickups ?? this.pickups,
    );
  }
}
