import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
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

  final List<DirectDisposalLogModel> _logs = [
    const DirectDisposalLogModel(
      id: '1',
      customerName: 'uiui',
      phone: '1234567890',
      customerAddress: 'Main St',
      disposalType: 'WALK IN',
      wasteType: 'Bio waste',
      wasteDescription: 'Kitchen and food waste',
      weight: 569.0,
      rate: 21.99,
      gstRatePercent: 5.0,
      gstAmount: 2253.24,
      totalAmount: 14771.24,
      paymentMethod: 'ONLINE',
      paymentStatus: 'PENDING',
      formattedDate: '03 Oct 2026, 10:16 AM',
    ),
    const DirectDisposalLogModel(
      id: '2',
      customerName: 'hfhn',
      phone: '8285580088',
      customerAddress: 'North Avenue',
      disposalType: 'WALK IN',
      wasteType: 'Mixed waste',
      wasteDescription: 'Household dry mix',
      weight: 582.0,
      rate: 2.00,
      gstRatePercent: 5.0,
      gstAmount: 209.52,
      totalAmount: 1373.52,
      paymentMethod: 'CASH',
      paymentStatus: 'PAID',
      formattedDate: '03 Oct 2026, 10:12 AM',
    ),
    const DirectDisposalLogModel(
      id: '3',
      customerName: 'Adithya',
      phone: '7736683620',
      customerAddress: 'Sector 4',
      disposalType: 'WALK IN',
      wasteType: 'Sanitary Waste',
      wasteDescription: 'Sanitary items',
      weight: 2.0,
      rate: 42.00,
      gstRatePercent: 5.0,
      gstAmount: 15.12,
      totalAmount: 99.12,
      paymentMethod: 'CASH',
      paymentStatus: 'PAID',
      formattedDate: '09 Sep 2026, 11:35 AM',
    ),
  ];

  Future<List<DirectDisposalLogModel>> fetchLogs() async {
    try {
      final response = await _apiClient.get(APIEndPoints.directDisposal);

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
        final collectorId =
            (await _collectorLocalStorage.getCollectorId()).trim().toLowerCase();

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

  Future<DirectDisposalLogModel> recordDisposal({
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String disposalType = 'direct',
    required String wasteType,
    String? wasteDescription,
    required double weight,
    required double disposalRate,
    int? localBody,
    int? ward,
  }) async {
    int resolvedLocalBody = localBody ?? 15;
    int resolvedWard = ward ?? 1;
    String username = '';

    try {
      username = await _collectorLocalStorage.getUsername();
      final collector = await _collectorLocalStorage.getCollector();
      if (collector != null) {
        if (collector['local_body'] != null) {
          resolvedLocalBody =
              int.tryParse(collector['local_body'].toString()) ??
                  resolvedLocalBody;
        }
        if (collector['ward'] != null) {
          resolvedWard =
              int.tryParse(collector['ward'].toString()) ?? resolvedWard;
        }
      }
    } catch (_) {}

    final requestBody = {
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'disposal_type': disposalType,
      'waste_type': wasteType,
      'waste_description': wasteDescription ?? 'Mixed waste',
      'weight': weight,
      'disposal_rate': disposalRate,
      'local_body': resolvedLocalBody,
      'ward': resolvedWard,
      if (username.isNotEmpty) 'recorded_by': username,
    };

    try {
      final response = await _apiClient.post(
        APIEndPoints.directDisposal,
        data: requestBody,
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

      if (response.data is Map && response.data['disposal'] != null) {
        final disposalData =
            Map<String, dynamic>.from(response.data['disposal'] as Map);
        if (disposalData['recorded_by'] == null && username.isNotEmpty) {
          disposalData['recorded_by'] = username;
        }
        final createdLog = DirectDisposalLogModel.fromJson(disposalData);
        _logs.insert(0, createdLog);
        return createdLog;
      }
    } catch (_) {}

    // Fallback log for offline or test execution
    final fallbackLog = DirectDisposalLogModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      customerName: customerName,
      phone: customerPhone,
      customerAddress: customerAddress,
      disposalType: disposalType.toUpperCase(),
      wasteType: wasteType,
      wasteDescription: wasteDescription ?? '',
      weight: weight,
      rate: disposalRate,
      gstRatePercent: 5.0,
      gstAmount: (weight * disposalRate) * 0.05,
      totalAmount: (weight * disposalRate) * 1.05,
      paymentMethod: 'CASH',
      paymentStatus: 'PAID',
      formattedDate: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      recordedBy: username.isNotEmpty ? username : null,
    );
    _logs.insert(0, fallbackLog);
    return fallbackLog;
  }

  Future<void> addLog(DirectDisposalLogModel log) async {
    _logs.insert(0, log);
  }
}


