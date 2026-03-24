import 'package:flutter_dotenv/flutter_dotenv.dart';

const String _sportradarApiKeyEnv = 'SPORTRADAR_API_KEY';

class SecretLoader {
  SecretLoader();

  Future<Secret> loadApiKey() {
    final apiKey = dotenv.env[_sportradarApiKeyEnv]?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError(
        'Missing $_sportradarApiKeyEnv in .env. Add your Sportradar API key and restart the app.',
      );
    }

    return Future.value(Secret(apiKey: apiKey));
  }

  Future<Secret> loadSRApiKey() {
    return loadApiKey();
  }
}

class Secret {
  final String apiKey;
  Secret({this.apiKey = ""});
}
