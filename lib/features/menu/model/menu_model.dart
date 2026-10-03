class UserProfileModel {
  final String name;
  final String phone;
  final String vehicleName;
  final String vehicleStatus;
  final String regNo;
  final String ward;
  final String aadhaarStatus;

  const UserProfileModel({
    this.name = 'floret',
    this.phone = '5656565656',
    this.vehicleName = 'Toyota HiAce',
    this.vehicleStatus = 'Assigned',
    this.regNo = 'KL-01-AB-1234',
    this.ward = 'Ward 1',
    this.aadhaarStatus = 'Verified On File',
  });
}
