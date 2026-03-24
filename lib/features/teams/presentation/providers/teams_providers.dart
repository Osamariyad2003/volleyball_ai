import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../injection_container.dart' as di;
import '../../data/models/competitor_model.dart';
import '../../data/repositories/competitor_repository.dart';
import '../../../tournaments/data/models/competition_model.dart';
import '../../../tournaments/data/models/season_model.dart';
import '../../../tournaments/data/repositories/competition_repository.dart';
import '../state/competition_teams_state.dart';

final competitorRepositoryProvider = Provider<CompetitorRepository>((ref) {
  return di.sl<CompetitorRepository>();
});

final teamCompetitionRepositoryProvider = Provider<CompetitionRepository>((ref) {
  return di.sl<CompetitionRepository>();
});

final seasonCompetitorsProvider =
    FutureProvider.family<List<CompetitorModel>, String>((ref, seasonId) {
      return ref.watch(competitorRepositoryProvider).getSeasonCompetitors(
        seasonId,
      );
    });

final competitionTeamsProvider =
    FutureProvider.family<CompetitionTeamsState, CompetitionModel>((
      ref,
      competition,
    ) async {
      final competitionRepository = ref.watch(teamCompetitionRepositoryProvider);
      final competitorRepository = ref.watch(competitorRepositoryProvider);

      final seasons = await competitionRepository.getCompetitionSeasons(
        competition.id,
      );

      if (seasons.isEmpty) {
        throw StateError('No seasons were found for this competition.');
      }

      final latestSeason = [...seasons]..sort(_compareSeasons);
      final selectedSeason = latestSeason.first;
      final competitors = await competitorRepository.getSeasonCompetitors(
        selectedSeason.id,
      );

      return CompetitionTeamsState(
        season: selectedSeason,
        competitors: competitors,
      );
    });

int _compareSeasons(SeasonModel a, SeasonModel b) {
  final startA = DateTime.tryParse(a.startDate ?? '');
  final startB = DateTime.tryParse(b.startDate ?? '');

  if (startA != null && startB != null) {
    return startB.compareTo(startA);
  }

  final yearA = int.tryParse(a.year ?? '');
  final yearB = int.tryParse(b.year ?? '');
  if (yearA != null && yearB != null) {
    return yearB.compareTo(yearA);
  }

  return b.name.compareTo(a.name);
}
