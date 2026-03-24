import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vollyball_stats/core/model/livestandings.dart';
import 'package:vollyball_stats/core/model/match_result.dart';
import 'package:vollyball_stats/core/model/team.dart';
import 'package:vollyball_stats/core/model/tournamentinfo.dart';
import 'package:vollyball_stats/core/model/tournaments.dart';
import 'package:vollyball_stats/core/net/StatsInteractor.dart';

const String tournamentsURL =
    "http://api.sportradar.com/volleyball-t1/indoor/en/tournaments.json";
const String tournamentBasePath =
    "http://api.sportradar.com/volleyball-t1/indoor/en/tournaments/";
const String seasonBasePath =
    "https://api.sportradar.com/volleyball/trial/v2/en/seasons/";
const String infoPath = "/info.json";
const String standingsPath = "/live_standings.json";
const String competitorsPath = "/competitors.json";
const String summariesPath = "/summaries.json";
const String _sportradarApiKeyEnv = 'SPORTRADAR_API_KEY';

class StatsInteractorImpl implements StatsInteractor {
  late http.Client client;

  StatsInteractorImpl() {
    client = http.Client();
  }

  String get _apiKey {
    final apiKey = dotenv.env[_sportradarApiKeyEnv]?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError(
        'Missing $_sportradarApiKeyEnv in .env. Add your Sportradar API key and restart the app.',
      );
    }
    return apiKey;
  }

  Map<String, String> get _headers => {
    'accept': 'application/json',
    'x-api-key': _apiKey,
  };

  @override
  Future<Tournaments> fetchTournaments() async {
    final response = await client.get(
      Uri.parse(tournamentsURL),
      headers: _headers,
    );
    return Tournaments.fromJson(json.decode(response.body));
  }

  @override
  Future<TournamentInfo> fetchTournamentInfo(String tournamentId) async {
    final response = await client.get(
      Uri.parse(tournamentBasePath + tournamentId + infoPath),
      headers: _headers,
    );
    return TournamentInfo.fromJson(json.decode(response.body));
  }

  @override
  Future<LiveStandings> fetchTournamentStandings(String tournamentId) async {
    final response = await client.get(
      Uri.parse(tournamentBasePath + tournamentId + standingsPath),
      headers: _headers,
    );
    return LiveStandings.fromJson(json.decode(response.body));
  }

  @override
  Future<List<Team>> fetchTeams(String seasonId) async {
    final response = await client.get(
      Uri.parse(seasonBasePath + seasonId + competitorsPath),
      headers: _headers,
    );

    final body = json.decode(response.body) as Map<String, dynamic>;
    final rawCompetitors =
        body['competitors'] ??
        body['season_competitors'] ??
        body['competitor'] ??
        (body['season'] is Map<String, dynamic>
            ? (body['season'] as Map<String, dynamic>)['competitors']
            : null);

    if (rawCompetitors is! List) {
      return [];
    }

    return rawCompetitors
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => Team(
            item['id']?.toString() ?? '',
            item['name']?.toString() ?? '',
            item['country']?.toString() ?? '',
            item['country_code']?.toString() ?? '',
            item['abbreviation']?.toString() ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<List<MatchResult>> fetchMatchesAndResults(String seasonId) async {
    final response = await client.get(
      Uri.parse(seasonBasePath + seasonId + summariesPath),
      headers: _headers,
    );

    final body = json.decode(response.body) as Map<String, dynamic>;
    final rawSummaries = body['summaries'];
    if (rawSummaries is! List) {
      return [];
    }

    return rawSummaries
        .whereType<Map>()
        .map(
          (item) => MatchResult.fromSummaryJson(item.cast<String, dynamic>()),
        )
        .toList();
  }
}
