class Expense {
  final String id;
  final String? serverId;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final String? note;
  final int expenseDate;
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final String syncStatus;

  const Expense({
    required this.id,
    this.serverId,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    this.note,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = 'local',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'server_id': serverId,
        'user_id': userId,
        'title': title,
        'amount': amount,
        'category': category,
        'note': note,
        'expense_date': expenseDate,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'is_deleted': isDeleted ? 1 : 0,
        'sync_status': syncStatus,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        serverId: map['server_id'] as String?,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        amount: map['amount'] as double,
        category: map['category'] as String,
        note: map['note'] as String?,
        expenseDate: map['expense_date'] as int,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
        isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
        syncStatus: map['sync_status'] as String? ?? 'local',
      );
}
