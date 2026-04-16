import 'package:sqflite/sqflite.dart';
import '../../models/recurring_transaction.dart';

class RecurringTransactionDao {
  final Database _db;

  RecurringTransactionDao(this._db);

  Future<List<RecurringTransaction>> getAll(String userId) async {
    final rows = await _db.query(
      'recurring_transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(RecurringTransaction.fromMap).toList();
  }

  Future<RecurringTransaction?> getById(String id) async {
    final rows = await _db.query(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RecurringTransaction.fromMap(rows.first);
  }

  Future<void> insert(RecurringTransaction rt) async {
    await _db.insert(
      'recurring_transactions',
      rt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(RecurringTransaction rt) async {
    await _db.update(
      'recurring_transactions',
      rt.toMap(),
      where: 'id = ?',
      whereArgs: [rt.id],
    );
  }

  Future<void> upsertAll(List<RecurringTransaction> items) async {
    final batch = _db.batch();
    for (final rt in items) {
      batch.insert(
        'recurring_transactions',
        rt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllForUser(String userId) async {
    await _db.delete('recurring_transactions', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> delete(String id) async {
    await _db.delete(
      'recurring_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<RecurringTransaction>> getUnsynced(String userId) async {
    final rows = await _db.query(
      'recurring_transactions',
      where: 'user_id = ? AND sync_status IN (\'local\', \'pending\')',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    return rows.map(RecurringTransaction.fromMap).toList();
  }

  Future<void> updateSyncStatus(String id, String serverId, String syncStatus) async {
    await _db.update(
      'recurring_transactions',
      {
        'server_id': serverId,
        'sync_status': syncStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
