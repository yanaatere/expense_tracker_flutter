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

  Future<Expense?> getById(String id) async {
    final rows = await _db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  Future<void> insert(Expense e) async {
    await _db.insert(
      'expenses',
      e.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Expense e) async {
    await _db.update(
      'expenses',
      e.toMap(),
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<void> softDelete(String id) async {
    await _db.update(
      'expenses',
      {
        'is_deleted': 1,
        'sync_status': 'pending',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> hardDelete(String id) async {
    await _db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Expense>> getUnsynced(String userId) async {
    final rows = await _db.query(
      'expenses',
      where: 'user_id = ? AND sync_status IN (\'local\', \'pending\') AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> updateSyncStatus(String id, String serverId, String syncStatus) async {
    await _db.update(
      'expenses',
      {
        'server_id': serverId,
        'sync_status': syncStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllForUser(String userId) async {
    await _db.delete('expenses', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> countSoftDeleted(String userId) async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) AS c FROM expenses WHERE user_id = ? AND is_deleted = 1 AND sync_status = 'synced'",
      [userId],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<void> hardDeleteSoftDeleted(String userId) async {
    await _db.delete(
      'expenses',
      where: "user_id = ? AND is_deleted = 1 AND sync_status = 'synced'",
      whereArgs: [userId],
    );
  }

  Future<int> countOldSynced(String userId, int cutoffMs) async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) AS c FROM expenses WHERE user_id = ? AND sync_status = 'synced' AND is_deleted = 0 AND expense_date < ?",
      [userId, cutoffMs],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<void> hardDeleteOldSynced(String userId, int cutoffMs) async {
    await _db.delete(
      'expenses',
      where: "user_id = ? AND sync_status = 'synced' AND is_deleted = 0 AND expense_date < ?",
      whereArgs: [userId, cutoffMs],
    );
  }

  Future<int> countAll(String userId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM expenses WHERE user_id = ? AND is_deleted = 0',
      [userId],
    );
    return (result.first['c'] as int?) ?? 0;
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
