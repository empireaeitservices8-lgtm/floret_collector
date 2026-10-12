import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import '../model/billing_history_model.dart';

abstract class BillingHistoryRepository {
  factory BillingHistoryRepository({
    ApiClient? apiClient,
    CollectorLocalStorage? collectorLocalStorage,
  }) = BillingHistoryRepositoryImpl;

  Future<List<BillItemModel>> fetchBills({String? userName});
}

class BillingHistoryRepositoryImpl implements BillingHistoryRepository {
  final ApiClient _apiClient;
  final CollectorLocalStorage _collectorLocalStorage;

  BillingHistoryRepositoryImpl({
    ApiClient? apiClient,
    CollectorLocalStorage? collectorLocalStorage,
  })  : _apiClient = apiClient ??
            (getIt.isRegistered<ApiClient>() ? getIt<ApiClient>() : ApiClient()),
        _collectorLocalStorage = collectorLocalStorage ??
            (getIt.isRegistered<CollectorLocalStorage>()
                ? getIt<CollectorLocalStorage>()
                : CollectorLocalStorage());

  @override
  Future<List<BillItemModel>> fetchBills({String? userName}) async {
    try {
      String resolvedUserName = userName?.trim() ?? '';
      if (resolvedUserName.isEmpty) {
        resolvedUserName = await _collectorLocalStorage.getUsername();
      }

      final queryParams = resolvedUserName.isNotEmpty
          ? {'user_name': resolvedUserName}
          : null;

      final response = await _apiClient.get(
        APIEndPoints.billHistory,
        queryParameters: queryParams,
      );

      // Print response formatted like the API response
      try {
        const encoder = JsonEncoder.withIndent('  ');
        final formattedJson = encoder.convert(response.data);
        // ignore: avoid_print
        print(formattedJson);
      } catch (_) {
        // ignore: avoid_print
        print(response.data);
      }

      final List<dynamic> data =
          response.data is List ? response.data as List<dynamic> : [];

      return data
          .map((item) => BillItemModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (e) {
      debugPrint('Error fetching bills from API: $e');
      rethrow;
    }
  }
}
