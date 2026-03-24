import 'sport_event.dart';
import 'sport_event_status.dart';

class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.type,
    this.competitor,
    this.time,
    this.homeScore,
    this.awayScore,
    this.period,
    this.periodName,
    this.breakName,
  });

  final String id;
  final String type;
  final String? competitor;
  final DateTime? time;
  final int? homeScore;
  final int? awayScore;
  final int? period;
  final String? periodName;
  final String? breakName;

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'event',
      competitor: json['competitor']?.toString(),
      time: DateTime.tryParse(json['time']?.toString() ?? ''),
      homeScore: _toInt(json['home_score']),
      awayScore: _toInt(json['away_score']),
      period: _toInt(json['period']),
      periodName: json['period_name']?.toString(),
      breakName: json['break_name']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }
}

class SportEventTimeline {
  const SportEventTimeline({
    required this.sportEvent,
    this.status,
    this.entries = const [],
  });

  final SportEvent sportEvent;
  final SportEventStatus? status;
  final List<TimelineEntry> entries;

  factory SportEventTimeline.fromJson(Map<String, dynamic> json) {
    final timelineRoot =
        (json['sport_event_timeline'] as Map?)?.cast<String, dynamic>() ?? json;
    final entries = _readTimelineEntries(timelineRoot['timeline']);
    final statusJson =
        (timelineRoot['sport_event_status'] as Map?)?.cast<String, dynamic>() ??
        (json['sport_event_status'] as Map?)?.cast<String, dynamic>();

    return SportEventTimeline(
      sportEvent: SportEvent.fromJson(timelineRoot, fallbackStatus: statusJson),
      status: statusJson == null ? null : SportEventStatus.fromJson(statusJson),
      entries: entries,
    );
  }

  static List<TimelineEntry> _readTimelineEntries(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => TimelineEntry.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      final nested = raw['event'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((item) => TimelineEntry.fromJson(item.cast<String, dynamic>()))
            .toList();
      }
    }
    return const [];
  }
}
