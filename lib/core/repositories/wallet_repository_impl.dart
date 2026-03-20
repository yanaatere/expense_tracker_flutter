import 'package:dio/dio.dart';

import '../database/daos/auth_cache_dao.dart';
import '../database/daos/wallet_dao.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../sync/connectivity_service.dart';
import 'wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletDao _walletDao;
  final AuthCacheDao _authCacheDao;
  final ConnectivityService _connectivity;

  WalletRepositoryImpl({
    required WalletDao walletDao,
    required AuthCacheDao authCacheDao,
    required ConnectivityService connectivity,
  })  : _walletDao = walletDao,
        _authCacheDao = authCacheDao,
        _connectivity = connectivity;

  Future<String> get _userId async {
    final entry = await _authCacheDao.get();
    return entry?.userId ?? 'local';
  }

  @override
  Future<List<Wallet>> getWallets() async {
    final userId = await _userId;

    if (await _connectivity.isOnline()) {
      try {
        final remote = await WalletService.getWallets();
        final wallets = remote
            .map((m) => Wallet(
                  id: m['id']?.toString() ?? '',
                  serverId: m['id']?.toString(),
                  userId: userId,
                  name: m['name'] as String? ?? '',
                  type: m['type'] as String? ?? 'Bank',
                  currency: m['currency'] as String? ?? 'IDR',
                  balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
                  goals: m['goals'] as String?,
                  syncStatus: 'synced',
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                ))
            .toList();
        await _walletDao.upsertAll(wallets);
      } on DioException {
        // Fall through to local
      }
    }

    return _walletDao.getAll(userId);
  }

  @override
  Future<Wallet> createWallet({
    required String name,
    required String type,
    required String currency,
    required double balance,
    String? goals,
  }) async {
    final userId = await _userId;
    final wallet = Wallet.create(
      userId: userId,
      name: name,
      type: type,
      currency: currency,
      balance: balance,
      goals: goals,
    );

    await _walletDao.insert(wallet);

    if (await _connectivity.isOnline()) {
      try {
        final data = await WalletService.createWallet(
          name: name,
          type: type,
          currency: currency,
          balance: balance,
          goals: goals,
        );
        final serverId = data['id']?.toString();
        if (serverId != null) {
          await _walletDao.updateSyncStatus(wallet.id, serverId, 'synced');
          return wallet.copyWith(serverId: serverId, syncStatus: 'synced');
        }
      } on DioException {
        // Created locally, will sync later
      }
    }

    return wallet;
  }
}
