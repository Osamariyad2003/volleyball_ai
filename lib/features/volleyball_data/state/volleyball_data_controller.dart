import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/competitor_feed_service.dart';
import '../services/other_feed_service.dart';
import '../services/sport_event_feed_service.dart';
import 'volleyball_data_state.dart';

class VolleyballDataController extends StateNotifier<VolleyballDataState> {
  VolleyballDataController({
    required SportEventFeedService sportEventService,
    required CompetitorFeedService competitorService,
    required OtherFeedService otherService,
  }) : _sportEventService = sportEventService,
       _competitorService = competitorService,
       _otherService = otherService,
       super(const VolleyballDataState());

  final SportEventFeedService _sportEventService;
  final CompetitorFeedService _competitorService;
  final OtherFeedService _otherService;

  void setEventId(String value) {
    state = state.copyWith(eventId: value.trim());
  }

  void setCompetitorId(String value) {
    state = state.copyWith(competitorId: value.trim());
  }

  void setCompetitorAId(String value) {
    state = state.copyWith(competitorAId: value.trim());
  }

  void setCompetitorBId(String value) {
    state = state.copyWith(competitorBId: value.trim());
  }

  Future<void> fetchSportEventSummary([String? eventId]) async {
    final id = (eventId ?? state.eventId).trim();
    if (id.isEmpty) {
      state = state.copyWith(
        sportEventSummary: const FeedState.error(
          'Enter a sport event id first.',
        ),
      );
      return;
    }

    state = state.copyWith(
      eventId: id,
      sportEventSummary: const FeedState.loading(),
    );
    try {
      final data = await _sportEventService.fetchSportEventSummary(id);
      state = state.copyWith(sportEventSummary: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(
        sportEventSummary: FeedState.error(error.toString()),
      );
    }
  }

  Future<void> fetchSportEventTimeline([String? eventId]) async {
    final id = (eventId ?? state.eventId).trim();
    if (id.isEmpty) {
      state = state.copyWith(
        sportEventTimeline: const FeedState.error(
          'Enter a sport event id first.',
        ),
      );
      return;
    }

    state = state.copyWith(
      eventId: id,
      sportEventTimeline: const FeedState.loading(),
    );
    try {
      final data = await _sportEventService.fetchSportEventTimeline(id);
      state = state.copyWith(sportEventTimeline: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(
        sportEventTimeline: FeedState.error(error.toString()),
      );
    }
  }

  Future<void> fetchSportEventsCreated() async {
    state = state.copyWith(sportEventsCreated: const FeedState.loading());
    try {
      final data = await _sportEventService.fetchSportEventsCreated();
      state = state.copyWith(sportEventsCreated: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(
        sportEventsCreated: FeedState.error(error.toString()),
      );
    }
  }

  Future<void> fetchSportEventsRemoved() async {
    state = state.copyWith(sportEventsRemoved: const FeedState.loading());
    try {
      final data = await _sportEventService.fetchSportEventsRemoved();
      state = state.copyWith(sportEventsRemoved: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(
        sportEventsRemoved: FeedState.error(error.toString()),
      );
    }
  }

  Future<void> fetchSportEventsUpdated() async {
    state = state.copyWith(sportEventsUpdated: const FeedState.loading());
    try {
      final data = await _sportEventService.fetchSportEventsUpdated();
      state = state.copyWith(sportEventsUpdated: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(
        sportEventsUpdated: FeedState.error(error.toString()),
      );
    }
  }

  Future<void> fetchCompetitorProfile([String? competitorId]) async {
    final id = (competitorId ?? state.competitorId).trim();
    if (id.isEmpty) {
      state = state.copyWith(
        competitorProfile: const FeedState.error(
          'Enter a competitor id first.',
        ),
      );
      return;
    }

    state = state.copyWith(
      competitorId: id,
      competitorProfile: const FeedState.loading(),
    );
    try {
      final data = await _competitorService.fetchCompetitorProfile(id);
      state = state.copyWith(competitorProfile: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(
        competitorProfile: FeedState.error(error.toString()),
      );
    }
  }

  Future<void> fetchCompetitorSummaries([String? competitorId]) async {
    final id = (competitorId ?? state.competitorId).trim();
    if (id.isEmpty) {
      state = state.copyWith(
        competitorSummaries: const FeedState.error(
          'Enter a competitor id first.',
        ),
      );
      return;
    }

    state = state.copyWith(
      competitorId: id,
      competitorSummaries: const FeedState.loading(),
    );
    try {
      final data = await _competitorService.fetchCompetitorSummaries(id);
      state = state.copyWith(competitorSummaries: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(
        competitorSummaries: FeedState.error(error.toString()),
      );
    }
  }

  Future<void> fetchCompetitorVsCompetitor({
    String? competitorAId,
    String? competitorBId,
  }) async {
    final first = (competitorAId ?? state.competitorAId).trim();
    final second = (competitorBId ?? state.competitorBId).trim();
    if (first.isEmpty || second.isEmpty) {
      state = state.copyWith(
        competitorComparison: const FeedState.error(
          'Enter both competitor ids first.',
        ),
      );
      return;
    }

    state = state.copyWith(
      competitorAId: first,
      competitorBId: second,
      competitorComparison: const FeedState.loading(),
    );
    try {
      final data = await _competitorService.fetchCompetitorVsCompetitor(
        first,
        second,
      );
      state = state.copyWith(competitorComparison: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(
        competitorComparison: FeedState.error(error.toString()),
      );
    }
  }

  Future<void> fetchCompetitorMergeMappings() async {
    state = state.copyWith(mergeMappings: const FeedState.loading());
    try {
      final data = await _otherService.fetchCompetitorMergeMappings();
      state = state.copyWith(mergeMappings: FeedState.success(data));
    } catch (error) {
      state = state.copyWith(mergeMappings: FeedState.error(error.toString()));
    }
  }
}
