import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../database/daos/auth_cache_dao.dart';
import '../database/daos/expense_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import '../database/daos/wallet_dao.dart';
import '../models/expense.dart';
import '../models/sync_item.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../storage/local_storage.dart';
import '../sync/connectivity_service.dart';
import 'transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final ExpenseDao _expenseDao;
  final AuthCacheDao _authCacheDao;
  final SyncQueueDao _syncQueueDao;
  final WalletDao _walletDao;
  final ConnectivityService _connectivity;

  TransactionRepositoryImpl({
    required ExpenseDao expenseDao,
    required AuthCacheDao authCacheDao,
    required SyncQueueDao syncQueueDao,
    required WalletDao walletDao,
    required ConnectivityService connectivity,
  })  : _expenseDao = expenseDao,
        _authCacheDao = authCacheDao,
        _syncQueueDao = syncQueueDao,
        _walletDao = walletDao,
        _connectivity = connectivity;

  Future<String> get _userId async {
    final entry = await _authCacheDao.get();
    return entry?.userId ?? 'local';
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    final userId = await _userId;
    final isPremium = await LocalStorage.isPremium();

    if (isPremium && await _connectivity.isOnline()) {
      try {
        final raw = await TransactionService.getRecentTransactions(limit: limit);
        final expenses = raw.map((m) => Expense.fromApi(m, userId)).toList();
        await _expenseDao.upsertAll(expenses);
      } catch (e) {
        debugPrint('[TransactionRepository] Remote fetch failed, using local: $e');
      }
    }

    final all = await _expenseDao.getAll(userId);
    // Build a walletLocalId → walletName map for the detail screen.
    final wallets = await _walletDao.getAll(userId);
    final walletNames = {for (final w in wallets) w.id: w.name};
    return all
        .take(limit)
        .map((e) => Transaction.fromExpense(
              e,
              walletName: e.walletId != null ? walletNames[e.walletId] : null,
            ))
        .toList();
  }

  @override
  Future<void> createTransaction({
    required String type,
    required double amount,
    required String description,
    String? note,
    required DateTime date,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    String? receiptImageUrl,
  }) async {
    final userId = await _userId;
    final isPremium = await LocalStorage.isPremium();

    if (!isPremium) {
      // Free user: local only
      final expense = Expense.create(
        userId: userId,
        title: description,
        amount: amount,
        category: '',
        note: note,
        date: date,
        type: type,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        walletId: walletId,
        receiptImageUrl: receiptImageUrl,
      );
      await _expenseDao.insert(expense);
      return;
    }

    // Premium: try API first
    if (await _connectivity.isOnline()) {
      try {
        final data = await TransactionService.createTransaction(
          type: type,
          amount: amount,
          description: description,
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          walletId: walletId != null ? int.tryParse(walletId) : null,
          date: date.toIso8601String(),
          receiptImageUrl: receiptImageUrl,
        );
        final expense = Expense.fromApi(data, userId);
        await _expenseDao.insert(expense);
        return;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Premium offline: save locally and queue
    final expense = Expense.create(
      userId: userId,
      title: description,
      amount: amount,
      category: '',
      note: note,
      date: date,
      type: type,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      walletId: walletId,
      receiptImageUrl: receiptImageUrl,
    );
    await _expenseDao.insert(expense);
    await _syncQueueDao.enqueue(SyncItem(
      operation: 'create_transaction',
      endpoint: '/api/transactions',
      httpMethod: 'POST',
      payload: jsonEncode({
        ...expense.toApiMap(),
        'local_id': expense.id,
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  Future<void> updateTransaction({
    required String localId,
    String? serverId,
    required String type,
    required double amount,
    required String description,
    String? note,
    required DateTime date,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    String? receiptImageUrl,
  }) async {
    final isPremium = await LocalStorage.isPremium();
    final serverIntId = serverId != null ? int.tryParse(serverId) : null;

    if (!isPremium) {
      // Free user: local update only
      final existing = await _expenseDao.getById(localId);
      if (existing == null) return;
      final updated = existing.copyWith(
        title: description,
        amount: amount,
        note: note,
        expenseDate: date.millisecondsSinceEpoch,
        type: type,
        categoryId: categoryId,
        clearCategoryId: categoryId == null,
        subCategoryId: subCategoryId,
        clearSubCategoryId: subCategoryId == null,
        walletId: walletId,
        clearWalletId: walletId == null,
        receiptImageUrl: receiptImageUrl,
        clearReceiptImageUrl: receiptImageUrl == null,
      );
      await _expenseDao.update(updated);
      return;
    }

    // Premium: try API first
    if (await _connectivity.isOnline() && serverIntId != null) {
      try {
        final dateStr =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        await TransactionService.updateTransaction(
          id: serverIntId,
          type: type,
          amount: amount,
          description: description,
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          walletId: walletId != null ? int.tryParse(walletId) : null,
          date: dateStr,
          receiptImageUrl: receiptImageUrl,
        );
        final existing = await _expenseDao.getById(localId);
        if (existing != null) {
          final updated = existing.copyWith(
            title: description,
            amount: amount,
            note: note,
            expenseDate: date.millisecondsSinceEpoch,
            type: type,
            categoryId: categoryId,
            clearCategoryId: categoryId == null,
            subCategoryId: subCategoryId,
            clearSubCategoryId: subCategoryId == null,
            walletId: walletId,
            clearWalletId: walletId == null,
            receiptImageUrl: receiptImageUrl,
            clearReceiptImageUrl: receiptImageUrl == null,
            syncStatus: 'synced',
          );
          await _expenseDao.update(updated);
        }
        return;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Premium offline or no server ID: update locally and queue
    final existing = await _expenseDao.getById(localId);
    if (existing == null) return;
    final updated = existing.copyWith(
      title: description,
      amount: amount,
      note: note,
      expenseDate: date.millisecondsSinceEpoch,
      type: type,
      categoryId: categoryId,
      clearCategoryId: categoryId == null,
      subCategoryId: subCategoryId,
      clearSubCategoryId: subCategoryId == null,
      walletId: walletId,
      clearWalletId: walletId == null,
      receiptImageUrl: receiptImageUrl,
      clearReceiptImageUrl: receiptImageUrl == null,
      syncStatus: serverIntId != null ? 'pending' : 'local',
    );
    await _expenseDao.update(updated);

    if (serverIntId != null) {
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _syncQueueDao.enqueue(SyncItem(
        operation: 'update_transaction',
        endpoint: '/api/transactions/$serverIntId',
        httpMethod: 'PUT',
        payload: jsonEncode({
          'type': type,
          'amount': amount,
          'description': description,
          'date': dateStr,
          'category_id': categoryId,
          'sub_category_id': subCategoryId,
          'wallet_id': walletId != null ? int.tryParse(walletId) : null,
          'receipt_image_url': receiptImageUrl,
          'local_id': localId,
        }),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }

  }

  @override
  Future<void> deleteTransaction({
    required String localId,
    String? serverId,
  }) async {
    final isPremium = await LocalStorage.isPremium();
    final serverIntId = serverId != null ? int.tryParse(serverId) : null;

    if (!isPremium) {
      // Free user: hard delete immediately
      await _expenseDao.hardDelete(localId);
      return;
    }

    // Premium: try API first
    if (await _connectivity.isOnline() && serverIntId != null) {
      try {
        await TransactionService.deleteTransaction(serverIntId);
        await _expenseDao.hardDelete(localId);
        return;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Premium offline: soft-delete locally; queue if has server ID
    await _expenseDao.softDelete(localId);
    if (serverIntId != null) {
      await _syncQueueDao.enqueue(SyncItem(
        operation: 'delete_transaction',
        endpoint: '/api/transactions/$serverIntId',
        httpMethod: 'DELETE',
        payload: jsonEncode({'local_id': localId, 'server_id': serverIntId}),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }
}
