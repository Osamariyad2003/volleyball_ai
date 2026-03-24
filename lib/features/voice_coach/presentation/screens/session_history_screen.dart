import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../data/models/coach_models.dart';
import 'post_match_screen.dart';

class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionHistoryProvider);
    final formatter = DateFormat('MMM d, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Session History')),
      body: sessions.isEmpty
          ? const Center(child: Text('No saved sessions yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionCard(
                  session: session,
                  subtitle: formatter.format(session.createdAt),
                  onResume: () async {
                    await ref
                        .read(coachControllerProvider)
                        .resumeSession(session);
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  onView: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PostMatchScreen(sessionId: session.id),
                      ),
                    );
                  },
                  onDelete: () async {
                    await ref
                        .read(coachControllerProvider)
                        .deleteSession(session.id);
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: sessions.length,
            ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.subtitle,
    required this.onResume,
    required this.onView,
    required this.onDelete,
  });

  final MatchSession session;
  final String subtitle;
  final VoidCallback onResume;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.matchName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.homeTeam} vs ${session.awayTeam}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${session.scoreHome} : ${session.scoreAway}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$subtitle  •  Set ${session.currentSet}  •  Rotation ${session.currentRotation}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: onView,
                  child: const Text('View'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: onResume, child: const Text('Resume')),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
