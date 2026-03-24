import 'competitor.dart';
import 'competitor_summary.dart';

class CompetitorComparison {
  const CompetitorComparison({
    required this.competitorAId,
    required this.competitorBId,
    this.competitorA,
    this.competitorB,
    this.summaries = const [],
  });

  final String competitorAId;
  final String competitorBId;
  final Competitor? competitorA;
  final Competitor? competitorB;
  final List<CompetitorSummary> summaries;

  factory CompetitorComparison.fromJson(
    Map<String, dynamic> json, {
    required String competitorAId,
    required String competitorBId,
  }) {
    final summaries = _readSummaries(json);
    Competitor? competitorA;
    Competitor? competitorB;

    for (final summary in summaries) {
      final home = summary.sportEvent.homeCompetitor;
      final away = summary.sportEvent.awayCompetitor;
      if (home?.id == competitorAId) {
        competitorA ??= home;
      }
      if (away?.id == competitorAId) {
        competitorA ??= away;
      }
      if (home?.id == competitorBId) {
        competitorB ??= home;
      }
      if (away?.id == competitorBId) {
        competitorB ??= away;
      }
    }

    return CompetitorComparison(
      competitorAId: competitorAId,
      competitorBId: competitorBId,
      competitorA: competitorA,
      competitorB: competitorB,
      summaries: summaries,
    );
  }

  static List<CompetitorSummary> _readSummaries(Map<String, dynamic> json) {
    final summaries = json['summaries'];
    if (summaries is List) {
      return summaries
          .whereType<Map>()
          .map(
            (item) => CompetitorSummary.fromJson(item.cast<String, dynamic>()),
          )
          .toList();
    }
    return const [];
  }
}
