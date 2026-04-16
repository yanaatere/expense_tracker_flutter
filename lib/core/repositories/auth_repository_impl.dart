import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../database/daos/auth_cache_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import '../models/auth_cache_entry.dart';
import '../models/sync_item.dart';
import '../services/auth_service.dart';
import '../storage/local_storage.dart';
import '../sync/connectivity_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthCacheDao _authCacheDao;
  final SyncQueueDao _syncQueueDao;
  final ConnectivityService _connectivity;

  static const _salt = 'monex_salt_v1';
  static final _googleSignIn = GoogleSignIn();

  AuthRepositoryImpl({
    required AuthCacheDao authCacheDao,
    required SyncQueueDao syncQueueDao,
    required ConnectivityService connectivity,
  })  : _authCacheDao = authCacheDao,
        _syncQueueDao = syncQueueDao,
        _connectivity = connectivity;

  String _hashPassword(String email, String password) {
    final input = '$email:$password:$_salt';
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final online = await _connectivity.isOnline();

    if (online) {
      try {
        final data = await AuthService.login(email: email, password: password);
        final token = data['token'] as String;
        final username = data['username'] as String;
        final isPremium = data['is_premium'] as bool? ?? false;
        await LocalStorage.saveToken(token);
        await LocalStorage.saveUsername(username);
        await LocalStorage.setPremium(isPremium);
        await LocalStorage.setOnboardingCompleted();
        try {
          final hash = _hashPassword(email, password);
          await _authCacheDao.upsert(AuthCacheEntry(
            id: 1,
            userId: data['id']?.toString() ?? '',
            username: username,
            email: email,
            passwordHash: hash,
            token: token,
            tokenSavedAt: DateTime.now().millisecondsSinceEpoch,
            syncedAt: DateTime.now().millisecondsSinceEpoch,
            isPremium: isPremium,
          ));
        } catch (e) {
          debugPrint('[AuthRepository] Failed to cache credentials: $e');
        }
        return AuthResult.online(token: token, username: username);
      } on DioException catch (e) {
        return AuthResult.failure(AuthService.errorMessage(e));
      } on Exception catch (e) {
        return AuthResult.failure(e.toString());
      }
    } else {
      final cached = await _authCacheDao.get();
      if (cached == null) {
        return AuthResult.failure('No network and no cached credentials');
      }
      final hash = _hashPassword(email, password);
      if (hash != cached.passwordHash) {
        return AuthResult.failure('Incorrect credentials (offline mode)');
      }
      await LocalStorage.saveUsername(cached.username);
      await LocalStorage.setPremium(cached.isPremium);
      await LocalStorage.setOnboardingCompleted();
      if (cached.token != null) {
        await LocalStorage.saveToken(cached.token!);
      }
      return AuthResult.offline(username: cached.username);
    }
  }

  @override
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final online = await _connectivity.isOnline();

    if (online) {
      try {
        final data = await AuthService.register(
          username: username,
          email: email,
          password: password,
        );
        try {
          final hash = _hashPassword(email, password);
          await _authCacheDao.upsert(AuthCacheEntry(
            id: 1,
            userId: data['id']?.toString() ?? '',
            username: username,
            email: email,
            passwordHash: hash,
            token: data['token'] as String?,
            tokenSavedAt: DateTime.now().millisecondsSinceEpoch,
            syncedAt: DateTime.now().millisecondsSinceEpoch,
          ));
        } catch (e) {
          debugPrint('[AuthRepository] Failed to cache credentials after register: $e');
        }
        if (data['token'] != null) {
          await LocalStorage.saveToken(data['token'] as String);
        }
        await LocalStorage.saveUsername(username);
        return AuthResult.online(username: username);
      } on DioException catch (e) {
        return AuthResult.failure(AuthService.errorMessage(e));
      } on Exception catch (e) {
        return AuthResult.failure(e.toString());
      }
    } else {
      final payload = jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      });
      await _syncQueueDao.enqueue(SyncItem(
        operation: 'register',
        endpoint: '/auth/register',
        httpMethod: 'POST',
        payload: payload,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      final hash = _hashPassword(email, password);
      await _authCacheDao.upsert(AuthCacheEntry(
        id: 1,
        userId: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        email: email,
        passwordHash: hash,
        syncedAt: null,
      ));
      await LocalStorage.saveUsername(username);
      return AuthResult.pending(username: username);
    }
  }

  @override
  Future<AuthResult> loginWithGoogle() async {
    try {
      // Sign out first to force account picker on every call.
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return AuthResult.failure('Sign in cancelled');
      }
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return AuthResult.failure('Failed to get Google ID token');
      }

      final data = await AuthService.loginWithGoogle(idToken: idToken);
      final token = data['token'] as String;
      final username = data['username'] as String;
      final isPremium = data['is_premium'] as bool? ?? false;
      await LocalStorage.saveToken(token);
      await LocalStorage.saveUsername(username);
      await LocalStorage.setPremium(isPremium);
      await LocalStorage.setOnboardingCompleted();
      try {
        await _authCacheDao.upsert(AuthCacheEntry(
          id: 1,
          userId: data['id']?.toString() ?? '',
          username: username,
          email: data['email'] as String? ?? '',
          passwordHash: '',
          token: token,
          tokenSavedAt: DateTime.now().millisecondsSinceEpoch,
          syncedAt: DateTime.now().millisecondsSinceEpoch,
          isPremium: isPremium,
        ));
      } catch (e) {
        debugPrint('[AuthRepository] Failed to cache Google credentials: $e');
      }
      return AuthResult.online(token: token, username: username);
    } on DioException catch (e) {
      return AuthResult.failure(AuthService.errorMessage(e));
    } on Exception catch (e) {
      debugPrint('[AuthRepository] Google sign-in error: $e');
      return AuthResult.failure('Google sign in failed. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await LocalStorage.clearAll();
    // auth_cache is intentionally preserved for future offline login
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await LocalStorage.getToken();
    return token != null;
  }
}
