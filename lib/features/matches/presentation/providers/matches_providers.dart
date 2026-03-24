import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vollyball_stats/core/model/match_result.dart';
import 'package:vollyball_stats/core/net/StatsInteractor.dart';
import 'package:vollyball_stats/core/net/StatsInteractorImpl.dart';
import 'package:vollyball_stats/features/matches/data/repositories/matches_repository.dart';
import 'package:vollyball_stats/features/matches/presentation/controllers/matches_overview_controller.dart';
import 'package:vollyball_stats/features/matches/presentation/state/matches_overview_state.dart';
import 'package:vollyball_stats/features/tournaments/data/repositories/competition_repository.dart';

import '../../../../injection_container.dart' as di;

final matchesCompetitionRepositoryProvider = Provider<CompetitionRepository>((
  ref,
) {
  return di.sl<CompetitionRepository>();
});

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return di.sl<MatchesRepository>();
});

final statsInteractorProvider = Provider<StatsInteractor>((ref) {
  final interactor = StatsInteractorImpl();
  ref.onDispose(() => interactor.client.close());
  return interactor;
});

final seasonMatchesResultsProvider =
    FutureProvider.family<List<MatchResult>, String>((ref, seasonId) {
      return ref.watch(statsInteractorProvider).fetchMatchesAndResults(seasonId);
    });

final matchesOverviewControllerProvider =
    NotifierProvider<MatchesOverviewController, MatchesOverviewState>(
      MatchesOverviewController.new,
    );
