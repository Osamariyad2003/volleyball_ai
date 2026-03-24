import '../models/competitor.dart';
import '../models/competitor_comparison.dart';
import '../models/competitor_summary.dart';
import '../models/merge_mapping.dart';
import '../models/sport_event.dart';
import '../models/sport_event_timeline.dart';

enum FeedStatus { idle, loading, success, error }

class FeedState<T> {
  const FeedState({required this.status, this.data, this.error});

  final FeedStatus status;
  final T? data;
  final String? error;

  const FeedState.idle() : this(status: FeedStatus.idle);
  const FeedState.loading() : this(status: FeedStatus.loading);
  const FeedState.success(T data)
    : this(status: FeedStatus.success, data: data);
  const FeedState.error(String error)
    : this(status: FeedStatus.error, error: error);
}

class VolleyballDataState {
  const VolleyballDataState({
    this.eventId = '',
    this.competitorId = '',
    this.competitorAId = '',
    this.competitorBId = '',
    this.sportEventSummary = const FeedState<SportEvent>.idle(),
    this.sportEventTimeline = const FeedState<SportEventTimeline>.idle(),
    this.sportEventsCreated = const FeedState<List<SportEvent>>.idle(),
    this.sportEventsRemoved = const FeedState<List<SportEvent>>.idle(),
    this.sportEventsUpdated = const FeedState<List<SportEvent>>.idle(),
    this.competitorProfile = const FeedState<Competitor>.idle(),
    this.competitorSummaries = const FeedState<List<CompetitorSummary>>.idle(),
    this.competitorComparison = const FeedState<CompetitorComparison>.idle(),
    this.mergeMappings = const FeedState<List<MergeMapping>>.idle(),
  });

  final String eventId;
  final String competitorId;
  final String competitorAId;
  final String competitorBId;
  final FeedState<SportEvent> sportEventSummary;
  final FeedState<SportEventTimeline> sportEventTimeline;
  final FeedState<List<SportEvent>> sportEventsCreated;
  final FeedState<List<SportEvent>> sportEventsRemoved;
  final FeedState<List<SportEvent>> sportEventsUpdated;
  final FeedState<Competitor> competitorProfile;
  final FeedState<List<CompetitorSummary>> competitorSummaries;
  final FeedState<CompetitorComparison> competitorComparison;
  final FeedState<List<MergeMapping>> mergeMappings;

  VolleyballDataState copyWith({
    String? eventId,
    String? competitorId,
    String? competitorAId,
    String? competitorBId,
    FeedState<SportEvent>? sportEventSummary,
    FeedState<SportEventTimeline>? sportEventTimeline,
    FeedState<List<SportEvent>>? sportEventsCreated,
    FeedState<List<SportEvent>>? sportEventsRemoved,
    FeedState<List<SportEvent>>? sportEventsUpdated,
    FeedState<Competitor>? competitorProfile,
    FeedState<List<CompetitorSummary>>? competitorSummaries,
    FeedState<CompetitorComparison>? competitorComparison,
    FeedState<List<MergeMapping>>? mergeMappings,
  }) {
    return VolleyballDataState(
      eventId: eventId ?? this.eventId,
      competitorId: competitorId ?? this.competitorId,
      competitorAId: competitorAId ?? this.competitorAId,
      competitorBId: competitorBId ?? this.competitorBId,
      sportEventSummary: sportEventSummary ?? this.sportEventSummary,
      sportEventTimeline: sportEventTimeline ?? this.sportEventTimeline,
      sportEventsCreated: sportEventsCreated ?? this.sportEventsCreated,
      sportEventsRemoved: sportEventsRemoved ?? this.sportEventsRemoved,
      sportEventsUpdated: sportEventsUpdated ?? this.sportEventsUpdated,
      competitorProfile: competitorProfile ?? this.competitorProfile,
      competitorSummaries: competitorSummaries ?? this.competitorSummaries,
      competitorComparison: competitorComparison ?? this.competitorComparison,
      mergeMappings: mergeMappings ?? this.mergeMappings,
    );
  }
}
