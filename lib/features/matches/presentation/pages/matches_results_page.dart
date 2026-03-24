import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vollyball_stats/core/model/match_result.dart';
import 'package:vollyball_stats/features/matches/presentation/providers/matches_providers.dart';
import 'package:vollyball_stats/features/shared/widgets/empty_view.dart';
import 'package:vollyball_stats/features/shared/widgets/error_view.dart';
import 'package:vollyball_stats/features/shared/widgets/loading_skeleton.dart';
import 'package:vollyball_stats/features/tournaments/data/models/season_model.dart';

class MatchesResultsPage extends ConsumerWidget {
  const MatchesResultsPage({super.key, required this.season});

  final SeasonModel season;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(seasonMatchesResultsProvider(season.id));

    return Scaffold(
      appBar: AppBar(title: Text('${season.name} Matches')),
      body: matchesAsync.when(
        loading: () => const ListSkeleton(itemCount: 8),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(seasonMatchesResultsProvider(season.id)),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            return const EmptyView(
              title: 'No Matches Found',
              message: 'This season does not have any published matches yet.',
              icon: Icons.sports_score_rounded,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: matches.length + 1,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _MatchesHeader(
                  seasonName: season.name,
                  matchCount: matches.length,
                );
              }

              return _MatchCard(match: matches[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class _MatchesHeader extends StatelessWidget {
  const _MatchesHeader({required this.seasonName, required this.matchCount});

  final String seasonName;
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.95),
            theme.colorScheme.primary.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matches & Results',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$seasonName - $matchCount matches',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d, HH:mm');
    final scheduled = match.scheduledAt == null
        ? 'Time TBD'
        : formatter.format(match.scheduledAt!.toLocal());
    final hasScore = match.homeScore != null || match.awayScore != null;
    final scoreText = hasScore
        ? '${match.homeScore ?? 0} : ${match.awayScore ?? 0}'
        : 'vs';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    scheduled,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                _StatusChip(status: match.status),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TeamColumn(
                    name: match.homeTeam,
                    isWinner: match.winnerId == match.homeTeamId,
                    alignEnd: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    scoreText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: _TeamColumn(
                    name: match.awayTeam,
                    isWinner: match.winnerId == match.awayTeamId,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.name,
    required this.isWinner,
    required this.alignEnd,
  });

  final String name;
  final bool isWinner;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'closed' || 'ended' || 'complete' => const Color(0xFF22C55E),
      'live' || 'inprogress' || 'started' => const Color(0xFFF97316),
      _ => theme.colorScheme.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
