import 'package:dio/dio.dart';

import '../../../../core/network/sportradar_client.dart';
import '../models/competition_info_model.dart';
import '../models/competition_model.dart';
import '../models/season_model.dart';

class CompetitionRepository {
  final SportradarClient _client;
  List<CompetitionModel>? _competitionsCache;
  final Map<String, List<SeasonModel>> _seasonsCache = {};
  final Map<String, CompetitionInfoModel> _competitionInfoCache = {};

  CompetitionRepository(this._client);

  Future<List<CompetitionModel>> getCompetitions() async {
    if (_competitionsCache != null) {
      return _competitionsCache!;
    }

    try {
      final response = await _client.getCompetitions();
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final data = CompetitionsResponse.fromJson(response.data);
      _competitionsCache = data.competitions;
      return data.competitions;
    } on DioException catch (e) {
      throw StateError(_mapDioError(e, resource: 'competitions'));
    }
  }

  Future<List<SeasonModel>> getCompetitionSeasons(String competitionUrn) async {
    final cached = _seasonsCache[competitionUrn];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _client.getCompetitionSeasons(competitionUrn);
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final data = SeasonsResponse.fromJson(response.data);
      _seasonsCache[competitionUrn] = data.seasons;
      return data.seasons;
    } on DioException catch (e) {
      throw StateError(_mapDioError(e, resource: 'seasons'));
    }
  }

  Future<CompetitionInfoModel> getCompetitionInfo(String competitionUrn) async {
    final cached = _competitionInfoCache[competitionUrn];
    if (cached != null) {
      return cached;
    }

    try {
      final response = await _client.getCompetitionInfo(competitionUrn);
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      final data = CompetitionInfoModel.fromJson(response.data);
      _competitionInfoCache[competitionUrn] = data;
      return data;
    } on DioException catch (e) {
      throw StateError(_mapDioError(e, resource: 'competition info'));
    }
  }

  String _mapDioError(DioException error, {required String resource}) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 429) {
      return 'Too many requests were sent to Sportradar while loading $resource. Please wait a moment and try again.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Sportradar rejected the $resource request ($statusCode). Check the API key and access level configuration.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The $resource request timed out. Please check your connection and try again.';
    }

    return 'Unable to load $resource right now. Please try again.';
  }
}
