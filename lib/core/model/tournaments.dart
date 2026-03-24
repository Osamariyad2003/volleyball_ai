import 'package:vollyball_stats/core/model/tournament.dart';

class Tournaments {
  late List<Tournament> tournaments;

  Tournaments(this.tournaments);

  Tournaments.fromJson(Map<String, dynamic> json) {
    tournaments = (json['tournaments'] as List)
        .map((i) => Tournament.fromJson(i))
        .toList();
  }

  Map<String, dynamic> toJson() => {'tournaments': tournaments};
}
