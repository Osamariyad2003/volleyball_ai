import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';

import '../data/hugging_face_coach_service.dart';
import '../data/models/coach_models.dart';
import '../data/services/alert_service.dart';
import '../data/session_storage_service.dart';
import '../data/voice_service.dart';

const _uuid = Uuid();

const defaultFollowups = <String>[
  "What's their setter doing this rotation?",
  'Where should we serve next?',
  "Who's their weakest passer?",
];

final storageServiceProvider = Provider<SessionStorageService>((ref) {
  return SessionStorageService();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier(ref.read(storageServiceProvider));
});

final coachTokenProvider = Provider<String>((ref) {
  return dotenv.env['HF_TOKEN']?.trim() ?? '';
});

final hasCoachTokenProvider = Provider<bool>((ref) {
  return ref.watch(coachTokenProvider).isNotEmpty;
});

final coachHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final coachServiceProvider = Provider<HuggingFaceCoachService>((ref) {
  return HuggingFaceCoachService(
    client: ref.watch(coachHttpClientProvider),
    token: ref.watch(coachTokenProvider),
  );
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  unawaited(service.init(settings: ref.read(settingsProvider)));
  ref.onDispose(service.dispose);
  return service;
});

final availableVoicesProvider = FutureProvider<List<VoiceOption>>((ref) async {
  final service = ref.watch(voiceServiceProvider);
  await service.init(settings: ref.read(settingsProvider));
  return service.getVoices();
});

final alertServiceProvider = Provider<AlertService>((ref) => AlertService());

final sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, List<MatchSession>>((ref) {
      return SessionHistoryNotifier(ref.read(storageServiceProvider));
    });

final matchSessionProvider =
    StateNotifierProvider<MatchSessionNotifier, MatchSession?>((ref) {
      final storage = ref.read(storageServiceProvider);
      final activeSessionId = ref.watch(
        settingsProvider.select((settings) => settings.activeSessionId),
      );
      final initial = activeSessionId == null
          ? null
          : storage.getSession(activeSessionId);
      return MatchSessionNotifier(initial);
    });

final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(matchSessionProvider)?.conversation ?? const [];
});

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, List<CoachingAlert>>((ref) {
      return AlertsNotifier();
    });

final isLoadingProvider = StateProvider<bool>((ref) => false);

final isListeningProvider = StateProvider<bool>((ref) => false);

final liveTranscriptProvider = StateProvider<String>((ref) => '');

final followupSuggestionsProvider = StateProvider<List<String>>((ref) {
  return defaultFollowups;
});

final coachControllerProvider = Provider<CoachController>((ref) {
  return CoachController(ref);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._storage) : super(_storage.loadSettings());

  final SessionStorageService _storage;

  Future<void> save(AppSettings settings) async {
    state = settings;
    await _storage.saveSettings(settings);
  }

  Future<void> update({
    String? voiceName,
    String? voiceLocale,
    double? speechRate,
    bool? autoSpeak,
    AppThemePreference? themePreference,
    String? activeSessionId,
    bool? hasSeenCoachWelcome,
    bool clearActiveSessionId = false,
  }) async {
    final next = state.copyWith(
      voiceName: voiceName,
      voiceLocale: voiceLocale,
      speechRate: speechRate,
      autoSpeak: autoSpeak,
      themePreference: themePreference,
      activeSessionId: activeSessionId,
      hasSeenCoachWelcome: hasSeenCoachWelcome,
      clearActiveSessionId: clearActiveSessionId,
    );
    await save(next);
  }
}

class SessionHistoryNotifier extends StateNotifier<List<MatchSession>> {
  SessionHistoryNotifier(this._storage) : super(_storage.allSessions());

  final SessionStorageService _storage;

  void refresh() {
    state = _storage.allSessions();
  }

  void upsert(MatchSession session) {
    final next = [...state.where((item) => item.id != session.id), session]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = next;
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}

class MatchSessionNotifier extends StateNotifier<MatchSession?> {
  MatchSessionNotifier(super.initialSession);

  void setSession(MatchSession? session) {
    state = session;
  }

  void updateSession(MatchSession session) {
    state = session;
  }

  void clear() {
    state = null;
  }
}

class AlertsNotifier extends StateNotifier<List<CoachingAlert>> {
  AlertsNotifier() : super(const []);

