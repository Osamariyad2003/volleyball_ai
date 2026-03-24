import 'package:hive_flutter/hive_flutter.dart';

import 'models/coach_models.dart';
import 'session_storage_service.dart';

Future<void> bootstrapVoiceCoach() async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(MatchSessionAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(RallyRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ChatMessageAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }

  if (!Hive.isBoxOpen(SessionStorageService.sessionsBoxName)) {
    await Hive.openBox<MatchSession>(SessionStorageService.sessionsBoxName);
  }
  if (!Hive.isBoxOpen(SessionStorageService.settingsBoxName)) {
    await Hive.openBox<AppSettings>(SessionStorageService.settingsBoxName);
  }
}
