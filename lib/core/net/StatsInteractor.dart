import 'dart:async';

import 'package:vollyball_stats/core/model/livestandings.dart';
import 'package:vollyball_stats/core/model/match_result.dart';
import 'package:vollyball_stats/core/model/team.dart';
import 'package:vollyball_stats/core/model/tournamentinfo.dart';
import 'package:vollyball_stats/core/model/tournaments.dart';

abstract class StatsInteractor {
  Future<Tournaments> fetchTournaments();

  Future<TournamentInfo> fetchTournamentInfo(String tournamentId);

  Future<LiveStandings> fetchTournamentStandings(String tournamentId);

  Future<List<Team>> fetchTeams(String seasonId);

  Future<List<MatchResult>> fetchMatchesAndResults(String seasonId);
}
