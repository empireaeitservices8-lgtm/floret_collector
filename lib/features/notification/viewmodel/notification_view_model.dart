import 'package:floret_collector/providers/view_model.dart';
import '../model/notification_model.dart';
import '../repos/notification_repository.dart';

class NotificationViewModel extends ViewModel {
  final NotificationRepository _repository;
  List<NotificationItemModel> _notifications = [];

  NotificationViewModel({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository() {
    loadNotifications();
  }

  List<NotificationItemModel> get notifications => _notifications;

  Future<void> loadNotifications({bool waitThreeSeconds = false}) async {
    isLoading = true;
    notifyListeners();

    final fetchFuture = _repository.fetchNotifications();
    if (waitThreeSeconds) {
      await Future.wait([
        fetchFuture.then((value) => _notifications = value),
        Future.delayed(const Duration(seconds: 3)),
      ]);
    } else {
      _notifications = await fetchFuture;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    await loadNotifications(waitThreeSeconds: true);
  }
}
