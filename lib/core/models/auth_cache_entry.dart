class AuthCacheEntry {
  final int? id;
  final String userId;
  final String username;
  final String email;
  final String passwordHash;
  final String? token;
  final int? tokenSavedAt;
  final int? syncedAt;
  final bool isPremium;

  const AuthCacheEntry({
    this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.passwordHash,
    this.token,
    this.tokenSavedAt,
    this.syncedAt,
    this.isPremium = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id ?? 1,
        'user_id': userId,
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'token': token,
        'token_saved_at': tokenSavedAt,
        'synced_at': syncedAt,
        'is_premium': isPremium ? 1 : 0,
      };

  factory AuthCacheEntry.fromMap(Map<String, dynamic> map) => AuthCacheEntry(
        id: map['id'] as int?,
        userId: map['user_id'] as String,
        username: map['username'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        token: map['token'] as String?,
        tokenSavedAt: map['token_saved_at'] as int?,
        syncedAt: map['synced_at'] as int?,
        isPremium: (map['is_premium'] as int? ?? 0) == 1,
      );
}
