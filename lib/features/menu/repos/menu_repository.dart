import '../model/menu_model.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/services/web_api_services.dart';
import 'package:floret_collector/utils/sp_keys.dart' as sp_keys;
import 'package:shared_preferences/shared_preferences.dart';

class MenuRepository {
  final WebAPIService _webAPIService;
  final CollectorLocalStorage _collectorLocalStorage;

  MenuRepository({
    WebAPIService? webAPIService,
    CollectorLocalStorage? collectorLocalStorage,
  })  : _webAPIService = webAPIService ?? WebAPIService(),
        _collectorLocalStorage =
            collectorLocalStorage ?? CollectorLocalStorage();

  Future<UserProfileModel> fetchUserProfile() async {
    try {
      final collector = await _collectorLocalStorage.getCollector();
      final sp = await SharedPreferences.getInstance();
      final savedUser = collector?['name']?.toString() ??
          collector?['username']?.toString() ??
          sp.getString('saved_username') ??
          sp.getString(sp_keys.keyUserName) ??
          'shyam';

      final phone = collector?['phone']?.toString() ?? '+91 82815 35237';
      final vehicleName =
          collector?['vehicle_name']?.toString() ?? 'Toyota HiAce';
      final regNo =
          collector?['vehicle_number']?.toString() ?? 'KL-01-AB-1200';

      return UserProfileModel(
        name: savedUser.isNotEmpty ? savedUser : 'shyam',
        phone: phone.isNotEmpty ? phone : '+91 82815 35237',
        vehicleName: vehicleName.isNotEmpty ? vehicleName : 'Toyota HiAce',
        vehicleStatus: 'Assigned',
        regNo: regNo.isNotEmpty ? regNo : 'KL-01-AB-1200',
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
    await _collectorLocalStorage.clearCollector();
    await _webAPIService.initTokenToHeader();
  }
}
