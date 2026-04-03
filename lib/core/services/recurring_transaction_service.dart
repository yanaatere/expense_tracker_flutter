import 'api_client.dart';

class RecurringTransactionService {
  static final _dio = ApiClient.dio;

  static Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _dio.get('/api/recurring-transactions');
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> getById(int id) async {
    final response = await _dio.get('/api/recurring-transactions/$id');
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> create({
    required String title,
    required String type,
    required double amount,
    int? categoryId,
    int? subCategoryId,
    int? walletId,
    required String frequency,
    required String startDate,
    String? endDate,
  }) async {
    final response = await _dio.post('/api/recurring-transactions', data: {
      'title': title,
      'type': type,
      'amount': amount,
      'category_id': ?categoryId,
      'sub_category_id': ?subCategoryId,
      'wallet_id': ?walletId,
      'frequency': frequency,
      'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
    });
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> update({
    required int id,
    required String title,
    required String type,
    required double amount,
    int? categoryId,
    int? subCategoryId,
    int? walletId,
    required String frequency,
    required String startDate,
    String? endDate,
  }) async {
    final response = await _dio.put('/api/recurring-transactions/$id', data: {
      'title': title,
      'type': type,
      'amount': amount,
      'category_id': ?categoryId,
      'sub_category_id': ?subCategoryId,
      'wallet_id': ?walletId,
      'frequency': frequency,
      'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
    });
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  static Future<void> delete(int id) async {
    await _dio.delete('/api/recurring-transactions/$id');
  }
}
