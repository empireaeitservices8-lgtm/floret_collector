import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import 'package:floret_collector/services/token_storage.dart';
import '../model/direct_disposal_model.dart';

class DirectDisposalRepository {
  final ApiClient _apiClient;
  final CollectorLocalStorage _collectorLocalStorage;

  DirectDisposalRepository({
    ApiClient? apiClient,
    CollectorLocalStorage? collectorLocalStorage,
  })  : _apiClient = apiClient ??
            (getIt.isRegistered<ApiClient>()
                ? getIt<ApiClient>()
                : ApiClient()),
        _collectorLocalStorage = collectorLocalStorage ??
            (getIt.isRegistered<CollectorLocalStorage>()
                ? getIt<CollectorLocalStorage>()
                : CollectorLocalStorage());

  final List<DirectDisposalLogModel> _logs = [];

  Future<List<DirectDisposalLogModel>> fetchLogs() async {
    try {
      final response = await _apiClient.get(APIEndPoints.directDisposal);
      // // Print response formatted like the API response
      // try {
      //   const encoder = JsonEncoder.withIndent('  ');
      //   final formattedJson = encoder.convert(response.data);
      //   // ignore: avoid_print
      //   print(formattedJson);
      // } catch (_) {
      //   // ignore: avoid_print
      //   print(response.data);
      // }

      if (response.data is List) {
        final list = response.data as List;
        final fetched = list
            .map((item) => DirectDisposalLogModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
        final username =
            (await _collectorLocalStorage.getUsername()).trim().toLowerCase();

        final collector = await _collectorLocalStorage.getCollector();
        final collectorName =
            (collector?['name']?.toString() ?? '').trim().toLowerCase();
        final collectorId = (await _collectorLocalStorage.getCollectorId())
            .trim()
            .toLowerCase();

        final userLogs = fetched.where((log) {
          final rec = (log.recordedBy ?? '').trim().toLowerCase();
          if (rec.isEmpty) return false;
          return (username.isNotEmpty && rec == username) ||
              (collectorName.isNotEmpty && rec == collectorName) ||
              (collectorId.isNotEmpty && rec == collectorId);
        }).toList();

        _logs.clear();
        _logs.addAll(userLogs);
        return List.from(_logs);
      }
    } catch (_) {}

    return List.from(_logs);
  }

  Future<Map<String, dynamic>?> fetchBagAssignment([String? collectorId]) async {
    try {
      String effectiveCollectorId = collectorId ?? '';
      if (effectiveCollectorId.isEmpty) {
        effectiveCollectorId = await _collectorLocalStorage.getCollectorId();
      }
      if (effectiveCollectorId.isEmpty) {
        final collector = await _collectorLocalStorage.getCollector();
        effectiveCollectorId = collector?['id']?.toString() ?? '';
      }
      if (effectiveCollectorId.isEmpty) return null;

      final response = await _apiClient.get(
        APIEndPoints.bagAssignment,
        queryParameters: {'collector_id': effectiveCollectorId},
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is List && (response.data as List).isNotEmpty) {
        final first = (response.data as List).first;
        if (first is Map) {
          return Map<String, dynamic>.from(first);
        }
      }
      return null;
    } catch (e) {
      debugPrint('DirectDisposalRepository fetchBagAssignment error: $e');
      return null;
    }
  }

  Future<DirectDisposalLogModel> recordDisposal({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String disposalType = 'direct',
    required String wasteType,
    String? wasteDescription,
    required double weight,
    required double disposalRate,
    // int? localBody,
    // int? ward,
    required String paymentStatus,
    int bagCount = 0,
  }) async {
    // int? resolvedLocalBody = localBody;
    // int? resolvedWard = ward;
    String username = '';

    username = await _collectorLocalStorage.getUsername();
    final collector = await _collectorLocalStorage.getCollector();
    final collectorId = (await _collectorLocalStorage.getCollectorId()).trim();

    // if (collector != null) {
    //   resolvedLocalBody ??=
    //       int.tryParse(collector['local_body']?.toString() ?? '');

    //   resolvedWard ??= int.tryParse(collector['ward']?.toString() ?? '');
    // }

    // if (resolvedLocalBody == null || resolvedWard == null) {
    //   throw Exception('Please select a local body and ward.');
    // }

    final requestBody = <String, dynamic>{
      'customer_name': customerName.trim(),
      'customer_phone': customerPhone.trim(),
      'customer_address': customerAddress.trim(),
      'disposal_type': disposalType,
      'waste_type': wasteType,
      'waste_description': wasteDescription ?? 'Mixed waste',
      'weight': weight,
      'disposal_rate': disposalRate,
      // 'local_body': resolvedLocalBody,
      // 'ward': resolvedWard,
      'payment_status': paymentStatus.trim().toLowerCase(),
      'bag_count': bagCount,
      'bags_count': bagCount,
      'bags_used': bagCount,
      if (collectorId.isNotEmpty) 'collector_id': collectorId,
      if (username.isNotEmpty) 'recorded_by': username,
    };

    final response = await _apiClient.post(
      APIEndPoints.directDisposal,
      data: requestBody,
    );

    final data = response.data;

    if (data is! Map || data['disposal'] is! Map) {
      throw const FormatException(
        'Invalid response: disposal details are missing.',
      );
    }

    final disposalData = Map<String, dynamic>.from(
      data['disposal'] as Map,
    );

    if (disposalData['recorded_by'] == null && username.isNotEmpty) {
      disposalData['recorded_by'] = username;
    }

    final createdLog = DirectDisposalLogModel.fromJson(disposalData);

    _logs.insert(0, createdLog);

    return createdLog;
  }

  Future<Response?> exportDisposalLogs({String? collectorId}) async {
    final id = (collectorId != null && collectorId.trim().isNotEmpty)
        ? collectorId.trim()
        : await _collectorLocalStorage.getCollectorId();

    const url = APIEndPoints.directDisposalExport;
    debugPrint(
        'Calling direct disposal export API (GET): $url with collector_id: $id');

    String? token;
    try {
      if (getIt.isRegistered<TokenStorage>()) {
        token = await getIt<TokenStorage>().getToken();
      }
    } catch (_) {}

    final headers = <String, dynamic>{
      'accept': '*/*',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final res = await _apiClient.dio.get(
        url,
        queryParameters: {'collector_id': id},
        options: Options(
          headers: headers,
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      debugPrint('Export API GET Response: status=${res.statusCode}');
      return res;
    } catch (e) {
      debugPrint('Export API GET error: $e');
      return null;
    }
  }

  Future<Response?> downloadDisposalLogs(String savePath,
      {String? collectorId}) async {
    final id = (collectorId != null && collectorId.trim().isNotEmpty)
        ? collectorId.trim()
        : await _collectorLocalStorage.getCollectorId();

    const url = APIEndPoints.directDisposalExport;
    debugPrint(
        'Calling dio.download: $url with collector_id: $id to $savePath');

    String? token;
    try {
      if (getIt.isRegistered<TokenStorage>()) {
        token = await getIt<TokenStorage>().getToken();
      }
    } catch (_) {}

    final headers = <String, dynamic>{
      'accept': '*/*',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final res = await _apiClient.dio.download(
        url,
        savePath,
        queryParameters: {'collector_id': id},
        options: Options(
          method: 'GET',
          headers: headers,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      debugPrint('Dio download Response: status=${res.statusCode}');
      return res;
    } catch (e) {
      debugPrint('Dio download error: $e');
      return null;
    }
  }
}
