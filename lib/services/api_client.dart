import 'package:dio/dio.dart';
import 'package:floret_collector/services/api_endpoints.dart';

class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: APIEndPoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<Response> get(String endpoint) async {
    return dio.get(endpoint);
  }

  Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    return dio.post(
      endpoint,
      data: data,
    );
  }
}
