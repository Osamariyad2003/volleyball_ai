import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vollyball_stats/features/matches/data/repositories/matches_repository.dart';
import 'package:vollyball_stats/features/matches/presentation/providers/matches_providers.dart';
import 'package:vollyball_stats/features/matches/presentation/state/matches_overview_state.dart';
import 'package:vollyball_stats/features/tournaments/data/models/competition_model.dart';
import 'package:vollyball_stats/features/tournaments/data/models/season_model.dart';
import 'package:vollyball_stats/features/tournaments/data/repositories/competition_repository.dart';

class MatchesOverviewController extends Notifier<MatchesOverviewState> {
  bool _hasStartedInitialLoad = false;

  CompetitionRepository get _competitionRepository =>
      ref.read(matchesCompetitionRepositoryProvider);
  MatchesRepository get _matchesRepository =>
      ref.read(matchesRepositoryProvider);

  @override
  MatchesOverviewState build() {
    if (!_hasStartedInitialLoad) {
      _hasStartedInitialLoad = true;
      Future.microtask(loadCompetitions);
    }
    return const MatchesOverviewState.initial();
  }

  List<CompetitionModel> get filteredCompetitions {
    return state.competitions.where((competition) {
      if (state.selectedFilter == MatchesFilter.all) {
        return true;
      }

      final infoGender = state.selectedCompetition?.id == competition.id
          ? state.selectedCompetitionInfo?.gender
          : null;
      final normalized = _normalizeGender(infoGender ?? competition.gender);

      return switch (state.selectedFilter) {
        MatchesFilter.men => normalized == 'men' || normalized == 'male',
        MatchesFilter.women =>
          normalized == 'women' || normalized == 'female',
        MatchesFilter.all => true,
      };
    }).toList();
  }

  Future<void> loadCompetitions() async {
    state = state.copyWith(
      isLoadingCompetitions: true,
      pageError: null,
      hasLoadedCompetitions: true,
    );

    try {
      final competitions = await _competitionRepository.getCompetitions();
      state = state.copyWith(
        competitions: competitions,
        isLoadingCompetitions: false,
        pageError: null,
      );
      await _syncSelectionWithFilter();
    } catch (error) {
      state = state.copyWith(
        isLoadingCompetitions: false,
        pageError: error.toString(),
      );
    }
  }

  Future<void> setFilter(MatchesFilter filter) async {
    state = state.copyWith(selectedFilter: filter);
    await _syncSelectionWithFilter();
  }

  Future<void> selectCompetition(String? competitionId) async {
    if (competitionId == null) {
      return;
    }

    final competition = state.competitions.firstWhere(
      (item) => item.id == competitionId,
    );
    await _loadCompetitionFlow(competition);
  }

  Future<void> selectSeason(String? seasonId) async {
    if (seasonId == null) {
      return;
    }

    final season = state.seasons.firstWhere((item) => item.id == seasonId);
    state = state.copyWith(
      isLoadingSelection: true,
      pageError: null,
      selectedSeason: season,
      matches: const [],
    );

    try {
      final matches = await _matchesRepository.getSeasonMatches(season.id);
      state = state.copyWith(
        matches: matches,
        isLoadingSelection: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingSelection: false,
        pageError: error.toString(),
      );
    }
  }

  Future<void> retry() async {
    if (state.selectedCompetition == null) {
      await loadCompetitions();
      return;
    }

    await _loadCompetitionFlow(state.selectedCompetition!);
  }

  Future<void> _syncSelectionWithFilter() async {
    final filtered = filteredCompetitions;
    if (filtered.isEmpty) {
      state = state.copyWith(
        selectedCompetition: null,
        selectedCompetitionInfo: null,
        selectedSeason: null,
        seasons: const [],
        matches: const [],
        pageError: null,
      );
      return;
    }

    final current = state.selectedCompetition;
    final nextCompetition =
        current != null && filtered.any((competition) => competition.id == current.id)
        ? current
        : filtered.first;

    if (current?.id != nextCompetition.id || state.selectedSeason == null) {
      await _loadCompetitionFlow(nextCompetition);
    }
  }

  Future<void> _loadCompetitionFlow(CompetitionModel competition) async {
    state = state.copyWith(
      isLoadingSelection: true,
      pageError: null,
      selectedCompetition: competition,
      selectedCompetitionInfo: null,
      selectedSeason: null,
      seasons: const [],
      matches: const [],
    );

    try {
      final info = await _competitionRepository.getCompetitionInfo(
        competition.id,
      );
      final seasons = await _competitionRepository.getCompetitionSeasons(
        competition.id,
      );

      if (seasons.isEmpty) {
        state = state.copyWith(
          selectedCompetitionInfo: info,
          seasons: const [],
          selectedSeason: null,
          matches: const [],
          isLoadingSelection: false,
        );
        return;
      }

      final season = _pickSeason(seasons);
      final matches = await _matchesRepository.getSeasonMatches(season.id);

      state = state.copyWith(
        selectedCompetitionInfo: info,
        seasons: seasons,
        selectedSeason: season,
        matches: matches,
        isLoadingSelection: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingSelection: false,
        pageError: error.toString(),
      );
    }
  }

  SeasonModel _pickSeason(List<SeasonModel> seasons) {
    final now = DateTime.now();

    for (final season in seasons) {
      final start = DateTime.tryParse(season.startDate ?? '');
      final end = DateTime.tryParse(season.endDate ?? '');
      if (start != null && end != null) {
        final startsBeforeNow =
            start.isBefore(now) || start.isAtSameMomentAs(now);
        final endsAfterNow = end.isAfter(now) || end.isAtSameMomentAs(now);
        if (startsBeforeNow && endsAfterNow) {
          return season;
        }
      }
    }

    final latest = [...seasons]
      ..sort((a, b) {
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
      });
    return latest.first;
  }

  String _normalizeGender(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  }
}
