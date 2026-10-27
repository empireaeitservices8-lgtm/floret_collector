import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:floret_collector/features/collection_history/model/collection_summary_model.dart';
import 'package:intl/intl.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import '../model/collection_item_model.dart';

class CollectionHistoryResult {
  final List<CollectionItemModel> items;
  final CollectionSummaryModel summary;

  const CollectionHistoryResult({
    this.items = const [],
    this.summary = const CollectionSummaryModel(),
  });
}

class CollectionHistoryRepository {
  final ApiClient _apiClient;
  final CollectorLocalStorage _collectorLocalStorage;

  CollectionHistoryRepository({
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

  Future<String> getCollectorId() async {
    try {
      final id = await _collectorLocalStorage.getCollectorId();
      if (id.trim().isNotEmpty) {
        return id.trim();
      }
    } catch (_) {}
    return '';
  }

  Future<CollectionHistoryResult> fetchHistory({
    String? collectorId,
    String? dateFrom,
    String? dateTo,
    String? wasteType,
    String? paymentStatus,
    bool simulateTimeout = false,
  }) async {
    String resolvedCollectorId = collectorId?.trim() ?? '';
    if (resolvedCollectorId.isEmpty) {
      resolvedCollectorId = await getCollectorId();
    }

    final now = DateTime.now();
    final defaultDateTo = DateFormat('yyyy-MM-dd').format(
      now.add(const Duration(days: 1)),
    );

    final defaultDateFrom =
        DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month - 1, 1));

    final effectiveDateFrom = dateFrom?.trim().isNotEmpty == true
        ? dateFrom!.trim()
        : defaultDateFrom;
    final effectiveDateTo =
        dateTo?.trim().isNotEmpty == true ? dateTo!.trim() : defaultDateTo;

    final queryParameters = <String, dynamic>{
      'collector_id': resolvedCollectorId,
      'date_from': effectiveDateFrom,
      'date_to': defaultDateTo,
    };

    if (wasteType != null &&
        wasteType.trim().isNotEmpty &&
        wasteType.toLowerCase() != 'all') {
      queryParameters['waste_type'] = wasteType.trim();
    }

    if (paymentStatus != null &&
        paymentStatus.trim().isNotEmpty &&
        paymentStatus.toLowerCase() != 'all') {
      queryParameters['payment_status'] = paymentStatus.trim();
    }

    final requestUri =
        '${APIEndPoints.collectorHistory}?${Uri(queryParameters: queryParameters).query}';

    if (simulateTimeout) {
      throw formatTimeoutException(requestUri);
    }

    try {
      final response = await _apiClient.get(
        APIEndPoints.collectorHistory,
        queryParameters: queryParameters,
      );
      try {
        const encoder = JsonEncoder.withIndent('  ');
        final formattedJson = encoder.convert(response.data);
        print(formattedJson);
      } catch (_) {}

      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final historyList = data['history'] as List? ?? [];
        final items = historyList
            .map((item) => CollectionItemModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
        final summary = data['summary'] != null
            ? CollectionSummaryModel.fromJson(
                Map<String, dynamic>.from(data['summary'] as Map))
            : CollectionSummaryModel(
                totalStops: items.length,
                totalWeight: items.fold(0.0, (sum, i) => sum + i.weight),
                totalAmount: items.fold(0.0, (sum, i) => sum + i.amount),
              );

        return CollectionHistoryResult(items: items, summary: summary);
      }

      return const CollectionHistoryResult();
    } on DioException catch (e) {
      // Check for timeout or connection errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        throw formatTimeoutException(requestUri);
      }
      return const CollectionHistoryResult();
    } catch (e) {
      if (e is SocketException) {
        throw formatTimeoutException(requestUri);
      }
      return const CollectionHistoryResult();
    }
  }

  static String formatTimeoutException(String requestUri) {
    return 'ClientException with SocketConnection timed out (OS Error: Connection timed out, errno = 110), address = florettech.pythonanywhere.com, port = 52088, uri=$requestUri';
  }
}
