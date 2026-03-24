import '../../data/constants/ai_chat_constants.dart';
import '../../data/models/ai_chat_message.dart';

const _errorSentinel = Object();

class AiChatState {
  const AiChatState({
    required this.messages,
    required this.isLoading,
    required this.errorMessage,
    required this.isListening,
    required this.liveTranscript,
  });

  factory AiChatState.initial() {
    return AiChatState(
      messages: [
        AiChatMessage(
          role: AiChatRole.assistant,
          content: volleyballExercisesWelcomeMessage,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
      errorMessage: null,
      isListening: false,
      liveTranscript: '',
    );
  }

  final List<AiChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final bool isListening;
  final String liveTranscript;

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isLoading,
    Object? errorMessage = _errorSentinel,
    bool? isListening,
    String? liveTranscript,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _errorSentinel)
          ? this.errorMessage
          : errorMessage as String?,
      isListening: isListening ?? this.isListening,
      liveTranscript: liveTranscript ?? this.liveTranscript,
    );
  }
}
