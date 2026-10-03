import '../model/home_model.dart';
import 'package:floret_collector/services/web_api_services.dart';
import 'package:floret_collector/utils/sp_keys.dart' as sp_keys;
import 'package:shared_preferences/shared_preferences.dart';

class HomeRepository {
  final WebAPIService _webAPIService;

  HomeRepository({WebAPIService? webAPIService})
      : _webAPIService = webAPIService ?? WebAPIService();

  WebAPIService get webAPIService => _webAPIService;

  Future<HomeSummaryModel> fetchHomeSummary() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final savedUser =
          sp.getString('saved_username') ?? sp.getString(sp_keys.keyUserName);
      final userName = (savedUser != null && savedUser.trim().isNotEmpty)
          ? savedUser.trim()
          : 'User';

      return HomeSummaryModel(
        userName: userName,
        locationArea: 'N/A',
        remainingCovers: '0/0',
        weight: '0.0 kg',
        collectedAmount: '₹0',
        sanitaryPickups: '0/0',
        routeDescription: 'Organic & domestic bio-waste',
      );
    } catch (_) {
      return const HomeSummaryModel();
    }
  }
}
