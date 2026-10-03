import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floret_collector/features/collection_history/model/collection_history_model.dart';
import 'package:floret_collector/features/collection_history/viewmodel/collection_history_view_model.dart';
import 'package:floret_collector/features/collection_history/screen/collection_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Collection History Models and ViewModel Tests', () {
    test('CollectionItemModel parse and properties test', () {
      final item = CollectionItemModel(
        id: '1',
        stopId: '77',
        stopName: 'ne',
        wasteType: 'General Waste',
        status: 'PAID',
        weight: 0.0,
        rate: 42.0,
        amount: 16.52,
        date: '10 Sep 2026, 02:25 PM',
        paymentMethod: 'CASH',
      );

      expect(item.stopId, '77');
      expect(item.stopName, 'ne');
      expect(item.wasteType, 'General Waste');
      expect(item.status, 'PAID');
      expect(item.weight, 0.0);
      expect(item.rate, 42.0);
      expect(item.amount, 16.52);
      expect(item.paymentMethod, 'CASH');
    });

    test('CollectionHistoryViewModel initial shimmering state and 3s load',
        () async {
      final vm = CollectionHistoryViewModel();

      // Initially shimmering
      expect(vm.isShimmering, isTrue);

      // Wait 3 seconds for shimmer effect to finish
      await Future.delayed(const Duration(seconds: 3, milliseconds: 200));

      expect(vm.isShimmering, isFalse);
      expect(vm.filteredHistory.isNotEmpty, isTrue);
      expect(vm.effectiveSummary.totalStops, 348);
    });

    test('CollectionHistoryViewModel search filter test', () async {
      final vm = CollectionHistoryViewModel();
      await Future.delayed(const Duration(seconds: 3, milliseconds: 200));

      // Search by stop ID
      vm.setSearchQuery('77');
      expect(vm.filteredHistory.every((i) => i.stopId.contains('77')), isTrue);

      // Search by nonexistent term
      vm.setSearchQuery('XYZ999');
      expect(vm.filteredHistory.isEmpty, isTrue);
      expect(vm.effectiveSummary.totalStops, 0);
      expect(vm.effectiveSummary.totalAmount, 0.0);
    });

    test('CollectionHistoryViewModel waste type filter and clear test',
        () async {
      final vm = CollectionHistoryViewModel();
      await Future.delayed(const Duration(seconds: 3, milliseconds: 200));

      // Filter by Bio waste (which has 0 items in dataset)
      vm.applyFilters(const CollectionFilterModel(wasteType: 'Bio waste'));
      expect(vm.filteredHistory.isEmpty, isTrue);
      expect(vm.effectiveSummary.totalStops, 0);

      // Clear filter
      vm.clearAllFilters();
      expect(vm.filteredHistory.isNotEmpty, isTrue);
      expect(vm.effectiveSummary.totalStops, 348);
    });

    test('CollectionHistoryViewModel timeout error handling test', () async {
      final vm = CollectionHistoryViewModel();
      await vm.loadHistory(simulateTimeout: true);

      expect(vm.isTimeoutError, isTrue);
      expect(vm.errorMessage.contains('SocketConnection timed out'), isTrue);
      expect(vm.filteredHistory.isEmpty, isTrue);
      expect(vm.effectiveSummary.totalStops, 0);

      // Retry should recover
      vm.retry();
      expect(vm.isShimmering, isTrue);
      await Future.delayed(const Duration(seconds: 3, milliseconds: 200));
      expect(vm.isTimeoutError, isFalse);
      expect(vm.filteredHistory.isNotEmpty, isTrue);
    });
  });

  group('CollectionHistoryScreen Widget Tests', () {
    testWidgets(
        'Shows shimmering effect initially for 3 sec, then shows history list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CollectionHistoryScreen(),
        ),
      );

      // Header is visible
      expect(find.text('Collection History'), findsOneWidget);
      expect(find.text('Total Stops'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);

      // Shimmer should be present initially
      expect(find.byType(Shimmer), findsOneWidget);

      // Advance by 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Shimmer is gone, history list is shown
      expect(find.byType(Shimmer), findsNothing);
      expect(find.text('Stop ID: #77 • ne'), findsWidgets);
      expect(find.text('348'), findsOneWidget);
      expect(find.text('19104.0 kg'), findsOneWidget);
      expect(find.text('₹786223'), findsOneWidget);
      expect(find.text('PAID'), findsWidgets);
      expect(find.text('CASH'), findsWidgets);
    });

    testWidgets('Tapping filter button shows bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CollectionHistoryScreen(),
        ),
      );

      // Fast forward shimmer
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap filter button
      final filterBtnFinder = find.byIcon(Icons.tune_rounded);
      expect(filterBtnFinder, findsOneWidget);
      await tester.tap(filterBtnFinder);
      await tester.pumpAndSettle();

      // Verify Bottom Sheet contents (Image 3)
      expect(find.text('Filter Collection History'), findsOneWidget);
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('Select Date Range'), findsOneWidget);
      expect(find.text('Waste Type'), findsOneWidget);
      expect(find.text('Payment Status'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
    });

    testWidgets(
        'If no result show "No Collection Logs Found" with empty state and clear button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CollectionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Open filter
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select 'Bio waste'
      await tester.tap(find.text('Bio waste'));
      await tester.pumpAndSettle();

      // Tap 'Apply Filters'
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Verify Empty State (Image 4)
      expect(find.text('No Collection Logs Found'), findsOneWidget);
      expect(
        find.text(
            'Start confirming collection routes and recording pickups to view your logs here.'),
        findsOneWidget,
      );
      expect(find.text('Type: Bio waste'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0.0 kg'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Restored list
      expect(find.text('No Collection Logs Found'), findsNothing);
      expect(find.text('Stop ID: #77 • ne'), findsWidgets);
    });

    testWidgets(
        'If connection timeout occurs show "Failed to Load History" with Retry button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CollectionHistoryScreen(),
        ),
      );

      // Wait for initial shimmer to complete
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Long press refresh button triggers timeout simulation
      await tester.longPress(find.byIcon(Icons.refresh_rounded));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify Error State (Image 5)
      expect(find.text('Failed to Load History'), findsOneWidget);
      expect(
        find.textContaining('SocketConnection timed out'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0.0 kg'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);

      // Tap Retry
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Shows shimmer while retrying
      expect(find.byType(Shimmer), findsOneWidget);

      // Fast forward retry shimmer
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Recovered
      expect(find.text('Failed to Load History'), findsNothing);
      expect(find.text('Stop ID: #77 • ne'), findsWidgets);
    });
  });
}
