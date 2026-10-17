class UserProfileModel {
  final String collectorId;
  final String name;
  final String phone;
  final String vehicleName;
  final String vehicleStatus;
  final String regNo;
  final String ward;
  final String localBody;
  final String district;
  final String aadhaarStatus;
  final String aadhaarPhoto;

  const UserProfileModel({
    this.collectorId = '68',
    this.name = 'shyam',
    this.phone = '+91 82815 35237',
    this.vehicleName = 'Toyota HiAce',
    this.vehicleStatus = 'Assigned',
    this.regNo = 'KL-01-AB-1201',
    this.ward = '39 - CHIRAKANI',
    this.localBody = '',
    this.district = '',
    this.aadhaarStatus = 'Verified On File',
    this.aadhaarPhoto = '',
  });

  UserProfileModel copyWith({
    String? collectorId,
    String? name,
    String? phone,
    String? vehicleName,
    String? vehicleStatus,
    String? regNo,
    String? ward,
    String? localBody,
    String? district,
    String? aadhaarStatus,
    String? aadhaarPhoto,
  }) {
    return UserProfileModel(
      collectorId: collectorId ?? this.collectorId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleStatus: vehicleStatus ?? this.vehicleStatus,
      regNo: regNo ?? this.regNo,
      ward: ward ?? this.ward,
      localBody: localBody ?? this.localBody,
      district: district ?? this.district,
      aadhaarStatus: aadhaarStatus ?? this.aadhaarStatus,
      aadhaarPhoto: aadhaarPhoto ?? this.aadhaarPhoto,
    );
  }
}
