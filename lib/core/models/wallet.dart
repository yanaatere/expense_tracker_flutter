import 'dart:math';

class Wallet {
  final String id;
  final String? serverId;
  final String userId;
  final String name;
  final String type; // 'Bank', 'E-Wallet', 'Cash'
  final String currency; // 'IDR', 'USD', 'EUR'
  final double balance;
  final String? goals;
  final String syncStatus; // 'local', 'synced', 'pending'
  final int createdAt;
  final int updatedAt;

  const Wallet({
    required this.id,
    this.serverId,
    required this.userId,
    required this.name,
    required this.type,
    required this.currency,
    required this.balance,
    this.goals,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.create({
    required String userId,
    required String name,
    required String type,
    required String currency,
    required double balance,
    String? goals,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Wallet(
      id: _generateId(),
      userId: userId,
      name: name,
      type: type,
      currency: currency,
      balance: balance,
      goals: goals,
      syncStatus: 'local',
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'server_id': serverId,
        'user_id': userId,
        'name': name,
        'type': type,
        'currency': currency,
        'balance': balance,
        'goals': goals,
        'sync_status': syncStatus,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Wallet.fromMap(Map<String, dynamic> map) => Wallet(
        id: map['id'] as String,
        serverId: map['server_id'] as String?,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        currency: map['currency'] as String? ?? 'IDR',
        balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
        goals: map['goals'] as String?,
        syncStatus: map['sync_status'] as String? ?? 'local',
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );

  static String _generateId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Wallet copyWith({
    String? serverId,
    String? syncStatus,
    String? name,
    String? type,
    String? currency,
    double? balance,
    String? goals,
  }) =>
      Wallet(
        id: id,
        serverId: serverId ?? this.serverId,
        userId: userId,
        name: name ?? this.name,
        type: type ?? this.type,
        currency: currency ?? this.currency,
        balance: balance ?? this.balance,
        goals: goals ?? this.goals,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
}
