import 'package:vollyball_stats/core/model/standingsteamentry.dart';

class StandingsGroup {
  String name;
  String group_name;
  List<StandingsTeamEntry> team_standings;

  StandingsGroup({required this.group_name, required this.team_standings})
    : name = "";

  StandingsGroup.fromJson(Map<String, dynamic> json)
    : team_standings = (json['team_standings'] as List)
          .map((i) => StandingsTeamEntry.fromJson(i))
          .toList(),
      group_name = json['group_name'],
      name = json['name'];

  Map<String, dynamic> toJson() => {
    'team_standings': team_standings,
    'group_name': group_name,
    'name': name,
  };
}
