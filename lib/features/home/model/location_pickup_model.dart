class LocationPickupModel {
  final int id;
  final int pickupId;
  final String name;
  final String contactNumber;
  final String street;
  final String city;
  final String state;
  final String district;
  final String ward;
  final String localBody;
  final String pickupDate;
  final String pickupTimeSlot;
  final String wasteType;
  final String status;

  const LocationPickupModel({
    required this.id,
    required this.pickupId,
    required this.name,
    required this.contactNumber,
    required this.street,
    required this.city,
    required this.state,
    required this.district,
    required this.ward,
    required this.localBody,
    required this.pickupDate,
    required this.pickupTimeSlot,
    required this.wasteType,
    required this.status,
  });

  factory LocationPickupModel.fromJson(Map<String, dynamic> json) {
    return LocationPickupModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      pickupId: (json['pickup_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      localBody: json['local_body']?.toString() ?? '',
      pickupDate: json['pickup_date']?.toString() ?? '',
      pickupTimeSlot: json['pickup_time_slot']?.toString() ?? '',
      wasteType: json['waste_type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
    );
  }

  bool get isToday {
    if (pickupDate.isEmpty) return false;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // pickupDate is "YYYY-MM-DD" — compare the first 10 chars directly
    return pickupDate.length >= 10 && pickupDate.substring(0, 10) == todayStr;
  }

  @override
  String toString() =>
      'LocationPickupModel(id: $id, name: $name, status: $status, date: $pickupDate)';
}
