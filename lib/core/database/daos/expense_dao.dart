import 'package:sqflite/sqflite.dart';
import '../../models/expense.dart';

class ExpenseDao {
  final Database _db;

  ExpenseDao(this._db);

  Future<List<Expense>> getAll(String userId) async {
    final rows = await _db.query(
      'expenses',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'expense_date DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> upsertAll(List<Expense> expenses) async {
    final batch = _db.batch();
    for (final e in expenses) {
      batch.insert(
        'expenses',
        e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
