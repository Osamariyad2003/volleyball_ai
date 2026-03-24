import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vollyball_stats/features/shared/widgets/empty_view.dart';
import 'package:vollyball_stats/features/shared/widgets/error_view.dart';
import 'package:vollyball_stats/features/shared/widgets/loading_skeleton.dart';
import 'package:vollyball_stats/features/tournaments/data/models/competition_model.dart';

import '../providers/teams_providers.dart';

class CompetitionTeamsPage extends ConsumerWidget {
  const CompetitionTeamsPage({super.key, required this.competition});

  final CompetitionModel competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(competitionTeamsProvider(competition));

    return Scaffold(
      appBar: AppBar(title: Text('${competition.name} Teams')),
      body: teamsAsync.when(
        loading: () => const ListSkeleton(itemCount: 8),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(competitionTeamsProvider(competition)),
        ),
        data: (data) {
          if (data.competitors.isEmpty) {
            return const EmptyView(
              title: 'No Teams Found',
              message: 'No teams were returned for this competition yet.',
              icon: Icons.groups_2_outlined,
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: const Text('Season'),
                    subtitle: Text(data.season.name),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: data.competitors.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final competitor = data.competitors[index];
                    final subtitle = [
                      if ((competitor.country ?? '').isNotEmpty)
                        competitor.country!,
                      if ((competitor.abbreviation ?? '').isNotEmpty)
                        competitor.abbreviation!,
                    ].join(' • ');

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            _buildInitials(competitor.name),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        title: Text(competitor.name),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _buildInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
