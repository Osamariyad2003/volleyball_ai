import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vollyball_stats/core/model/match_result.dart';
import 'package:vollyball_stats/features/matches/presentation/providers/matches_providers.dart';
import 'package:vollyball_stats/features/matches/presentation/state/matches_overview_state.dart';
import 'package:vollyball_stats/features/shared/widgets/empty_view.dart';
import 'package:vollyball_stats/features/shared/widgets/error_view.dart';
import 'package:vollyball_stats/features/shared/widgets/loading_skeleton.dart';
import 'package:vollyball_stats/features/tournaments/data/models/competition_info_model.dart';
import 'package:vollyball_stats/features/tournaments/data/models/competition_model.dart';
import 'package:vollyball_stats/features/tournaments/data/models/season_model.dart';

class MatchesOverviewPage extends ConsumerStatefulWidget {
  const MatchesOverviewPage({super.key});

  @override
  ConsumerState<MatchesOverviewPage> createState() => _MatchesOverviewPageState();
}

class _MatchesOverviewPageState extends ConsumerState<MatchesOverviewPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchesOverviewControllerProvider);
    final controller = ref.read(matchesOverviewControllerProvider.notifier);
    final filteredCompetitions = controller.filteredCompetitions;

    if (state.isLoadingCompetitions) {
      return Scaffold(
        appBar: AppBar(title: const Text('Volleyball Matches')),
        body: const ListSkeleton(itemCount: 8),
      );
    }

    if (state.pageError != null && state.selectedCompetition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Volleyball Matches')),
        body: ErrorView(
          message: state.pageError!,
          onRetry: controller.loadCompetitions,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Volleyball Matches')),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          _FilterCard(
            selectedFilter: state.selectedFilter,
            competitionCount: filteredCompetitions.length,
            onChanged: (filter) async {
              _jumpToTop();
              await controller.setFilter(filter);
            },
          ),
          const SizedBox(height: 16),
          if (filteredCompetitions.isEmpty)
            const EmptyView(
              title: 'No Tournaments Found',
              message: 'There are no competitions available for this category.',
              icon: Icons.filter_alt_off_rounded,
            )
          else ...[
            _SelectionCard(
              competitions: filteredCompetitions,
              selectedCompetitionId: state.selectedCompetition?.id,
              seasons: state.seasons,
              selectedSeasonId: state.selectedSeason?.id,
              selectedCompetitionInfo: state.selectedCompetitionInfo,
              isLoadingSelection: state.isLoadingSelection,
              onCompetitionChanged: (competitionId) async {
                _jumpToTop();
                await controller.selectCompetition(competitionId);
              },
              onSeasonChanged: (seasonId) async {
                _jumpToTop();
                await controller.selectSeason(seasonId);
              },
            ),
            const SizedBox(height: 12),
            if (state.pageError != null)
              ErrorView(
                message: state.pageError!,
                onRetry: () async {
                  _jumpToTop();
                  await controller.retry();
                },
              )
            else if (state.isLoadingSelection)
              const ListSkeleton(itemCount: 6, shrinkWrap: true)
            else if (state.matches.isEmpty)
              const EmptyView(
                title: 'No Matches Found',
                message:
                    'This tournament season does not have any published matches yet.',
                icon: Icons.sports_score_rounded,
              )
            else
              ...state.matches.map(
                (match) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MatchCard(
                    match: match,
                    tournamentName:
                        state.selectedCompetitionInfo?.name ??
                        state.selectedCompetition?.name ??
                        '',
                    gender:
                        state.selectedCompetitionInfo?.gender ??
                        state.selectedCompetition?.gender,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _jumpToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.jumpTo(0);
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.selectedFilter,
    required this.competitionCount,
    required this.onChanged,
  });

  final MatchesFilter selectedFilter;
  final int competitionCount;
  final ValueChanged<MatchesFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Filter',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SegmentedButton<MatchesFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: MatchesFilter.all, label: Text('All')),
                ButtonSegment(value: MatchesFilter.men, label: Text('Men')),
                ButtonSegment(value: MatchesFilter.women, label: Text('Women')),
              ],
              selected: {selectedFilter},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
            const SizedBox(height: 10),
            Text(
              '$competitionCount tournaments available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.competitions,
    required this.selectedCompetitionId,
    required this.seasons,
    required this.selectedSeasonId,
    required this.selectedCompetitionInfo,
    required this.isLoadingSelection,
    required this.onCompetitionChanged,
    required this.onSeasonChanged,
  });

  final List<CompetitionModel> competitions;
  final String? selectedCompetitionId;
  final List<SeasonModel> seasons;
  final String? selectedSeasonId;
  final CompetitionInfoModel? selectedCompetitionInfo;
  final bool isLoadingSelection;
  final ValueChanged<String?> onCompetitionChanged;
  final ValueChanged<String?> onSeasonChanged;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = selectedCompetitionInfo?.categoryName;
    final genderLabel = selectedCompetitionInfo?.gender;
    final selectedCompetition = competitions.cast<CompetitionModel?>().firstWhere(
      (competition) => competition?.id == selectedCompetitionId,
      orElse: () => null,
    );
    final selectedSeason = seasons.cast<SeasonModel?>().firstWhere(
      (season) => season?.id == selectedSeasonId,
      orElse: () => null,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectorField(
              label: 'Tournament',
              value: selectedCompetition?.name ?? 'Choose tournament',
              enabled: !isLoadingSelection && competitions.isNotEmpty,
              onTap: () => _showCompetitionPicker(
                context,
                competitions: competitions,
                selectedCompetitionId: selectedCompetitionId,
                onChanged: onCompetitionChanged,
              ),
            ),
            const SizedBox(height: 10),
            _SelectorField(
              label: 'Season',
              value: selectedSeason?.name ?? 'Choose season',
              enabled: !isLoadingSelection && seasons.isNotEmpty,
              onTap: () => _showSeasonPicker(
                context,
                seasons: seasons,
                selectedSeasonId: selectedSeasonId,
                onChanged: onSeasonChanged,
              ),
            ),
            if ((genderLabel ?? '').isNotEmpty ||
                (categoryLabel ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((genderLabel ?? '').isNotEmpty)
                    _MetaChip(label: genderLabel!),
                  if ((categoryLabel ?? '').isNotEmpty)
                    _MetaChip(label: categoryLabel!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showCompetitionPicker(
    BuildContext context, {
    required List<CompetitionModel> competitions,
    required String? selectedCompetitionId,
    required ValueChanged<String?> onChanged,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: competitions.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final competition = competitions[index];
              final isSelected = competition.id == selectedCompetitionId;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                    : null,
                title: Text(
                  competition.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${competition.gender ?? "Both"} - ${competition.type ?? "Competition"}',
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onChanged(competition.id);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showSeasonPicker(
    BuildContext context, {
    required List<SeasonModel> seasons,
    required String? selectedSeasonId,
    required ValueChanged<String?> onChanged,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: seasons.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final season = seasons[index];
              final isSelected = season.id == selectedSeasonId;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                    : null,
                title: Text(
                  season.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(season.year ?? season.startDate ?? 'Season'),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onChanged(season.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.tournamentName,
    required this.gender,
  });

  final MatchResult match;
  final String tournamentName;
  final String? gender;

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
    final homeWon = match.winnerId == match.homeTeamId;
    final awayWon = match.winnerId == match.awayTeamId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournamentName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scheduled,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if ((gender ?? '').isNotEmpty) _MetaChip(label: gender!),
                    const SizedBox(height: 8),
                    _StatusBadge(status: match.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.22,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TeamSide(
                      name: match.homeTeam,
                      alignEnd: false,
                      highlighted: homeWon,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          scoreText,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasScore ? 'Final score' : 'Scheduled',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _TeamSide(
                      name: match.awayTeam,
                      alignEnd: true,
                      highlighted: awayWon,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (homeWon || awayWon)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      homeWon ? '${match.homeTeam} won' : '${match.awayTeam} won',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.name,
    required this.alignEnd,
    required this.highlighted,
  });

  final String name;
  final bool alignEnd;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (highlighted)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 18,
              color: theme.colorScheme.secondary,
            ),
          ),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

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
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.expand_more_rounded,
              color: enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
