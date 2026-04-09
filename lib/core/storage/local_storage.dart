import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'username';
  static const _emailKey = 'email';
  static const _localeKey = 'locale';
  static const _onboardingKey = 'onboarding_completed';
  static const _lastActiveKey = 'last_active_at';
  static const _appInstalledKey = 'app_installed';
  static const _pinKey = 'user_pin';
  static const _pinEnabledKey = 'pin_enabled';
  static const sessionTimeout = Duration(minutes: 5);

  // ── Token (secure storage) ──────────────────────────────────────────────────

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  // ── Username (shared prefs) ─────────────────────────────────────────────────

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // ── Email (shared prefs) ────────────────────────────────────────────────────

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // ── Locale (shared prefs) ───────────────────────────────────────────────────

  static Future<void> saveLocale(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, langCode);
  }

  static Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  // ── Onboarding (shared prefs) ────────────────────────────────────────────────

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // ── Fresh install detection ──────────────────────────────────────────────────
  // SharedPreferences is wiped on reinstall, but iOS Keychain (FlutterSecureStorage)
  // persists. If app_installed flag is missing, it's a fresh install — clear the
  // stale Keychain token so the user starts from scratch.

  static Future<void> clearStaleKeychainIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final installed = prefs.getBool(_appInstalledKey) ?? false;
    if (!installed) {
      await _storage.deleteAll();
      await prefs.setBool(_appInstalledKey, true);
    }
  }

  // ── Last active (shared prefs) ───────────────────────────────────────────────

  static Future<void> saveLastActiveAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getInt(_lastActiveKey);
    if (lastActive == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastActive;
    return elapsed > sessionTimeout.inMilliseconds;
  }

  static Future<void> clearLastActiveAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActiveKey);
  }

  // ── PIN (secure storage) ────────────────────────────────────────────────────

  static Future<void> savePin(String pin) => _storage.write(key: _pinKey, value: pin);
  static Future<String?> getPin() => _storage.read(key: _pinKey);
  static Future<void> clearPin() => _storage.delete(key: _pinKey);

  // ── Avatar path (shared prefs) ──────────────────────────────────────────────

  static const _avatarPathKey = 'avatar_path';

  static Future<void> saveAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPathKey, path);
  }

  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarPathKey);
  }

  static Future<void> clearAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarPathKey);
  }

  // ── PIN enabled flag (shared prefs) ─────────────────────────────────────────

  static Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
  }

  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  // ── Theme mode (shared prefs) ───────────────────────────────────────────────

  static const _themeModeKey = 'theme_mode';

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  // ── Premium (shared prefs) ──────────────────────────────────────────────────

  static const _isPremiumKey = 'is_premium';

  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, value);
  }

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPremiumKey) ?? false;
  }

  // ── Clear all ───────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await clearToken();
    await clearPin();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_onboardingKey);
    await prefs.remove(_lastActiveKey);
    await prefs.remove(_pinEnabledKey);
  }
}
