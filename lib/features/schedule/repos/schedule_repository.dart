import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/features/home/model/location_pickup_model.dart';
import 'package:floret_collector/features/home/model/pickup_dates_model.dart';
import 'package:floret_collector/features/home/model/pickup_slot_model.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../model/schedule_model.dart';

class ScheduleRepository {
  final ApiClient _apiClient;
  final CollectorLocalStorage _collectorLocalStorage;

  ScheduleRepository({
    ApiClient? apiClient,
    CollectorLocalStorage? collectorLocalStorage,
  })  : _apiClient = apiClient ??
            (getIt.isRegistered<ApiClient>() ? getIt<ApiClient>() : ApiClient()),
        _collectorLocalStorage = collectorLocalStorage ??
            (getIt.isRegistered<CollectorLocalStorage>()
                ? getIt<CollectorLocalStorage>()
                : CollectorLocalStorage());

  static String getTodayFormatted([DateTime? date]) {
    final d = date ?? DateTime.now();
    return formatFullDate(d);
  }

  static String formatFullDate(DateTime d) {
    final day = d.day;
    String suffix = 'th';
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
          break;
      }
    }
    final weekDay = DateFormat('EEE').format(d);
    final month = DateFormat('MMM').format(d);
    return '$weekDay, $day$suffix $month';
  }

  /// Format date string "YYYY-MM-DD" to "Tue, 13th Oct"
  static String formatDateString(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final dt = DateTime(year, month, day);
        return formatFullDate(dt);
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  /// Fetch collector pickup dates from API
  Future<List<String>> fetchCollectorPickupDates() async {
    try {
      final collectorId = await _collectorLocalStorage.getCollectorId();
      final endpoint = APIEndPoints.collectorPickupDates(collectorId);
      final response = await _apiClient.get(endpoint);
      debugPrint('GET collector-pickup-dates response: ${response.statusCode}');
      if (response.data is Map) {
        final parsed = CollectorPickupDatesModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        return parsed.pickupDates;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching collector pickup dates: $e');
      return [];
    }
  }

  /// Fetch all locations / pickups
  Future<List<LocationPickupModel>> fetchLocations() async {
    try {
      final response = await _apiClient.get(APIEndPoints.locations);
      debugPrint('Schedule: GET locations response: ${response.statusCode}');
      if (response.data is List) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((item) => LocationPickupModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching locations in schedule: $e');
      return [];
    }
  }

  Future<ScheduleModel> fetchSchedule({DateTime? date}) async {
    final todayText = getTodayFormatted(date);
    try {
      final response = await _apiClient.get(APIEndPoints.pickupSlots);
      if (response.data is Map) {
        final parsed = PickupSlotsResponseModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        final slots = parsed.slots;
        final now = date ?? DateTime.now();
        final todaySlots = slots.where((s) =>
            s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day).toList();

        final totalToday = todaySlots.length;
        final totalAll = slots.length;

        return ScheduleModel(
          dateText: todayText,
          progressText: totalToday > 0
              ? '0 of $totalToday completed'
              : '0 of $totalAll completed',
          sanitaryPickups:
              totalToday > 0 ? '$totalToday/$totalToday' : '0/$totalAll',
          scrapPickups: '0/0',
          wasteType: 'Sanitary & Scrap waste',
          progressPercent: 0.0,
          pickups: slots,
        );
      }
      return ScheduleModel(
        dateText: todayText,
      );
    } catch (_) {
      return ScheduleModel(
        dateText: todayText,
      );
    }
  }
}
