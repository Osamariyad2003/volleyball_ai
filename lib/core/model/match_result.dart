class MatchResult {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeam;
  final String awayTeam;
  final String status;
  final DateTime? scheduledAt;
  final int? homeScore;
  final int? awayScore;
  final String? winnerId;

  MatchResult({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    this.scheduledAt,
    this.homeScore,
    this.awayScore,
    this.winnerId,
  });

  factory MatchResult.fromSummaryJson(Map<String, dynamic> json) {
    final sportEvent =
        (json['sport_event'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final sportEventStatus =
        (json['sport_event_status'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final competitors =
        (sportEvent['competitors'] as List?)
            ?.whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    final home = _findCompetitor(competitors, 'home');
    final away = _findCompetitor(competitors, 'away');

    return MatchResult(
      id: sportEvent['id']?.toString() ?? '',
      homeTeamId: home['id']?.toString() ?? '',
      awayTeamId: away['id']?.toString() ?? '',
      homeTeam: home['name']?.toString() ?? 'Home',
      awayTeam: away['name']?.toString() ?? 'Away',
      status:
          sportEventStatus['status']?.toString() ??
          sportEvent['status']?.toString() ??
          'unknown',
      scheduledAt: DateTime.tryParse(
        sportEvent['start_time']?.toString() ??
            sportEvent['scheduled']?.toString() ??
            '',
      ),
      homeScore: _toInt(sportEventStatus['home_score']),
      awayScore: _toInt(sportEventStatus['away_score']),
      winnerId: sportEventStatus['winner_id']?.toString(),
    );
  }

  static Map<String, dynamic> _findCompetitor(
    List<Map<String, dynamic>> competitors,
    String qualifier,
  ) {
    return competitors.firstWhere(
      (competitor) => competitor['qualifier'] == qualifier,
      orElse: () => const <String, dynamic>{},
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
