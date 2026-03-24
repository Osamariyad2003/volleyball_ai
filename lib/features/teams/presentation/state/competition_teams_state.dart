import '../../data/models/competitor_model.dart';
import '../../../tournaments/data/models/season_model.dart';

class CompetitionTeamsState {
  const CompetitionTeamsState({
    required this.season,
    required this.competitors,
  });

  final SeasonModel season;
  final List<CompetitorModel> competitors;
}
