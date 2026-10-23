import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floret_collector/core/di/injection.dart';
import 'package:floret_collector/features/collection_history/model/collection_history_model.dart';
import 'package:floret_collector/features/collection_history/repos/collection_history_repository.dart';
import 'package:floret_collector/features/collection_history/viewmodel/collection_history_view_model.dart';
import 'package:floret_collector/features/collection_history/screen/collection_history_screen.dart';

class FakeCollectionHistoryRepository extends CollectionHistoryRepository {
  final List<CollectionItemModel> mockItems;
  final CollectionSummaryModel mockSummary;

  FakeCollectionHistoryRepository({
    this.mockItems = const [],
    this.mockSummary = const CollectionSummaryModel(),
  });

  @override
  Future<CollectionHistoryResult> fetchHistory({
    String? collectorId,
    String? dateFrom,
    String? dateTo,
    String? wasteType,
    String? paymentStatus,
    bool simulateTimeout = false,
  }) async {
    if (simulateTimeout) {
      throw CollectionHistoryRepository.formatTimeoutException('test_uri');
    }
    return CollectionHistoryResult(
      items: mockItems,
      summary: mockSummary,
    );
  }
}

final sampleTestItems = [
  CollectionItemModel(
    id: '234',
    stopId: '77',
    stopName: 'ne',
    wasteType: 'General Waste',
    status: 'PAID',
    weight: 10.0,
    rate: 42.0,
    amount: 420.0,
    date: '10 Sep 2026, 02:25 PM',
    dateTime: DateTime(2026, 9, 10, 14, 25),
    paymentMethod: 'CASH',
  ),
  CollectionItemModel(
    id: '231',
    stopId: '42',
    stopName: 'ne',
    wasteType: 'Hazardous',
    status: 'PENDING',
    weight: 15.0,
    rate: 80.0,
    amount: 1200.0,
    date: '09 Sep 2026, 04:10 PM',
    dateTime: DateTime(2026, 9, 9, 16, 10),
    paymentMethod: 'ONLINE',
  ),
];

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

    test('CollectionSummaryModel parses empty api response correctly', () {
      final summary = CollectionSummaryModel.fromJson({
        "total_collections": 0,
        "total_weight_collected": "0",
        "total_earnings": "0",
      });

      expect(summary.totalStops, 0);
      expect(summary.totalWeight, 0.0);
      expect(summary.totalAmount, 0.0);
      expect(summary.formattedWeight, '0.0 kg');
      expect(summary.formattedAmount, '₹0');
    });

    test('When api returns empty history, no mock is shown and summary is 0',
        () async {
      final emptyRepo = FakeCollectionHistoryRepository(
        mockItems: [],
        mockSummary: const CollectionSummaryModel(
          totalStops: 0,
          totalWeight: 0.0,
          totalAmount: 0.0,
        ),
      );
      final vm = CollectionHistoryViewModel(repository: emptyRepo);

      expect(vm.isShimmering, isTrue);
      await Future.delayed(const Duration(seconds: 3, milliseconds: 200));

      expect(vm.isShimmering, isFalse);
      expect(vm.filteredHistory.isEmpty, isTrue);
      expect(vm.effectiveSummary.totalStops, 0);
      expect(vm.effectiveSummary.totalWeight, 0.0);
      expect(vm.effectiveSummary.totalAmount, 0.0);
    });

    test('CollectionHistoryViewModel search filter test with items', () async {
      final repo = FakeCollectionHistoryRepository(
        mockItems: sampleTestItems,
        mockSummary: const CollectionSummaryModel(
          totalStops: 2,
          totalWeight: 25.0,
          totalAmount: 1620.0,
        ),
      );
      final vm = CollectionHistoryViewModel(repository: repo);
      await Future.delayed(const Duration(seconds: 3, milliseconds: 200));

      expect(vm.filteredHistory.length, 2);

      // Search by stop ID
      vm.setSearchQuery('77');
      expect(vm.filteredHistory.length, 1);
      expect(vm.filteredHistory.first.stopId, '77');

      // Search by nonexistent term
      vm.setSearchQuery('XYZ999');
      expect(vm.filteredHistory.isEmpty, isTrue);
      expect(vm.effectiveSummary.totalStops, 0);
      expect(vm.effectiveSummary.totalAmount, 0.0);
    });

    test('CollectionHistoryViewModel waste type filter and clear test',
        () async {
      final repo = FakeCollectionHistoryRepository(
        mockItems: sampleTestItems,
        mockSummary: const CollectionSummaryModel(
          totalStops: 2,
          totalWeight: 25.0,
          totalAmount: 1620.0,
        ),
      );
      final vm = CollectionHistoryViewModel(repository: repo);
      await Future.delayed(const Duration(seconds: 3, milliseconds: 200));

      // Filter by Bio waste (which has 0 items in dataset)
      vm.applyFilters(const CollectionFilterModel(wasteType: 'Bio waste'));
      expect(vm.filteredHistory.isEmpty, isTrue);
      expect(vm.effectiveSummary.totalStops, 0);

      // Clear filter
      vm.clearAllFilters();
      expect(vm.filteredHistory.isNotEmpty, isTrue);
      expect(vm.filteredHistory.length, 2);
    });

    test('CollectionHistoryViewModel timeout error handling test', () async {
      final repo = FakeCollectionHistoryRepository(
        mockItems: sampleTestItems,
      );
      final vm = CollectionHistoryViewModel(repository: repo);
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
        'Shows shimmering effect initially for 3 sec, then shows empty state "No History Found" when api returns empty',
        (WidgetTester tester) async {
      final emptyRepo = FakeCollectionHistoryRepository(
        mockItems: [],
        mockSummary: const CollectionSummaryModel(),
      );
      if (getIt.isRegistered<CollectionHistoryViewModel>()) {
        getIt.unregister<CollectionHistoryViewModel>();
      }
      getIt.registerFactory<CollectionHistoryViewModel>(
        () => CollectionHistoryViewModel(repository: emptyRepo),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CollectionHistoryScreen(),
        ),
      );

      // Header is visible
      expect(find.text('Collection History'), findsOneWidget);
      expect(find.text('Total Pickups'), findsOneWidget);
      expect(find.text('Total Weight'), findsOneWidget);
      expect(find.text('Total Amount'), findsOneWidget);

      // Shimmer should be present initially
      expect(find.byType(Shimmer), findsOneWidget);

      // Advance by 3 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Shimmer is gone, "No History Found" is shown instead of mock data
      expect(find.byType(Shimmer), findsNothing);
      expect(find.text('No History Found'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0.0 kg'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('348'), findsNothing);
    });

    testWidgets('Tapping filter button shows bottom sheet',
        (WidgetTester tester) async {
      final emptyRepo = FakeCollectionHistoryRepository(
        mockItems: [],
      );
      if (getIt.isRegistered<CollectionHistoryViewModel>()) {
        getIt.unregister<CollectionHistoryViewModel>();
      }
      getIt.registerFactory<CollectionHistoryViewModel>(
        () => CollectionHistoryViewModel(repository: emptyRepo),
      );

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

      // Verify Bottom Sheet contents
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
        'If items exist they are shown, and applying filter with 0 match shows "No History Found"',
        (WidgetTester tester) async {
      final repo = FakeCollectionHistoryRepository(
        mockItems: sampleTestItems,
        mockSummary: const CollectionSummaryModel(
          totalStops: 2,
          totalWeight: 25.0,
          totalAmount: 1620.0,
        ),
      );
      if (getIt.isRegistered<CollectionHistoryViewModel>()) {
        getIt.unregister<CollectionHistoryViewModel>();
      }
      getIt.registerFactory<CollectionHistoryViewModel>(
        () => CollectionHistoryViewModel(repository: repo),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CollectionHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text('Stop ID: #77 • ne'), findsOneWidget);

      // Open filter
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select 'Bio waste'
      await tester.tap(find.text('Bio waste'));
      await tester.pumpAndSettle();

      // Tap 'Apply Filters'
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Verify Empty State: "No History Found"
      expect(find.text('No History Found'), findsOneWidget);
      expect(find.text('Type: Bio waste'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0.0 kg'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);

      // Tap Clear All
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      // Restored list
      expect(find.text('No History Found'), findsNothing);
      expect(find.text('Stop ID: #77 • ne'), findsOneWidget);
    });

    testWidgets(
        'If connection timeout occurs show "Failed to Load History" with Retry button',
        (WidgetTester tester) async {
      final repo = FakeCollectionHistoryRepository(
        mockItems: sampleTestItems,
      );
      if (getIt.isRegistered<CollectionHistoryViewModel>()) {
        getIt.unregister<CollectionHistoryViewModel>();
      }
      getIt.registerFactory<CollectionHistoryViewModel>(
        () => CollectionHistoryViewModel(repository: repo),
      );

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

      // Verify Error State
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
      expect(find.text('Stop ID: #77 • ne'), findsOneWidget);
    });
  });
}
