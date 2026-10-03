class IssueModel {
  final String id;
  final String title;
  final String description;
  final String userName;
  final String? phoneNumber;
  final bool isResolved;
  final String? createdAt;

  const IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userName,
    this.phoneNumber,
    required this.isResolved,
    this.createdAt,
  });

  String get userInitial {
    if (userName.trim().isEmpty) return '?';
    return userName.trim().substring(0, 1).toUpperCase();
  }

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Issue Report',
      description: json['description']?.toString() ??
          json['reason']?.toString() ??
          '',
      userName: json['user_name']?.toString() ??
          json['customer_name']?.toString() ??
          json['stop_name']?.toString() ??
          'User',
      phoneNumber: json['phone']?.toString() ?? json['phone_number']?.toString(),
      isResolved: json['is_resolved'] == true ||
          json['status']?.toString().toLowerCase() == 'resolved',
      createdAt: json['created_at']?.toString(),
    );
  }
}
