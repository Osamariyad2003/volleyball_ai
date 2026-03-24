import 'models/coach_models.dart';
import 'package:hive/hive.dart';

class SessionStorageService {
  static const sessionsBoxName = 'voice_coach_sessions';
  static const settingsBoxName = 'voice_coach_settings';
  static const settingsKey = 'primary';

  Box<MatchSession> get _sessionsBox => Hive.box<MatchSession>(sessionsBoxName);
  Box<AppSettings> get _settingsBox => Hive.box<AppSettings>(settingsBoxName);

  List<MatchSession> allSessions() {
    final sessions = _sessionsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  MatchSession? getSession(String id) => _sessionsBox.get(id);

  Future<void> upsertSession(MatchSession session) async {
    await _sessionsBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
  }

  AppSettings loadSettings() =>
      _settingsBox.get(settingsKey) ?? const AppSettings.defaults();

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(settingsKey, settings);
  }
}
