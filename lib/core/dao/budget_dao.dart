import 'package:sqflite/sqflite.dart';

// ---------------------------------------------------------------------------
// Budget model
// ---------------------------------------------------------------------------

class Budget {
  final int? id;
  final String categoryName;
  final int? categoryId;
  final double monthlyLimit;
  final String period; // 'daily' | 'weekly' | 'monthly'
  final String? title;
  final bool notificationEnabled;
  final int createdAt;
  final int updatedAt;

  const Budget({
    this.id,
    required this.categoryName,
    this.categoryId,
    required this.monthlyLimit,
    this.period = 'monthly',
    this.title,
    this.notificationEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name: custom title if set, otherwise the category name.
  String get displayName =>
      (title?.isNotEmpty ?? false) ? title! : categoryName;

  /// Short period label for display.
  String get periodLabel =>
      period == 'daily' ? 'Day' : period == 'weekly' ? 'Week' : 'Month';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_name': categoryName,
        'category_id': categoryId,
        'monthly_limit': monthlyLimit,
        'period': period,
        'title': title,
        'notification_enabled': notificationEnabled ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] as int?,
        categoryName: map['category_name'] as String,
        categoryId: map['category_id'] as int?,
        monthlyLimit: (map['monthly_limit'] as num).toDouble(),
        period: map['period'] as String? ?? 'monthly',
        title: map['title'] as String?,
        notificationEnabled: (map['notification_enabled'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  Budget copyWith({
    int? id,
    String? categoryName,
    int? categoryId,
    double? monthlyLimit,
    String? period,
    String? title,
    bool? notificationEnabled,
    int? createdAt,
    int? updatedAt,
    bool clearTitle = false,
  }) =>
      Budget(
        id: id ?? this.id,
        categoryName: categoryName ?? this.categoryName,
        categoryId: categoryId ?? this.categoryId,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
        period: period ?? this.period,
        title: clearTitle ? null : (title ?? this.title),
        notificationEnabled: notificationEnabled ?? this.notificationEnabled,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ---------------------------------------------------------------------------
// DAO
// ---------------------------------------------------------------------------

class BudgetDao {
  final Database _db;

  BudgetDao(this._db);

  Future<List<Budget>> getAll() async {
    final rows = await _db.query('budgets', orderBy: 'period ASC, category_name ASC');
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget?> getForCategory(int categoryId) async {
    final rows = await _db.query(
      'budgets',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
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

  /// Returns the total expense amount for [budget]'s category in the current period.
  Future<double> getCurrentSpending(Budget budget, String userId) async {
    if (budget.categoryId == null) return 0.0;

    final now = DateTime.now();
    final int startMs;
    switch (budget.period) {
      case 'daily':
        startMs = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      case 'weekly':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        startMs = DateTime(monday.year, monday.month, monday.day).millisecondsSinceEpoch;
      default: // monthly
        startMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    }

    final result = await _db.rawQuery(
      '''SELECT COALESCE(SUM(amount), 0.0) AS total
         FROM expenses
         WHERE user_id = ?
           AND type = 'expense'
           AND category_id = ?
           AND is_deleted = 0
           AND expense_date >= ?''',
      [userId, budget.categoryId, startMs],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
