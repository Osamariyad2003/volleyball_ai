import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/sportradar_client.dart';
import '../../../injection_container.dart' as di;
import '../repositories/competitor_feed_repository.dart';
import '../repositories/other_feed_repository.dart';
import '../repositories/sport_event_feed_repository.dart';
import '../services/competitor_feed_service.dart';
import '../services/other_feed_service.dart';
import '../services/sport_event_feed_service.dart';
import 'volleyball_data_controller.dart';
import 'volleyball_data_state.dart';

final volleyballFeedClientProvider = Provider<SportradarClient>((ref) {
  return di.sl<SportradarClient>();
});

final sportEventFeedRepositoryProvider = Provider<SportEventFeedRepository>((
  ref,
) {
  return SportEventFeedRepository(ref.watch(volleyballFeedClientProvider));
});

final competitorFeedRepositoryProvider = Provider<CompetitorFeedRepository>((
  ref,
) {
  return CompetitorFeedRepository(ref.watch(volleyballFeedClientProvider));
});

final otherFeedRepositoryProvider = Provider<OtherFeedRepository>((ref) {
  return OtherFeedRepository(ref.watch(volleyballFeedClientProvider));
});

final sportEventFeedServiceProvider = Provider<SportEventFeedService>((ref) {
  return SportEventFeedService(ref.watch(sportEventFeedRepositoryProvider));
});

final competitorFeedServiceProvider = Provider<CompetitorFeedService>((ref) {
  return CompetitorFeedService(ref.watch(competitorFeedRepositoryProvider));
});

final otherFeedServiceProvider = Provider<OtherFeedService>((ref) {
  return OtherFeedService(ref.watch(otherFeedRepositoryProvider));
});

final volleyballDataControllerProvider =
    StateNotifierProvider<VolleyballDataController, VolleyballDataState>((ref) {
      return VolleyballDataController(
        sportEventService: ref.watch(sportEventFeedServiceProvider),
        competitorService: ref.watch(competitorFeedServiceProvider),
        otherService: ref.watch(otherFeedServiceProvider),
      );
    });
