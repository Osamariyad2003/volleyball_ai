import 'package:flutter/material.dart';

class AiChatEmptyState extends StatelessWidget {
  const AiChatEmptyState({required this.hasToken, super.key});

  final bool hasToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 84,
                    width: 84,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 38,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ask for workouts, jump drills, warm-ups, or recovery exercises',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Get focused volleyball exercise guidance with sets, reps, duration, and rest suggestions whenever possible.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: hasToken
                          ? theme.colorScheme.primary.withValues(alpha: 0.10)
                          : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      hasToken
                          ? 'HF_TOKEN is configured. If requests fail, verify it is a Hugging Face User Access Token with Inference Providers permission.'
                          : 'HF_TOKEN is missing from .env, so exercise guidance cannot be generated yet.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasToken
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
