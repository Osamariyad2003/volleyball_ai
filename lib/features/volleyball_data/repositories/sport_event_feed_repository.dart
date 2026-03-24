import 'package:dio/dio.dart';

import '../../../core/network/sportradar_client.dart';
import '../models/sport_event.dart';
import '../models/sport_event_timeline.dart';

class SportEventFeedRepository {
  SportEventFeedRepository(this._client);

  final SportradarClient _client;

  Future<SportEvent> fetchSportEventSummary(String eventId) async {
    try {
      final response = await _client.getSportEventSummary(eventId);
      final json = _readJson(response.data);
      return SportEvent.fromJson(json);
    } on DioException catch (error) {
      throw StateError(_mapDioError(error, 'sport event summary'));
    }
  }

  Future<SportEventTimeline> fetchSportEventTimeline(String eventId) async {
    try {
      final response = await _client.getSportEventTimeline(eventId);
      final json = _readJson(response.data);
      return SportEventTimeline.fromJson(json);
    } on DioException catch (error) {
      throw StateError(_mapDioError(error, 'sport event timeline'));
    }
  }

  Future<List<SportEvent>> fetchSportEventsCreated() async {
    try {
      final response = await _client.getSportEventsCreated();
      final json = _readJson(response.data);
      return _readSportEvents(
        json,
        primaryKeys: const ['sport_event_created', 'sport_events_created'],
      );
    } on DioException catch (error) {
      throw StateError(_mapDioError(error, 'sport events created'));
    }
  }

  Future<List<SportEvent>> fetchSportEventsRemoved() async {
    try {
      final response = await _client.getSportEventsRemoved();
      final json = _readJson(response.data);
      return _readSportEvents(
        json,
        primaryKeys: const ['sport_event_removed', 'sport_events_removed'],
      );
    } on DioException catch (error) {
      throw StateError(_mapDioError(error, 'sport events removed'));
    }
  }

  Future<List<SportEvent>> fetchSportEventsUpdated() async {
    try {
      final response = await _client.getSportEventsUpdated();
      final json = _readJson(response.data);
      return _readSportEvents(
        json,
        primaryKeys: const [
          'sport_event_updated',
          'sport_events_updated',
          'sport_event_update',
        ],
      );
    } on DioException catch (error) {
      throw StateError(_mapDioError(error, 'sport events updated'));
    }
  }

  Map<String, dynamic> _readJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    throw const FormatException('Unexpected sport event response format.');
  }

  List<SportEvent> _readSportEvents(
    Map<String, dynamic> json, {
    required List<String> primaryKeys,
  }) {
    for (final key in primaryKeys) {
      final value = json[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => SportEvent.fromJson(item.cast<String, dynamic>()))
            .toList();
      }
    }
    return const [];
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
