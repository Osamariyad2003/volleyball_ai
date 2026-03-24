import 'package:dio/dio.dart';
import 'package:vollyball_stats/core/model/match_result.dart';

import '../../../../core/network/sportradar_client.dart';

class MatchesRepository {
  MatchesRepository(this._client);

  final SportradarClient _client;
  final Map<String, List<MatchResult>> _matchesCache = {};

  Future<List<MatchResult>> getSeasonMatches(String seasonUrn) async {
    final cached = _matchesCache[seasonUrn];
    if (cached != null) {
      return cached;
    }

    try {
      final matches = await _fetchAllSeasonMatches(seasonUrn);
      _matchesCache[seasonUrn] = matches;
      return matches;
    } on DioException catch (e) {
      throw StateError(_mapDioError(e));
    }
  }

  Future<List<MatchResult>> _fetchAllSeasonMatches(
    String seasonUrn, {
    int page = 1,
  }) async {
    final response = await _client.getSeasonSummaries(seasonUrn, page: page);
    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final summaries = (body['summaries'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => MatchResult.fromSummaryJson(item.cast<String, dynamic>()),
        )
        .toList();

    final nextPage = _extractNextPage(body);
    if (nextPage == null || nextPage <= page) {
      return summaries;
    }

    final nextMatches = await _fetchAllSeasonMatches(seasonUrn, page: nextPage);
    return [...summaries, ...nextMatches];
  }

  int? _extractNextPage(Map<String, dynamic> body) {
    final nextPage = body['next_page'];
    if (nextPage is int) {
      return nextPage;
    }

    final pagination = body['pagination'];
    if (pagination is Map<String, dynamic>) {
      final nestedNext = pagination['next_page'];
      if (nestedNext is int) {
        return nestedNext;
      }
      return int.tryParse(nestedNext?.toString() ?? '');
    }

    return int.tryParse(nextPage?.toString() ?? '');
  }

  String _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 429) {
      return 'Too many requests were sent to Sportradar while loading matches. Please wait a moment and try again.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Sportradar rejected the matches request ($statusCode). Check the API key and access level configuration.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The matches request timed out. Please check your connection and try again.';
    }

    return 'Unable to load matches right now. Please try again.';
  }
}
