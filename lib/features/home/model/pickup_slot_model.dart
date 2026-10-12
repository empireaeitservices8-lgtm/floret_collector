class PickupSlotModel {
  final int id;
  final DateTime date;
  final String timeSlot;
  final int availableSpots;
  final String district;
  final String localBody;

  const PickupSlotModel({
    required this.id,
    required this.date,
    required this.timeSlot,
    required this.availableSpots,
    required this.district,
    required this.localBody,
  });

  factory PickupSlotModel.fromJson(Map<String, dynamic> json) {
    return PickupSlotModel(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      timeSlot: json['time_slot'] as String,
      availableSpots: (json['available_spots'] as num).toInt(),
      district: json['district'] as String,
      localBody: json['local_body'] as String,
    );
  }

  @override
  String toString() {
    return 'PickupSlotModel(id: $id, date: $date, '
        'timeSlot: $timeSlot, availableSpots: $availableSpots, '
        'district: $district, localBody: $localBody)';
  }
}

//respons model

class PickupSlotsResponseModel {
  final List<PickupSlotModel> slots;
  final int totalAvailable;

  const PickupSlotsResponseModel({
    required this.slots,
    required this.totalAvailable,
  });

  factory PickupSlotsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PickupSlotsResponseModel(
      slots: (json['slots'] as List<dynamic>)
          .map(
            (item) => PickupSlotModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      totalAvailable: (json['total_available'] as num).toInt(),
    );
  }

  @override
  String toString() {
    return 'PickupSlotsResponseModel(slots: $slots)';
  }
}
