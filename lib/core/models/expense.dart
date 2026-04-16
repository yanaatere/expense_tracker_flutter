import 'dart:math';

String _generateId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

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
  final String type;
  final int? categoryId;
  final int? subCategoryId;
  final String? walletId;
  final String? receiptImageUrl;

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
    this.type = 'expense',
    this.categoryId,
    this.subCategoryId,
    this.walletId,
    this.receiptImageUrl,
  });

  factory Expense.create({
    required String userId,
    required String title,
    required double amount,
    required String category,
    String? note,
    required DateTime date,
    String type = 'expense',
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    String? receiptImageUrl,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Expense(
      id: _generateId(),
      userId: userId,
      title: title,
      amount: amount,
      category: category,
      note: note,
      expenseDate: date.millisecondsSinceEpoch,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'local',
      type: type,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      walletId: walletId,
      receiptImageUrl: receiptImageUrl,
    );
  }

  factory Expense.fromApi(Map<String, dynamic> m, String userId) {
    final rawAmount = m['amount'];
    final amount =
        (rawAmount is num ? rawAmount.toDouble() : double.tryParse(rawAmount.toString()) ?? 0)
            .abs();
    final dateStr = m['transaction_date'] as String? ?? '';
    int expenseDate;
    try {
      expenseDate = DateTime.parse(dateStr).millisecondsSinceEpoch;
    } catch (_) {
      expenseDate = DateTime.now().millisecondsSinceEpoch;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    return Expense(
      id: _generateId(),
      serverId: m['id']?.toString(),
      userId: userId,
      title: m['description'] as String? ?? '',
      amount: amount,
      category: '',
      note: m['notes'] as String?,
      expenseDate: expenseDate,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'synced',
      type: m['type'] as String? ?? 'expense',
      categoryId: m['category_id'] as int?,
      subCategoryId: m['sub_category_id'] as int?,
      walletId: m['wallet_id']?.toString(),
      receiptImageUrl: m['receipt_image_url'] as String?,
    );
  }

  Map<String, dynamic> toApiMap() {
    final dateIso =
        DateTime.fromMillisecondsSinceEpoch(expenseDate).toIso8601String();
    return {
      'type': type,
      'amount': amount,
      'date': dateIso,
      if (categoryId != null) 'category_id': categoryId,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (walletId != null) 'wallet_id': int.tryParse(walletId!),
      'description': title,
      if (receiptImageUrl != null) 'receipt_image_url': receiptImageUrl,
    };
  }

  Expense copyWith({
    String? serverId,
    String? title,
    double? amount,
    String? category,
    String? note,
    int? expenseDate,
    bool? isDeleted,
    String? syncStatus,
    String? type,
    int? categoryId,
    bool clearCategoryId = false,
    int? subCategoryId,
    bool clearSubCategoryId = false,
    String? walletId,
    bool clearWalletId = false,
    String? receiptImageUrl,
    bool clearReceiptImageUrl = false,
  }) {
    return Expense(
      id: id,
      serverId: serverId ?? this.serverId,
      userId: userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      type: type ?? this.type,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      subCategoryId: clearSubCategoryId ? null : (subCategoryId ?? this.subCategoryId),
      walletId: clearWalletId ? null : (walletId ?? this.walletId),
      receiptImageUrl: clearReceiptImageUrl ? null : (receiptImageUrl ?? this.receiptImageUrl),
    );
  }

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
        'type': type,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'wallet_id': walletId,
        'receipt_image_url': receiptImageUrl,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        serverId: map['server_id'] as String?,
        userId: map['user_id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String? ?? '',
        note: map['note'] as String?,
        expenseDate: map['expense_date'] as int,
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
        isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
        syncStatus: map['sync_status'] as String? ?? 'local',
        type: map['type'] as String? ?? 'expense',
        categoryId: map['category_id'] as int?,
        subCategoryId: map['sub_category_id'] as int?,
        walletId: map['wallet_id'] as String?,
        receiptImageUrl: map['receipt_image_url'] as String?,
      );
}
