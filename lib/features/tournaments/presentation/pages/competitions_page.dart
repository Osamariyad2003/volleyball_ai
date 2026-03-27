import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vollyball_stats/features/tournaments/data/models/competition_model.dart';
import 'package:vollyball_stats/features/teams/presentation/pages/competition_teams_page.dart';
import 'package:vollyball_stats/features/tournaments/presentation/pages/seasons_page.dart';
import '../providers/tournaments_providers.dart';

class CompetitionsPage extends ConsumerWidget {
  const CompetitionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionsAsync = ref.watch(competitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volleyball Competitions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(competitionsProvider.notifier).load();
            },
          ),
        ],
      ),
      body: competitionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        data: (competitions) =>
            _buildCompetitionsList(context, ref, competitions),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(_displayMessage(error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(competitionsProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayMessage(Object error) {
    if (error is StateError) {
      return error.message;
    }

    final raw = error.toString();
    const prefix = 'Bad state: ';
    return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
  }

  Widget _buildCompetitionsList(
    BuildContext context,
    WidgetRef ref,
    List<CompetitionModel> competitions,
  ) {
    final selectedFilter = ref.watch(competitionCategoryFilterProvider);
    final filteredCompetitions = competitions
        .where(
          (competition) => _matchesSelectedFilter(competition, selectedFilter),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Filter',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<CompetitionCategoryFilter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: CompetitionCategoryFilter.both,
                      label: Text('Both'),
                    ),
                    ButtonSegment(
                      value: CompetitionCategoryFilter.men,
                      label: Text('Men'),
                    ),
                    ButtonSegment(
                      value: CompetitionCategoryFilter.women,
                      label: Text('Women'),
                    ),
                  ],
                  selected: {selectedFilter},
                  onSelectionChanged: (selection) {
                    ref.read(competitionCategoryFilterProvider.notifier).state =
                        selection.first;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  '${filteredCompetitions.length} competitions shown',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (filteredCompetitions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.filter_alt_off_rounded, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No competitions match this filter.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredCompetitions.map(
            (competition) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: ListTile(
                  title: Text(
                    competition.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    '${competition.gender ?? "Universal"} - ${competition.type ?? "League"}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: IconButton(
                    tooltip: 'Open teams',
                    icon: const Icon(Icons.groups_rounded),
                    onPressed: () => _openTeams(context, competition),
                  ),
                  onTap: () => _openSeasons(context, competition),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _matchesSelectedFilter(
    CompetitionModel competition,
    CompetitionCategoryFilter selectedFilter,
  ) {
    if (selectedFilter == CompetitionCategoryFilter.both) {
      return true;
    }

    final normalized = (competition.gender ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '');

    return switch (selectedFilter) {
      CompetitionCategoryFilter.men =>
        normalized == 'men' || normalized == 'male',
      CompetitionCategoryFilter.women =>
        normalized == 'women' || normalized == 'female',
      CompetitionCategoryFilter.both => true,
    };
  }

  void _openSeasons(BuildContext context, CompetitionModel competition) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeasonsPage(competition: competition)),
    );
  }

  void _openTeams(BuildContext context, CompetitionModel competition) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompetitionTeamsPage(competition: competition),
      ),
    );
  }
}
