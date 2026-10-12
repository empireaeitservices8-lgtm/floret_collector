import 'package:dio/dio.dart';
import 'package:floret_collector/core/storage/collector_details.dart';
import 'package:floret_collector/features/login/model/user_model.dart';
import 'package:floret_collector/services/api_client.dart';
import 'package:floret_collector/services/api_endpoints.dart';

class AuthService {
  final ApiClient apiClient;
  final CollectorLocalStorage collectorLocalStorage;

  AuthService(
    this.apiClient,
    this.collectorLocalStorage,
  );

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

      final user = UserModel.fromJson(response.data);

      if (response.statusCode == 200) {
        final collector = Map<String, dynamic>.from(
          response.data['collector'],
        );

        await collectorLocalStorage.saveCollector(collector);
      }

      return user;
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
