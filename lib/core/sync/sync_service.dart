import 'dart:convert';

import 'package:dio/dio.dart';

import '../database/daos/auth_cache_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import '../storage/local_storage.dart';

class SyncService {
  final SyncQueueDao _syncQueueDao;
  final AuthCacheDao _authCacheDao;
  final Dio _dio;

  SyncService({
    required SyncQueueDao syncQueueDao,
    required AuthCacheDao authCacheDao,
    required Dio dio,
  })  : _syncQueueDao = syncQueueDao,
        _authCacheDao = authCacheDao,
        _dio = dio;

  Future<void> processQueue() async {
    final items = await _syncQueueDao.getPending();
    for (final item in items) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        final response = await _dio.request<dynamic>(
          item.endpoint,
          data: payload,
          options: Options(method: item.httpMethod),
        );

        if (item.operation == 'register') {
          final data = response.data;
          if (data is Map<String, dynamic>) {
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
}
