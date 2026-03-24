import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'injection_container.dart' as di;
import 'features/voice_coach/data/app_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await bootstrapVoiceCoach();
  await di.init();
  runApp(const ProviderScope(child: VolleyballApp()));
}
