import 'package:flutter/foundation.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import 'package:floret_collector/services/web_api_services.dart';
import 'package:floret_collector/utils/sp_keys.dart' as sp_keys;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/menu_model.dart';

class MenuRepository {
  final ApiClient _apiClient;
  final WebAPIService _webAPIService;
  final CollectorLocalStorage _collectorLocalStorage;

  MenuRepository({
    ApiClient? apiClient,
    WebAPIService? webAPIService,
    CollectorLocalStorage? collectorLocalStorage,
  })  : _apiClient = apiClient ??
            (getIt.isRegistered<ApiClient>()
                ? getIt<ApiClient>()
                : ApiClient()),
        _webAPIService = webAPIService ?? WebAPIService(),
        _collectorLocalStorage = collectorLocalStorage ??
            (getIt.isRegistered<CollectorLocalStorage>()
                ? getIt<CollectorLocalStorage>()
                : CollectorLocalStorage());

  Future<UserProfileModel> fetchUserProfile() async {
    try {
      final collector = await _collectorLocalStorage.getCollector() ?? <String, dynamic>{};
      final collectorId = await _collectorLocalStorage.getCollectorId();

      String name = collector['name']?.toString() ??
          collector['username']?.toString() ??
          '';
      String phone = collector['phone']?.toString() ?? '';
      String vehicleName = collector['vehicle_name']?.toString() ?? '';
      String vehicleNumber = collector['vehicle_number']?.toString() ?? '';
      String aadhaarPhoto = collector['aadhaar_card_photo']?.toString() ??
          collector['photo']?.toString() ??
          '';

      // 1. Fetch collector profile details from API
      try {
        final profileRes = await _apiClient.get(
          APIEndPoints.collectorDetail(collectorId),
        );
        if (profileRes.data is Map) {
          final data = Map<String, dynamic>.from(profileRes.data as Map);
          final apiName = data['name']?.toString() ?? data['username']?.toString();
          if (apiName != null && apiName.trim().isNotEmpty) {
            name = apiName.trim();
            collector['name'] = name;
          }
          final apiPhone = data['phone']?.toString();
          if (apiPhone != null && apiPhone.trim().isNotEmpty) {
            phone = apiPhone.trim();
            collector['phone'] = phone;
          }
          final apiVehicleNumber = data['vehicle_number']?.toString();
          if (apiVehicleNumber != null && apiVehicleNumber.trim().isNotEmpty) {
            vehicleNumber = apiVehicleNumber.trim();
            collector['vehicle_number'] = vehicleNumber;
          }
        }
      } catch (_) {}

      // 2. Fetch assigned vehicle details from API
      try {
        final vehicleRes = await _apiClient.get(
          APIEndPoints.getAssignVehicle,
          queryParameters: {
            'collector_id': collectorId,
            'id': collectorId,
          },
        );
        if (vehicleRes.data is Map) {
          final data = Map<String, dynamic>.from(vehicleRes.data as Map);
          if (data['vehicle_name'] != null) {
            vehicleName = data['vehicle_name'].toString();
            collector['vehicle_name'] = vehicleName;
          }
          if (data['vehicle_number'] != null) {
            vehicleNumber = data['vehicle_number'].toString();
            collector['vehicle_number'] = vehicleNumber;
          }
          if (data['aadhaar_card_photo'] != null) {
            aadhaarPhoto = data['aadhaar_card_photo'].toString();
            collector['aadhaar_card_photo'] = aadhaarPhoto;
          }
          final colName = data['collector_name']?.toString();
          if (colName != null && colName.trim().isNotEmpty) {
            name = colName.trim();
            collector['name'] = name;
          }
        }
      } catch (_) {}

      // 3. Fetch corresponding ward, local body, district of pickup from locations API
      String ward = '';
      String localBody = '';
      String district = '';

      try {
        final locRes = await _apiClient.get(APIEndPoints.locations);
        debugPrint('MenuRepository: GET locations response: ${locRes.statusCode}');
        if (locRes.data is List && (locRes.data as List).isNotEmpty) {
          final list = locRes.data as List;
          final now = DateTime.now();
          final todayStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          Map<String, dynamic>? targetPickup;

          // Find today's corresponding pickup (prioritize arrived/pending/in-progress)
          for (final item in list) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final pDate = map['pickup_date']?.toString() ?? '';
              final pWard = map['ward']?.toString().trim() ?? '';
              if (pWard.isNotEmpty && pDate.length >= 10 && pDate.substring(0, 10) == todayStr) {
                final status = map['status']?.toString().toLowerCase() ?? '';
                if (status == 'arrived' || status == 'pending' || status == 'in_progress' || status == 'in progress') {
                  targetPickup = map;
                  break;
                }
                targetPickup ??= map;
              }
            }
          }

          // Fallback to the first pickup with a valid ward
          if (targetPickup == null) {
            for (final item in list) {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                final pWard = map['ward']?.toString().trim() ?? '';
                if (pWard.isNotEmpty) {
                  targetPickup = map;
                  break;
                }
              }
            }
          }

          if (targetPickup != null) {
            ward = targetPickup['ward']?.toString().trim() ?? '';
            localBody = targetPickup['local_body']?.toString().trim() ?? '';
            district = targetPickup['district']?.toString().trim() ?? '';

            if (ward.isNotEmpty) collector['ward'] = ward;
            if (localBody.isNotEmpty) collector['local_body'] = localBody;
            if (district.isNotEmpty) collector['district'] = district;
          }
        }
      } catch (e) {
        debugPrint('MenuRepository: Error fetching locations: $e');
      }

      if (ward.isEmpty) {
        ward = collector['ward']?.toString() ?? '';
      }
      if (localBody.isEmpty) {
        localBody = collector['local_body']?.toString() ?? '';
      }
      if (district.isEmpty) {
        district = collector['district']?.toString() ?? '';
      }

      // Save updated cache
      await _collectorLocalStorage.saveCollector(collector);

      final sp = await SharedPreferences.getInstance();
      if (name.isEmpty) {
        name = sp.getString('saved_username') ??
            sp.getString(sp_keys.keyUserName) ??
            'shyam';
      }
      if (phone.isEmpty) {
        phone = sp.getString(sp_keys.keyUseMobile) ?? '+91 82815 35237';
      }
      if (vehicleName.isEmpty) {
        vehicleName = 'Toyota HiAce';
      }
      if (vehicleNumber.isEmpty) {
        vehicleNumber = 'KL-01-AB-1201';
      }

      return UserProfileModel(
        collectorId: collectorId,
        name: name,
        phone: phone,
        vehicleName: vehicleName,
        vehicleStatus: 'Assigned',
        regNo: vehicleNumber,
        ward: ward.isNotEmpty ? ward : '39 - CHIRAKANI',
        localBody: localBody,
        district: district,
        aadhaarStatus: 'Verified On File',
        aadhaarPhoto: aadhaarPhoto,
      );
    } catch (_) {
      return const UserProfileModel();
    }
  }

  Future<Map<String, dynamic>> fetchVehicleAssignment({String? collectorId}) async {
    final id = collectorId?.trim().isNotEmpty == true
        ? collectorId!.trim()
        : await _collectorLocalStorage.getCollectorId();

    final response = await _apiClient.get(
      APIEndPoints.getAssignVehicle,
      queryParameters: {
        'collector_id': id,
        'id': id,
      },
    );

    if (response.data is Map) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final collector = await _collectorLocalStorage.getCollector() ?? <String, dynamic>{};
      if (data['vehicle_name'] != null) {
        collector['vehicle_name'] = data['vehicle_name'];
      }
      if (data['vehicle_number'] != null) {
        collector['vehicle_number'] = data['vehicle_number'];
      }
      if (data['aadhaar_card_photo'] != null) {
        collector['aadhaar_card_photo'] = data['aadhaar_card_photo'];
      }
      await _collectorLocalStorage.saveCollector(collector);
      return data;
    }
    throw Exception('Failed to load vehicle assignment');
  }

  Future<Map<String, dynamic>> assignVehicle({
    required String collectorId,
    required String vehicleName,
    required String vehicleNumber,
    String? aadhaarPhoto,
  }) async {
    final payload = <String, dynamic>{
      'vehicle_name': vehicleName,
      'vehicle_number': vehicleNumber,
    };
    if (aadhaarPhoto != null && aadhaarPhoto.trim().isNotEmpty) {
      payload['aadhaar_card_photo'] = aadhaarPhoto.trim();
    }

    final response = await _apiClient.post(
      APIEndPoints.assignVehicle(collectorId),
      data: payload,
    );

    if (response.data is Map) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final collector = await _collectorLocalStorage.getCollector() ?? <String, dynamic>{};
      collector['vehicle_name'] = vehicleName;
      collector['vehicle_number'] = vehicleNumber;
      if (aadhaarPhoto != null && aadhaarPhoto.trim().isNotEmpty) {
        collector['aadhaar_card_photo'] = aadhaarPhoto.trim();
      }
      await _collectorLocalStorage.saveCollector(collector);
      return data;
    }
    throw Exception('Failed to assign vehicle');
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(sp_keys.keyToken);
    await sp.remove('saved_username');
    await sp.remove(sp_keys.keyUserName);
    await _collectorLocalStorage.clearCollector();
    await _webAPIService.initTokenToHeader();
  }
}
