import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/coaching_prompts.dart';
import 'models/coach_models.dart';

const defaultFallbackFollowups = <String>[
  "What's their setter doing this rotation?",
  'Where should we serve next?',
  "Who's their weakest passer?",
];

class GeminiCoachService {
  GeminiCoachService(this.apiKey)
    : _liveModel = _buildModel(
        apiKey: apiKey,
        prompt: liveCoachPrompt,
        temperature: 0.4,
        maxOutputTokens: 256,
      ),
      _timeoutModel = _buildModel(
        apiKey: apiKey,
        prompt: timeoutPrompt,
        temperature: 0.3,
        maxOutputTokens: 128,
      ),
      _debriefModel = _buildModel(
        apiKey: apiKey,
        prompt: debriefPrompt,
        temperature: 0.4,
        maxOutputTokens: 1024,
      ),
      _drillModel = _buildModel(
        apiKey: apiKey,
        prompt: drillPrompt,
        temperature: 0.5,
        maxOutputTokens: 512,
      ),
      _videoScoutModel = _buildModel(
        apiKey: apiKey,
        prompt: videoScoutPrompt,
        temperature: 0.3,
        maxOutputTokens: 192,
      );

  final String apiKey;
  final GenerativeModel? _liveModel;
  final GenerativeModel? _timeoutModel;
  final GenerativeModel? _debriefModel;
  final GenerativeModel? _drillModel;
  final GenerativeModel? _videoScoutModel;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<CoachResponse> askLive(MatchSession match, String question) async {
    if (!isConfigured || _liveModel == null) {
      return const CoachResponse(
        text:
            'Add your Gemini API key in Settings so I can answer live coaching questions.',
        followups: defaultFallbackFollowups,
        confidence: 0.25,
        mode: 'live',
      );
    }

    final prompt =
        '''
${_buildMatchContext(match)}

RECENT CONVERSATION:
${_buildConversationContext(match)}

COACH ASKS: $question
''';

    try {
      final response = await _liveModel.generateContent([Content.text(prompt)]);
      return CoachResponse(
        text: _cleanResponse(response.text, 'I need more data to answer that.'),
        followups: _generateFollowups(question),
        confidence: match.rallies.length > 10 ? 0.85 : 0.55,
        mode: 'live',
      );
    } catch (_) {
      return const CoachResponse(
        text:
            'I lost the line to Gemini for a moment. Ask me again in one sentence.',
        followups: defaultFallbackFollowups,
        confidence: 0.2,
        mode: 'live',
      );
    }
  }

  Future<CoachResponse> quickTimeout(MatchSession match) async {
    if (!isConfigured || _timeoutModel == null) {
      return const CoachResponse(
        text:
            'When they speed us up in serve receive, we need to settle first contact and attack high hands.',
        followups: <String>[],
        confidence: 0.45,
        mode: 'timeout',
      );
    }

    final prompt =
        '''
${_buildMatchContext(match)}

Give me the ONE most impactful adjustment for this timeout.
''';

    try {
      final response = await _timeoutModel.generateContent([
        Content.text(prompt),
      ]);
      return CoachResponse(
        text: _cleanResponse(
          response.text,
          'Regroup and focus on serve receive.',
        ),
        followups: const [
          'What serve target changes that?',
          'Which rotation needs the adjustment most?',
        ],
        confidence: 0.8,
        mode: 'timeout',
      );
    } catch (_) {
      return const CoachResponse(
        text:
            'When they get us moving, we need to simplify and side out on the first good swing.',
        followups: <String>[],
        confidence: 0.35,
        mode: 'timeout',
      );
    }
  }

  Future<CoachResponse> debrief(MatchSession match) async {
    if (!isConfigured || _debriefModel == null) {
      return const CoachResponse(
        text:
            'Match data is saved locally, but Gemini needs an API key before I can deliver a spoken debrief.',
        followups: <String>[
          'What drills should we run next?',
          'Which rotation hurt us most?',
        ],
        confidence: 0.2,
        mode: 'debrief',
      );
    }

    final prompt =
        '''
${_buildMatchContext(match)}

Total rallies: ${match.rallies.length}
Final score: ${match.scoreHome}-${match.scoreAway}

Give me a complete post-match debrief.
''';

    try {
      final response = await _debriefModel.generateContent([
        Content.text(prompt),
      ]);
      return CoachResponse(
        text: _cleanResponse(
          response.text,
          'Match data insufficient for debrief.',
        ),
        followups: const [
          'What drills should we run?',
          'How was our reception?',
        ],
        confidence: 0.9,
        mode: 'debrief',
      );
    } catch (_) {
      return const CoachResponse(
        text:
            'I could not build the full debrief right now, but your session data is still saved for review.',
        followups: <String>[
          'What drills should we run?',
          'Which rotation struggled?',
        ],
        confidence: 0.25,
        mode: 'debrief',
      );
    }
  }

  Future<CoachResponse> drillForWeakness(
    MatchSession match,
    String weakness,
  ) async {
    if (!isConfigured || _drillModel == null) {
      return const CoachResponse(
        text:
            'Add your Gemini API key in Settings, then I can turn that weakness into a practical drill.',
        followups: <String>[
          'Give me a serve receive drill',
          'Give me a blocking drill',
        ],
        confidence: 0.2,
        mode: 'drill',
      );
    }

    final prompt =
        '''
${_buildMatchContext(match)}

WEAKNESS: $weakness

Design a practice drill to fix this.
''';

    try {
      final response = await _drillModel.generateContent([
        Content.text(prompt),
      ]);
      return CoachResponse(
        text: _cleanResponse(
          response.text,
          'Practice more serve receive reps.',
        ),
        followups: const ['Another drill?', 'Warm-up version?'],
        confidence: 0.8,
        mode: 'drill',
      );
    } catch (_) {
      return const CoachResponse(
        text:
            'Run a short, high-rep wash drill around that weakness and keep the cue focused on first contact quality.',
        followups: <String>['Another drill?', 'Make it game-like?'],
        confidence: 0.3,
        mode: 'drill',
      );
    }
  }

