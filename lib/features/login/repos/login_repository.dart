import 'package:floret_collector/services/web_api_services.dart';
import 'package:floret_collector/utils/sp_keys.dart' as sp_keys;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/login_model.dart';

class LoginRepository {
  final WebAPIService _webAPIService;

  LoginRepository({WebAPIService? webAPIService})
      : _webAPIService = webAPIService ?? WebAPIService();

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      // If mock/offline or before server is wired up, simulate successful login
      // or connect to real endpoint when ready
      final sp = await SharedPreferences.getInstance();
      await sp.setString(sp_keys.keyToken, 'auth_token_${request.username}');
      await sp.setString('saved_username', request.username);
      await sp.setString(sp_keys.keyUserName, request.username);
      await _webAPIService.initTokenToHeader();

      return LoginResponseModel(
        success: true,
        message: 'Login successful',
        token: 'auth_token_${request.username}',
        user: UserModel(
          username: request.username,
          name: request.username,
        ),
      );
    } catch (e) {
      return LoginResponseModel(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<String?> getSavedUsername() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('saved_username');
  }
}
