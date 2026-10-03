import 'package:flutter/material.dart';
import 'package:floret_collector/utils/enums.dart';

class AppConfig {
  static const appName = "floret_collector";
  static const bundleId = "com.floret_collector";
  static const designWidth = 390.0;
  static const designHeight = 844.0;

  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
  GlobalKey bottomNavigationKey = GlobalKey();
  static bool isDebugMode = true;

  static EnumBuildEnvironment server = EnumBuildEnvironment.dg;
}
