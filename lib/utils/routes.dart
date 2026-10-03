import 'package:floret_collector/features/splash/screen/splash_screen.dart';
import 'package:floret_collector/features/login/screen/login_screen.dart';
import 'package:floret_collector/features/main/screen/main_screen.dart';
import 'package:floret_collector/features/home/screen/home_screen.dart';
import 'package:floret_collector/features/schedule/screen/schedule_screen.dart';
import 'package:floret_collector/features/notification/screen/notification_screen.dart';
import 'package:floret_collector/features/menu/screen/menu_screen.dart';
import 'package:floret_collector/features/billing_history/screen/billing_history_screen.dart';
import 'package:floret_collector/features/collection_history/screen/collection_history_screen.dart';
import 'package:floret_collector/features/issues_management/screen/issues_management_screen.dart';
import 'package:floret_collector/features/direct_disposal/screen/direct_disposal_screen.dart';
import 'package:floret_collector/features/help_support/screen/help_support_screen.dart';
import 'package:floret_collector/utils/connection_failed_screen.dart';
import 'package:flutter/material.dart';

Map<String, Widget Function(BuildContext context)> appRoutes() => {
      SplashScreen.routeName: (context) => const SplashScreen(),
      LoginScreen.routeName: (context) => const LoginScreen(),
      MainScreen.routeName: (context) => const MainScreen(),
      HomeScreen.routeName: (context) => const HomeScreen(),
      ScheduleScreen.routeName: (context) => const ScheduleScreen(),
      NotificationScreen.routeName: (context) => const NotificationScreen(),
      MenuScreen.routeName: (context) => const MenuScreen(),
      BillingHistoryScreen.routeName: (context) => const BillingHistoryScreen(),
      CollectionHistoryScreen.routeName: (context) =>
          const CollectionHistoryScreen(),
      IssuesManagementScreen.routeName: (context) =>
          const IssuesManagementScreen(),
      DirectDisposalScreen.routeName: (context) =>
          const DirectDisposalScreen(),
      HelpSupportScreen.routeName: (context) =>
          const HelpSupportScreen(),
    };

Widget? _getScreen(RouteSettings settings) {
  switch (settings.name) {
    case ConnectionFailedScreen.routeName:
      ConnectionFailedScreenParams params =
          settings.arguments as ConnectionFailedScreenParams;
      return ConnectionFailedScreen(
        param: params,
      );
    // case OwnerManageUserScreen.route:
    //   OwnerManageUserScreenParams params =
    //       settings.arguments as OwnerManageUserScreenParams;
    //   return OwnerManageUserScreen(
    //     params: params,
    //   );

    default:
      return null;
  }
}

RouteFactory onAppGenerateRoute() => (settings) {
      Widget? screen = _getScreen(settings);
      if (screen != null) {
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => screen,
          transitionsBuilder: (_, a, __, c) {
            return FadeTransition(opacity: a, child: c);
          },
        );
      }
      return null;
    };
