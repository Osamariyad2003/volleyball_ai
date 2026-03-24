import '../models/sport_event.dart';
import '../models/sport_event_timeline.dart';
import '../repositories/sport_event_feed_repository.dart';

class SportEventFeedService {
  SportEventFeedService(this._repository);

  final SportEventFeedRepository _repository;
  final Map<String, SportEvent> _summaryCache = {};
  final Map<String, SportEventTimeline> _timelineCache = {};
  List<SportEvent>? _createdCache;
  List<SportEvent>? _removedCache;
  List<SportEvent>? _updatedCache;

  Future<SportEvent> fetchSportEventSummary(String eventId) async {
    final cached = _summaryCache[eventId];
    if (cached != null) {
      return cached;
    }
    final summary = await _repository.fetchSportEventSummary(eventId);
    _summaryCache[eventId] = summary;
    return summary;
  }

  Future<SportEventTimeline> fetchSportEventTimeline(String eventId) async {
    final cached = _timelineCache[eventId];
    if (cached != null) {
      return cached;
    }
    final timeline = await _repository.fetchSportEventTimeline(eventId);
    _timelineCache[eventId] = timeline;
    return timeline;
  }

  Future<List<SportEvent>> fetchSportEventsCreated() async {
    _createdCache ??= await _repository.fetchSportEventsCreated();
    return _createdCache!;
  }

  Future<List<SportEvent>> fetchSportEventsRemoved() async {
    _removedCache ??= await _repository.fetchSportEventsRemoved();
    return _removedCache!;
  }

  Future<List<SportEvent>> fetchSportEventsUpdated() async {
    _updatedCache ??= await _repository.fetchSportEventsUpdated();
    return _updatedCache!;
  }
}