  void addAlerts(List<CoachingAlert> alerts) {
    state = [...alerts, ...state];
  }

  void dismiss(String id) {
    state = state.where((alert) => alert.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}

class CoachController {
  CoachController(this.ref);

  final Ref ref;

  MatchSession? get _currentSession => ref.read(matchSessionProvider);

  Future<void> createMatch({
    required String matchName,
    required String homeTeam,
    required String awayTeam,
  }) async {
    final settings = ref.read(settingsProvider);
    final session = MatchSession(
      id: _uuid.v4(),
      matchName: matchName.trim(),
      homeTeam: homeTeam.trim(),
      awayTeam: awayTeam.trim(),
      createdAt: DateTime.now(),
      rallies: const [],
      conversation: const [],
      currentSet: 1,
      currentRotation: 1,
      scoreHome: 0,
      scoreAway: 0,
      coachingMode: 'live',
      voiceId: settings.voiceId,
    );

    await _persistSession(session);
    await ref
        .read(settingsProvider.notifier)
        .update(activeSessionId: session.id);
    ref.read(followupSuggestionsProvider.notifier).state = defaultFollowups;
    ref.read(alertsProvider.notifier).clear();
    ref.read(liveTranscriptProvider.notifier).state = '';
  }

  Future<void> resumeSession(MatchSession session) async {
    ref.read(matchSessionProvider.notifier).setSession(session);
    ref
        .read(followupSuggestionsProvider.notifier)
        .state = session.conversation.isEmpty
        ? defaultFollowups
        : session.conversation.last.followups.isEmpty
        ? defaultFollowups
        : session.conversation.last.followups;
    await ref
        .read(settingsProvider.notifier)
        .update(activeSessionId: session.id);
  }

  Future<void> endCurrentSession() async {
    ref.read(matchSessionProvider.notifier).clear();
    ref.read(followupSuggestionsProvider.notifier).state = defaultFollowups;
    ref.read(alertsProvider.notifier).clear();
    await ref
        .read(settingsProvider.notifier)
        .update(clearActiveSessionId: true);
  }

  Future<void> addPoint(String winner) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }

    final updated = session.copyWith(
      scoreHome: winner == 'home' ? session.scoreHome + 1 : session.scoreHome,
      scoreAway: winner == 'away' ? session.scoreAway + 1 : session.scoreAway,
      rallies: [
        ...session.rallies,
        RallyRecord(
          rallyNumber: session.rallies.length + 1,
          winner: winner,
          pointType: null,
          serverTeam: null,
          setNumber: session.currentSet,
          rotation: session.currentRotation,
          scoreHome: winner == 'home'
              ? session.scoreHome + 1
              : session.scoreHome,
          scoreAway: winner == 'away'
              ? session.scoreAway + 1
              : session.scoreAway,
          timestamp: DateTime.now(),
        ),
      ],
    );

    await _persistSession(updated);
    await _handleAlerts(updated);
  }

  Future<void> removePoint(String team) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }

    if (team == 'home' && session.scoreHome == 0) {
      return;
    }
    if (team == 'away' && session.scoreAway == 0) {
      return;
    }

    var updatedRallies = List<RallyRecord>.from(session.rallies);
    if (updatedRallies.isNotEmpty && updatedRallies.last.winner == team) {
      updatedRallies.removeLast();
    }

    final updated = session.copyWith(
      scoreHome: team == 'home' ? session.scoreHome - 1 : session.scoreHome,
      scoreAway: team == 'away' ? session.scoreAway - 1 : session.scoreAway,
      rallies: updatedRallies,
    );

