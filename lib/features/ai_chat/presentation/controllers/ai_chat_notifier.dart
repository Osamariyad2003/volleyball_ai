import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/exceptions/ai_chat_exception.dart';
import '../../data/constants/ai_chat_constants.dart';
import '../../data/models/ai_chat_message.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../data/services/ai_chat_voice_input_service.dart';
import '../state/ai_chat_state.dart';

class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier({
    required AiChatRepositoryImpl repository,
    required AiChatVoiceInputService voiceInputService,
  }) : _repository = repository,
       _voiceInputService = voiceInputService,
       super(AiChatState.initial());

  final AiChatRepositoryImpl _repository;
  final AiChatVoiceInputService _voiceInputService;

  Future<void> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || state.isLoading) {
      return;
    }

    final userMessage = AiChatMessage(
      role: AiChatRole.user,
      content: message,
      timestamp: DateTime.now(),
    );
    final updatedConversation = [...state.messages, userMessage];

    if (_shouldRedirectToExerciseTopics(message)) {
      final redirectMessage = AiChatMessage(
        role: AiChatRole.assistant,
        content: exerciseOnlyRedirectMessage,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...updatedConversation, redirectMessage],
        isLoading: false,
        errorMessage: null,
        liveTranscript: '',
      );
      return;
    }

    state = state.copyWith(
      messages: updatedConversation,
      isLoading: true,
      errorMessage: null,
      liveTranscript: '',
    );

    try {
      final assistantMessage = await _repository.sendMessage(
        conversation: updatedConversation,
        userMessage: message,
      );

      state = state.copyWith(
        messages: [...updatedConversation, assistantMessage],
        isLoading: false,
      );
    } on AiChatException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Something went wrong while building your volleyball workout response. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> startVoiceInput() async {
    if (state.isListening || state.isLoading) {
      return;
    }

    state = state.copyWith(
      isListening: true,
      errorMessage: null,
      liveTranscript: 'Listening for a volleyball exercise request...',
    );

    try {
      await _voiceInputService.startListening(
        onPartial: (text) {
          state = state.copyWith(liveTranscript: text);
        },
        onFinal: (text) {
          state = state.copyWith(isListening: false, liveTranscript: text);
          if (text.trim().isNotEmpty) {
            unawaited(sendMessage(text));
          }
        },
        onDone: () {
          state = state.copyWith(
            isListening: false,
            liveTranscript: state.isLoading ? state.liveTranscript : '',
          );
        },
        onError: (message) {
          state = state.copyWith(
            isListening: false,
            errorMessage: message,
            liveTranscript: '',
          );
        },
      );
    } on AiChatException catch (error) {
      state = state.copyWith(
        isListening: false,
        errorMessage: error.message,
        liveTranscript: '',
      );
    } catch (_) {
      state = state.copyWith(
        isListening: false,
        errorMessage:
            'Voice input is unavailable right now for the exercises assistant.',
        liveTranscript: '',
      );
    }
  }

  Future<void> stopVoiceInput() async {
    await _voiceInputService.stopListening();
    state = state.copyWith(isListening: false, liveTranscript: '');
  }

  bool _shouldRedirectToExerciseTopics(String message) {
    final normalized = message.toLowerCase();
    return !exerciseTopicKeywords.any(normalized.contains);
  }
}
