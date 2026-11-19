import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floret_collector/features/issues_management/model/issue_model.dart';
import 'package:floret_collector/features/issues_management/viewmodel/issues_view_model.dart';
import 'package:floret_collector/features/issues_management/screen/issues_management_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issues Management Model and ViewModel Tests', () {
    test('IssueModel properties and initial calculation', () {
      const issue = IssueModel(
        id: '1',
        title: 'Dispose by themselves',
        description:
            'Collector marked warning with reason: Dispose by themselves.',
        userName: 'noel',
        phoneNumber: '5674564897',
        isResolved: false,
      );

      expect(issue.id, '1');
      expect(issue.title, 'Dispose by themselves');
      expect(issue.userName, 'noel');
      expect(issue.userInitial, 'N');
      expect(issue.phoneNumber, '5674564897');
      expect(issue.isResolved, isFalse);
      test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });

    test('IssueModel.fromJson parses API response format correctly', () {
      final jsonResolved = {
        "id": 97,
        "user_name": "Main Road",
        "user_email": "",
        "user_phone": "",
        "pickup_id": 77,
        "issue_type": "collection",
        "subject": "Dispose by themselves",
        "description": "Collector marked warning with reason: Dispose by themselves.",
        "status": "resolved",
        "priority": "medium",
        "created_at": "2026-09-10 08:52:08.400957+00:00",
        "updated_at": "2026-10-01 10:38:49.563783+00:00",
        "resolved_at": "2026-10-01 10:38:49.562809+00:00",
        "resolution_notes": "Resolved by collector."
      };

      final issueResolved = IssueModel.fromJson(jsonResolved);
      expect(issueResolved.id, '97');
      expect(issueResolved.title, 'Dispose by themselves');
      expect(issueResolved.userName, 'Main Road');
      expect(issueResolved.userInitial, 'M');
      expect(issueResolved.isResolved, isTrue);

      final jsonPending = {
        "id": 96,
        "user_name": "noel",
        "user_email": "noel@gmail.com",
        "user_phone": "5674564897",
        "pickup_id": 23,
        "issue_type": "collection",
        "subject": "Dispose by themselves",
        "description": "Collector marked warning with reason: Dispose by themselves.",
        "status": "pending",
        "priority": "medium",
        "created_at": "2026-09-10 08:51:07.850376+00:00",
        "updated_at": "2026-09-10 08:51:07.850420+00:00",
        "resolved_at": null,
        "resolution_notes": null
      };

      final issuePending = IssueModel.fromJson(jsonPending);
      expect(issuePending.id, '96');
      expect(issuePending.title, 'Dispose by themselves');
      expect(issuePending.userName, 'noel');
      expect(issuePending.phoneNumber, '5674564897');
      expect(issuePending.isResolved, isFalse);
      test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });

    test('IssuesViewModel tab switching and counts', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      expect(vm.selectedTab, IssueTab.issues);
      expect(vm.openCount, 93);
      expect(vm.resolvedCount, 4);
      expect(vm.currentTabIssues.length, 93);
      expect(vm.currentTabIssues.first.title, 'Dispose by themselves');
      expect(vm.currentTabIssues.first.userName, 'noel');

      // Switch to resolved tab
      vm.setSelectedTab(IssueTab.resolved);
      expect(vm.selectedTab, IssueTab.resolved);
      expect(vm.currentTabIssues.length, 4);
      expect(vm.currentTabIssues.every((i) => i.isResolved), isTrue);
      test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });

    test('IssuesViewModel refresh 3-second progress state', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      // Trigger refresh with 3-second delay
      final refreshFuture = vm.refresh(delaySeconds: 3);
      expect(vm.isRefreshing, isTrue);

      await refreshFuture;
      expect(vm.isRefreshing, isFalse);
      test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });
    test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });

  group('IssuesManagementScreen Widget Tests', () {
    testWidgets(
        'Renders Issues and Resolved tabs with correct badges and issue cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IssuesManagementScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.text('Issues Management'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Tabs & Badges
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('93'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      // Open issue cards in first tab (Image 1)
      expect(find.text('Dispose by themselves'), findsWidgets);
      expect(
        find.text(
            'Collector marked warning with reason: Dispose by themselves.'),
        findsWidgets,
      );
      expect(find.text('noel'), findsOneWidget);
      expect(find.text('5674564897'), findsOneWidget);
      expect(find.text('Main Road'), findsOneWidget);
      expect(find.text('nedumangadu'), findsOneWidget);
      expect(find.text('+918281971803'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('subham'), 200);
      expect(find.text('subham'), findsOneWidget);
      expect(find.text('+918921305443'), findsOneWidget);
      test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });

    testWidgets('Tapping Resolved tab displays resolved issues list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IssuesManagementScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Resolved' tab
      await tester.tap(find.text('Resolved'));
      await tester.pumpAndSettle();

      // Check resolved items (Image 2)
      expect(find.text('Dispose by themselves'), findsOneWidget);
      expect(find.text('Mixed waste'), findsOneWidget);
      expect(find.text('testing issuweee'), findsOneWidget);
      expect(find.text('testing one'), findsOneWidget);
      expect(find.text('+918281535237'), findsOneWidget);
      expect(find.text("Collector didn't arrive"), findsWidgets);
      expect(
        find.text(
            "The collector was supposed to arrive at 9AM but didn't show up."),
        findsWidgets,
      );
      expect(find.text('Jos'), findsWidgets);
      expect(find.text('+919876543210'), findsWidgets);
      test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });

    testWidgets(
        'Tapping refresh button shows CircularProgressIndicator for 3 seconds',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IssuesManagementScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify list is initially visible
      expect(find.text('noel'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap refresh button
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();

      // Tabs remain visible, and CircularProgressIndicator is shown (Image 3)
      expect(find.text('Issues Management'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('noel'), findsNothing);

      // Advance 1.5 seconds (still refreshing)
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance remaining 1.5 seconds to complete 3 seconds
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Progress indicator disappears and list is back
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('noel'), findsOneWidget);
      test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });

    testWidgets(
        'Renders issue card with long user name and phone number without overflow on narrow device',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IssuesManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });
    test('IssueModel formattedResolvedDate and formattedCreatedDate format correctly', () {
      final now = DateTime.now();
      final todayStr = now.toIso8601String();
      final issueToday = IssueModel(
        id: '1',
        title: 'Issue 1',
        description: 'Desc',
        userName: 'User',
        isResolved: true,
        resolvedAt: todayStr,
        createdAt: '2026-09-10T08:52:08.400Z',
      );

      expect(issueToday.formattedResolvedDate, startsWith('Today,'));
      expect(issueToday.formattedCreatedDate, '10 Sep 2026');
    });

    test('IssuesViewModel sorts resolved issues newest first', () async {
      final vm = IssuesViewModel();
      await vm.loadData();

      final resolved = vm.resolvedIssues;
      expect(resolved.isNotEmpty, isTrue);

      // Verify that dates or IDs are in descending order
      for (int i = 0; i < resolved.length - 1; i++) {
        final dateA = DateTime.tryParse(resolved[i].resolvedAt ?? resolved[i].createdAt ?? '');
        final dateB = DateTime.tryParse(resolved[i + 1].resolvedAt ?? resolved[i + 1].createdAt ?? '');
        if (dateA != null && dateB != null) {
          expect(dateA.isAfter(dateB) || dateA.isAtSameMomentAs(dateB), isTrue);
        }
      }
    });
  });
}
