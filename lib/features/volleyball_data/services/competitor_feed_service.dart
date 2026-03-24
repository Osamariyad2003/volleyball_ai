import '../models/competitor.dart';
import '../models/competitor_comparison.dart';
import '../models/competitor_summary.dart';
import '../repositories/competitor_feed_repository.dart';

class CompetitorFeedService {
  CompetitorFeedService(this._repository);

  final CompetitorFeedRepository _repository;
  final Map<String, Competitor> _profileCache = {};
  final Map<String, List<CompetitorSummary>> _summariesCache = {};
  final Map<String, CompetitorComparison> _comparisonCache = {};

  Future<Competitor> fetchCompetitorProfile(String competitorId) async {
    final cached = _profileCache[competitorId];
    if (cached != null) {
      return cached;
    }
    final profile = await _repository.fetchCompetitorProfile(competitorId);
    _profileCache[competitorId] = profile;
    return profile;
  }

  Future<List<CompetitorSummary>> fetchCompetitorSummaries(
    String competitorId,
  ) async {
    final cached = _summariesCache[competitorId];
    if (cached != null) {
      return cached;
    }
    final summaries = await _repository.fetchCompetitorSummaries(competitorId);
    _summariesCache[competitorId] = summaries;
    return summaries;
  }

  Future<CompetitorComparison> fetchCompetitorVsCompetitor(
    String competitorAId,
    String competitorBId,
  ) async {
    final key = '$competitorAId::$competitorBId';
    final cached = _comparisonCache[key];
    if (cached != null) {
      return cached;
    }
    final comparison = await _repository.fetchCompetitorVsCompetitor(
      competitorAId,
      competitorBId,
    );
    _comparisonCache[key] = comparison;
    return comparison;
  }
}
