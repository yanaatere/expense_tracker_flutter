import 'package:dio/dio.dart';
import 'api_client.dart';

class WalletService {
  static final _dio = ApiClient.dio;

  /// POST /api/wallets → { id, name, type, ... }
  static Future<Map<String, dynamic>> createWallet({
    required String name,
    required String type,
    String? currency,
    double? balance,
    String? goals,
  }) async {
    final response = await _dio.post(
      '/api/wallets',
      data: {
        'name': name,
        'type': type,
        'currency': currency,
        'balance': balance,
        if (goals != null && goals.isNotEmpty) 'goals': goals,
      },
    );
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  /// GET /api/wallets → list of user wallets
  static Future<List<Map<String, dynamic>>> getWallets() async {
    final response = await _dio.get('/api/wallets');
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// GET /api/wallets/{id}/transactions?type=income|expense
  static Future<List<Map<String, dynamic>>> getWalletTransactions(
    int walletId, {
    String? type,
  }) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    final response = await _dio.get(
      '/api/wallets/$walletId/transactions',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// PUT /api/wallets/{id}
  static Future<Map<String, dynamic>> updateWallet(
    int walletId, {
    required String name,
    required String type,
    required String currency,
    required double balance,
    String? goals,
  }) async {
    final response = await _dio.put(
      '/api/wallets/$walletId',
      data: {
        'name': name,
        'type': type,
        'currency': currency,
        'balance': balance,
        'goals': goals ?? '',
      },
    );
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  /// DELETE /api/wallets/{id}
  static Future<void> deleteWallet(int walletId) async {
    await _dio.delete('/api/wallets/$walletId');
  }

  static String errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) return (inner['message'] ?? '').toString();
      return (data['message'] ?? data['error'] ?? '').toString();
    }
    return 'Something went wrong. Please try again.';
  }
}
