import 'package:flutter/foundation.dart';
import 'package:floret_collector/features/login/model/login_model.dart';
import 'package:floret_collector/features/login/model/user_model.dart';
import 'package:floret_collector/services/auth_services.dart';
import 'package:floret_collector/services/token_storage.dart';
import 'package:flutter/material.dart';

abstract class LoginRepository {
  Future<UserModel> login(LoginRequestModel request);
  Future<String?> getSavedToken();
  Future<void> logout();
}

class LoginRepositoryImpl implements LoginRepository {
  final AuthService authService;
  final TokenStorage tokenStorage;

  LoginRepositoryImpl({
    required this.authService,
    required this.tokenStorage,
  });

  @override
  Future<UserModel> login(LoginRequestModel request) async {
    final response = await authService.login(
      request.username,
      request.password,
    );

    if (response.token.isEmpty) {
      throw Exception('Login response did not contain a token');
    }
    // print("Toke");
    // print(response.token);
    await tokenStorage.saveToken(response.token);
    debugPrint("api/login/ response:${response.toString()}");

    return response;
  }

  @override
  Future<String?> getSavedToken() {
    return tokenStorage.getToken();
  }

  @override
  Future<void> logout() {
    return tokenStorage.deleteToken();
  }
}
  // Future<void> logout() async {
  //   final sp = await SharedPreferences.getInstance();
  //   await sp.remove(sp_keys.keyToken);
  //   await sp.remove('saved_username');
  //   await sp.remove(sp_keys.keyUserName);
  //   await _collectorLocalStorage.clearCollector();
  //   await _webAPIService.initTokenToHeader();
  // }