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
      '/api/auth/register',
      data: {'username': username, 'email': email, 'password': password},
    );
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  /// POST /auth/login → { token, username }
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  /// POST /auth/google → { id, username, email, token }
  static Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final response = await _dio.post(
      '/api/auth/google',
      data: {'id_token': idToken},
    );
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  /// GET /api/auth/me → { id, username, email, is_premium }
  static Future<bool> fetchIsPremium() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/auth/me');
    final data = (response.data?['data'] as Map<String, dynamic>?) ?? {};
    return data['is_premium'] as bool? ?? false;
  }

  /// PUT /api/users/{id}/premium → { is_premium: bool }
  static Future<void> setPremium({
    required String userId,
    required bool isPremium,
  }) async {
    await _dio.put<void>(
      '/api/users/$userId/premium',
      data: {'is_premium': isPremium},
    );
  }

  /// Extract a readable message from a DioException.
  static String errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) {
        return (inner['message'] ?? '').toString();
      }
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
