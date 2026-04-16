import 'dart:convert';

import 'package:dio/dio.dart';

import '../database/daos/auth_cache_dao.dart';
import '../database/daos/expense_dao.dart';
import '../database/daos/recurring_transaction_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import '../database/daos/wallet_dao.dart';
import '../models/expense.dart';
import '../models/recurring_transaction.dart';
import '../models/sync_item.dart';
import '../storage/local_storage.dart';

class SyncService {
  final SyncQueueDao _syncQueueDao;
  final AuthCacheDao _authCacheDao;
  final WalletDao _walletDao;
  final ExpenseDao _expenseDao;
  final RecurringTransactionDao _recurringTransactionDao;
  final Dio _dio;

  SyncService({
    required SyncQueueDao syncQueueDao,
    required AuthCacheDao authCacheDao,
    required WalletDao walletDao,
    required ExpenseDao expenseDao,
    required RecurringTransactionDao recurringTransactionDao,
    required Dio dio,
  })  : _syncQueueDao = syncQueueDao,
        _authCacheDao = authCacheDao,
        _walletDao = walletDao,
        _expenseDao = expenseDao,
        _recurringTransactionDao = recurringTransactionDao,
        _dio = dio;

  Future<void> processQueue() async {
    final items = await _syncQueueDao.getPending();
    for (final item in items) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        final response = await _dio.request<dynamic>(
          item.endpoint,
          data: item.httpMethod == 'DELETE' ? null : payload,
          options: Options(method: item.httpMethod),
        );

        switch (item.operation) {
          case 'register':
            final envelope = response.data;
            if (envelope is Map<String, dynamic>) {
              final data = envelope['data'] as Map<String, dynamic>? ?? {};
              final serverId = data['id']?.toString() ?? '';
              final token = data['token'] as String?;
              if (token != null) {
                await _authCacheDao.updateAfterSync(
                  serverId: serverId,
                  token: token,
                  syncedAt: DateTime.now().millisecondsSinceEpoch,
                );
                await LocalStorage.saveToken(token);
              }
            }

          case 'create_wallet':
            final envelope = response.data;
            if (envelope is Map<String, dynamic>) {
              final data = envelope['data'] as Map<String, dynamic>? ?? {};
              final serverId = data['id']?.toString();
              final localId = payload['local_id'] as String?;
              if (serverId != null && localId != null) {
                await _walletDao.updateSyncStatus(localId, serverId, 'synced');
              }
            }

          case 'update_wallet':
          case 'delete_wallet':
            break;

          case 'create_transaction':
            final envelope = response.data;
            if (envelope is Map<String, dynamic>) {
              final data = envelope['data'] as Map<String, dynamic>? ?? {};
              final serverId = data['id']?.toString();
              final localId = payload['local_id'] as String?;
              if (serverId != null && localId != null) {
                await _expenseDao.updateSyncStatus(localId, serverId, 'synced');
              }
            }

          case 'update_transaction':
            break;

          case 'delete_transaction':
            final localId = payload['local_id'] as String?;
            if (localId != null) {
              await _expenseDao.hardDelete(localId);
            }

          case 'create_recurring':
            final envelope = response.data;
            if (envelope is Map<String, dynamic>) {
              final data = envelope['data'] as Map<String, dynamic>? ?? {};
              final serverId = data['id']?.toString();
              final localId = payload['local_id'] as String?;
              if (serverId != null && localId != null) {
                await _recurringTransactionDao.updateSyncStatus(
                    localId, serverId, 'synced');
              }
            }

          case 'update_recurring':
          case 'delete_recurring':
            break;
        }

        await _syncQueueDao.markDone(item.id!);
      } on DioException catch (e) {
        await _syncQueueDao.incrementRetry(
          item.id!,
          e.message ?? e.toString(),
        );
      } catch (e) {
        await _syncQueueDao.incrementRetry(item.id!, e.toString());
      }
    }
  }

  /// Prune old/stale local SQLite data for premium users.
  /// Returns a [MaintenanceResult] describing what was deleted.
  Future<MaintenanceResult> maintenanceLocalData(
      String userId, int retentionMonths) async {
    if (retentionMonths == 0) {
      return MaintenanceResult(deletedExpenses: 0, deletedQueueItems: 0);
    }

    final cutoffMs = DateTime.now()
        .subtract(Duration(days: retentionMonths * 30))
        .millisecondsSinceEpoch;

    // 1. Count + hard-delete soft-deleted synced rows
    final softDeleted = await _expenseDao.countSoftDeleted(userId);
    await _expenseDao.hardDeleteSoftDeleted(userId);

    // 2. Count + hard-delete old synced rows beyond retention window
    final oldSynced = await _expenseDao.countOldSynced(userId, cutoffMs);
    await _expenseDao.hardDeleteOldSynced(userId, cutoffMs);

    // 3. Purge stale sync_queue entries (done/failed older than 7 days)
    final queueCutoffMs = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    final deletedQueue = await _syncQueueDao.purgeStale(queueCutoffMs);

    return MaintenanceResult(
      deletedExpenses: softDeleted + oldSynced,
      deletedQueueItems: deletedQueue,
    );
  }

  /// Pull all server data into local SQLite (best-effort, premium only).
  Future<void> pullSync(String userId) async {
    // Pull transactions
    try {
      final response = await _dio.get<dynamic>('/api/transactions');
      final envelope = response.data as Map<String, dynamic>?;
      final list = (envelope?['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final expenses = list.map((m) => Expense.fromApi(m, userId)).toList();
      await _expenseDao.upsertAll(expenses);
    } catch (_) {}

    // Pull recurring transactions
    try {
      final response = await _dio.get<dynamic>('/api/recurring-transactions');
      final envelope = response.data as Map<String, dynamic>?;
      final list = (envelope?['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final items =
          list.map((m) => RecurringTransaction.fromApi(m, userId)).toList();
      await _recurringTransactionDao.upsertAll(items);
    } catch (_) {}
  }

  /// Bulk-push all local (unsynced) data to the API. Called when a free user
  /// activates premium. Wallets are pushed first so their server IDs are
  /// available before transaction sync.
  Future<void> bulkPushLocalData() async {
    final entry = await _authCacheDao.get();
    if (entry == null) return;
    final userId = entry.userId;

    // 1. Push unsynced wallets
    final wallets = await _walletDao.getUnsynced(userId);
    for (final wallet in wallets) {
      try {
        final response = await _dio.post<dynamic>(
          '/api/wallets',
          data: {
            'name': wallet.name,
            'type': wallet.type,
            'currency': wallet.currency,
            'balance': wallet.balance,
            if (wallet.goals != null && wallet.goals!.isNotEmpty)
              'goals': wallet.goals,
          },
        );
        final data =
            (response.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?;
        final serverId = data?['id']?.toString();
        if (serverId != null) {
          await _walletDao.updateSyncStatus(wallet.id, serverId, 'synced');
        }
      } catch (_) {
        await _syncQueueDao.enqueue(SyncItem(
          operation: 'create_wallet',
          endpoint: '/api/wallets',
          httpMethod: 'POST',
          payload: jsonEncode({
            'local_id': wallet.id,
            'name': wallet.name,
            'type': wallet.type,
            'currency': wallet.currency,
            'balance': wallet.balance,
            if (wallet.goals != null) 'goals': wallet.goals,
          }),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }

    // 2. Push unsynced transactions
    final expenses = await _expenseDao.getUnsynced(userId);
    for (final expense in expenses) {
      try {
        final response = await _dio.post<dynamic>(
          '/api/transactions',
          data: expense.toApiMap(),
        );
        final data =
            (response.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?;
        final serverId = data?['id']?.toString();
        if (serverId != null) {
          await _expenseDao.updateSyncStatus(expense.id, serverId, 'synced');
        }
      } catch (_) {
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
    }

    // 3. Push unsynced recurring transactions
    final recurring = await _recurringTransactionDao.getUnsynced(userId);
    for (final rt in recurring) {
      try {
        final response = await _dio.post<dynamic>(
          '/api/recurring-transactions',
          data: rt.toApiMap(),
        );
        final data =
            (response.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?;
        final serverId = data?['id']?.toString();
        if (serverId != null) {
          await _recurringTransactionDao.updateSyncStatus(rt.id, serverId, 'synced');
        }
      } catch (_) {
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
      }
    }

    // 4. Pull server data and process any queued retries
    await pullSync(userId);
    await processQueue();
  }
}

// ---------------------------------------------------------------------------
// MaintenanceResult
// ---------------------------------------------------------------------------

class MaintenanceResult {
  final int deletedExpenses;
  final int deletedQueueItems;

  const MaintenanceResult({
    required this.deletedExpenses,
    required this.deletedQueueItems,
  });

  int get total => deletedExpenses + deletedQueueItems;
}
