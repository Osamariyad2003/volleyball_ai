import 'sport_event.dart';

class CompetitorSummary {
  const CompetitorSummary({required this.sportEvent, this.role});

  final SportEvent sportEvent;
  final String? role;

  factory CompetitorSummary.fromJson(Map<String, dynamic> json) {
    final sportEvent = SportEvent.fromJson(json);
    String? role;
    final homeId = sportEvent.homeCompetitor?.id;
    final awayId = sportEvent.awayCompetitor?.id;
    final competitorId = json['competitor_id']?.toString();
    if (competitorId != null && competitorId.isNotEmpty) {
      if (competitorId == homeId) {
        role = 'home';
      } else if (competitorId == awayId) {
        role = 'away';
      }
    }
    return CompetitorSummary(sportEvent: sportEvent, role: role);
  }
}
