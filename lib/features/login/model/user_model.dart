import 'collector_model.dart';

class UserModel {
  final String message;
  final String token;
  final CollectorModel collector;

  const UserModel({
    required this.message,
    required this.token,
    required this.collector,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      collector: CollectorModel.fromJson(
        json['collector'] is Map<String, dynamic>
            ? json['collector'] as Map<String, dynamic>
            : {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'token': token,
      'collector': collector.toJson(),
    };
  }
}
