import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/ai_service.dart';
import 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatState> {
  AiChatCubit() : super(const AiChatState());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.loading) return;

    final userMsg = AiMessage(
      role: 'user',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMsg],
      loading: true,
      clearError: true,
    ));

    try {
      // Build history for context (exclude the message just added)
      final history = state.messages
          .map((m) => {'role': m.role, 'text': m.text})
          .toList();

      final reply = await AiService.chat(text.trim(), history);

      if (isClosed) return;

      final aiMsg = AiMessage(
        role: 'ai',
        text: reply,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, aiMsg],
        loading: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        loading: false,
        error: 'Failed to get a response. Please try again.',
      ));
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));
}
