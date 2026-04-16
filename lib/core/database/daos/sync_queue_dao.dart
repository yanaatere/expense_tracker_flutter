import 'package:sqflite/sqflite.dart';
import '../../models/sync_item.dart';

class SyncQueueDao {
  final Database _db;

  SyncQueueDao(this._db);

  Future<int> enqueue(SyncItem item) async {
    return _db.insert('sync_queue', item.toMap());
  }

  Future<List<SyncItem>> getPending() async {
    final rows = await _db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map(SyncItem.fromMap).toList();
  }

  Future<void> markDone(int id) async {
    await _db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete done/failed entries older than [olderThanMs]. Returns count deleted.
  Future<int> purgeStale(int olderThanMs) async {
    return _db.delete(
      'sync_queue',
      where: "status IN ('done', 'failed') AND created_at < ?",
      whereArgs: [olderThanMs],
    );
  }

  Future<void> incrementRetry(int id, String error) async {
    final rows =
        await _db.query('sync_queue', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final current = SyncItem.fromMap(rows.first);
    final newRetryCount = current.retryCount + 1;
    await _db.update(
      'sync_queue',
      {
        'retry_count': newRetryCount,
        'last_error': error,
        'status': newRetryCount >= 3 ? 'failed' : 'pending',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
