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
      return const [
        NotificationItemModel(
          id: '1',
          title: 'Issue Report: Dispose by themselves',
          timestamp: '2026-09-10 08:52:08',
          body: 'Collector marked warning with reason: Dispose by themselves.',
        ),
        NotificationItemModel(
          id: '2',
          title: 'Issue Report: Dispose by themselves',
          timestamp: '2026-09-10 08:51:07',
          body: 'Collector marked warning with reason: Dispose by themselves.',
        ),
        NotificationItemModel(
          id: '3',
          title: 'Issue Report: Dispose by themselves',
          timestamp: '2026-09-10 08:45:54',
          body: 'Collector marked warning with reason: Dispose by themselves.',
        ),
        NotificationItemModel(
          id: '4',
          title: 'Issue Report: Improper bags',
          timestamp: '2026-09-10 05:42:35',
          body: 'Collector marked warning with reason: Improper bags.',
        ),
        NotificationItemModel(
          id: '5',
          title: 'Issue Report: Dispose by themselves',
          timestamp: '2026-09-10 05:37:57',
          body: 'Collector marked warning with reason: Dispose by themselves.',
        ),
        NotificationItemModel(
          id: '6',
          title: 'Issue Report: Dispose by themselves',
          timestamp: '2026-09-09 11:28:25',
          body: 'Collector marked warning with reason: Dispose by themselves.',
        ),
      ];
    } catch (_) {
      return [];
    }
  }
}
