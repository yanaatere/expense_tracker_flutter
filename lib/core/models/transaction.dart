import '../constants/category_definitions.dart';
import 'expense.dart';

class Transaction {
  final String title;
  final String category;
  final String type;
  final double amount;
  final DateTime date;
  final int? categoryId;
  final Map<String, dynamic> rawData;

  const Transaction({
    required this.title,
    required this.category,
    required this.type,
    required this.amount,
    required this.date,
    this.categoryId,
    required this.rawData,
  });

  factory Transaction.fromApi(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'expense';
    final raw = map['amount'];
    double amount = raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
    if (type == 'expense') amount = -amount.abs();

    final rawId = map['category_id'];
    int? categoryId;
    String categoryName = '';
    if (rawId != null) {
      final id = rawId is int ? rawId : int.tryParse(rawId.toString());
      categoryId = id;
      if (id != null) {
        final cats = localCategories(type: type);
        final match = cats.firstWhere((c) => c['id'] == id, orElse: () => {});
        categoryName = match['name'] as String? ?? '';
      }
    }

    final dateStr = map['transaction_date'] as String? ?? '';
    DateTime date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      date = DateTime.now();
    }

    return Transaction(
      title: map['description'] as String? ?? '',
      category: categoryName,
      type: type,
      amount: amount,
      date: date,
      categoryId: categoryId,
      rawData: map,
    );
  }

  factory Transaction.fromExpense(Expense e) {
    final type = e.type;
    double amount = e.amount.abs();
    if (type == 'expense') amount = -amount;

    String categoryName = '';
    if (e.categoryId != null) {
      final cats = localCategories(type: type);
      final match = cats.firstWhere((c) => c['id'] == e.categoryId, orElse: () => {});
      categoryName = match['name'] as String? ?? '';
    }

    DateTime date;
    try {
      date = DateTime.fromMillisecondsSinceEpoch(e.expenseDate);
    } catch (_) {
      date = DateTime.now();
    }

    final rawData = <String, dynamic>{
      'id': e.serverId != null ? int.tryParse(e.serverId!) : null,
      'local_id': e.id,
      'description': e.title,
      'transaction_date': date.toIso8601String(),
      'type': type,
      'amount': e.amount.abs(),
      'category_id': e.categoryId,
      'sub_category_id': e.subCategoryId,
      'wallet_id': e.walletId != null ? int.tryParse(e.walletId!) : null,
      'receipt_image_url': e.receiptImageUrl,
      'notes': e.note,
    };

    return Transaction(
      title: e.title,
      category: categoryName,
      type: type,
      amount: amount,
      date: date,
      categoryId: e.categoryId,
      rawData: rawData,
    );
  }
}
