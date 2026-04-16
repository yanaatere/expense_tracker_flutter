import 'package:sqflite/sqflite.dart';
import '../../models/auth_cache_entry.dart';

class AuthCacheDao {
  final Database _db;

  AuthCacheDao(this._db);

  Future<void> upsert(AuthCacheEntry entry) async {
    await _db.insert(
      'auth_cache',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AuthCacheEntry?> get() async {
    final rows =
        await _db.query('auth_cache', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) return null;
    return AuthCacheEntry.fromMap(rows.first);
  }

  Future<void> updateIsPremium(bool isPremium) async {
    await _db.update(
      'auth_cache',
      {'is_premium': isPremium ? 1 : 0},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> updateAfterSync({
    required String serverId,
    required String token,
    required int syncedAt,
  }) async {
    await _db.update(
      'auth_cache',
      {
        'user_id': serverId,
        'token': token,
        'token_saved_at': DateTime.now().millisecondsSinceEpoch,
        'synced_at': syncedAt,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
