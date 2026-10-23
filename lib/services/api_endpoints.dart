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
  static String assignVehicle(dynamic id) =>
      '/api/collectors/$id/assign-vehicle/';
  static const String getAssignVehicle = '/api/assign-vehicle/';

  //issues
  static const String issues = '/api/issues/';
  static const String reportIssue = '/api/report-issue/';
  static const String updateIssueStatus = '/api/update-issue-status/';

  //direct disposal
  static const String directDisposal = '/api/direct-disposal/';

  //help & support
  static const String helpSupport = '/api/help-support/';

  //collection route & payment
  static const String wardCollectionRoutes = '/api/ward-collection-routes/';
  static const String pickupDetails = '/api/pickup-details/';
  static const String startTrackingRoute = '/api/start-tracking/';
  static const String confirmRouteStart = '/api/confirm-route-start/';
  static const String startNavigate = '/api/start-navigate/';
  static const String updateCollectorLocation = '/api/update-collector-location/';
  static const String confirmReached = '/api/confirm-reached/';
  static const String confirmAndPayData = '/api/confirm-and-pay-data/';
  static const String disposalRates = '/api/disposal-rates/';
  static const String generateBill = '/api/generate-bill/';
  static const String processPayment = '/api/process-payment/';
  static const String confirmAndPay = '/api/confirm-and-pay/';
  static const String updatePickupStatus = '/api/update-pickup-status/';
  static const String collectPickup = '/api/collect-pickup/';
  static const String uploadWastePhoto = '/api/upload-waste-photo/';
  static const String razorpayGenerateQr = '/api/razorpay/generate-qr/';
}
