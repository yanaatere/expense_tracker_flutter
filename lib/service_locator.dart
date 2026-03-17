import 'core/database/app_database.dart';
import 'core/database/daos/auth_cache_dao.dart';
import 'core/database/daos/sync_queue_dao.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/auth_repository_impl.dart';
import 'core/services/api_client.dart';
import 'core/sync/connectivity_service.dart';
import 'core/sync/sync_service.dart';

class ServiceLocator {
  static late ConnectivityService connectivity;
  static late SyncService syncService;
  static late AuthRepository authRepository;

  static Future<void> setup() async {
    final db = await AppDatabase.database;

    connectivity = ConnectivityService();

    syncService = SyncService(
      syncQueueDao: SyncQueueDao(db),
      authCacheDao: AuthCacheDao(db),
      dio: ApiClient.dio,
    );

    authRepository = AuthRepositoryImpl(
      authCacheDao: AuthCacheDao(db),
      syncQueueDao: SyncQueueDao(db),
      connectivity: connectivity,
    );

    connectivity.onConnectivityChanged.listen((online) {
      if (online) syncService.processQueue();
    });
  }
}
