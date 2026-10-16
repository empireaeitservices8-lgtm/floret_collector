import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floret_collector/core/storage/collection_metrics_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CollectionMetricsStorage().clearTodayMetrics();
  });

  test('CollectionMetricsStorage accumulates weight and amount from multiple pickups', () async {
    final storage = CollectionMetricsStorage();

    expect(storage.todayWeight, 0.0);
    expect(storage.todayAmount, 0.0);
    expect(storage.formattedWeight, '0.0 kg');
    expect(storage.formattedAmount, '₹0');

    // Pickup 1: 2kg and 40 Rs
    await storage.recordCollection(
      pickupId: 1,
      weight: 2.0,
      amount: 40.0,
    );

    expect(storage.todayWeight, 2.0);
    expect(storage.todayAmount, 40.0);
    expect(storage.formattedWeight, '2 kg');
    expect(storage.formattedAmount, '₹40');

    // Pickup 2: 2kg and 45 Rs
    await storage.recordCollection(
      pickupId: 2,
      weight: 2.0,
      amount: 45.0,
    );

    expect(storage.todayWeight, 4.0);
    expect(storage.todayAmount, 85.0);
    expect(storage.formattedWeight, '4 kg');
    expect(storage.formattedAmount, '₹85');
  });

  test('CollectionMetricsStorage updates existing pickup instead of duplicating', () async {
    final storage = CollectionMetricsStorage();

    await storage.recordCollection(pickupId: 1, weight: 2.0, amount: 40.0);
    expect(storage.todayWeight, 2.0);
    expect(storage.todayAmount, 40.0);

    // Re-record with updated weight
    await storage.recordCollection(pickupId: 1, weight: 3.0, amount: 60.0);
    expect(storage.todayWeight, 3.0);
    expect(storage.todayAmount, 60.0);
    expect(storage.formattedWeight, '3 kg');
    expect(storage.formattedAmount, '₹60');
  });
}
