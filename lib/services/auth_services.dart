import 'package:dio/dio.dart';
import 'package:floret_collector/features/login/model/user_model.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  Future<UserModel> login(
    String username,
    String password,
  ) async {
    try {
      final response = await apiClient.post(
        APIEndPoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        final errorMessage = data['error'];

        if (errorMessage != null) {
          throw Exception(errorMessage.toString());
        }
      }

      throw Exception(
        'Unable to login. Please try again.',
      );
    }
  }
}
