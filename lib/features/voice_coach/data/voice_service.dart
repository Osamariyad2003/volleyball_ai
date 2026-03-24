import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'models/coach_models.dart';

class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastTranscript = '';

  bool get isListening => _isListening;

  bool get isSpeaking => _isSpeaking;

  Future<void> init({AppSettings? settings}) async {
    if (!_initialized) {
      await _stt.initialize();
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.52);
      await _tts.setPitch(0.95);
      await _tts.setVolume(1.0);
      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setCancelHandler(() => _isSpeaking = false);
      _initialized = true;
    }

    if (settings != null) {
      await applySettings(settings);
    }
  }

  Future<void> applySettings(AppSettings settings) async {
    await init();
    await _tts.setLanguage(settings.voiceLocale);
    await _tts.setSpeechRate(settings.speechRate);
    await _tts.setPitch(0.95);
    await _tts.setVolume(1.0);
    if (settings.voiceName.isNotEmpty) {
      await _tts.setVoice({
        'name': settings.voiceName,
        'locale': settings.voiceLocale,
      });
    }
  }

  Future<List<VoiceOption>> getVoices() async {
    await init();
    final raw = await _tts.getVoices;
    if (raw is! List) {
      return const [];
    }

    final voices = <VoiceOption>[];
    for (final item in raw) {
      if (item is Map) {
        final name = '${item['name'] ?? ''}'.trim();
        final locale = '${item['locale'] ?? item['language'] ?? 'en-US'}'
            .trim();
        voices.add(VoiceOption(name: name, locale: locale));
      }
    }

    voices.sort((a, b) => a.label.compareTo(b.label));
    return voices;
  }

  Future<void> startListening({
    required void Function(String text) onPartial,
    required void Function(String text) onFinal,
    required void Function() onDone,
    required void Function(String message) onError,
  }) async {
    await init();

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      onError('Microphone permission is required for voice coaching.');
      return;
    }

    if (_isSpeaking) {
      await stopSpeaking();
    }

    final available = await _stt.initialize(
      onError: (error) {
        _isListening = false;
        onError(error.errorMsg);
      },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && _isListening) {
          _isListening = false;
          if (_lastTranscript.trim().isNotEmpty) {
            onFinal(_lastTranscript.trim());
          }
          onDone();
        }
      },
    );

    if (!available) {
      onError('Speech recognition is unavailable on this device.');
      return;
    }

    _lastTranscript = '';
    _isListening = true;

    await _stt.listen(
      onResult: (result) {
        _lastTranscript = result.recognizedWords;
        onPartial(_lastTranscript);
        if (result.finalResult && _isListening) {
          _isListening = false;
          onFinal(_lastTranscript.trim());
          unawaited(_stt.stop());
          onDone();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _stt.stop();
  }

  Future<void> speak(String text) async {
    await init();
    if (_isListening) {
      await stopListening();
    }
    _isSpeaking = true;
    final clean = text
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'#{1,4}\s*'), '')
        .trim();
    await _tts.speak(clean);
  }

  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  void dispose() {
    unawaited(stopListening());
    unawaited(stopSpeaking());
  }
}
