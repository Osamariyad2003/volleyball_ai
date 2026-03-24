import 'package:dio/dio.dart';

import '../../../core/network/sportradar_client.dart';
import '../models/competitor.dart';
import '../models/competitor_comparison.dart';
import '../models/competitor_summary.dart';

class CompetitorFeedRepository {
  CompetitorFeedRepository(this._client);

  final SportradarClient _client;

  Future<Competitor> fetchCompetitorProfile(String competitorId) async {
    try {
      final response = await _client.getCompetitorProfile(competitorId);
      final json = _readJson(response.data);
      final competitor =
          (json['competitor'] as Map?)?.cast<String, dynamic>() ?? json;
      final category =
          (json['category'] as Map?)?.cast<String, dynamic>() ??
          (competitor['category'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      return Competitor.fromJson(
        competitor,
        categoryName: category['name']?.toString(),
      );
    } on DioException catch (error) {
      throw StateError(_mapDioError(error, 'competitor profile'));
    }
  }

  Future<List<CompetitorSummary>> fetchCompetitorSummaries(
    String competitorId,
  ) async {
    try {
      final response = await _client.getCompetitorSummaries(competitorId);
      final json = _readJson(response.data);
      final summaries = json['summaries'];
      if (summaries is List) {
        return summaries
            .whereType<Map>()
            .map(
              (item) => CompetitorSummary.fromJson({
                ...item.cast<String, dynamic>(),
                'competitor_id': competitorId,
              }),
            )
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      throw StateError(_mapDioError(error, 'competitor summaries'));
    }
  }

  Future<CompetitorComparison> fetchCompetitorVsCompetitor(
    String competitorAId,
    String competitorBId,
  ) async {
    try {
      final response = await _client.getCompetitorVsCompetitor(
        competitorAId,
        competitorBId,
      );
      final json = _readJson(response.data);
      return CompetitorComparison.fromJson(
        json,
        competitorAId: competitorAId,
        competitorBId: competitorBId,
      );
    } on DioException catch (error) {
      throw StateError(_mapDioError(error, 'competitor comparison'));
    }
  }

  Map<String, dynamic> _readJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    throw const FormatException('Unexpected competitor response format.');
  }

  String _mapDioError(DioException error, String resource) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 429) {
      return 'Too many requests were sent to Sportradar while loading $resource. Please wait a moment and try again.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Sportradar rejected the $resource request ($statusCode). Check the API key and access level configuration.';
    }
    return 'Unable to load $resource right now. Please try again.';
  }
}
