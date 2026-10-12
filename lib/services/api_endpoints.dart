class APIEndPoints {
  static const String baseUrl = "https://florettech.pythonanywhere.com";
  //auth
  static const String login = "/api/login/";
  static const String register = "/api/register/";

//home
  static const String pickupSlots = '/api/pickup-slots/';
  static const String bags = '/api/bags/';
  static String bagDetails(int id) => '$bags$id/';

  //billing
  static const String billHistory = '/api/bill-history/';

  //collection history
  static const String collectorHistory = '/api/collector-history';

  //issues
  static const String issues = '/api/issues/';

  //direct disposal
  static const String directDisposal = '/api/direct-disposal/';

  //help & support
  static const String helpSupport = '/api/help-support/';
}
