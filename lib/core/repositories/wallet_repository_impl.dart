import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../database/daos/auth_cache_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import '../database/daos/wallet_dao.dart';
import '../models/sync_item.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../sync/connectivity_service.dart';
import 'wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletDao _walletDao;
  final AuthCacheDao _authCacheDao;
  final SyncQueueDao _syncQueueDao;
  final ConnectivityService _connectivity;

  WalletRepositoryImpl({
    required WalletDao walletDao,
    required AuthCacheDao authCacheDao,
    required SyncQueueDao syncQueueDao,
    required ConnectivityService connectivity,
  })  : _walletDao = walletDao,
        _authCacheDao = authCacheDao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity;

  Future<String> get _userId async {
    final entry = await _authCacheDao.get();
    return entry?.userId ?? 'local';
  }

  Wallet _fromApiMap(Map<String, dynamic> m, String userId) => Wallet(
        id: m['id']?.toString() ?? '',
        serverId: m['id']?.toString(),
        userId: userId,
        name: m['name'] as String? ?? '',
        type: m['type'] as String? ?? 'Bank',
        currency: m['currency'] as String? ?? 'IDR',
        balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
        goals: m['goals'] as String?,
        backdropImage: m['backdrop_image'] as String?,
        syncStatus: 'synced',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

  @override
  Future<List<Wallet>> getWallets() async {
    final userId = await _userId;

    if (await _connectivity.isOnline()) {
      try {
        final remote = await WalletService.getWallets();
        final wallets = remote.map((m) => _fromApiMap(m, userId)).toList();
        _walletDao.upsertAll(wallets);
        return wallets;
      } catch (e) {
        debugPrint('[WalletRepository] Remote fetch failed, using local cache: $e');
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

    if (await _connectivity.isOnline()) {
      try {
        final data = await WalletService.createWallet(
          name: name,
          type: type,
          currency: currency,
          balance: balance,
          goals: goals,
        );
        final wallet = _fromApiMap(data, userId);
        await _walletDao.insert(wallet);
        return wallet;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Offline: save locally and enqueue for later sync
    final wallet = Wallet.create(
      userId: userId,
      name: name,
      type: type,
      currency: currency,
      balance: balance,
      goals: goals,
    );
    await _walletDao.insert(wallet);
    await _syncQueueDao.enqueue(SyncItem(
      operation: 'create_wallet',
      endpoint: '/api/wallets',
      httpMethod: 'POST',
      payload: jsonEncode({
        'local_id': wallet.id,
        'name': name,
        'type': type,
        'currency': currency,
        'balance': balance,
        if (goals != null && goals.isNotEmpty) 'goals': goals,
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    return wallet;
  }

  @override
  Future<Wallet> updateWallet({
    required Wallet wallet,
    required String name,
    required String type,
    required String currency,
    required double balance,
    String? goals,
    String? backdropImage,
  }) async {
    final userId = await _userId;
    final serverId = wallet.serverId != null ? int.tryParse(wallet.serverId!) : null;

    if (await _connectivity.isOnline() && serverId != null) {
      try {
        final data = await WalletService.updateWallet(
          serverId,
          name: name,
          type: type,
          currency: currency,
          balance: balance,
          goals: goals,
          backdropImage: backdropImage,
        );
        final updated = _fromApiMap(data, userId);
        // Parallel local cache update
        _walletDao.update(updated);
        return updated;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Offline or no server ID: update locally and enqueue
    final updated = wallet.copyWith(
      name: name,
      type: type,
      currency: currency,
      balance: balance,
      goals: goals,
      backdropImage: backdropImage,
      syncStatus: serverId != null ? 'pending' : 'local',
    );
    await _walletDao.update(updated);
    if (serverId != null) {
      await _syncQueueDao.enqueue(SyncItem(
        operation: 'update_wallet',
        endpoint: '/api/wallets/$serverId',
        httpMethod: 'PUT',
        payload: jsonEncode({
          'name': name,
          'type': type,
          'currency': currency,
          'balance': balance,
          'goals': goals ?? '',
        }),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    return updated;
  }

  @override
  Future<void> deleteWallet({required Wallet wallet}) async {
    final serverId = wallet.serverId != null ? int.tryParse(wallet.serverId!) : null;

    if (await _connectivity.isOnline() && serverId != null) {
      try {
        await WalletService.deleteWallet(serverId);
        // Parallel local cache delete
        _walletDao.delete(wallet.id);
        return;
      } on DioException {
        // Fall through to offline path
      }
    }

    // Delete locally always; queue server deletion if we have a server ID
    await _walletDao.delete(wallet.id);
    if (serverId != null) {
      await _syncQueueDao.enqueue(SyncItem(
        operation: 'delete_wallet',
        endpoint: '/api/wallets/$serverId',
        httpMethod: 'DELETE',
        payload: jsonEncode({'server_id': serverId}),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }
}
