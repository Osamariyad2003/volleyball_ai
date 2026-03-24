import '../datasources/ai_chat_remote_data_source.dart';
import '../models/ai_chat_message.dart';

class AiChatRepositoryImpl {
  AiChatRepositoryImpl({required AiChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AiChatRemoteDataSource _remoteDataSource;

  Future<AiChatMessage> sendMessage({
    required List<AiChatMessage> conversation,
    required String userMessage,
  }) async {
    return _remoteDataSource.sendMessage(
      conversation: conversation,
      userMessage: userMessage,
    );
  }
}
