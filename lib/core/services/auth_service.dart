import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthService {
  static final _dio = ApiClient.dio;

  /// POST /auth/register → { id, username, email, token }
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'username': username, 'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /auth/login → { token, username }
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Extract a readable message from a DioException.
  static String errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? '').toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Network error. Please check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
