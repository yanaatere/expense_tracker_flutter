import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../database/daos/auth_cache_dao.dart';
import '../database/daos/recurring_transaction_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import '../models/recurring_transaction.dart';
import '../models/sync_item.dart';
import '../services/recurring_transaction_service.dart';
import '../storage/local_storage.dart';
import '../sync/connectivity_service.dart';
import 'recurring_repository.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringTransactionDao _recurringDao;
  final AuthCacheDao _authCacheDao;
  final SyncQueueDao _syncQueueDao;
  final ConnectivityService _connectivity;

  RecurringRepositoryImpl({
    required RecurringTransactionDao recurringDao,
    required AuthCacheDao authCacheDao,
    required SyncQueueDao syncQueueDao,
    required ConnectivityService connectivity,
  })  : _recurringDao = recurringDao,
        _authCacheDao = authCacheDao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity;

  Future<String> get _userId async {
    final entry = await _authCacheDao.get();
    return entry?.userId ?? 'local';
  }

  @override
  Future<List<RecurringTransaction>> getAll() async {
    final userId = await _userId;
    final isPremium = await LocalStorage.isPremium();

    if (isPremium && await _connectivity.isOnline()) {
      try {
        final raw = await RecurringTransactionService.getAll();
        final items = raw.map((m) => RecurringTransaction.fromApi(m, userId)).toList();
        await _recurringDao.upsertAll(items);
      } catch (e) {
        debugPrint('[RecurringRepository] Remote fetch failed, using local: $e');
      }
    }

    return _recurringDao.getAll(userId);
  }

  @override
  Future<RecurringTransaction> create({
    required String title,
    required String type,
    required double amount,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    required String frequency,
    required String startDate,
    String? endDate,
  }) async {
    final userId = await _userId;
    final isPremium = await LocalStorage.isPremium();

    if (!isPremium) {
      // Free user: local only
      final rt = RecurringTransaction.create(
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
      );
      await _recurringDao.insert(rt);
      return rt;
    }

    // Premium: try API first
    if (await _connectivity.isOnline()) {
      try {
        final raw = await RecurringTransactionService.create(
          title: title,
          type: type,
          amount: amount,
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          walletId: walletId != null ? int.tryParse(walletId) : null,
          frequency: frequency,
          startDate: startDate,
          endDate: endDate,
        );
        final rt = RecurringTransaction.fromApi(raw, userId);
        await _recurringDao.insert(rt);
        return rt;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Premium offline: save locally and queue
    final rt = RecurringTransaction.create(
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
    );
    await _recurringDao.insert(rt);
    await _syncQueueDao.enqueue(SyncItem(
      operation: 'create_recurring',
      endpoint: '/api/recurring-transactions',
      httpMethod: 'POST',
      payload: jsonEncode({
        ...rt.toApiMap(),
        'local_id': rt.id,
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    return rt;
  }

  @override
  Future<RecurringTransaction> update({
    required RecurringTransaction original,
    required String title,
    required String type,
    required double amount,
    int? categoryId,
    int? subCategoryId,
    String? walletId,
    required String frequency,
    required String startDate,
    String? endDate,
  }) async {
    final isPremium = await LocalStorage.isPremium();
    final serverIntId =
        original.serverId != null ? int.tryParse(original.serverId!) : null;

    final updatedLocal = original.copyWith(
      title: title,
      type: type,
      amount: amount,
      categoryId: categoryId,
      clearCategoryId: categoryId == null,
      subCategoryId: subCategoryId,
      clearSubCategoryId: subCategoryId == null,
      walletId: walletId,
      clearWalletId: walletId == null,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      clearEndDate: endDate == null || endDate.isEmpty,
      syncStatus: (!isPremium || serverIntId == null) ? 'local' : 'pending',
    );

    if (!isPremium) {
      await _recurringDao.update(updatedLocal);
      return updatedLocal;
    }

    // Premium: try API first
    if (await _connectivity.isOnline() && serverIntId != null) {
      try {
        await RecurringTransactionService.update(
          id: serverIntId,
          title: title,
          type: type,
          amount: amount,
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          walletId: walletId != null ? int.tryParse(walletId) : null,
          frequency: frequency,
          startDate: startDate,
          endDate: endDate,
        );
        final synced = updatedLocal.copyWith(syncStatus: 'synced');
        await _recurringDao.update(synced);
        return synced;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Premium offline or no server ID: update locally and queue
    await _recurringDao.update(updatedLocal);
    if (serverIntId != null) {
      await _syncQueueDao.enqueue(SyncItem(
        operation: 'update_recurring',
        endpoint: '/api/recurring-transactions/$serverIntId',
        httpMethod: 'PUT',
        payload: jsonEncode({
          ...updatedLocal.toApiMap(),
          'local_id': original.id,
        }),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    return updatedLocal;
  }

  @override
  Future<void> delete(RecurringTransaction rt) async {
    final isPremium = await LocalStorage.isPremium();
    final serverIntId =
        rt.serverId != null ? int.tryParse(rt.serverId!) : null;

    if (!isPremium) {
      await _recurringDao.delete(rt.id);
      return;
    }

    // Premium: try API first
    if (await _connectivity.isOnline() && serverIntId != null) {
      try {
        await RecurringTransactionService.delete(serverIntId);
        await _recurringDao.delete(rt.id);
        return;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Premium offline: delete locally and queue if has server ID
    await _recurringDao.delete(rt.id);
    if (serverIntId != null) {
      await _syncQueueDao.enqueue(SyncItem(
        operation: 'delete_recurring',
        endpoint: '/api/recurring-transactions/$serverIntId',
        httpMethod: 'DELETE',
        payload: jsonEncode({'server_id': serverIntId, 'local_id': rt.id}),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }
}
