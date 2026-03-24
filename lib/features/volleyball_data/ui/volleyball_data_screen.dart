import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/section_card.dart';
import '../models/competitor.dart';
import '../models/competitor_comparison.dart';
import '../models/competitor_summary.dart';
import '../models/merge_mapping.dart';
import '../models/sport_event.dart';
import '../models/sport_event_timeline.dart';
import '../state/providers.dart';
import '../ui/widgets/feed_result_card.dart';
import '../ui/widgets/property_list.dart';

class VolleyballDataScreen extends ConsumerStatefulWidget {
  const VolleyballDataScreen({super.key});

  @override
  ConsumerState<VolleyballDataScreen> createState() =>
      _VolleyballDataScreenState();
}

class _VolleyballDataScreenState extends ConsumerState<VolleyballDataScreen> {
  late final TextEditingController _eventIdController;
  late final TextEditingController _competitorIdController;
  late final TextEditingController _competitorAController;
  late final TextEditingController _competitorBController;

  @override
  void initState() {
    super.initState();
    _eventIdController = TextEditingController();
    _competitorIdController = TextEditingController();
    _competitorAController = TextEditingController();
    _competitorBController = TextEditingController();
  }

  @override
  void dispose() {
    _eventIdController.dispose();
    _competitorIdController.dispose();
    _competitorAController.dispose();
    _competitorBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(volleyballDataControllerProvider);
    final controller = ref.read(volleyballDataControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Volleyball Data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          SectionCard(
            title: 'Sport Events',
            subtitle:
                'Load summary, timeline, and delta feeds by sport event id.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _eventIdController,
                  decoration: const InputDecoration(
                    labelText: 'Sport event id',
                    hintText: 'sr:sport_event:52378325',
                  ),
                  onChanged: controller.setEventId,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => controller.fetchSportEventSummary(
                        _eventIdController.text,
                      ),
                      child: const Text('Summary'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => controller.fetchSportEventTimeline(
                        _eventIdController.text,
                      ),
                      child: const Text('Timeline'),
                    ),
                    OutlinedButton(
                      onPressed: controller.fetchSportEventsCreated,
                      child: const Text('Created'),
                    ),
                    OutlinedButton(
                      onPressed: controller.fetchSportEventsRemoved,
                      child: const Text('Removed'),
                    ),
                    OutlinedButton(
                      onPressed: controller.fetchSportEventsUpdated,
                      child: const Text('Updated'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                FeedResultCard<SportEvent>(
                  title: 'Sport Event Summary',
                  state: state.sportEventSummary,
                  onRetry: () => controller.fetchSportEventSummary(
                    _eventIdController.text,
                  ),
                  builder: _buildSportEventSummary,
                ),
                FeedResultCard<SportEventTimeline>(
                  title: 'Sport Event Timeline',
                  state: state.sportEventTimeline,
                  onRetry: () => controller.fetchSportEventTimeline(
                    _eventIdController.text,
                  ),
                  builder: _buildTimeline,
                ),
                FeedResultCard<List<SportEvent>>(
                  title: 'Sport Events Created',
                  state: state.sportEventsCreated,
                  onRetry: controller.fetchSportEventsCreated,
                  builder: _buildSportEventList,
                  emptyMessage:
                      'No recently created sport events were returned.',
                ),
                FeedResultCard<List<SportEvent>>(
                  title: 'Sport Events Removed',
                  state: state.sportEventsRemoved,
                  onRetry: controller.fetchSportEventsRemoved,
                  builder: _buildSportEventList,
                  emptyMessage:
                      'No recently removed sport events were returned.',
                ),
                FeedResultCard<List<SportEvent>>(
                  title: 'Sport Events Updated',
                  state: state.sportEventsUpdated,
                  onRetry: controller.fetchSportEventsUpdated,
                  builder: _buildSportEventList,
                  emptyMessage:
                      'No recently updated sport events were returned.',
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Competitors',
            subtitle:
                'Load profile, summaries, and head-to-head feeds by competitor id.',
            child: Column(
              children: [
                TextField(
                  controller: _competitorIdController,
                  decoration: const InputDecoration(
                    labelText: 'Competitor id',
                    hintText: 'sr:competitor:1234',
                  ),
                  onChanged: controller.setCompetitorId,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => controller.fetchCompetitorProfile(
                        _competitorIdController.text,
                      ),
                      child: const Text('Profile'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => controller.fetchCompetitorSummaries(
                        _competitorIdController.text,
                      ),
                      child: const Text('Summaries'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _competitorAController,
                        decoration: const InputDecoration(
                          labelText: 'Competitor A',
                        ),
                        onChanged: controller.setCompetitorAId,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _competitorBController,
                        decoration: const InputDecoration(
                          labelText: 'Competitor B',
                        ),
                        onChanged: controller.setCompetitorBId,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => controller.fetchCompetitorVsCompetitor(
                      competitorAId: _competitorAController.text,
                      competitorBId: _competitorBController.text,
                    ),
                    child: const Text('Compare Competitors'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                FeedResultCard<Competitor>(
                  title: 'Competitor Profile',
                  state: state.competitorProfile,
                  onRetry: () => controller.fetchCompetitorProfile(
                    _competitorIdController.text,
                  ),
                  builder: _buildCompetitorProfile,
                ),
                FeedResultCard<List<CompetitorSummary>>(
                  title: 'Competitor Summaries',
                  state: state.competitorSummaries,
                  onRetry: () => controller.fetchCompetitorSummaries(
                    _competitorIdController.text,
                  ),
                  builder: _buildCompetitorSummaries,
                  emptyMessage: 'No competitor summaries were returned.',
                ),
                FeedResultCard<CompetitorComparison>(
                  title: 'Competitor vs Competitor',
                  state: state.competitorComparison,
                  onRetry: () => controller.fetchCompetitorVsCompetitor(
                    competitorAId: _competitorAController.text,
                    competitorBId: _competitorBController.text,
                  ),
                  builder: _buildCompetitorComparison,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Other',
            subtitle: 'Use supporting feeds like competitor merge mappings.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: controller.fetchCompetitorMergeMappings,
                icon: const Icon(Icons.merge_type_rounded),
                label: const Text('Load Merge Mappings'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FeedResultCard<List<MergeMapping>>(
              title: 'Competitor Merge Mappings',
              state: state.mergeMappings,
              onRetry: controller.fetchCompetitorMergeMappings,
              builder: _buildMergeMappings,
              emptyMessage: 'No competitor merge mappings were returned.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportEventSummary(SportEvent event) {
    return PropertyList(
      items: [
        PropertyItem('Event', event.name),
        PropertyItem('Tournament', event.tournamentName ?? ''),
        PropertyItem('Category', event.categoryName ?? ''),
        PropertyItem('Gender', event.gender ?? ''),
        PropertyItem('Start', _formatDate(event.startTime)),
        PropertyItem('Home', event.homeCompetitor?.name ?? ''),
        PropertyItem('Away', event.awayCompetitor?.name ?? ''),
        PropertyItem('Status', event.status?.status ?? ''),
        PropertyItem(
          'Score',
          event.status == null
              ? ''
              : '${event.status?.homeScore ?? 0} : ${event.status?.awayScore ?? 0}',
        ),
      ],
    );
  }

  Widget _buildTimeline(SportEventTimeline timeline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSportEventSummary(timeline.sportEvent),
        if (timeline.entries.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Timeline Entries',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...timeline.entries
              .take(12)
              .map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(entry.type),
                  subtitle: Text(
                    [
                      if (entry.competitor != null) entry.competitor!,
                      if (entry.periodName != null) entry.periodName!,
                      if (entry.time != null) _formatDate(entry.time),
                    ].join(' - '),
                  ),
                  trailing: entry.homeScore != null || entry.awayScore != null
                      ? Text('${entry.homeScore ?? 0}:${entry.awayScore ?? 0}')
                      : null,
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildSportEventList(List<SportEvent> events) {
    return Column(
      children: events
          .take(10)
          .map(
            (event) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(event.name),
              subtitle: Text(
                [
                  if (event.tournamentName?.isNotEmpty ?? false)
                    event.tournamentName!,
                  if (event.startTime != null) _formatDate(event.startTime),
                ].join(' - '),
              ),
              trailing: event.status == null
                  ? null
                  : Text(
                      '${event.status?.homeScore ?? 0}:${event.status?.awayScore ?? 0}',
                    ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCompetitorProfile(Competitor competitor) {
    return PropertyList(
      items: [
        PropertyItem('Name', competitor.name),
        PropertyItem('Country', competitor.country ?? ''),
        PropertyItem('Code', competitor.countryCode ?? ''),
        PropertyItem('Abbreviation', competitor.abbreviation ?? ''),
        PropertyItem('Gender', competitor.gender ?? ''),
        PropertyItem('Age Group', competitor.ageGroup ?? ''),
        PropertyItem('Category', competitor.categoryName ?? ''),
      ],
    );
  }

  Widget _buildCompetitorSummaries(List<CompetitorSummary> summaries) {
    return Column(
      children: summaries
          .take(10)
          .map(
            (summary) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(summary.sportEvent.name),
              subtitle: Text(
                [
                  if (summary.sportEvent.tournamentName?.isNotEmpty ?? false)
                    summary.sportEvent.tournamentName!,
                  if (summary.sportEvent.startTime != null)
                    _formatDate(summary.sportEvent.startTime),
                ].join(' - '),
              ),
              trailing: summary.sportEvent.status == null
                  ? null
                  : Text(
                      '${summary.sportEvent.status?.homeScore ?? 0}:${summary.sportEvent.status?.awayScore ?? 0}',
                    ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCompetitorComparison(CompetitorComparison comparison) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyList(
          items: [
            PropertyItem(
              'Competitor A',
              comparison.competitorA?.name ?? comparison.competitorAId,
            ),
            PropertyItem(
              'Competitor B',
              comparison.competitorB?.name ?? comparison.competitorBId,
            ),
            PropertyItem('Shared summaries', '${comparison.summaries.length}'),
          ],
        ),
        if (comparison.summaries.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...comparison.summaries
              .take(8)
              .map(
                (summary) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(summary.sportEvent.name),
                  subtitle: Text(summary.sportEvent.tournamentName ?? ''),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildMergeMappings(List<MergeMapping> mappings) {
    return Column(
      children: mappings
          .take(10)
          .map(
            (mapping) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(mapping.mergedName ?? mapping.mergedId),
              subtitle: Text(
                'Merged into ${mapping.retainedName ?? mapping.retainedId}',
              ),
              trailing: mapping.createdAt == null
                  ? null
                  : Text(
                      DateFormat('MMM d').format(mapping.createdAt!.toLocal()),
                    ),
            ),
          )
          .toList(),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    return DateFormat('MMM d, yyyy HH:mm').format(dateTime.toLocal());
  }
}
