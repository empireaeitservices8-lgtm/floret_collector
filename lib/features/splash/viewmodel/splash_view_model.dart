import 'dart:async';
import 'package:flutter/material.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../model/splash_model.dart';
import '../repos/splash_repository.dart';

class SplashViewModel extends ViewModel {
  final SplashRepository _repository;
  SplashModel _state = const SplashModel();

  Timer? _timer;

  SplashViewModel({SplashRepository? repository})
      : _repository = repository ?? SplashRepository();

  SplashModel get state => _state;

  void initialize(BuildContext context, {required VoidCallback onComplete}) {
    _timer = Timer(const Duration(milliseconds: 2500), () async {
      final isLoggedIn = await _repository.initializeApp();
      _state = _state.copyWith(isReady: true, isAuthenticated: isLoggedIn);
      notifyListeners();

      if (!context.mounted) return;
      onComplete();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
