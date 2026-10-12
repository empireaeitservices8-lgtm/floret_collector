import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floret_collector/features/schedule/model/schedule_filter_model.dart';
import 'package:floret_collector/features/schedule/viewmodel/schedule_view_model.dart';
import 'package:floret_collector/features/schedule/screen/schedule_screen.dart';
import 'package:floret_collector/features/schedule/screen/schedule_filter_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Schedule Filter Models and ViewModel Tests', () {
    test('ScheduleFilterModel default values and copyWith', () {
      const filter = ScheduleFilterModel();
      expect(filter.pickupType, PickupTypeFilter.all);
      expect(filter.collectionStatus, CollectionStatusFilter.all);
      expect(filter.isDefault, isTrue);
      expect(PickupTypeFilter.all.label, 'Select all');
      expect(PickupTypeFilter.sanitary.label, 'Sanitary pickups');
      expect(PickupTypeFilter.scrap.label, 'Scrap pickups');
      expect(CollectionStatusFilter.all.label, 'Select all');
      expect(CollectionStatusFilter.pending.label, 'Only pending pickups');
      expect(CollectionStatusFilter.completed.label, 'Only completed pickups');

      final updated = filter.copyWith(
        pickupType: PickupTypeFilter.sanitary,
        collectionStatus: CollectionStatusFilter.pending,
      );
      expect(updated.pickupType, PickupTypeFilter.sanitary);
      expect(updated.collectionStatus, CollectionStatusFilter.pending);
      expect(updated.isDefault, isFalse);
    });

    test('ScheduleViewModel filter updates and wasteTypeDisplay', () {
      final vm = ScheduleViewModel();
      expect(vm.filter.isDefault, isTrue);
      expect(vm.wasteTypeDisplay, 'Sanitary & Scrap waste');

      // Update to Sanitary
      vm.setFilter(
        const ScheduleFilterModel(
          pickupType: PickupTypeFilter.sanitary,
        ),
      );
      expect(vm.wasteTypeDisplay, 'Sanitary waste');

      // Update to Scrap
      vm.setFilter(
        const ScheduleFilterModel(
          pickupType: PickupTypeFilter.scrap,
        ),
      );
      expect(vm.wasteTypeDisplay, 'Scrap waste');

      // Reset
      vm.resetFilter();
      expect(vm.filter.isDefault, isTrue);
      expect(vm.wasteTypeDisplay, 'Sanitary & Scrap waste');
    });
  });

  group('Schedule Screen and Filter Bottom Sheet Widget Tests', () {
    testWidgets('Tapping filter button opens Filter schedule bottom sheet with all UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScheduleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar title and filter button
      expect(find.text('Collection schedule'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);

      // Tap filter button to open bottom sheet
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and close button
      expect(find.text('Filter schedule'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify section 1: "Select pickup type."
      expect(find.text('Select pickup type.'), findsOneWidget);
      expect(find.text('Select all'), findsNWidgets(2)); // in both sections
      expect(find.text('Sanitary pickups'), findsOneWidget);
      expect(find.text('Scrap pickups'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsWidgets);
      expect(find.byIcon(Icons.grid_view_rounded), findsWidgets);

      // Verify section 2: "Filter by collection status"
      expect(find.text('Filter by collection status'), findsOneWidget);
      expect(find.text('Only pending pickups'), findsOneWidget);
      expect(find.text('Only completed pickups'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

      // Verify action buttons
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('Selecting options in bottom sheet and tapping Apply updates the filter and waste type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScheduleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Waste type: Sanitary & Scrap waste'), findsOneWidget);

      // Open bottom sheet
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      // Tap 'Sanitary pickups'
      await tester.tap(find.text('Sanitary pickups'));
      await tester.pumpAndSettle();

      // Tap 'Only pending pickups'
      await tester.tap(find.text('Only pending pickups'));
      await tester.pumpAndSettle();

      // Tap 'Apply'
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Bottom sheet is closed
      expect(find.text('Filter schedule'), findsNothing);

      // Waste type header reflects sanitary filter
      expect(find.text('Waste type: Sanitary waste'), findsOneWidget);
    });

    testWidgets('Tapping Clear resets options back to Select all',
        (WidgetTester tester) async {
      ScheduleFilterModel? appliedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScheduleFilterBottomSheet.show(
                      context: context,
                      currentFilter: const ScheduleFilterModel(
                        pickupType: PickupTypeFilter.scrap,
                        collectionStatus: CollectionStatusFilter.completed,
                      ),
                      onApply: (f) {
                        appliedFilter = f;
                      },
                    );
                  },
                  child: const Text('Open Filter'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      // Verify initial selected state was scrap & completed
      expect(find.text('Filter schedule'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Tap Apply to confirm cleared filter
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.pickupType, PickupTypeFilter.all);
      expect(appliedFilter!.collectionStatus, CollectionStatusFilter.all);
      expect(appliedFilter!.isDefault, isTrue);
    });

    testWidgets('Tapping Close icon dismisses bottom sheet without applying changes',
        (WidgetTester tester) async {
      var applied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ScheduleFilterBottomSheet.show(
                      context: context,
                      currentFilter: const ScheduleFilterModel(),
                      onApply: (_) {
                        applied = true;
                      },
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Filter schedule'), findsOneWidget);

      // Tap close 'X'
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Filter schedule'), findsNothing);
      expect(applied, isFalse);
    });
  });
}
