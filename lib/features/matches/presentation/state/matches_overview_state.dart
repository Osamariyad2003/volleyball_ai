import 'package:vollyball_stats/core/model/match_result.dart';
import 'package:vollyball_stats/features/tournaments/data/models/competition_info_model.dart';
import 'package:vollyball_stats/features/tournaments/data/models/competition_model.dart';
import 'package:vollyball_stats/features/tournaments/data/models/season_model.dart';

enum MatchesFilter { all, men, women }

const _errorSentinel = Object();
const _competitionSentinel = Object();
const _competitionInfoSentinel = Object();
const _seasonSentinel = Object();

class MatchesOverviewState {
  const MatchesOverviewState({
    required this.selectedFilter,
    required this.isLoadingCompetitions,
    required this.isLoadingSelection,
    required this.pageError,
    required this.competitions,
    required this.selectedCompetition,
    required this.selectedCompetitionInfo,
    required this.seasons,
    required this.selectedSeason,
    required this.matches,
    required this.hasLoadedCompetitions,
  });

  const MatchesOverviewState.initial()
    : selectedFilter = MatchesFilter.all,
      isLoadingCompetitions = true,
      isLoadingSelection = false,
      pageError = null,
      competitions = const [],
      selectedCompetition = null,
      selectedCompetitionInfo = null,
      seasons = const [],
      selectedSeason = null,
      matches = const [],
      hasLoadedCompetitions = false;

  final MatchesFilter selectedFilter;
  final bool isLoadingCompetitions;
  final bool isLoadingSelection;
  final String? pageError;
  final List<CompetitionModel> competitions;
  final CompetitionModel? selectedCompetition;
  final CompetitionInfoModel? selectedCompetitionInfo;
  final List<SeasonModel> seasons;
  final SeasonModel? selectedSeason;
  final List<MatchResult> matches;
  final bool hasLoadedCompetitions;

  MatchesOverviewState copyWith({
    MatchesFilter? selectedFilter,
    bool? isLoadingCompetitions,
    bool? isLoadingSelection,
    Object? pageError = _errorSentinel,
    List<CompetitionModel>? competitions,
    Object? selectedCompetition = _competitionSentinel,
    Object? selectedCompetitionInfo = _competitionInfoSentinel,
    List<SeasonModel>? seasons,
    Object? selectedSeason = _seasonSentinel,
    List<MatchResult>? matches,
    bool? hasLoadedCompetitions,
  }) {
    return MatchesOverviewState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoadingCompetitions:
          isLoadingCompetitions ?? this.isLoadingCompetitions,
      isLoadingSelection: isLoadingSelection ?? this.isLoadingSelection,
      pageError: identical(pageError, _errorSentinel)
          ? this.pageError
          : pageError as String?,
      competitions: competitions ?? this.competitions,
      selectedCompetition: identical(selectedCompetition, _competitionSentinel)
          ? this.selectedCompetition
          : selectedCompetition as CompetitionModel?,
      selectedCompetitionInfo: identical(
        selectedCompetitionInfo,
        _competitionInfoSentinel,
      )
          ? this.selectedCompetitionInfo
          : selectedCompetitionInfo as CompetitionInfoModel?,
      seasons: seasons ?? this.seasons,
      selectedSeason: identical(selectedSeason, _seasonSentinel)
          ? this.selectedSeason
          : selectedSeason as SeasonModel?,
      matches: matches ?? this.matches,
      hasLoadedCompetitions:
          hasLoadedCompetitions ?? this.hasLoadedCompetitions,
    );
  }
}
