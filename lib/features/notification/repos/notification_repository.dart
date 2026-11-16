import '../model/notification_model.dart';
import 'package:floret_collector/services/web_api_services.dart';

class NotificationRepository {
  final WebAPIService _webAPIService;

  NotificationRepository({WebAPIService? webAPIService})
      : _webAPIService = webAPIService ?? WebAPIService();

  WebAPIService get webAPIService => _webAPIService;

  Future<List<NotificationItemModel>> fetchNotifications() async {
    try {
      // Mock data matching exact notification items in screenshot
      return const [];
    } catch (_) {
      return [];
    }
  }
}
