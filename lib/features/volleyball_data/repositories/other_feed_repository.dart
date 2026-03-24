import 'package:dio/dio.dart';

import '../../../core/network/sportradar_client.dart';
import '../models/merge_mapping.dart';

class OtherFeedRepository {
  OtherFeedRepository(this._client);

  final SportradarClient _client;

  Future<List<MergeMapping>> fetchCompetitorMergeMappings() async {
    try {
      final response = await _client.getCompetitorMergeMappings();
      final json = _readJson(response.data);
      final mappings =
          json['merge_mappings'] ?? json['competitor_merge_mappings'];
      if (mappings is List) {
        return mappings
            .whereType<Map>()
            .map((item) => MergeMapping.fromJson(item.cast<String, dynamic>()))
            .toList();
      }
      return const [];
    } on DioException catch (error) {
      throw StateError(_mapDioError(error));
    }
  }

  Map<String, dynamic> _readJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    throw const FormatException('Unexpected merge mappings response format.');
  }

  String _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 429) {
      return 'Too many requests were sent to Sportradar while loading merge mappings. Please wait a moment and try again.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Sportradar rejected the merge mappings request ($statusCode). Check the API key and access level configuration.';
    }
    return 'Unable to load merge mappings right now. Please try again.';
  }
}
