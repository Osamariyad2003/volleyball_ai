class PeriodScore {
  const PeriodScore({
    required this.number,
    required this.type,
    this.homeScore,
    this.awayScore,
  });

  final int number;
  final String type;
  final int? homeScore;
  final int? awayScore;

  factory PeriodScore.fromJson(Map<String, dynamic> json) {
    return PeriodScore(
      number: _toInt(json['number']) ?? 0,
      type: json['type']?.toString() ?? 'period',
      homeScore: _toInt(json['home_score']),
      awayScore: _toInt(json['away_score']),
    );
  }
}

class SportEventStatus {
  const SportEventStatus({
    required this.status,
    this.matchStatus,
    this.homeScore,
    this.awayScore,
    this.winnerId,
    this.aggregateHomeScore,
    this.aggregateAwayScore,
    this.aggregateWinnerId,
    this.periodScores = const [],
  });

  final String status;
  final String? matchStatus;
  final int? homeScore;
  final int? awayScore;
  final String? winnerId;
  final int? aggregateHomeScore;
  final int? aggregateAwayScore;
  final String? aggregateWinnerId;
  final List<PeriodScore> periodScores;

  factory SportEventStatus.fromJson(Map<String, dynamic> json) {
    final periodScores = _readList(
      json['period_scores'],
    ).map(PeriodScore.fromJson).toList();

    return SportEventStatus(
      status: json['status']?.toString() ?? 'unknown',
      matchStatus: json['match_status']?.toString(),
      homeScore: _toInt(json['home_score']),
      awayScore: _toInt(json['away_score']),
      winnerId: json['winner_id']?.toString(),
      aggregateHomeScore: _toInt(json['aggregate_home_score']),
      aggregateAwayScore: _toInt(json['aggregate_away_score']),
      aggregateWinnerId: json['aggregate_winner_id']?.toString(),
      periodScores: periodScores,
    );
  }

  static List<Map<String, dynamic>> _readList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    if (value is Map<String, dynamic>) {
      final nested = value['period_score'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
      }
    }
    return const [];
  }
}

int? _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '');
}
