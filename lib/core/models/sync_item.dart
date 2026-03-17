class SyncItem {
  final int? id;
  final String operation;
  final String endpoint;
  final String httpMethod;
  final String payload;
  final int createdAt;
  final int retryCount;
  final String? lastError;
  final String status;

  const SyncItem({
    this.id,
    required this.operation,
    required this.endpoint,
    required this.httpMethod,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'operation': operation,
        'endpoint': endpoint,
        'http_method': httpMethod,
        'payload': payload,
        'created_at': createdAt,
        'retry_count': retryCount,
        'last_error': lastError,
        'status': status,
      };

  factory SyncItem.fromMap(Map<String, dynamic> map) => SyncItem(
        id: map['id'] as int?,
        operation: map['operation'] as String,
        endpoint: map['endpoint'] as String,
        httpMethod: map['http_method'] as String,
        payload: map['payload'] as String,
        createdAt: map['created_at'] as int,
        retryCount: map['retry_count'] as int? ?? 0,
        lastError: map['last_error'] as String?,
        status: map['status'] as String? ?? 'pending',
      );
}
