class NotificationItemModel {
  final String id;
  final String title;
  final String timestamp;
  final String body;
  final bool isWarning;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.body,
    this.isWarning = true,
  });
}
