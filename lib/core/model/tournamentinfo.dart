import 'package:vollyball_stats/core/model/group.dart';
import 'package:vollyball_stats/core/model/tournament.dart';

class TournamentInfo {
  late List<Group> groups;
  late Tournament tournament;

  TournamentInfo({required this.groups, required this.tournament});

  TournamentInfo.fromJson(Map<String, dynamic> json) {
    tournament = Tournament.fromJson(json['tournament']);
    groups = (json['groups'] as List).map((i) => Group.fromJson(i)).toList();
  }

  Map<String, dynamic> toJson() => {'groups': groups};
}