  Future<CoachResponse> analyzeVideoFrame(
    MatchSession match,
    Uint8List imageBytes,
  ) async {
    if (!isConfigured || _videoScoutModel == null) {
      return const CoachResponse(
        text:
            'Add your Gemini API key in Settings so I can scout live video frames during the match.',
        followups: <String>[
          'Capture another frame',
          'What should we watch in serve receive?',
        ],
        confidence: 0.25,
        mode: 'vision',
      );
    }

    final prompt =
        '''
${_buildMatchContext(match)}

Analyze this live match frame and give me the most useful bench-side coaching cue right now.
''';

    try {
      final response = await _videoScoutModel.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ]);

      return CoachResponse(
        text: _cleanResponse(
          response.text,
          'The frame is not clear enough. Try a wider angle that shows both blockers and the backcourt shape.',
        ),
        followups: const [
          'Capture another frame',
          'What should we cue next rotation?',
        ],
        confidence: 0.72,
        mode: 'vision',
      );
    } catch (_) {
      return const CoachResponse(
        text:
            'I could not read that live frame clearly. Try capturing the full court so I can scout spacing and defensive shape.',
        followups: <String>[
          'Capture another frame',
          'What should we watch in transition?',
        ],
        confidence: 0.25,
        mode: 'vision',
      );
    }
  }

  String _buildMatchContext(MatchSession match) {
    final buffer = StringBuffer()
      ..writeln(
        'CURRENT STATE: Set ${match.currentSet}, Rotation ${match.currentRotation}, Score ${match.scoreHome}-${match.scoreAway}',
      )
      ..writeln('MATCH: ${match.homeTeam} vs ${match.awayTeam}')
      ..writeln('MODE: ${match.coachingMode}');

    final recent = match.rallies.reversed.take(15).toList().reversed;
    if (recent.isNotEmpty) {
      buffer.writeln('\nRECENT RALLIES:');
      for (final rally in recent) {
        buffer.writeln(
          'Rally ${rally.rallyNumber}: ${rally.winner} wins (${rally.pointType ?? "unknown"}) R${rally.rotation} ${rally.scoreHome}-${rally.scoreAway}',
        );
      }
    }

    final lastFive = match.rallies.reversed.take(5).toList();
    final awayWins = lastFive.where((rally) => rally.winner == 'away').length;
    final homeWins = lastFive.where((rally) => rally.winner == 'home').length;
    if (awayWins >= 4) {
      buffer.writeln(
        '\nPATTERN: Opponent won $awayWins of the last 5 rallies.',
      );
    } else if (homeWins >= 4) {
      buffer.writeln('\nPATTERN: We won $homeWins of the last 5 rallies.');
    }

    final rotationMap = <int, List<String>>{};
    for (final rally in match.rallies) {
      rotationMap.putIfAbsent(rally.rotation, () => []).add(rally.winner);
    }

    if (rotationMap.isNotEmpty) {
      buffer.writeln('\nROTATION PERFORMANCE:');
      final keys = rotationMap.keys.toList()..sort();
      for (final key in keys) {
        final results = rotationMap[key]!;
        final wins = results.where((result) => result == 'home').length;
        final total = results.length;
        final percent = total == 0 ? 0 : ((wins / total) * 100).round();
        buffer.writeln('Rotation $key: $wins/$total won ($percent%)');
      }
    }

    final opponentServes = match.rallies.where(
      (rally) => rally.serverTeam == 'away',
    );
    final aces = opponentServes
        .where((rally) => rally.pointType == 'ace')
        .length;
    if (opponentServes.isNotEmpty) {
      buffer.writeln(
        '\nOPPONENT SERVES: $aces aces in ${opponentServes.length} serves.',
      );
    }

    return buffer.toString();
  }

  String _buildConversationContext(MatchSession match) {
    if (match.conversation.isEmpty) {
      return 'No prior live coaching exchange yet.';
    }

    final recent = match.conversation.reversed.take(6).toList().reversed;
    return recent
        .map((message) => '${message.role.toUpperCase()}: ${message.text}')
        .join('\n');
  }

  String _cleanResponse(String? text, String fallback) {
    final value = (text ?? fallback).trim();
    return value.isEmpty ? fallback : value;
  }

  List<String> _generateFollowups(String question) {
    final lower = question.toLowerCase();
    if (lower.contains('serve')) {
      return const [
        'Which passer do we target now?',
        'Do you like zone 1 or 5 here?',
        'What changes in the next rotation?',
      ];
    }
    if (lower.contains('setter')) {
      return const [
        'How do we slow their setter down?',
        'Where is the block late?',
        'What serve gets them off the net?',
      ];
    }
    return defaultFallbackFollowups;
  }

  static GenerativeModel? _buildModel({
    required String apiKey,
    required String prompt,
    required double temperature,
    required int maxOutputTokens,
  }) {
    if (apiKey.trim().isEmpty) {
      return null;
    }

    return GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.text(prompt),
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxOutputTokens,
      ),
    );
  }
}
