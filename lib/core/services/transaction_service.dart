import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';

class TransactionService {
  static final _dio = ApiClient.dio;

  static Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    final response = await _dio.get(
      '/api/categories',
      queryParameters: type != null ? {'type': type} : null,
    );
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getSubCategories(int categoryId) async {
    final response = await _dio.get('/api/categories/$categoryId/sub-categories');
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 10}) async {
    final response = await _dio.get('/api/transactions', queryParameters: {'limit': limit});
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  /// Upload a receipt image to the backend and return the stored URL.
  static Future<String> uploadReceipt(File file) async {
    final formData = FormData.fromMap({
      'receipt': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    final response = await _dio.post(
      '/api/uploads/receipts',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final envelope = response.data as Map<String, dynamic>;
    final data = envelope['data'] as Map<String, dynamic>;
    return data['url'] as String;
  }

  /// Delete a previously uploaded receipt by its public URL.
  static Future<void> deleteReceipt(String url) async {
    final objectName = Uri.parse(url).pathSegments.last;
    if (!RegExp(r'^[\w\-.]+$').hasMatch(objectName)) {
      throw ArgumentError('Invalid receipt object name: $objectName');
    }
    await _dio.delete('/api/uploads/receipts/$objectName');
  }

  static Future<Map<String, dynamic>> getTransaction(int id) async {
    final response = await _dio.get('/api/transactions/$id');
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getHomeSummary() async {
    final response = await _dio.get('/api/home/summary');
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  static Future<void> deleteTransaction(int id) async {
    await _dio.delete('/api/transactions/$id');
  }

  static Future<Map<String, dynamic>> updateTransaction({
    required int id,
    required String type,
    required double amount,
    String? description,
    int? categoryId,
    int? subCategoryId,
    int? walletId,
    String? date,
    String? receiptImageUrl,
  }) async {
    final response = await _dio.put('/api/transactions/$id', data: {
      'type': type,
      'amount': amount,
      if (description != null && description.isNotEmpty) 'description': description,
      'category_id': ?categoryId,
      'sub_category_id': ?subCategoryId,
      'wallet_id': ?walletId,
      if (date != null) 'date': date,
      if (receiptImageUrl != null) 'receipt_image_url': receiptImageUrl,
    });
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createTransaction({
    required String type,
    required double amount,
    String? description,
    int? categoryId,
    int? subCategoryId,
    int? walletId,
    String? date,
    String? receiptImageUrl,
  }) async {
    final today = DateTime.now();
    final dateStr = date ?? '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final response = await _dio.post('/api/transactions', data: {
      'type': type,
      'amount': amount,
      'date': dateStr,
      if (description != null && description.isNotEmpty) 'description': description,
      'category_id': ?categoryId,
      'sub_category_id': ?subCategoryId,
      'wallet_id': ?walletId,
      if (receiptImageUrl != null && receiptImageUrl.isNotEmpty) 'receipt_image_url': receiptImageUrl,
    });
    final envelope = response.data as Map<String, dynamic>;
    return envelope['data'] as Map<String, dynamic>;
  }
}
