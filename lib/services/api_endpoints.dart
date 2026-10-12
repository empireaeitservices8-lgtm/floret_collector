class APIEndPoints {
  static const String baseUrl = "https://florettech.pythonanywhere.com";
  //auth
  static const String login = "/api/login/";
  static const String register = "/api/register/";

//home
  static const String pickupSlots = '/api/pickup-slots/';
  static const String bags = '/api/bags/';
  static String bagDetails(int id) => '$bags$id/';
}