    await _persistSession(updated);
  }

  Future<void> updateRotation(int delta) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }
    final nextRotation =
        ((session.currentRotation - 1 + delta) % 6 + 6) % 6 + 1;
    await _persistSession(session.copyWith(currentRotation: nextRotation));
  }

  Future<void> updateSet(int delta) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }
    final nextSet = (session.currentSet + delta).clamp(1, 5);
    await _persistSession(session.copyWith(currentSet: nextSet));
  }

  Future<void> askQuestion(String question) async {
    final session = _currentSession;
    final trimmed = question.trim();
    if (session == null || trimmed.isEmpty) {
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(liveTranscriptProvider.notifier).state = trimmed;

    final coachMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'coach',
      text: trimmed,
      confidence: null,
      mode: 'live',
      followups: const [],
      timestamp: DateTime.now(),
    );

    final sessionWithQuestion = session.copyWith(
      conversation: [...session.conversation, coachMessage],
      coachingMode: 'live',
    );
    await _persistSession(sessionWithQuestion);

    final response = await ref
        .read(coachServiceProvider)
        .askLive(sessionWithQuestion, trimmed);

    final aiMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'ai',
      text: response.text,
      confidence: response.confidence,
      mode: response.mode,
      followups: response.followups,
      timestamp: DateTime.now(),
    );

    final sessionWithAnswer = sessionWithQuestion.copyWith(
      conversation: [...sessionWithQuestion.conversation, aiMessage],
      coachingMode: response.mode,
    );

    await _persistSession(sessionWithAnswer);
    ref.read(followupSuggestionsProvider.notifier).state = response.followups;
    ref.read(isLoadingProvider.notifier).state = false;

    if (ref.read(settingsProvider).autoSpeak) {
      await ref.read(voiceServiceProvider).speak(response.text);
    }
  }

  Future<void> requestTimeout() async {
    final session = _currentSession;
    if (session == null) {
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    final response = await ref.read(coachServiceProvider).quickTimeout(session);
    final aiMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'ai',
      text: response.text,
      confidence: response.confidence,
      mode: response.mode,
      followups: response.followups,
      timestamp: DateTime.now(),
    );

    final updated = session.copyWith(
      conversation: [...session.conversation, aiMessage],
      coachingMode: 'timeout',
    );
    await _persistSession(updated);
    ref.read(followupSuggestionsProvider.notifier).state =
        response.followups.isEmpty ? defaultFollowups : response.followups;
    ref.read(isLoadingProvider.notifier).state = false;

    if (ref.read(settingsProvider).autoSpeak) {
      await ref.read(voiceServiceProvider).speak(response.text);
    }
  }

  Future<void> playDebrief() async {
    final session = _currentSession;
    if (session == null) {
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    final response = await ref.read(coachServiceProvider).debrief(session);
    final aiMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'ai',
      text: response.text,
      confidence: response.confidence,
      mode: response.mode,
      followups: response.followups,
      timestamp: DateTime.now(),
    );

    final updated = session.copyWith(
      conversation: [...session.conversation, aiMessage],
      coachingMode: 'debrief',
    );
    await _persistSession(updated);
    ref.read(followupSuggestionsProvider.notifier).state = response.followups;
    ref.read(isLoadingProvider.notifier).state = false;

    if (ref.read(settingsProvider).autoSpeak) {
      await ref.read(voiceServiceProvider).speak(response.text);
    }
  }

  Future<void> buildDrill(String weakness) async {
    final session = _currentSession;
    final trimmed = weakness.trim();
    if (session == null || trimmed.isEmpty) {
      return;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    final response = await ref
        .read(coachServiceProvider)
        .drillForWeakness(session, trimmed);

    final aiMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'ai',
      text: response.text,
      confidence: response.confidence,
      mode: response.mode,
      followups: response.followups,
      timestamp: DateTime.now(),
    );

    final updated = session.copyWith(
      conversation: [...session.conversation, aiMessage],
      coachingMode: 'drill',
    );
    await _persistSession(updated);
    ref.read(followupSuggestionsProvider.notifier).state = response.followups;
    ref.read(isLoadingProvider.notifier).state = false;

    if (ref.read(settingsProvider).autoSpeak) {
      await ref.read(voiceServiceProvider).speak(response.text);
    }
  }

  Future<CoachResponse?> analyzeVideoFrame(
    Uint8List imageBytes, {
    String sourceLabel = 'live video frame',
  }) async {
    final session = _currentSession;
    if (session == null || imageBytes.isEmpty) {
      return null;
    }

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(liveTranscriptProvider.notifier).state =
        'Analyzing $sourceLabel...';

    final response = await ref
        .read(coachServiceProvider)
        .analyzeVideoFrame(session, imageBytes, sourceLabel: sourceLabel);

    final aiMessage = ChatMessage(
      id: _uuid.v4(),
      role: 'ai',
      text: response.text,
      confidence: response.confidence,
      mode: response.mode,
      followups: response.followups,
      timestamp: DateTime.now(),
    );

    final updated = session.copyWith(
      conversation: [...session.conversation, aiMessage],
      coachingMode: response.mode,
    );
    await _persistSession(updated);
    ref.read(followupSuggestionsProvider.notifier).state =
        response.followups.isEmpty ? defaultFollowups : response.followups;
    ref.read(isLoadingProvider.notifier).state = false;
    ref.read(liveTranscriptProvider.notifier).state = '';

    if (ref.read(settingsProvider).autoSpeak) {
      await ref.read(voiceServiceProvider).speak(response.text);
    }

    return response;
  }

  Future<void> replayMessage(ChatMessage message) async {
    await ref.read(voiceServiceProvider).speak(message.text);
  }

  Future<void> startListening() async {
    final session = _currentSession;
    if (session == null) {
      return;
    }

    ref.read(isListeningProvider.notifier).state = true;
    ref.read(liveTranscriptProvider.notifier).state = 'Listening...';

    await ref
        .read(voiceServiceProvider)
        .startListening(
          onPartial: (text) {
            ref.read(liveTranscriptProvider.notifier).state = text;
          },
          onFinal: (text) {
            ref.read(isListeningProvider.notifier).state = false;
            ref.read(liveTranscriptProvider.notifier).state = text;
            if (text.trim().isNotEmpty) {
              unawaited(askQuestion(text));
            }
          },
          onDone: () {
            ref.read(isListeningProvider.notifier).state = false;
          },
          onError: (message) {
            ref.read(isListeningProvider.notifier).state = false;
            ref.read(liveTranscriptProvider.notifier).state = message;
          },
        );
  }

  Future<void> stopListening() async {
    await ref.read(voiceServiceProvider).stopListening();
    ref.read(isListeningProvider.notifier).state = false;
    ref.read(liveTranscriptProvider.notifier).state = '';
  }

  Future<void> saveSettings(AppSettings settings) async {
    await ref.read(settingsProvider.notifier).save(settings);
    await ref.read(voiceServiceProvider).applySettings(settings);
  }

  Future<void> deleteSession(String id) async {
    await ref.read(storageServiceProvider).deleteSession(id);
    ref.read(sessionHistoryProvider.notifier).remove(id);
    final active = ref.read(matchSessionProvider);
    if (active?.id == id) {
      await endCurrentSession();
    }
  }

  void dismissAlert(String id) {
    ref.read(alertsProvider.notifier).dismiss(id);
  }

  MatchSession? findSession(String sessionId) {
    final current = ref.read(matchSessionProvider);
    if (current != null && current.id == sessionId) {
      return current;
    }

    try {
      return ref
          .read(sessionHistoryProvider)
          .firstWhere((item) => item.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSession(MatchSession session) async {
    await ref.read(storageServiceProvider).upsertSession(session);
    ref.read(matchSessionProvider.notifier).updateSession(session);
    ref.read(sessionHistoryProvider.notifier).upsert(session);
  }

  Future<void> _handleAlerts(MatchSession session) async {
    final candidates = ref.read(alertServiceProvider).checkForAlerts(session);
    if (candidates.isEmpty) {
      return;
    }

    final existing = ref.read(alertsProvider);
    final freshAlerts = candidates.where((alert) {
      return !existing.any(
        (current) =>
            current.category == alert.category &&
            current.message == alert.message,
      );
    }).toList();

    if (freshAlerts.isEmpty) {
      return;
    }

    ref.read(alertsProvider.notifier).addAlerts(freshAlerts);

    for (final alert in freshAlerts) {
      if (alert.priority == AlertPriority.critical) {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator) {
          await Vibration.vibrate(duration: 180);
        }
      }

      if (ref.read(settingsProvider).autoSpeak &&
          (alert.priority == AlertPriority.critical ||
              alert.priority == AlertPriority.high)) {
        await ref.read(voiceServiceProvider).speak(alert.message);
      }

      final duration = alert.priority == AlertPriority.critical
          ? const Duration(seconds: 8)
          : const Duration(seconds: 5);
      unawaited(
        Future<void>.delayed(duration, () {
          dismissAlert(alert.id);
        }),
      );
    }
  }
}
