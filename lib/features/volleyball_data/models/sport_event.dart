import 'competitor.dart';
import 'sport_event_status.dart';

class SportEvent {
  const SportEvent({
    required this.id,
    required this.name,
    this.startTime,
    this.tournamentName,
    this.categoryName,
    this.gender,
    this.seasonId,
    this.seasonName,
    this.homeCompetitor,
    this.awayCompetitor,
    this.status,
  });

  final String id;
  final String name;
  final DateTime? startTime;
  final String? tournamentName;
  final String? categoryName;
  final String? gender;
  final String? seasonId;
  final String? seasonName;
  final Competitor? homeCompetitor;
  final Competitor? awayCompetitor;
  final SportEventStatus? status;

  factory SportEvent.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? fallbackStatus,
  }) {
    final sportEvent =
        (json['sport_event'] as Map?)?.cast<String, dynamic>() ?? json;
    final context =
        (sportEvent['sport_event_context'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final competition =
        (context['competition'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final category =
        (context['category'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final season =
        (context['season'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final competitors = _readCompetitors(
      sportEvent['competitors'],
      category['name']?.toString(),
    );
    final home = _findCompetitor(competitors, 'home');
    final away = _findCompetitor(competitors, 'away');
    final statusJson =
        (json['sport_event_status'] as Map?)?.cast<String, dynamic>() ??
        fallbackStatus;

    return SportEvent(
      id: sportEvent['id']?.toString() ?? json['id']?.toString() ?? '',
      name:
          sportEvent['name']?.toString() ??
          competition['name']?.toString() ??
          'Sport event',
      startTime: DateTime.tryParse(
        sportEvent['start_time']?.toString() ??
            sportEvent['scheduled']?.toString() ??
            json['created_at']?.toString() ??
            json['updated_at']?.toString() ??
            '',
      ),
      tournamentName: competition['name']?.toString(),
      categoryName: category['name']?.toString(),
      gender: competition['gender']?.toString(),
      seasonId: season['id']?.toString(),
      seasonName: season['name']?.toString(),
      homeCompetitor: home,
      awayCompetitor: away,
      status: statusJson == null ? null : SportEventStatus.fromJson(statusJson),
    );
  }

  static List<Competitor> _readCompetitors(dynamic raw, String? categoryName) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (item) => Competitor.fromJson(
              item.cast<String, dynamic>(),
              categoryName: categoryName,
            ),
          )
          .toList();
    }

    if (raw is Map<String, dynamic>) {
      final nested = raw['competitor'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map(
              (item) => Competitor.fromJson(
                item.cast<String, dynamic>(),
                categoryName: categoryName,
              ),
            )
            .toList();
      }
    }

    return const [];
  }

  static Competitor? _findCompetitor(
    List<Competitor> competitors,
    String qualifier,
  ) {
    for (final competitor in competitors) {
      if (competitor.qualifier == qualifier) {
        return competitor;
      }
    }
    return competitors.isEmpty ? null : competitors.first;
  }
}
