import 'package:dio/dio.dart';

import '../../../../core/network/sportradar_client.dart';
import '../models/competitor_model.dart';

class CompetitorRepository {
  final SportradarClient _client;
  final Map<String, List<CompetitorModel>> _competitorsCache = {};

  CompetitorRepository(this._client);

  Future<List<CompetitorModel>> getSeasonCompetitors(String seasonUrn) async {
    final cached = _competitorsCache[seasonUrn];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _client.getSeasonCompetitors(seasonUrn);
      if (response.statusCode == 200) {
        final data = CompetitorsResponse.fromJson(response.data);
        _competitorsCache[seasonUrn] = data.competitors;
        return data.competitors;
      }
      throw Exception('Failed to load competitors');
    } on DioException catch (e) {
      throw StateError(_mapDioError(e));
    }
  }

  String _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 429) {
      return 'Too many requests were sent to Sportradar while loading teams. Please wait a moment and try again.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Sportradar rejected the teams request ($statusCode). Check the API key and access level configuration.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The teams request timed out. Please check your connection and try again.';
    }

    return 'Unable to load teams right now. Please try again.';
  }
}
