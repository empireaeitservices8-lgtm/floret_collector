class CollectorModel {
  final int id;
  final String username;
  final String name;
  final String email;
  final String phone;
  final String vehicleName;
  final String vehicleNumber;
  final String? photo;

  const CollectorModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleName,
    required this.vehicleNumber,
    this.photo,
  });

  factory CollectorModel.fromJson(Map<String, dynamic> json) {
    return CollectorModel(
      id: json['id'] ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      vehicleName: json['vehicle_name']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      photo: json['photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicle_name': vehicleName,
      'vehicle_number': vehicleNumber,
      'photo': photo,
    };
  }
}
