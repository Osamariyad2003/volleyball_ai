import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/ai_chat_constants.dart';
import '../exceptions/ai_chat_exception.dart';

class HuggingFaceChatService {
  HuggingFaceChatService({required http.Client client, required String token})
    : _client = client,
      _token = token;

  static const String _endpoint =
      'https://router.huggingface.co/v1/chat/completions';

  final http.Client _client;
  final String _token;

  Future<String> createChatCompletion({
    required List<Map<String, dynamic>> messages,
  }) async {
    if (_token.trim().isEmpty) {
      throw const AiChatException(
        'Missing HF_TOKEN. Add a Hugging Face User Access Token to .env and restart the app to generate volleyball exercise guidance.',
      );
    }

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'model': huggingFaceChatModel, 'messages': messages}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiChatException(
        _buildFailureMessage(
          statusCode: response.statusCode,
          responseBody: response.body,
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AiChatException(
        'The exercises assistant received an unexpected response. Please try again.',
      );
    }

    final content = _extractAssistantContent(decoded).trim();
    if (content.isEmpty) {
      throw const AiChatException(
        'No volleyball exercise guidance was returned. Please try again.',
      );
    }

    return content;
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _buildFailureMessage({
    required int statusCode,
    required String responseBody,
  }) {
    final details = _extractErrorMessage(responseBody);
    final normalizedDetails = details?.toLowerCase() ?? '';

    if (statusCode == 401) {
      return 'HF_TOKEN is invalid. Use a Hugging Face User Access Token in .env and restart the app.';
    }

    if (statusCode == 403) {
      if (normalizedDetails.contains('inference providers') ||
          normalizedDetails.contains('authentication method') ||
          normalizedDetails.contains('insufficient permissions')) {
        return 'HF_TOKEN does not have permission to call Hugging Face Inference Providers. Create a Hugging Face User Access Token with Inference Providers access, replace HF_TOKEN in .env, and restart the app.';
      }

      return 'Hugging Face rejected this request. Check that HF_TOKEN is a User Access Token with permission to use Inference Providers, then restart the app.';
    }

    if (statusCode == 429) {
      return 'Hugging Face is rate-limiting the exercises assistant right now. Please wait a moment and try again.';
    }

    final suffix = details == null ? '' : ' $details';
    return 'The exercises assistant could not reach Hugging Face ($statusCode).$suffix';
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
        if (item is Map<String, dynamic>) {
          final text = item['text'];
          if (text is String && text.trim().isNotEmpty) {
            if (buffer.isNotEmpty) {
              buffer.writeln();
            }
            buffer.write(text.trim());
          }
        }
      }
      return buffer.toString();
    }

    return '';
  }
}
