import 'package:sqflite/sqflite.dart';

// ---------------------------------------------------------------------------
// Budget model
// ---------------------------------------------------------------------------

class Budget {
  final int? id;
  final String categoryName;
  final double monthlyLimit;
  final int createdAt;
  final int updatedAt;

  const Budget({
    this.id,
    required this.categoryName,
    required this.monthlyLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_name': categoryName,
        'monthly_limit': monthlyLimit,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] as int?,
        categoryName: map['category_name'] as String,
        monthlyLimit: (map['monthly_limit'] as num).toDouble(),
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );
}

// ---------------------------------------------------------------------------
// DAO
// ---------------------------------------------------------------------------

class BudgetDao {
  final Database _db;

  BudgetDao(this._db);

  Future<List<Budget>> getAll() async {
    final rows = await _db.query('budgets', orderBy: 'category_name ASC');
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> upsert(Budget budget) async {
    await _db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
