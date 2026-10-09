import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:floret_collector/config/app_config.dart';
import 'package:floret_collector/features/login/screen/login_screen.dart';
import 'package:floret_collector/features/login/viewmodel/login_view_model.dart';
import 'package:floret_collector/features/splash/screen/splash_screen.dart';
import 'package:floret_collector/features/main/screen/main_screen.dart';
import 'package:floret_collector/features/home/screen/home_screen.dart';
import 'package:floret_collector/features/schedule/screen/schedule_screen.dart';
import 'package:floret_collector/features/notification/screen/notification_screen.dart';
import 'package:floret_collector/features/menu/screen/menu_screen.dart';
import 'package:floret_collector/features/billing_history/screen/billing_history_screen.dart';
import 'package:floret_collector/features/billing_history/viewmodel/billing_history_view_model.dart';
import 'package:floret_collector/utils/routes.dart';

void main() {
  test('App configuration test', () {
    expect(AppConfig.appName, 'floret_collector');
    expect(AppConfig.bundleId, 'com.floret_collector');
    expect(AppConfig.designWidth, 390.0);
    expect(AppConfig.designHeight, 844.0);
  });

  test('LoginViewModel validation and state test', () {
    final vm = LoginViewModel(repository: null);
    expect(vm.isFormValid, isFalse);
    expect(vm.isPasswordVisible, isFalse);

    vm.togglePasswordVisibility();
    expect(vm.isPasswordVisible, isTrue);

    vm.onUsernameChanged('test_user');
    expect(vm.isFormValid, isFalse);

    vm.onPasswordChanged('password123');
    expect(vm.isFormValid, isTrue);
  });

  testWidgets('LoginScreen renders all UI elements accurately',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('Powered by Floret Technologies'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(
      find.text('Login to manage your waste sustainably'),
      findsOneWidget,
    );
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('SplashScreen renders progress and logo',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          LoginScreen.routeName: (context) =>
              const Scaffold(body: Text('Login')),
        },
        home: const SplashScreen(),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'MainScreen renders shimmer for 3s, then shows Hi, shyam! and right arrow navigates to schedule',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'saved_username': 'shyam'});

    await tester.pumpWidget(
      MaterialApp(
        routes: appRoutes(),
        home: const MainScreen(),
      ),
    );

    // Verify 4 bottom navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Notification'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);

    // Initial tab is Home and in shimmer loading state
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hi, shyam!'), findsNothing);

    // Advance 3 seconds for shimmer effect to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // After 3 seconds, dynamic username and content appear
    expect(find.text('Hi, shyam!'), findsOneWidget);
    expect(find.text('Remaining Covers'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Collected'), findsOneWidget);
    expect(find.text("Today's collection schedule"), findsOneWidget);

    // Tap on right arrow button on Home page -> should navigate to schedule
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();
    expect(find.byType(ScheduleScreen), findsOneWidget);
    expect(find.text('Collection schedule'), findsOneWidget);
    expect(find.text('View your pickups'), findsOneWidget);

    // Switch to Notification tab
    await tester.tap(find.text('Notification'));
    await tester.pump();
    expect(find.byType(NotificationScreen), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);

    // Initial list is displayed
    expect(find.text('Issue Report: Dispose by themselves'), findsWidgets);

    // Tap on refresh icon in notification screen
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();

    // Verify circular progress indicator is shown and list is hidden during refresh
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Issue Report: Dispose by themselves'), findsNothing);

    // Advance 3 seconds
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Verify progress indicator is gone and list items are displayed again
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Issue Report: Dispose by themselves'), findsWidgets);

    // Switch to Menu tab
    await tester.tap(find.text('Menu'));
    await tester.pump();
    expect(find.byType(MenuScreen), findsOneWidget);
    expect(find.text('Menu & Profile'), findsOneWidget);
    expect(find.text('Log out Account'), findsOneWidget);

    // Scroll to and tap on eye icon to view Verified Aadhaar Card dialog
    await tester.ensureVisible(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    // Verify Aadhaar card modal dialog content matches screenshot
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Verified Aadhaar Card'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Aadhaar No: Verified On File'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);

    // Tap close button on dialog
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Verify dialog is closed
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Verified Aadhaar Card'), findsNothing);

    // Scroll down to and tap on Billing & History menu item
    await tester.ensureVisible(find.text('Billing & History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Billing & History'));
    await tester.pumpAndSettle();

    // Verify BillingHistoryScreen is opened
    expect(find.byType(BillingHistoryScreen), findsOneWidget);
    expect(find.text('Billing History'), findsOneWidget);
    expect(find.text('Method: All'), findsOneWidget);
    expect(find.text('Status: All'), findsOneWidget);
    expect(find.text('Bill #234'), findsOneWidget);
    expect(find.text('Bill #233'), findsOneWidget);
    expect(find.text('Bill #232'), findsOneWidget);

    // Tap back button to return to MenuScreen
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(BillingHistoryScreen), findsNothing);
    expect(find.byType(MenuScreen), findsOneWidget);
  });

  test('BillingHistoryViewModel filtering and options test', () async {
    final vm = BillingHistoryViewModel();
    expect(vm.methodOptions, ['All', 'Cash', 'Online']);
    expect(vm.statusOptions, ['All', 'Paid', 'Pending']);

    await vm.loadBills();
    expect(vm.filteredBills.isNotEmpty, isTrue);

    // Filter by Online
    vm.setSelectedMethod('Online');
    expect(
      vm.filteredBills.every((b) => b.method.toLowerCase() == 'online'),
      isTrue,
    );

    // Filter by Cash
    vm.setSelectedMethod('Cash');
    expect(
      vm.filteredBills.every((b) => b.method.toLowerCase() == 'cash'),
      isTrue,
    );

    // Filter by Online + Pending (empty state in screenshot 3)
    vm.setSelectedMethod('Online');
    vm.setSelectedStatus('Pending');
    expect(vm.filteredBills.isEmpty, isTrue);

    // Reset filters and test search
    vm.setSelectedMethod('All');
    vm.setSelectedStatus('All');
    vm.setSearchQuery('234');
    expect(vm.filteredBills.length, 1);
    expect(vm.filteredBills.first.id, '234');
  });

  testWidgets(
      'BillingHistoryScreen dropdown popup opens and displays prefixed options with selection highlight',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BillingHistoryScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial dropdown buttons
    expect(find.text('Method: All'), findsOneWidget);
    expect(find.text('Status: All'), findsOneWidget);

    // Tap on Method dropdown
    await tester.tap(find.text('Method: All'));
    await tester.pumpAndSettle();

    // Verify popup menu options appear with "Method: " prefix
    expect(find.text('Method: All'), findsNWidgets(2)); // button + menu item
    expect(find.text('Method: Cash'), findsOneWidget);
    expect(find.text('Method: Online'), findsOneWidget);

    // Select "Method: Cash"
    await tester.tap(find.text('Method: Cash'));
    await tester.pumpAndSettle();

    // Now button displays "Method: Cash"
    expect(find.text('Method: Cash'), findsOneWidget);

    // Tap on Status dropdown
    await tester.tap(find.text('Status: All'));
    await tester.pumpAndSettle();

    // Verify popup menu options appear with "Status: " prefix
    expect(find.text('Status: All'), findsNWidgets(2)); // button + menu item
    expect(find.text('Status: Paid'), findsOneWidget);
    expect(find.text('Status: Pending'), findsOneWidget);

    // Select "Status: Paid"
    await tester.tap(find.text('Status: Paid'));
    await tester.pumpAndSettle();

    // Now button displays "Status: Paid"
    expect(find.text('Status: Paid'), findsOneWidget);
  });
}
