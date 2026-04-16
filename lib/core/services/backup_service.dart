import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/category_definitions.dart';
import '../database/daos/expense_dao.dart';
import '../database/daos/recurring_transaction_dao.dart';
import '../database/daos/wallet_dao.dart';
import '../models/expense.dart';
import '../models/recurring_transaction.dart';
import '../models/wallet.dart';

class BackupService {
  // ── Export ────────────────────────────────────────────────────────────────

  static Future<String> exportToJson({
    required String userId,
    required ExpenseDao expenseDao,
    required WalletDao walletDao,
    required RecurringTransactionDao recurringDao,
  }) async {
    final expenses = await expenseDao.getAll(userId);
    final wallets = await walletDao.getAll(userId);
    final recurring = await recurringDao.getAll(userId);

    final payload = jsonEncode({
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'wallets': wallets.map((w) => w.toMap()).toList(),
      'recurring_transactions': recurring.map((r) => r.toMap()).toList(),
    });

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/monex_backup.json');
    await file.writeAsString(payload);
    return file.path;
  }

  static Future<String> exportToCsv({
    required String userId,
    required ExpenseDao expenseDao,
  }) async {
    final expenses = await expenseDao.getAll(userId);

    final rows = <List<dynamic>>[
      ['Date', 'Title', 'Type', 'Category', 'Sub Category', 'Amount', 'Notes'],
    ];

    for (final e in expenses) {
      final dateStr = DateTime.fromMillisecondsSinceEpoch(e.expenseDate)
          .toIso8601String()
          .split('T')
          .first;

      // Resolve category name from local definitions
      String categoryName = '';
      String subCategoryName = '';
      if (e.categoryId != null) {
        final cats = localCategories(type: e.type);
        final match = cats.firstWhere((c) => c['id'] == e.categoryId, orElse: () => {});
        categoryName = match['name'] as String? ?? '';
      }
      if (e.subCategoryId != null && categoryName.isNotEmpty) {
        final subs = localSubcategories(categoryName, type: e.type);
        final match = subs.firstWhere((s) => s['id'] == e.subCategoryId, orElse: () => {});
        subCategoryName = match['name'] as String? ?? '';
      }

      rows.add([
        dateStr,
        e.title,
        e.type,
        categoryName,
        subCategoryName,
        e.amount,
        e.note ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/monex_export.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  static Future<void> restoreFromJson({
    required String filePath,
    required String userId,
    required ExpenseDao expenseDao,
    required WalletDao walletDao,
    required RecurringTransactionDao recurringDao,
  }) async {
    final content = await File(filePath).readAsString();
    final Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;

    // Wipe current user data
    await expenseDao.deleteAllForUser(userId);
    await walletDao.deleteAllForUser(userId);
    await recurringDao.deleteAllForUser(userId);

    // Restore wallets
    final walletList = (data['wallets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final wallets = walletList
        .map((m) => Wallet.fromMap({...m, 'user_id': userId}))
        .toList();
    await walletDao.upsertAll(wallets);

    // Restore expenses
    final expenseList = (data['expenses'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final expenses = expenseList
        .map((m) => Expense.fromMap({...m, 'user_id': userId}))
        .toList();
    await expenseDao.upsertAll(expenses);

    // Restore recurring transactions
    final recurringList = (data['recurring_transactions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final recurring = recurringList
        .map((m) => RecurringTransaction.fromMap({...m, 'user_id': userId}))
        .toList();
    await recurringDao.upsertAll(recurring);
  }

  static Future<void> restoreFromCsv({
    required String filePath,
    required String userId,
    required ExpenseDao expenseDao,
  }) async {
    final content = await File(filePath).readAsString();
    final rows = const CsvToListConverter().convert(content, eol: '\n');
    if (rows.length < 2) return; // No data rows

    // Skip header row; columns: Date, Title, Type, Category, Sub Category, Amount, Notes
    await expenseDao.deleteAllForUser(userId);

    final expenses = <Expense>[];
    for (final row in rows.skip(1)) {
      if (row.length < 6) continue;
      final dateStr = row[0].toString().trim();
      final title = row[1].toString().trim();
      final type = row[2].toString().trim().toLowerCase();
      final categoryName = row[3].toString().trim();
      final subCategoryName = row[4].toString().trim();
      final rawAmount = row[5];
      final note = row.length > 6 ? row[6].toString().trim() : null;

      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        date = DateTime.now();
      }

      final amount =
          rawAmount is num ? rawAmount.toDouble() : double.tryParse(rawAmount.toString()) ?? 0;

      // Resolve category IDs from names
      int? categoryId;
      int? subCategoryId;
      if (categoryName.isNotEmpty) {
        final cats = localCategories(type: type.isEmpty ? 'expense' : type);
        final match = cats.firstWhere(
          (c) => (c['name'] as String).toLowerCase() == categoryName.toLowerCase(),
          orElse: () => {},
        );
        categoryId = match['id'] as int?;
      }
      if (subCategoryName.isNotEmpty && categoryName.isNotEmpty) {
        final subs = localSubcategories(categoryName, type: type.isEmpty ? 'expense' : type);
        final match = subs.firstWhere(
          (s) => (s['name'] as String).toLowerCase() == subCategoryName.toLowerCase(),
          orElse: () => {},
        );
        subCategoryId = match['id'] as int?;
      }

      expenses.add(Expense.create(
        userId: userId,
        title: title.isEmpty ? 'Imported' : title,
        amount: amount,
        category: categoryName,
        note: note?.isEmpty == true ? null : note,
        date: date,
        type: type.isEmpty ? 'expense' : type,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
      ));
    }

    await expenseDao.upsertAll(expenses);
  }
}
