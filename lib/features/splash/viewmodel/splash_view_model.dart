import 'package:flutter/foundation.dart';
import 'package:floret_collector/features/login/repos/login_repository.dart';

class SplashViewModel extends ChangeNotifier {
  final LoginRepository _repository;

  SplashViewModel({
    required LoginRepository repository,
  }) : _repository = repository;

  Future<bool> checkLoginStatus() async {
    try {
      final token = await _repository.getSavedToken();

      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Splash error: $e');
      return false;
    }
  }
}
