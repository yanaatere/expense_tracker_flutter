import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getRecentTransactions({int limit = 10});

  Future<void> createTransaction({
    required String type,
    required double amount,
    required String description,
    String? note,
    required DateTime date,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    String? receiptImageUrl,
  });

  Future<void> updateTransaction({
    required String localId,
    String? serverId,
    required String type,
    required double amount,
    required String description,
    String? note,
    required DateTime date,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    String? receiptImageUrl,
  });

  Future<void> deleteTransaction({
    required String localId,
    String? serverId,
  });
}
