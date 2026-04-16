import '../models/recurring_transaction.dart';

abstract class RecurringRepository {
  Future<List<RecurringTransaction>> getAll();

  Future<RecurringTransaction> create({
    required String title,
    required String type,
    required double amount,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    required String frequency,
    required String startDate,
    String? endDate,
  });

  Future<RecurringTransaction> update({
    required RecurringTransaction original,
    required String title,
    required String type,
    required double amount,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    required String frequency,
    required String startDate,
    String? endDate,
  });

  Future<void> delete(RecurringTransaction rt);
}
