import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/datasources/ai_chat_remote_data_source.dart';
import '../../data/constants/ai_chat_constants.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../data/services/ai_chat_voice_input_service.dart';
import '../../data/services/hugging_face_chat_service.dart';
import '../controllers/ai_chat_notifier.dart';
import '../state/ai_chat_state.dart';

final hfTokenProvider = Provider<String>((ref) {
  return dotenv.env['HF_TOKEN']?.trim() ?? '';
});

final hasHfTokenProvider = Provider<bool>((ref) {
  return ref.watch(hfTokenProvider).isNotEmpty;
});

final aiChatHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final huggingFaceChatServiceProvider = Provider<HuggingFaceChatService>((ref) {
  return HuggingFaceChatService(
    client: ref.watch(aiChatHttpClientProvider),
    token: ref.watch(hfTokenProvider),
  );
});

final aiChatRemoteDataSourceProvider = Provider<AiChatRemoteDataSource>((ref) {
  return AiChatRemoteDataSourceImpl(
    chatService: ref.watch(huggingFaceChatServiceProvider),
  );
});

final aiChatRepositoryProvider = Provider<AiChatRepositoryImpl>((ref) {
  return AiChatRepositoryImpl(
    remoteDataSource: ref.watch(aiChatRemoteDataSourceProvider),
  );
});

final aiChatVoiceInputServiceProvider = Provider<AiChatVoiceInputService>((
  ref,
) {
  final service = AiChatVoiceInputService();
  ref.onDispose(service.dispose);
  return service;
});

final aiChatControllerProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
      return AiChatNotifier(
        repository: ref.watch(aiChatRepositoryProvider),
        voiceInputService: ref.watch(aiChatVoiceInputServiceProvider),
      );
    });

final aiChatQuickSuggestionsProvider = Provider<List<String>>((ref) {
  return aiChatQuickSuggestions;
});
