import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  static Future<Database> _openDatabase() async {
    final path = join(await getDatabasesPath(), 'monex.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE auth_cache (
        id             INTEGER PRIMARY KEY,
        user_id        TEXT NOT NULL,
        username       TEXT NOT NULL,
        email          TEXT NOT NULL,
        password_hash  TEXT NOT NULL,
        token          TEXT,
        token_saved_at INTEGER,
        synced_at      INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        operation    TEXT NOT NULL,
        endpoint     TEXT NOT NULL,
        http_method  TEXT NOT NULL,
        payload      TEXT NOT NULL,
        created_at   INTEGER NOT NULL,
        retry_count  INTEGER NOT NULL DEFAULT 0,
        last_error   TEXT,
        status       TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id           TEXT PRIMARY KEY,
        server_id    TEXT,
        user_id      TEXT NOT NULL,
        title        TEXT NOT NULL,
        amount       REAL NOT NULL,
        category     TEXT NOT NULL,
        note         TEXT,
        expense_date INTEGER NOT NULL,
        created_at   INTEGER NOT NULL,
        updated_at   INTEGER NOT NULL,
        is_deleted   INTEGER NOT NULL DEFAULT 0,
        sync_status  TEXT NOT NULL DEFAULT 'local'
      )
    ''');

    await _createWalletsTable(db);
  }

  static Future<void> _createWalletsTable(Database db) async {
    await db.execute('''
      CREATE TABLE wallets (
        id          TEXT PRIMARY KEY,
        server_id   TEXT,
        user_id     TEXT NOT NULL,
        name        TEXT NOT NULL,
        type        TEXT NOT NULL,
        currency    TEXT NOT NULL DEFAULT 'IDR',
        balance     REAL NOT NULL DEFAULT 0,
        goals           TEXT,
        backdrop_image  TEXT,
        sync_status TEXT NOT NULL DEFAULT 'local',
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createWalletsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE wallets ADD COLUMN backdrop_image TEXT',
      );
    }
  }
}
