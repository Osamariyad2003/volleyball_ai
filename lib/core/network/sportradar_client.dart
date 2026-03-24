import 'package:dio/dio.dart';
import 'dio_client.dart';

class SportradarClient {
  final DioClient _dioClient;
  final String apiKey;
  final String accessLevel; // trial or production
  final String locale;

  SportradarClient({
    required DioClient dioClient,
    required this.apiKey,
    this.accessLevel = 'trial',
    this.locale = 'en',
  }) : _dioClient = dioClient;

  // GET /{locale}/competitions
  Future<Response> getCompetitions() async {
    return await _dioClient.get(
      '/$locale/competitions.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/competitions/{competition_urn}/info
  Future<Response> getCompetitionInfo(String competitionUrn) async {
    return await _dioClient.get(
      '/$locale/competitions/$competitionUrn/info.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/competitions/{competition_urn}/seasons
  Future<Response> getCompetitionSeasons(String competitionUrn) async {
    return await _dioClient.get(
      '/$locale/competitions/$competitionUrn/seasons.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/seasons/{season_urn}/competitors
  Future<Response> getSeasonCompetitors(String seasonUrn) async {
    return await _dioClient.get(
      '/$locale/seasons/$seasonUrn/competitors.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/seasons/{season_urn}/summaries
  Future<Response> getSeasonSummaries(String seasonUrn, {int? page}) async {
    return await _dioClient.get(
      '/$locale/seasons/$seasonUrn/summaries.json',
      queryParameters: {if (page != null) 'page': page},
      options: _authOptions(),
    );
  }

  // GET /{locale}/competitors/{competitor_urn}/profile
  Future<Response> getCompetitorProfile(String competitorUrn) async {
    return await _dioClient.get(
      '/$locale/competitors/$competitorUrn/profile.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/sport_events/{sport_event_urn}/summary
  Future<Response> getSportEventSummary(String eventUrn) async {
    return await _dioClient.get(
      '/$locale/sport_events/$eventUrn/summary.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/sport_events/{sport_event_urn}/timeline
  Future<Response> getSportEventTimeline(String eventUrn) async {
    return await _dioClient.get(
      '/$locale/sport_events/$eventUrn/timeline.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/sport_events/created
  Future<Response> getSportEventsCreated() async {
    return await _dioClient.get(
      '/$locale/sport_events/created.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/sport_events/removed
  Future<Response> getSportEventsRemoved() async {
    return await _dioClient.get(
      '/$locale/sport_events/removed.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/sport_events/updated
  Future<Response> getSportEventsUpdated() async {
    return await _dioClient.get(
      '/$locale/sport_events/updated.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/competitors/{competitor_urn}/summaries
  Future<Response> getCompetitorSummaries(String competitorUrn) async {
    return await _dioClient.get(
      '/$locale/competitors/$competitorUrn/summaries.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/competitors/{competitor_a_urn}/versus/{competitor_b_urn}/summaries
  Future<Response> getCompetitorVsCompetitor(
    String competitorAUrn,
    String competitorBUrn,
  ) async {
    return await _dioClient.get(
      '/$locale/competitors/$competitorAUrn/versus/$competitorBUrn/summaries.json',
      options: _authOptions(),
    );
  }

  // GET /{locale}/competitors/merge_mappings
  Future<Response> getCompetitorMergeMappings() async {
    return await _dioClient.get(
      '/$locale/competitors/merge_mappings.json',
      options: _authOptions(),
    );
  }

  Options _authOptions() {
    return Options(
      headers: {'accept': 'application/json', 'x-api-key': apiKey},
    );
  }
}
