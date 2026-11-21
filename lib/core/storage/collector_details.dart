import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CollectorLocalStorage {
  static const String _collectorKey = 'collector_data';
  static const String keyCollectorName = 'KEY_USER_NAME';
  static const String keyCollectorPhone = 'KEY_USER_MOBILE';
  static const String keyVehicleName = 'KEY_VEHICLE_NAME';
  static const String keyVehicleNumber = 'KEY_VEHICLE_NUMBER';
  static const String keyVehicleStatus = 'KEY_VEHICLE_STATUS';
  static const String keyUserProfile = 'KEY_USER_PROFILE';
  static const String keyLocalBody = 'KEY_LOCAL_BODY';
  static const String keyDistrict = 'KEY_DISTRICT';
  static const String keyWard = 'KEY_WARD';

  Future<void> saveCollector(
    Map<String, dynamic> collector,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _collectorKey,
      jsonEncode(collector),
    );

    // Save individual fields locally for instant access
    final name = collector['name']?.toString() ?? collector['username']?.toString();
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(keyCollectorName, name.trim());
      await prefs.setString('saved_username', name.trim());
    }

    final phone = collector['phone']?.toString();
    if (phone != null && phone.trim().isNotEmpty) {
      await prefs.setString(keyCollectorPhone, phone.trim());
    }

    final vehicleName = collector['vehicle_name']?.toString();
    if (vehicleName != null && vehicleName.trim().isNotEmpty) {
      await prefs.setString(keyVehicleName, vehicleName.trim());
    }

    final vehicleNumber = collector['vehicle_number']?.toString() ??
        collector['reg_no']?.toString();
    if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) {
      await prefs.setString(keyVehicleNumber, vehicleNumber.trim());
    }

    final vehicleStatus = collector['vehicle_status']?.toString();
    if (vehicleStatus != null && vehicleStatus.trim().isNotEmpty) {
      await prefs.setString(keyVehicleStatus, vehicleStatus.trim());
    }

    final localBody = collector['local_body']?.toString() ??
        collector['localBody']?.toString();
    if (localBody != null && localBody.trim().isNotEmpty) {
      await prefs.setString(keyLocalBody, localBody.trim());
    }

    final district = collector['district']?.toString();
    if (district != null && district.trim().isNotEmpty) {
      await prefs.setString(keyDistrict, district.trim());
    }

    final ward = collector['ward']?.toString();
    if (ward != null && ward.trim().isNotEmpty) {
      await prefs.setString(keyWard, ward.trim());
    }
  }

  Future<void> saveCollectorDetails({
    String? name,
    String? phone,
    String? vehicleName,
    String? vehicleNumber,
    String? vehicleStatus,
    String? localBody,
    String? district,
    String? ward,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(keyCollectorName, name.trim());
      await prefs.setString('saved_username', name.trim());
    }
    if (phone != null && phone.trim().isNotEmpty) {
      await prefs.setString(keyCollectorPhone, phone.trim());
    }
    if (vehicleName != null && vehicleName.trim().isNotEmpty) {
      await prefs.setString(keyVehicleName, vehicleName.trim());
    }
    if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) {
      await prefs.setString(keyVehicleNumber, vehicleNumber.trim());
    }
    if (vehicleStatus != null && vehicleStatus.trim().isNotEmpty) {
      await prefs.setString(keyVehicleStatus, vehicleStatus.trim());
    }
    if (localBody != null && localBody.trim().isNotEmpty) {
      await prefs.setString(keyLocalBody, localBody.trim());
    }
    if (district != null && district.trim().isNotEmpty) {
      await prefs.setString(keyDistrict, district.trim());
    }
    if (ward != null && ward.trim().isNotEmpty) {
      await prefs.setString(keyWard, ward.trim());
    }

    final collector = await getCollector() ?? <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) collector['name'] = name.trim();
    if (phone != null && phone.trim().isNotEmpty) collector['phone'] = phone.trim();
    if (vehicleName != null && vehicleName.trim().isNotEmpty) collector['vehicle_name'] = vehicleName.trim();
    if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty) collector['vehicle_number'] = vehicleNumber.trim();
    if (vehicleStatus != null && vehicleStatus.trim().isNotEmpty) collector['vehicle_status'] = vehicleStatus.trim();
    if (localBody != null && localBody.trim().isNotEmpty) collector['local_body'] = localBody.trim();
    if (district != null && district.trim().isNotEmpty) collector['district'] = district.trim();
    if (ward != null && ward.trim().isNotEmpty) collector['ward'] = ward.trim();
    await prefs.setString(_collectorKey, jsonEncode(collector));
  }

  Future<String?> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyCollectorName) ?? prefs.getString('saved_username');
  }

  Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyCollectorPhone);
  }

  Future<String?> getSavedVehicleName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyVehicleName);
  }

  Future<String?> getSavedVehicleNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyVehicleNumber);
  }

  Future<String?> getSavedLocalBody() async {
    final prefs = await SharedPreferences.getInstance();
    final lb = prefs.getString(keyLocalBody);
    if (lb != null && lb.trim().isNotEmpty) return lb.trim();
    final collector = await getCollector();
    final colLb = collector?['local_body']?.toString() ??
        collector?['localBody']?.toString();
    return (colLb != null && colLb.trim().isNotEmpty) ? colLb.trim() : null;
  }

  Future<String?> getSavedDistrict() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString(keyDistrict);
    if (d != null && d.trim().isNotEmpty) return d.trim();
    final collector = await getCollector();
    final colD = collector?['district']?.toString();
    return (colD != null && colD.trim().isNotEmpty) ? colD.trim() : null;
  }

  Future<String?> getSavedWard() async {
    final prefs = await SharedPreferences.getInstance();
    final w = prefs.getString(keyWard);
    if (w != null && w.trim().isNotEmpty) return w.trim();
    final collector = await getCollector();
    final colW = collector?['ward']?.toString();
    return (colW != null && colW.trim().isNotEmpty) ? colW.trim() : null;
  }

  Future<Map<String, dynamic>?> getCollector() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_collectorKey);

    if (data == null) return null;

    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<String> getUsername() async {
    final collector = await getCollector();
    final username = collector?['username']?.toString() ??
        collector?['user_name']?.toString();
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_username') ??
        prefs.getString('KEY_USER_NAME');
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return 'sanu';
  }

  Future<String> getCollectorName() async {
    final collector = await getCollector();
    final username = collector?['username']?.toString() ??
        collector?['user_name']?.toString();
    if (username != null && username.trim().isNotEmpty) {
      return username.trim();
    }
    final name = collector?['name']?.toString();
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    return getUsername();
  }

  Future<String> getCollectorId() async {
    final collector = await getCollector();
    final id = collector?['id']?.toString();
    if (id != null && id.trim().isNotEmpty && id.trim() != '0') {
      return id.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('KEY_USER_ID');
    if (savedId != null && savedId.trim().isNotEmpty) {
      return savedId.trim();
    }
    return '68';
  }

  Future<void> clearCollector() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_collectorKey);
    await prefs.remove(keyCollectorName);
    await prefs.remove(keyCollectorPhone);
    await prefs.remove(keyVehicleName);
    await prefs.remove(keyVehicleNumber);
    await prefs.remove(keyVehicleStatus);
    await prefs.remove(keyUserProfile);
    await prefs.remove(keyLocalBody);
    await prefs.remove(keyDistrict);
    await prefs.remove(keyWard);
    await prefs.remove('saved_username');
    await prefs.remove('KEY_USER_NAME');
    await prefs.remove('KEY_USER_MOBILE');
    await prefs.remove('KEY_USER_ID');
    await prefs.remove('KEY_TOKEN');
  }
}
