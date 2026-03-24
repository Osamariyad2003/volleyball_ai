import '../constants/ai_chat_constants.dart';
import '../models/ai_chat_message.dart';
import '../services/hugging_face_chat_service.dart';

abstract class AiChatRemoteDataSource {
  Future<AiChatMessage> sendMessage({
    required List<AiChatMessage> conversation,
    required String userMessage,
  });
}

class AiChatRemoteDataSourceImpl implements AiChatRemoteDataSource {
  AiChatRemoteDataSourceImpl({required HuggingFaceChatService chatService})
    : _chatService = chatService;

  final HuggingFaceChatService _chatService;

  @override
  Future<AiChatMessage> sendMessage({
    required List<AiChatMessage> conversation,
    required String userMessage,
  }) async {
    conversation.length;
    // Product requirement for this backend-less version is to send the
    // volleyball system prompt plus the latest user question only.
    final content = await _chatService.createChatCompletion(
      messages: [
        {'role': 'system', 'content': volleyballAiSystemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
    );

    return AiChatMessage(
      role: AiChatRole.assistant,
      content: content,
      timestamp: DateTime.now(),
    );
  }
}
