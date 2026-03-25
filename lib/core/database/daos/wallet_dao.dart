import 'package:sqflite/sqflite.dart';
import '../../models/wallet.dart';

class WalletDao {
  final Database _db;

  WalletDao(this._db);

  Future<List<Wallet>> getAll(String userId) async {
    final rows = await _db.query(
      'wallets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Wallet.fromMap).toList();
  }

  Future<void> insert(Wallet wallet) async {
    await _db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Wallet wallet) async {
    await _db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> upsertAll(List<Wallet> wallets) async {
    final batch = _db.batch();
    for (final w in wallets) {
      batch.insert('wallets', w.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Wallet>> getUnsynced(String userId) async {
    final rows = await _db.query(
      'wallets',
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: [userId, 'local'],
    );
    return rows.map(Wallet.fromMap).toList();
  }

  Future<void> delete(String id) async {
    await _db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSyncStatus(String id, String serverId, String syncStatus) async {
    await _db.update(
      'wallets',
      {'server_id': serverId, 'sync_status': syncStatus, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
