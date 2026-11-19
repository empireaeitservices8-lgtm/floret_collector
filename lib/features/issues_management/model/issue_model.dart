class IssueModel {
  final String id;
  final String title;
  final String description;
  final String userName;
  final String? phoneNumber;
  final bool isResolved;
  final String? createdAt;
  final int? pickupId;
  final String? resolutionNotes;
  final String? resolvedAt;

  const IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userName,
    this.phoneNumber,
    required this.isResolved,
    this.createdAt,
    this.pickupId,
    this.resolutionNotes,
    this.resolvedAt,
  });

  String get userInitial {
    if (userName.trim().isEmpty) return '?';
    return userName.trim().substring(0, 1).toUpperCase();
  }

  String? get formattedResolvedDate {
    if (resolvedAt == null || resolvedAt!.trim().isEmpty) return null;
    try {
      final dt = DateTime.tryParse(resolvedAt!.trim());
      if (dt == null) return null;
      final local = dt.toLocal();
      final now = DateTime.now();

      final isToday = local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;

      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = local.year == yesterday.year &&
          local.month == yesterday.month &&
          local.day == yesterday.day;

      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final amPm = local.hour >= 12 ? 'PM' : 'AM';
      final minute = local.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute $amPm';

      if (isToday) {
        return 'Today, $timeStr';
      } else if (isYesterday) {
        return 'Yesterday, $timeStr';
      }

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[local.month - 1];
      return '${local.day} $month ${local.year}, $timeStr';
    } catch (_) {
      return null;
    }
  }

  String? get formattedCreatedDate {
    if (createdAt == null || createdAt!.trim().isEmpty) return null;
    try {
      final dt = DateTime.tryParse(createdAt!.trim());
      if (dt == null) return null;
      final local = dt.toLocal();
      final now = DateTime.now();

      final isToday = local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;

      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = local.year == yesterday.year &&
          local.month == yesterday.month &&
          local.day == yesterday.day;

      if (isToday) {
        final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
        final amPm = local.hour >= 12 ? 'PM' : 'AM';
        final minute = local.minute.toString().padLeft(2, '0');
        return 'Today, $hour:$minute $amPm';
      } else if (isYesterday) {
        return 'Yesterday';
      }

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[local.month - 1];
      return '${local.day} $month ${local.year}';
    } catch (_) {
      return null;
    }
  }

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id']?.toString() ?? '',
      title: json['subject']?.toString() ??
          json['title']?.toString() ??
          'Issue Report',
      description: json['description']?.toString() ??
          json['reason']?.toString() ??
          '',
      userName: json['user_name']?.toString() ??
          json['customer_name']?.toString() ??
          json['stop_name']?.toString() ??
          'User',
      phoneNumber: (json['user_phone'] ??
              json['phone'] ??
              json['phone_number'])
          ?.toString(),
      isResolved: json['is_resolved'] == true ||
          json['status']?.toString().toLowerCase() == 'resolved',
      createdAt: json['created_at']?.toString(),
      pickupId: json['pickup_id'] != null
          ? int.tryParse(json['pickup_id'].toString())
          : null,
      resolutionNotes: json['resolution_notes']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
    );
  }

  IssueModel copyWith({
    String? id,
    String? title,
    String? description,
    String? userName,
    String? phoneNumber,
    bool? isResolved,
    String? createdAt,
    int? pickupId,
    String? resolutionNotes,
    String? resolvedAt,
  }) {
    return IssueModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
      pickupId: pickupId ?? this.pickupId,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
