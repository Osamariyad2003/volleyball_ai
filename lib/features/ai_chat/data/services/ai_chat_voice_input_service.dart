import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../exceptions/ai_chat_exception.dart';

class AiChatVoiceInputService {
  final SpeechToText _speechToText = SpeechToText();

  bool _initialized = false;
  bool _isListening = false;
  String _lastTranscript = '';

  bool get isListening => _isListening;

  Future<void> startListening({
    required void Function(String text) onPartial,
    required void Function(String text) onFinal,
    required void Function() onDone,
    required void Function(String message) onError,
  }) async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      throw const AiChatException(
        'Microphone permission is required for voice input.',
      );
    }

    final available = await _ensureInitialized(
      onError: onError,
      onDone: onDone,
    );
    if (!available) {
      throw const AiChatException(
        'Speech recognition is unavailable on this device.',
      );
    }

    _lastTranscript = '';
    _isListening = true;

    await _speechToText.listen(
      onResult: (result) {
        _lastTranscript = result.recognizedWords;
        onPartial(_lastTranscript);

        if (result.finalResult && _isListening) {
          _isListening = false;
          onFinal(_lastTranscript.trim());
          unawaited(_speechToText.stop());
          onDone();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }

  void dispose() {
    unawaited(stopListening());
  }

  Future<bool> _ensureInitialized({
    required void Function(String message) onError,
    required void Function() onDone,
  }) async {
    if (_initialized) {
      return true;
    }

    final available = await _speechToText.initialize(
      onError: (error) {
        _isListening = false;
        onError(error.errorMsg);
      },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && _isListening) {
          _isListening = false;
          onDone();
        }
      },
    );
    _initialized = available;
    return available;
  }
}
