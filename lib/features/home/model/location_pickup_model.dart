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
  final String landmark;
  final int? userId;
  final String? collectorName;
  final String? createdAt;

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
    this.landmark = '',
    this.userId,
    this.collectorName,
    this.createdAt,
  });

  factory LocationPickupModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] as num?)?.toInt() ?? 0;
    final rawPickupId = (json['pickup_id'] as num?)?.toInt() ?? rawId;

    final userNameStr = json['user_name']?.toString() ?? '';
    final nameStr = json['name']?.toString() ?? '';
    final displayName = nameStr.isNotEmpty ? nameStr : userNameStr;

    String contact = json['contact_number']?.toString() ?? '';
    if (contact.isEmpty && userNameStr.isNotEmpty) {
      contact =
          userNameStr.contains('_') ? userNameStr.split('_').first : userNameStr;
    }

    final rawWasteType = json['waste_type']?.toString() ?? '';

    return LocationPickupModel(
      id: rawId,
      pickupId: rawPickupId,
      name: displayName,
      contactNumber: contact,
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      localBody: json['local_body']?.toString() ?? '',
      pickupDate: json['pickup_date']?.toString() ?? '',
      pickupTimeSlot: json['pickup_time_slot']?.toString() ?? '',
      wasteType: rawWasteType.isNotEmpty ? rawWasteType : 'Sanitary',
      status: json['status']?.toString() ?? 'pending',
      landmark: json['landmark']?.toString() ?? '',
      userId: (json['user_id'] as num?)?.toInt(),
      collectorName: json['collector_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  bool get isToday {
    if (pickupDate.isEmpty) return false;
    final clean = pickupDate.trim().replaceAll('/', '-');
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return clean.length >= 10 && clean.substring(0, 10) == todayStr;
  }

  @override
  String toString() =>
      'LocationPickupModel(id: $id, pickupId: $pickupId, name: $name, status: $status, date: $pickupDate)';
}
