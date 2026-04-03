import 'dart:math';

String _generateId() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class RecurringTransaction {
  final String id;
  final String? serverId;
  final String userId;
  final String title;
  final String type; // 'income' | 'expense'
  final double amount;
  final int? categoryId;
  final int? subCategoryId;
  final String? walletId;
  final String frequency; // 'daily' | 'weekly' | 'monthly' | 'yearly'
  final String startDate; // 'YYYY-MM-DD'
  final String? endDate; // 'YYYY-MM-DD'
  final bool isActive;
  final String? nextExecutionDate;
  final String syncStatus;
  final int createdAt;
  final int updatedAt;

  const RecurringTransaction({
    required this.id,
    this.serverId,
    required this.userId,
    required this.title,
    required this.type,
    required this.amount,
    this.categoryId,
    this.subCategoryId,
    this.walletId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.nextExecutionDate,
    this.syncStatus = 'local',
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringTransaction.create({
    required String userId,
    required String title,
    required String type,
    required double amount,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    required String frequency,
    required String startDate,
    String? endDate,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return RecurringTransaction(
      id: _generateId(),
      userId: userId,
      title: title,
      type: type,
      amount: amount,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      walletId: walletId,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      nextExecutionDate: startDate,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as String,
      serverId: map['server_id'] as String?,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int?,
      subCategoryId: map['sub_category_id'] as int?,
      walletId: map['wallet_id'] as String?,
      frequency: map['frequency'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      nextExecutionDate: map['next_execution_date'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'local',
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  factory RecurringTransaction.fromApi(Map<String, dynamic> map, String userId) {
    final raw = map['amount'];
    final amount = raw is num ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return RecurringTransaction(
      id: _generateId(),
      serverId: map['id']?.toString(),
      userId: userId,
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      amount: amount,
      categoryId: map['category_id'] as int?,
      subCategoryId: map['sub_category_id'] as int?,
      walletId: map['wallet_id']?.toString(),
      frequency: map['frequency'] as String? ?? 'monthly',
      startDate: map['start_date'] as String? ?? '',
      endDate: map['end_date'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      nextExecutionDate: map['next_execution_date'] as String?,
      syncStatus: 'synced',
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'user_id': userId,
      'title': title,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'wallet_id': walletId,
      'frequency': frequency,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive ? 1 : 0,
      'next_execution_date': nextExecutionDate,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'title': title,
      'type': type,
      'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (walletId != null) 'wallet_id': int.tryParse(walletId!),
      'frequency': frequency,
      'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
  }

  RecurringTransaction copyWith({
    String? serverId,
    String? title,
    String? type,
    double? amount,
    int? categoryId,
    bool clearCategoryId = false,
    int? subCategoryId,
    bool clearSubCategoryId = false,
    String? walletId,
    bool clearWalletId = false,
    String? frequency,
    String? startDate,
    String? endDate,
    bool clearEndDate = false,
    bool? isActive,
    String? nextExecutionDate,
    String? syncStatus,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return RecurringTransaction(
      id: id,
      serverId: serverId ?? this.serverId,
      userId: userId,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      subCategoryId: clearSubCategoryId ? null : (subCategoryId ?? this.subCategoryId),
      walletId: clearWalletId ? null : (walletId ?? this.walletId),
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      isActive: isActive ?? this.isActive,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: now,
    );
  }
}
