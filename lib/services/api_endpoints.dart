class APIEndPoints {
  static const String baseUrl = "https://florettech.pythonanywhere.com";
  //auth
  static const String login = "/api/login/";
  static const String register = "/api/register/";

  //home
  static const String pickupSlots = '/api/pickup-slots/';
  static const String bags = '/api/bags/';
  static String bagDetails(int id) => '$bags$id/';
  static const String bagAssignment = '/api/my-bag-assignment/';
  static const String locations = '/api/locations/';
  static String collectorPickupDates(dynamic collectorId) =>
      '/api/collector-pickup-dates/?collector_id=$collectorId';

  //notifications
  static const String notifications = '/api/notifications/';

  //billing
  static const String billHistory = '/api/bill-history/';

  //collection history
  static const String collectorHistory = '/api/collector-history/';

  //collectors & vehicle assignment
  static String collectorDetail(dynamic id) => '/api/collectors/$id/';
  static String assignVehicle(dynamic id) => '/api/collectors/$id/assign-vehicle/';
  static const String getAssignVehicle = '/api/assign-vehicle/';

  //issues
  static const String issues = '/api/issues/';

  //direct disposal
  static const String directDisposal = '/api/direct-disposal/';

  //help & support
  static const String helpSupport = '/api/help-support/';
}
