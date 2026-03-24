import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/livestandings.dart';
import '../model/tournamentinfo.dart';
import '../model/tournaments.dart';
import 'StatsInteractor.dart';
import 'package:http/http.dart' as http;

const String tournamentsURL =
    "http://api.sportradar.com/volleyball-t1/indoor/en/tournaments.json?api_key=";
const String tournamentBasePath =
    "http://api.sportradar.com/volleyball-t1/indoor/en/tournaments/";
const String infoPath = "/info.json?api_key=";
const String standingsPath = "/live_standings.json?api_key=";
const String sportradarApiKeyEnv = 'SPORTRADAR_API_KEY';

class StatsInteractorImpl implements StatsInteractor {
  late http.Client client;

  StatsInteractorImpl() {
    client = http.Client();
  }

  String get _apiKey {
    final apiKey = dotenv.env[sportradarApiKeyEnv]?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError(
        'Missing $sportradarApiKeyEnv in .env. Add your Sportradar API key and restart the app.',
      );
    }
    return apiKey;
  }

  @override
  Future<Tournaments> fetchTournaments() async {
    final response = await client.get(Uri.parse(tournamentsURL + _apiKey));
    return Tournaments.fromJson(json.decode(response.body));
  }

  @override
  Future<TournamentInfo> fetchTournamentInfo(String tournamentId) async {
    final response = await client.get(
      Uri.parse(tournamentBasePath + tournamentId + infoPath + _apiKey),
    );
    return TournamentInfo.fromJson(json.decode(response.body));
  }

  @override
  Future<LiveStandings> fetchTournamentStandings(String tournamentId) async {
    final response = await client.get(
      Uri.parse(tournamentBasePath + tournamentId + standingsPath + _apiKey),
    );
    return LiveStandings.fromJson(json.decode(response.body));
  }
}
