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

  Future<Map<String, dynamic>?> fetchVehicleAssignment({String? collectorId}) async {
    try {
      final res = await _repository.fetchVehicleAssignment(collectorId: collectorId);
      final vName = res['vehicle_name']?.toString() ?? _profile.vehicleName;
      final vNum = res['vehicle_number']?.toString() ?? _profile.regNo;
      final aPhoto = res['aadhaar_card_photo']?.toString() ?? _profile.aadhaarPhoto;
      final cName = res['collector_name']?.toString();
      _profile = _profile.copyWith(
        vehicleName: vName,
        regNo: vNum,
        aadhaarPhoto: aPhoto,
        name: (cName != null && cName.isNotEmpty) ? cName : _profile.name,
      );
      notifyListeners();
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> assignVehicle({
    required String collectorId,
    required String vehicleName,
    required String vehicleNumber,
    String? aadhaarPhoto,
  }) async {
    try {
      final res = await _repository.assignVehicle(
        collectorId: collectorId,
        vehicleName: vehicleName,
        vehicleNumber: vehicleNumber,
        aadhaarPhoto: aadhaarPhoto,
      );
      _profile = _profile.copyWith(
        collectorId: collectorId,
        vehicleName: res['vehicle_name']?.toString() ?? vehicleName,
        regNo: res['vehicle_number']?.toString() ?? vehicleNumber,
        aadhaarPhoto: res['aadhaar_card_photo']?.toString() ?? aadhaarPhoto,
      );
      notifyListeners();
      return res;
    } catch (_) {
      return null;
    }
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
