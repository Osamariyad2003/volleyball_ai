import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../core/coaching_prompts.dart';
import 'models/coach_models.dart';

const defaultFallbackFollowups = <String>[
  "What's their setter doing this rotation?",
  'Where should we serve next?',
  "Who's their weakest passer?",
];

class HuggingFaceCoachService {
  HuggingFaceCoachService({required http.Client client, required String token})
    : _client = client,
      _token = token;

  static const _endpoint = 'https://router.huggingface.co/v1/chat/completions';
  static const _textModel = 'CohereLabs/c4ai-command-r7b-12-2024';
  static const _visionModel = 'CohereLabs/aya-vision-32b';

  final http.Client _client;
  final String _token;

  bool get isConfigured => _token.trim().isNotEmpty;

  Future<CoachResponse> askLive(MatchSession match, String question) async {
    if (!isConfigured) {
      return const CoachResponse(
        text:
            'Add HF_TOKEN in .env so I can answer live coaching questions with Hugging Face.',
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
      final responseText = await _createChatCompletion(
        model: _textModel,
        systemPrompt: liveCoachPrompt,
        userContent: prompt,
        maxTokens: 256,
        temperature: 0.35,
      );

      return CoachResponse(
        text: _cleanResponse(responseText, 'I need more data to answer that.'),
        followups: _generateFollowups(question),
        confidence: match.rallies.length > 10 ? 0.85 : 0.58,
        mode: 'live',
      );
    } catch (_) {
      return const CoachResponse(
        text:
            'Hugging Face did not answer that cleanly. Ask again in one short sentence.',
        followups: defaultFallbackFollowups,
        confidence: 0.2,
        mode: 'live',
      );
    }
  }

  Future<CoachResponse> quickTimeout(MatchSession match) async {
    if (!isConfigured) {
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
      final responseText = await _createChatCompletion(
        model: _textModel,
        systemPrompt: timeoutPrompt,
        userContent: prompt,
        maxTokens: 160,
        temperature: 0.25,
      );

      return CoachResponse(
        text: _cleanResponse(
          responseText,
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
    if (!isConfigured) {
      return const CoachResponse(
        text:
            'Match data is saved locally, but HF_TOKEN is required before I can deliver a spoken debrief.',
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
      final responseText = await _createChatCompletion(
        model: _textModel,
        systemPrompt: debriefPrompt,
        userContent: prompt,
        maxTokens: 900,
        temperature: 0.4,
      );

      return CoachResponse(
        text: _cleanResponse(
          responseText,
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
    if (!isConfigured) {
      return const CoachResponse(
        text:
            'Add HF_TOKEN in .env, then I can turn that weakness into a practical drill.',
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
      final responseText = await _createChatCompletion(
        model: _textModel,
        systemPrompt: drillPrompt,
        userContent: prompt,
        maxTokens: 420,
        temperature: 0.45,
      );

      return CoachResponse(
        text: _cleanResponse(responseText, 'Practice more serve receive reps.'),
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
    Uint8List imageBytes, {
    String sourceLabel = 'live court frame',
  }) async {
    if (!isConfigured) {
      return const CoachResponse(
        text:
            'Add HF_TOKEN in .env so I can scout live frames with Hugging Face.',
        followups: <String>[
          'Capture another frame',
          'What should we watch in serve receive?',
        ],
        confidence: 0.25,
        mode: 'vision',
      );
    }

    final preparedBytes = _prepareVisionBytes(imageBytes);
    final base64Image = base64Encode(preparedBytes);
    final imageUrl = 'data:image/jpeg;base64,$base64Image';
    final prompt =
        '''
${_buildMatchContext(match)}

FRAME SOURCE: $sourceLabel

Analyze this volleyball frame for bench-side coaching.
Do not default to "Frame unclear" just because the full court is not visible.
If you can see at least one side of the net, three or more players, a receiving shape, or the blocker/defender alignment, give a best-effort partial read.
If enough of the court is visible, answer with exactly:
ACTION: one label from [Serve, Serve Receive, Set, Attack, Block, Defense, Transition, Coverage, Free Ball, Unknown]
READ: what the shape or spacing shows
RISK: the most exploitable issue
CUE: one immediate coaching instruction

If the frame is genuinely too tight, blurry, dark, or missing almost all player context, answer with:
ACTION: Unknown
READ: Frame unclear.
CUE: the exact better angle or wider view needed
''';

    try {
      final responseText = await _createChatCompletion(
        model: _visionModel,
        systemPrompt: videoScoutPrompt,
        userContent: [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': imageUrl},
          },
        ],
        maxTokens: 280,
        temperature: 0.2,
      );

      return CoachResponse(
        text: _cleanResponse(
          responseText,
          'READ: Frame unclear.\nCUE: Capture a wider angle that shows both blockers, the setter lane, and the backcourt shape.',
        ),
        followups: const [
          'Capture another frame',
          'What should we cue next rotation?',
        ],
        confidence: 0.76,
        mode: 'vision',
      );
    } catch (_) {
      return const CoachResponse(
        text:
            'I could not analyze that frame right now. Try again in steadier light, or upload a replay clip and scout a paused frame.',
        followups: <String>[
          'Capture another frame',
          'What should we watch in transition?',
        ],
        confidence: 0.25,
        mode: 'vision',
      );
    }
  }

  Future<String> _createChatCompletion({
    required String model,
    required String systemPrompt,
    required Object userContent,
    required int maxTokens,
    required double temperature,
  }) async {
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userContent},
        ],
        'max_tokens': maxTokens,
        'temperature': temperature,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Hugging Face request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected Hugging Face response payload.');
    }

    final content = _extractAssistantContent(decoded).trim();
    if (content.isEmpty) {
      throw const FormatException('Empty assistant response.');
    }

    return content;
  }

  String _extractAssistantContent(Map<String, dynamic> payload) {
    final choices = payload['choices'];
    if (choices is! List || choices.isEmpty) {
      return '';
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      return '';
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      return '';
    }

    final content = message['content'];
    if (content is String) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final item in content) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final text = item['text'];
        if (text is String && text.trim().isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }
          buffer.write(text.trim());
        }
      }
      return buffer.toString();
    }

    return '';
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

  Uint8List _prepareVisionBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }

    final normalized = decoded.width > 1440
        ? img.copyResize(decoded, width: 1440)
        : decoded;

    return Uint8List.fromList(img.encodeJpg(normalized, quality: 90));
  }
}
