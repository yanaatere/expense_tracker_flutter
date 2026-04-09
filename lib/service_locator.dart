import 'dart:async';

import 'package:flutter/material.dart';
import 'core/database/app_database.dart';
import 'core/dao/budget_dao.dart';
import 'core/database/daos/auth_cache_dao.dart';
import 'core/database/daos/recurring_transaction_dao.dart';
import 'core/database/daos/sync_queue_dao.dart';
import 'core/database/daos/wallet_dao.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/auth_repository_impl.dart';
import 'core/repositories/wallet_repository.dart';
import 'core/repositories/wallet_repository_impl.dart';
import 'core/services/api_client.dart';
import 'core/storage/local_storage.dart';
import 'core/sync/connectivity_service.dart';
import 'core/sync/sync_service.dart';

class ServiceLocator {
  static late ConnectivityService connectivity;
  static late SyncService syncService;
  static late AuthRepository authRepository;
  static late WalletRepository walletRepository;
  static late RecurringTransactionDao recurringTransactionDao;
  static late BudgetDao budgetDao;
  static late ValueNotifier<Locale> localeNotifier;
  static late ValueNotifier<ThemeMode> themeNotifier;
  static late ValueNotifier<String?> cardThemeNotifier;
  static StreamSubscription<bool>? _connectivitySubscription;

  static Future<void> setup() async {
    await LocalStorage.clearStaleKeychainIfNeeded();

    final db = await AppDatabase.database;

    final savedLocale = await LocalStorage.getLocale();
    localeNotifier = ValueNotifier(Locale(savedLocale ?? 'en'));

    final savedCardTheme = await LocalStorage.getDefaultCardTheme();
    cardThemeNotifier = ValueNotifier(savedCardTheme);

    final savedTheme = await LocalStorage.getThemeMode();
    themeNotifier = ValueNotifier(
      savedTheme == 'dark'
          ? ThemeMode.dark
          : savedTheme == 'light'
              ? ThemeMode.light
              : ThemeMode.system,
    );

    connectivity = ConnectivityService();

    final syncQueueDao = SyncQueueDao(db);
    final walletDao = WalletDao(db);
    final authCacheDao = AuthCacheDao(db);
    recurringTransactionDao = RecurringTransactionDao(db);
    budgetDao = BudgetDao(db);

    syncService = SyncService(
      syncQueueDao: syncQueueDao,
      authCacheDao: authCacheDao,
      walletDao: walletDao,
      dio: ApiClient.dio,
    );

    authRepository = AuthRepositoryImpl(
      authCacheDao: authCacheDao,
      syncQueueDao: syncQueueDao,
      connectivity: connectivity,
    );

    walletRepository = WalletRepositoryImpl(
      walletDao: walletDao,
      authCacheDao: authCacheDao,
      syncQueueDao: syncQueueDao,
      connectivity: connectivity,
    );

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((online) {
      if (online) syncService.processQueue();
    });
  }

  static Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
