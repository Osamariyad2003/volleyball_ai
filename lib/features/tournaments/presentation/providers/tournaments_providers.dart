import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../injection_container.dart' as di;
import '../../data/models/competition_model.dart';
import '../../data/models/season_model.dart';
import '../../data/repositories/competition_repository.dart';

enum CompetitionCategoryFilter { both, men, women }

final competitionRepositoryProvider = Provider<CompetitionRepository>((ref) {
  return di.sl<CompetitionRepository>();
});

final competitionCategoryFilterProvider =
    StateProvider<CompetitionCategoryFilter>((ref) {
      return CompetitionCategoryFilter.both;
    });

final competitionsProvider =
    AsyncNotifierProvider<CompetitionsController, List<CompetitionModel>>(
      CompetitionsController.new,
    );

final seasonsProvider =
    AsyncNotifierProvider.family<SeasonsController, List<SeasonModel>, String>(
      SeasonsController.new,
    );

class CompetitionsController extends AsyncNotifier<List<CompetitionModel>> {
  CompetitionRepository get _repository => ref.read(competitionRepositoryProvider);

  @override
  Future<List<CompetitionModel>> build() {
    return _repository.getCompetitions();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getCompetitions);
  }
}

class SeasonsController extends FamilyAsyncNotifier<List<SeasonModel>, String> {
  CompetitionRepository get _repository => ref.read(competitionRepositoryProvider);

  @override
  Future<List<SeasonModel>> build(String competitionUrn) {
    return _repository.getCompetitionSeasons(competitionUrn);
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getCompetitionSeasons(arg),
    );
  }
}
