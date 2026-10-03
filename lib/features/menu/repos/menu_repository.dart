import '../model/menu_model.dart';
import 'package:floret_collector/services/web_api_services.dart';
import 'package:floret_collector/utils/sp_keys.dart' as sp_keys;
import 'package:shared_preferences/shared_preferences.dart';

class MenuRepository {
  final WebAPIService _webAPIService;

  MenuRepository({WebAPIService? webAPIService})
      : _webAPIService = webAPIService ?? WebAPIService();

  Future<UserProfileModel> fetchUserProfile() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final savedUser =
          sp.getString('saved_username') ?? sp.getString(sp_keys.keyUserName);
      return UserProfileModel(
        name: savedUser != null && savedUser.isNotEmpty ? savedUser : 'shyam',
        phone: '+91 82815 35237',
        vehicleName: 'Toyota HiAce',
        vehicleStatus: 'Assigned',
        regNo: 'KL-01-AB-1200',
        ward: 'Ward 1',
        aadhaarStatus: 'Verified On File',
      );
    } catch (_) {
      return const UserProfileModel();
    }
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(sp_keys.keyToken);
    await sp.remove('saved_username');
    await sp.remove(sp_keys.keyUserName);
    await _webAPIService.initTokenToHeader();
  }
}
