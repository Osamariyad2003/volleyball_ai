import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vollyball_stats/features/matches/presentation/pages/matches_results_page.dart';
import 'package:vollyball_stats/features/shared/widgets/empty_view.dart';
import 'package:vollyball_stats/features/shared/widgets/error_view.dart';
import 'package:vollyball_stats/features/shared/widgets/loading_skeleton.dart';
import 'package:vollyball_stats/features/teams/presentation/pages/competitors_page.dart';
import '../../data/models/season_model.dart';
import '../../data/models/competition_model.dart';
import '../providers/tournaments_providers.dart';

class SeasonsPage extends ConsumerWidget {
  final CompetitionModel competition;

  const SeasonsPage({super.key, required this.competition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(seasonsProvider(competition.id));

    return Scaffold(
      appBar: AppBar(title: Text('${competition.name} Seasons')),
      body: seasonsAsync.when(
        loading: () => const ListSkeleton(itemCount: 6),
        data: (seasons) {
          if (seasons.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _SeasonIntroCard(competition: competition),
                const SizedBox(height: 16),
                const EmptyView(
                  title: 'No Seasons Found',
                  message:
                      'This competition does not have any published seasons right now.',
                  icon: Icons.calendar_month_rounded,
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: seasons.length + 1,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SeasonIntroCard(competition: competition);
              }

              final season = seasons[index - 1];
              return _SeasonCard(season: season);
            },
          );
        },
        error: (error, stackTrace) => ErrorView(
          message: _displayMessage(error),
          onRetry: () =>
              ref.read(seasonsProvider(competition.id).notifier).load(),
        ),
      ),
    );
  }
}

String _displayMessage(Object error) {
  if (error is StateError) {
    return error.message;
  }

  final raw = error.toString();
  const prefix = 'Bad state: ';
  return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
}

class _SeasonIntroCard extends StatelessWidget {
  const _SeasonIntroCard({required this.competition});

  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.92),
            theme.colorScheme.secondary.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_2_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  competition.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Choose a season to open its teams or matches.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({required this.season});

  final SeasonModel season;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = _buildDateLabel();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CompetitorsPage(season: season)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(season.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Year: ${season.year ?? "N/A"}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (dateLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Teams',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CompetitorsPage(season: season),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.groups_rounded,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Matches',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MatchesResultsPage(season: season),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.sports_score_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _buildDateLabel() {
    final start = season.startDate;
    final end = season.endDate;
    if ((start ?? '').isEmpty && (end ?? '').isEmpty) {
      return null;
    }
    if ((start ?? '').isNotEmpty && (end ?? '').isNotEmpty) {
      return '$start to $end';
    }
    return start ?? end;
  }
}
