import 'package:floret_collector/services/web_api_services.dart';

class SplashRepository {
  final WebAPIService _webAPIService;

  SplashRepository({WebAPIService? webAPIService})
      : _webAPIService = webAPIService ?? WebAPIService();

  Future<bool> initializeApp() async {
    try {
      await _webAPIService.initTokenToHeader();
      await _webAPIService.initLangPrefToHeader();
      final token = await _webAPIService.getTokenFromSharedPref();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
