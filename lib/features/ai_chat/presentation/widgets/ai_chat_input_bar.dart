import 'package:flutter/material.dart';

class AiChatInputBar extends StatelessWidget {
  const AiChatInputBar({
    required this.controller,
    required this.isLoading,
    required this.isListening,
    required this.onSend,
    required this.onVoiceTap,
    super.key,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onVoiceTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
      ),
    );

    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSend(),
      decoration: InputDecoration(
        hintText:
            'Ask for a volleyball exercise, warm-up, jump drill, or recovery plan',
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.4,
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 96,
          maxWidth: 108,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: isLoading ? null : onVoiceTap,
                tooltip: isListening ? 'Stop voice input' : 'Start voice input',
                icon: Icon(
                  isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  color: isListening
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                onPressed: isLoading ? null : onSend,
                tooltip: 'Send',
                icon: isLoading
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: theme.colorScheme.primary,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
