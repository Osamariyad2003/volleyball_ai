import 'dart:async';
import '../model/livestandings.dart';
import '../model/tournamentinfo.dart';
import '../model/tournaments.dart';

abstract class StatsInteractor {
  Future<Tournaments> fetchTournaments();

  Future<TournamentInfo> fetchTournamentInfo(String tournamentId);

  Future<LiveStandings> fetchTournamentStandings(String tournamentId);
}
