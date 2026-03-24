import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vollyball_stats/features/shared/widgets/empty_view.dart';
import 'package:vollyball_stats/features/shared/widgets/error_view.dart';
import 'package:vollyball_stats/features/shared/widgets/loading_skeleton.dart';
import 'package:vollyball_stats/features/tournaments/data/models/season_model.dart';

import '../providers/teams_providers.dart';

class CompetitorsPage extends ConsumerWidget {
  const CompetitorsPage({super.key, required this.season});

  final SeasonModel season;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitorsAsync = ref.watch(seasonCompetitorsProvider(season.id));

    return Scaffold(
      appBar: AppBar(title: Text('${season.name} Competitors')),
      body: competitorsAsync.when(
        loading: () => const ListSkeleton(itemCount: 8),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(seasonCompetitorsProvider(season.id)),
        ),
        data: (competitors) {
          if (competitors.isEmpty) {
            return const EmptyView(
              title: 'No Competitors Found',
              message: 'This season does not have any competitor data yet.',
              icon: Icons.groups_2_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: competitors.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final competitor = competitors[index];
              final subtitle = [
                if ((competitor.country ?? '').isNotEmpty) competitor.country!,
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
