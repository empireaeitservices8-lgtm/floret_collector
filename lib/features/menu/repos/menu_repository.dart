import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/core/storage/collection_metrics_storage.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import 'package:floret_collector/services/token_storage.dart';
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

  Future<UserProfileModel?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check full serialized profile first
      final cachedProfileStr =
          prefs.getString(CollectorLocalStorage.keyUserProfile);
      if (cachedProfileStr != null && cachedProfileStr.isNotEmpty) {
        final decoded = jsonDecode(cachedProfileStr);
        if (decoded is Map<String, dynamic>) {
          final profile = UserProfileModel.fromJson(decoded);
          if (profile.name.isNotEmpty ||
              profile.phone.isNotEmpty ||
              profile.vehicleName.isNotEmpty) {
            return profile;
          }
        }
      }

      // Fallback to collectorLocalStorage and individual keys
      final collector =
          await _collectorLocalStorage.getCollector() ?? <String, dynamic>{};
      final collectorId = await _collectorLocalStorage.getCollectorId();

      final name = collector['name']?.toString() ??
          collector['username']?.toString() ??
          prefs.getString(CollectorLocalStorage.keyCollectorName) ??
          prefs.getString('saved_username') ??
          '';

      final phone = collector['phone']?.toString() ??
          prefs.getString(CollectorLocalStorage.keyCollectorPhone) ??
          '';

      final vehicleName = collector['vehicle_name']?.toString() ??
          prefs.getString(CollectorLocalStorage.keyVehicleName) ??
          '';

      final vehicleNumber = collector['vehicle_number']?.toString() ??
          collector['reg_no']?.toString() ??
          prefs.getString(CollectorLocalStorage.keyVehicleNumber) ??
          '';

      final vehicleStatus = collector['vehicle_status']?.toString() ??
          prefs.getString(CollectorLocalStorage.keyVehicleStatus) ??
          'Assigned';

      final aadhaarPhoto = collector['aadhaar_card_photo']?.toString() ??
          collector['photo']?.toString() ??
          '';

      final ward = collector['ward']?.toString() ?? '';
      final localBody = collector['local_body']?.toString() ?? '';
      final district = collector['district']?.toString() ?? '';

      if (name.isNotEmpty ||
          phone.isNotEmpty ||
          vehicleName.isNotEmpty ||
          vehicleNumber.isNotEmpty) {
        return UserProfileModel(
          collectorId: collectorId,
          name: name,
          phone: phone,
          vehicleName: vehicleName.isNotEmpty ? vehicleName : 'Toyota HiAce',
          vehicleStatus: vehicleStatus,
          regNo: vehicleNumber.isNotEmpty ? vehicleNumber : 'KL-01-AB-1201',
          ward: ward.isNotEmpty ? ward : '39 - CHIRAKANI',
          localBody: localBody,
          district: district,
          aadhaarStatus: 'Verified On File',
          aadhaarPhoto: aadhaarPhoto,
        );
      }
    } catch (e) {
      debugPrint('MenuRepository: Error getting cached profile: $e');
    }
    return null;
  }

  Future<void> saveUserProfileLocally(UserProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Save serialized profile JSON
      await prefs.setString(
        CollectorLocalStorage.keyUserProfile,
        jsonEncode(profile.toJson()),
      );

      // 2. Save name, phone, vehicle details to individual keys & collector storage
      await _collectorLocalStorage.saveCollectorDetails(
        name: profile.name,
        phone: profile.phone,
        vehicleName: profile.vehicleName,
        vehicleNumber: profile.regNo,
        vehicleStatus: profile.vehicleStatus,
      );

      // Also ensure ward, local_body, district, photo are cached in collector map
      final collector =
          await _collectorLocalStorage.getCollector() ?? <String, dynamic>{};
      if (profile.ward.isNotEmpty) collector['ward'] = profile.ward;
      if (profile.localBody.isNotEmpty) {
        collector['local_body'] = profile.localBody;
      }
      if (profile.district.isNotEmpty) collector['district'] = profile.district;
      if (profile.aadhaarPhoto.isNotEmpty) {
        collector['aadhaar_card_photo'] = profile.aadhaarPhoto;
      }
      await _collectorLocalStorage.saveCollector(collector);
    } catch (e) {
      debugPrint('MenuRepository: Error saving user profile locally: $e');
    }
  }

  Future<UserProfileModel> fetchUserProfile() async {
    try {
      final collector =
          await _collectorLocalStorage.getCollector() ?? <String, dynamic>{};
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
      String ward = collector['ward']?.toString() ?? '';
      String localBody = collector['local_body']?.toString() ?? '';
      String district = collector['district']?.toString() ?? '';

      // Execute network requests concurrently with timeout so screen loads fast
      final futures = await Future.wait([
        // 1. Collector profile details from API
        _apiClient
            .get(APIEndPoints.collectorDetail(collectorId))
            .timeout(const Duration(seconds: 4))
            .catchError((e) {
          debugPrint('MenuRepository: Error fetching collector details: $e');
          return null as dynamic;
        }),
        // 2. Assigned vehicle details from API
        _apiClient
            .get(
          APIEndPoints.getAssignVehicle,
          queryParameters: {
            'collector_id': collectorId,
            'id': collectorId,
          },
        )
            .timeout(const Duration(seconds: 4))
            .catchError((e) {
          debugPrint('MenuRepository: Error fetching assigned vehicle: $e');
          return null as dynamic;
        }),
        // 3. Corresponding ward, local body, district of pickup from locations API
        _apiClient
            .get(APIEndPoints.locations)
            .timeout(const Duration(seconds: 4))
            .catchError((e) {
          debugPrint('MenuRepository: Error fetching locations: $e');
          return null as dynamic;
        }),
      ]);

      final dynamic profileRes = futures[0];
      final dynamic vehicleRes = futures[1];
      final dynamic locRes = futures[2];

      // 1. Parse profile details
      if (profileRes != null && profileRes.data is Map) {
        final data = Map<String, dynamic>.from(profileRes.data as Map);
        final apiName =
            data['name']?.toString() ?? data['username']?.toString();
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

      // 2. Parse assigned vehicle details
      if (vehicleRes != null && vehicleRes.data is Map) {
        final data = Map<String, dynamic>.from(vehicleRes.data as Map);
        if (data['vehicle_name'] != null &&
            data['vehicle_name'].toString().trim().isNotEmpty) {
          vehicleName = data['vehicle_name'].toString().trim();
          collector['vehicle_name'] = vehicleName;
        }
        if (data['vehicle_number'] != null &&
            data['vehicle_number'].toString().trim().isNotEmpty) {
          vehicleNumber = data['vehicle_number'].toString().trim();
          collector['vehicle_number'] = vehicleNumber;
        }
        if (data['aadhaar_card_photo'] != null &&
            data['aadhaar_card_photo'].toString().trim().isNotEmpty) {
          aadhaarPhoto = data['aadhaar_card_photo'].toString().trim();
          collector['aadhaar_card_photo'] = aadhaarPhoto;
        }
        final colName = data['collector_name']?.toString();
        if (colName != null && colName.trim().isNotEmpty) {
          name = colName.trim();
          collector['name'] = name;
        }
      }

      // 3. Parse locations
      if (locRes != null &&
          locRes.data is List &&
          (locRes.data as List).isNotEmpty) {
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
            if (pWard.isNotEmpty &&
                pDate.length >= 10 &&
                pDate.substring(0, 10) == todayStr) {
              final status = map['status']?.toString().toLowerCase() ?? '';
              if (status == 'arrived' ||
                  status == 'pending' ||
                  status == 'in_progress' ||
                  status == 'in progress') {
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
          final w = targetPickup['ward']?.toString().trim() ?? '';
          final lb = targetPickup['local_body']?.toString().trim() ?? '';
          final d = targetPickup['district']?.toString().trim() ?? '';

          if (w.isNotEmpty) {
            ward = w;
            collector['ward'] = ward;
          }
          if (lb.isNotEmpty) {
            localBody = lb;
            collector['local_body'] = localBody;
          }
          if (d.isNotEmpty) {
            district = d;
            collector['district'] = district;
          }
        }
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

      final profile = UserProfileModel(
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

      // Once loaded, save name, phone, vehicle details locally!
      await saveUserProfileLocally(profile);

      return profile;
    } catch (e) {
      debugPrint('MenuRepository: Error in fetchUserProfile: $e');
      final cached = await getCachedUserProfile();
      return cached ?? const UserProfileModel();
    }
  }

  Future<Map<String, dynamic>> fetchVehicleAssignment(
      {String? collectorId}) async {
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
      final collector =
          await _collectorLocalStorage.getCollector() ?? <String, dynamic>{};
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
      await _collectorLocalStorage.saveCollectorDetails(
        vehicleName: data['vehicle_name']?.toString(),
        vehicleNumber: data['vehicle_number']?.toString(),
      );
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
      final collector =
          await _collectorLocalStorage.getCollector() ?? <String, dynamic>{};
      collector['vehicle_name'] = vehicleName;
      collector['vehicle_number'] = vehicleNumber;
      if (aadhaarPhoto != null && aadhaarPhoto.trim().isNotEmpty) {
        collector['aadhaar_card_photo'] = aadhaarPhoto.trim();
      }
      await _collectorLocalStorage.saveCollector(collector);
      await _collectorLocalStorage.saveCollectorDetails(
        vehicleName: vehicleName,
        vehicleNumber: vehicleNumber,
      );
      return data;
    }
    throw Exception('Failed to assign vehicle');
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(sp_keys.keyToken);
    await sp.remove('saved_username');
    await sp.remove(sp_keys.keyUserName);
    await sp.remove(sp_keys.keyUseMobile);
    await sp.remove(CollectorLocalStorage.keyCollectorName);
    await sp.remove(CollectorLocalStorage.keyCollectorPhone);
    await sp.remove(CollectorLocalStorage.keyVehicleName);
    await sp.remove(CollectorLocalStorage.keyVehicleNumber);
    await sp.remove(CollectorLocalStorage.keyVehicleStatus);
    await sp.remove(CollectorLocalStorage.keyUserProfile);
    await _collectorLocalStorage.clearCollector();
    await CollectionMetricsStorage().clearMetrics();
    try {
      if (getIt.isRegistered<TokenStorage>()) {
        await getIt<TokenStorage>().deleteToken();
      }
    } catch (_) {}
    await _webAPIService.initTokenToHeader();
  }
}
