class LoginRequestModel {
  final String username;
  final String password;

  const LoginRequestModel({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class UserModel {
  final String? id;
  final String? username;
  final String? name;
  final String? email;
  final String? role;

  const UserModel({
    this.id,
    this.username,
    this.name,
    this.email,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      username: json['username']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'email': email,
        'role': role,
      };
}

class LoginResponseModel {
  final bool success;
  final String? message;
  final String? token;
  final UserModel? user;

  const LoginResponseModel({
    this.success = false,
    this.message,
    this.token,
    this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] == true || json['status'] == 200,
      message: json['message']?.toString(),
      token: json['token']?.toString() ?? json['access_token']?.toString(),
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
