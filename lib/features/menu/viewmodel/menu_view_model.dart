import 'package:flutter/material.dart';
import 'package:floret_collector/providers/view_model.dart';
import '../model/menu_model.dart';
import '../repos/menu_repository.dart';
import '../../login/screen/login_screen.dart';

class MenuViewModel extends ViewModel {
  final MenuRepository _repository;
  UserProfileModel _profile = const UserProfileModel();

  MenuViewModel({MenuRepository? repository})
      : _repository = repository ?? MenuRepository() {
    loadProfile();
  }

  UserProfileModel get profile => _profile;

  Future<void> loadProfile() async {
    isLoading = true;
    notifyListeners();

    _profile = await _repository.fetchUserProfile();

    isLoading = false;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.logout();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
      );
    }
  }
}
