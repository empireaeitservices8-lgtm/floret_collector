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
import 'package:floret_collector/features/collection_route/screen/collection_route_screen.dart';
import 'package:floret_collector/utils/connection_failed_screen.dart';
import 'package:floret_collector/features/collection_route/screen/confirm_and_pay_screen.dart';
import 'package:floret_collector/features/collection_route/screen/payment_receipt_screen.dart';
import 'package:floret_collector/features/collection_route/screen/mark_completed_with_warning_screen.dart';
import 'package:floret_collector/features/collection_route/screen/available_coupons_vouchers_screen.dart';
import 'package:floret_collector/features/collection_route/screen/razorpay_qr_screen.dart';
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
      CollectionRouteScreen.routeName: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return CollectionRouteScreen(
            routeNameParam: args['routeName']?.toString() ?? '',
            pickupType: args['type']?.toString() ?? '',
            address: args['address']?.toString() ?? '',
            timeSlot: args['time']?.toString() ?? '',
            latitude: (args['latitude'] as num?)?.toDouble() ??
                (args['lat'] as num?)?.toDouble(),
            longitude: (args['longitude'] as num?)?.toDouble() ??
                (args['lng'] as num?)?.toDouble(),
            pickupId: (args['pickupId'] as num?)?.toInt() ??
                (args['pickup_id'] as num?)?.toInt(),
            hasArrived: args['hasArrived'] as bool? ??
                (args['status']?.toString().toLowerCase() == 'arrived'),
          );
        }
        return const CollectionRouteScreen();
      },
      ConfirmAndPayScreen.routeName: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return ConfirmAndPayScreen(
            pickupId: (args['pickupId'] as num?)?.toInt() ?? 0,
            collectorId: (args['collectorId'] as num?)?.toInt() ?? 0,
            address: args['address']?.toString() ?? 'Main Road',
            wasteType: args['wasteType']?.toString() ?? 'Scheduled pickup',
            localBody:
                args['localBody']?.toString() ?? 'Nedumangadu Municipality',
            disposalRate: (args['disposalRate'] as num?)?.toDouble() ?? 42.00,
          );
        }
        return const ConfirmAndPayScreen();
      },
      PaymentReceiptScreen.routeName: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return PaymentReceiptScreen(
            totalAmount: (args['totalAmount'] as num?)?.toDouble() ?? 247.80,
            paymentMode: args['paymentMode']?.toString() ?? 'Cash',
            transactionId: args['transactionId']?.toString() ?? 'BILL-245',
            dateTime: args['dateTime'] as DateTime?,
            bagsCollected: (args['bagsCollected'] as num?)?.toInt() ?? 0,
            disposalWeight: (args['disposalWeight'] as num?)?.toDouble() ?? 5.0,
          );
        }
        return const PaymentReceiptScreen();
      },
      RazorpayQRScreen.routeName: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return RazorpayQRScreen(
            pickupId: (args['pickupId'] as num?)?.toInt() ?? 0,
            collectorId: (args['collectorId'] as num?)?.toInt() ?? 0,
            amount: (args['amount'] as num?)?.toDouble() ?? 0.0,
            billId: (args['billId'] as num?)?.toInt(),
            address: args['address']?.toString() ?? 'Main Road',
            userName: args['userName']?.toString() ?? '',
            userPhone: args['userPhone']?.toString() ?? '',
            wasteWeight: (args['wasteWeight'] as num?)?.toDouble() ?? 5.0,
            bagQuantity: (args['bagQuantity'] as num?)?.toInt() ?? 0,
            disposalRate: (args['disposalRate'] as num?)?.toDouble() ?? 42.0,
            redeemWallet: args['redeemWallet'] as bool? ?? false,
            applyCoupon: args['applyCoupon'] as bool? ?? false,
          );
        }
        return const RazorpayQRScreen(
          pickupId: 0,
          collectorId: 0,
          amount: 0.0,
        );
      },
      MarkCompletedWithWarningScreen.routeName: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return MarkCompletedWithWarningScreen(
            pickupId: (args['pickupId'] as num?)?.toInt() ?? 0,
            userName: args['userName']?.toString() ?? '',
            userEmail: args['userEmail']?.toString() ?? '',
            userPhone: args['userPhone']?.toString() ?? '',
            placeName: args['placeName']?.toString() ?? '',
            address: args['address']?.toString() ?? '',
          );
        }
        return const MarkCompletedWithWarningScreen(
          pickupId: 0,
          userName: '',
          userPhone: '',
          placeName: '',
          address: '',
        );
      },
      AvailableCouponsVouchersScreen.routeName: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return AvailableCouponsVouchersScreen(
            userPoints: (args['userPoints'] as num?)?.toInt() ?? 0,
            vouchers: (args['vouchers'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .toList(),
          );
        }
        return const AvailableCouponsVouchersScreen();
      },
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
