class AiMessage {
  final String role; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;

  const AiMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

class AiChatState {
  final List<AiMessage> messages;
  final bool loading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.loading = false,
    this.error,
  });

  AiChatState copyWith({
    List<AiMessage>? messages,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      AiChatState(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}
