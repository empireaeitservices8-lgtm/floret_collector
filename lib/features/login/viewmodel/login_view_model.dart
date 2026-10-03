import 'package:flutter/material.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../model/login_model.dart';
import '../repos/login_repository.dart';
import '../../main/screen/main_screen.dart';

class LoginViewModel extends ViewModel {
  final LoginRepository _repository;

  String _username = '';
  String _password = '';
  bool _isPasswordVisible = false;
  String? _errorMessage;

  LoginViewModel({LoginRepository? repository})
      : _repository = repository ?? LoginRepository();

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

  Future<bool> login(BuildContext context) async {
    if (!isFormValid) {
      _errorMessage = 'Please enter both username and password';
      notifyListeners();
      return false;
    }

    isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequestModel(
        username: _username.trim(),
        password: _password,
      );

      final response = await _repository.login(request);

      isLoading = false;
      notifyListeners();

      if (response.success) {
        if (!context.mounted) return true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome ${response.user?.name ?? _username}!'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, MainScreen.routeName);
        return true;
      } else {
        _errorMessage = response.message ?? 'Invalid credentials';
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      _errorMessage = 'An error occurred during login. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
