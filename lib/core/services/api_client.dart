import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Called when the server returns 401. Wire this up in app.dart to
  /// clear local state and navigate to /signin.
  static VoidCallback? onUnauthorized;

  static final Dio dio = _buildDio();

  /// Replaces `localhost` in a media URL with the same host as [_baseUrl].
  ///
  /// The backend stores MinIO URLs as `http://localhost:9000/...`. On an
  /// Android emulator `localhost` resolves to the device itself, not the dev
  /// machine.  By swapping the host to match the API base URL we ensure media
  /// loads correctly on every platform.
  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    final mediaUri = Uri.tryParse(url);
    if (mediaUri == null || mediaUri.host != 'localhost') return url;
    final apiUri = Uri.tryParse(_baseUrl);
    if (apiUri == null) return url;
    return mediaUri.replace(host: apiUri.host).toString();
  }

  static Dio _buildDio() {
    final d = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (kDebugMode) {
      d.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
          logPrint: (o) => debugPrint('[API] $o'),
        ),
      );
    }

    d.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await LocalStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await LocalStorage.clearAll();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );

    return d;
  }
}
