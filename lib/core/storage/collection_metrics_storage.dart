import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists daily collection metrics (weight & payment amount)
/// for completed pickups.
class CollectionMetricsStorage extends ChangeNotifier {
  static final CollectionMetricsStorage _instance =
      CollectionMetricsStorage._internal();

  factory CollectionMetricsStorage() => _instance;

  CollectionMetricsStorage._internal();

  double _todayWeight = 0.0;
  double _todayAmount = 0.0;
  int _todayPickupsCount = 0;
  bool _isLoaded = false;

  double get todayWeight => _todayWeight;
  double get todayAmount => _todayAmount;
  int get todayPickupsCount => _todayPickupsCount;
  bool get isLoaded => _isLoaded;

  String _getTodayKey() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'today_collections_$todayStr';
  }

  String get formattedWeight {
    if (_todayWeight <= 0) return '0.0 kg';
    if (_todayWeight == _todayWeight.roundToDouble()) {
      return '${_todayWeight.toInt()} kg';
    }
    return '${_todayWeight.toStringAsFixed(1)} kg';
  }

  String get formattedAmount {
    if (_todayAmount <= 0) return '₹0';
    if (_todayAmount == _todayAmount.roundToDouble()) {
      return '₹${_todayAmount.toInt()}';
    }
    return '₹${_todayAmount.toStringAsFixed(2)}';
  }

  /// Loads today's aggregated metrics from persistent storage.
  Future<void> loadTodayMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getTodayKey();
      final rawData = prefs.getString(key);

      double weightSum = 0.0;
      double amountSum = 0.0;
      int count = 0;

      if (rawData != null && rawData.isNotEmpty) {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) {
          decoded.forEach((_, val) {
            if (val is Map) {
              final w = (val['weight'] as num?)?.toDouble() ?? 0.0;
              final a = (val['amount'] as num?)?.toDouble() ?? 0.0;
              weightSum += w;
              amountSum += a;
              count++;
            }
          });
        }
      }

      _todayWeight = weightSum;
      _todayAmount = amountSum;
      _todayPickupsCount = count;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[CollectionMetricsStorage] Error loading metrics: $e');
    }
  }

  /// Records a completed pickup collection with its weight and payment amount.
  Future<void> recordCollection({
    required int pickupId,
    required double weight,
    required double amount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getTodayKey();
      final rawData = prefs.getString(key);

      Map<String, dynamic> todayMap = {};
      if (rawData != null && rawData.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawData);
          if (decoded is Map) {
            todayMap = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }

      final pickupKey = pickupId > 0
          ? '$pickupId'
          : 'pickup_${DateTime.now().millisecondsSinceEpoch}';

      todayMap[pickupKey] = {
        'pickup_id': pickupId,
        'weight': weight,
        'amount': amount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(key, jsonEncode(todayMap));

      // Recalculate totals
      double weightSum = 0.0;
      double amountSum = 0.0;
      int count = 0;

      todayMap.forEach((_, val) {
        if (val is Map) {
          final w = (val['weight'] as num?)?.toDouble() ?? 0.0;
          final a = (val['amount'] as num?)?.toDouble() ?? 0.0;
          weightSum += w;
          amountSum += a;
          count++;
        }
      });

      _todayWeight = weightSum;
      _todayAmount = amountSum;
      _todayPickupsCount = count;
      _isLoaded = true;

      debugPrint(
        '[CollectionMetricsStorage] Recorded pickup $pickupKey: weight=$weight, amount=$amount. New totals -> weight=$_todayWeight kg, amount=₹$_todayAmount',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('[CollectionMetricsStorage] Error recording collection: $e');
    }
  }

  /// Clears today's collection metrics (e.g. for testing or reset).
  Future<void> clearTodayMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getTodayKey());
      _todayWeight = 0.0;
      _todayAmount = 0.0;
      _todayPickupsCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
