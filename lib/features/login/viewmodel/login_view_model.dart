import 'package:floret_collector/features/login/model/login_model.dart';
import 'package:floret_collector/features/login/model/user_model.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../repos/login_repository.dart';

class LoginViewModel extends ViewModel {
  final LoginRepository _repository;

  LoginViewModel({
    required LoginRepository repository,
  }) : _repository = repository;

  String _username = '';
  String _password = '';
  bool _isPasswordVisible = false;
  String? _errorMessage;

  String get username => _username;
  String get password => _password;
  bool get isPasswordVisible => _isPasswordVisible;
  String? get errorMessage => _errorMessage;

  bool get isFormValid =>
      _username.trim().isNotEmpty && _password.trim().isNotEmpty;

  void onUsernameChanged(String value) {
    _username = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<UserModel?> login() async {
    if (isLoading) return null;

    if (!isFormValid) {
      _errorMessage = 'Please enter both username and password';
      notifyListeners();
      return null;
    }

    isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequestModel(
        username: _username.trim(),
        password: _password,
      );

      return await _repository.login(request);
    } catch (e) {
      final message = e.toString();

      _errorMessage = message.startsWith('Exception: ')
          ? message.substring('Exception: '.length)
          : 'Unable to login. Please try again.';

      notifyListeners();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
