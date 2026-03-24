import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_chat_providers.dart';
import '../state/ai_chat_state.dart';
import '../widgets/ai_chat_bubble.dart';
import '../widgets/ai_chat_empty_state.dart';
import '../widgets/ai_chat_input_bar.dart';
import '../widgets/ai_chat_quick_suggestions.dart';
import '../widgets/ai_chat_typing_indicator.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiChatState>(aiChatControllerProvider, (previous, next) {
      final hadNewError =
          next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage;
      if (hadNewError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        ref.read(aiChatControllerProvider.notifier).clearError();
      }

      final previousCount = previous?.messages.length ?? 0;
      if (next.messages.length > previousCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    final theme = Theme.of(context);
    final state = ref.watch(aiChatControllerProvider);
    final suggestions = ref.watch(aiChatQuickSuggestionsProvider);
    final hasToken = ref.watch(hasHfTokenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Volleyball Exercises Assistant')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.secondary.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? AiChatEmptyState(hasToken: hasToken)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        itemCount:
                            state.messages.length + (state.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
                            return const AiChatTypingIndicator();
                          }

                          final message = state.messages[index];
                          return AiChatBubble(
                            key: ValueKey(
                              '${message.role.name}-${message.timestamp.microsecondsSinceEpoch}',
                            ),
                            message: message,
                          );
                        },
                      ),
              ),
              if (state.liveTranscript.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.liveTranscript,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: AiChatQuickSuggestions(
                  suggestions: suggestions,
                  isLoading: state.isLoading,
                  onSelected: _sendSuggestion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AiChatInputBar(
                  controller: _controller,
                  isLoading: state.isLoading,
                  isListening: state.isListening,
                  onSend: _handleSend,
                  onVoiceTap: _handleVoiceTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      return;
    }

    _controller.clear();
    ref.read(aiChatControllerProvider.notifier).sendMessage(message);
  }

  void _sendSuggestion(String suggestion) {
    _controller.clear();
    ref.read(aiChatControllerProvider.notifier).sendMessage(suggestion);
  }

  void _handleVoiceTap() {
    final notifier = ref.read(aiChatControllerProvider.notifier);
    final isListening = ref.read(aiChatControllerProvider).isListening;
    if (isListening) {
      notifier.stopVoiceInput();
    } else {
      notifier.startVoiceInput();
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}
