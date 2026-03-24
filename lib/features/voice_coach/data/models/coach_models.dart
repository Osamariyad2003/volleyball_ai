import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum AlertPriority { critical, high, medium, low }

enum AppThemePreference { system, light, dark }

class MatchSession {
  MatchSession({
    required this.id,
    required this.matchName,
    required this.homeTeam,
    required this.awayTeam,
    required this.createdAt,
    required this.rallies,
    required this.conversation,
    required this.currentSet,
    required this.currentRotation,
    required this.scoreHome,
    required this.scoreAway,
    required this.coachingMode,
    required this.voiceId,
  });

  final String id;
  final String matchName;
  final String homeTeam;
  final String awayTeam;
  final DateTime createdAt;
  final List<RallyRecord> rallies;
  final List<ChatMessage> conversation;
  final int currentSet;
  final int currentRotation;
  final int scoreHome;
  final int scoreAway;
  final String coachingMode;
  final String voiceId;

  MatchSession copyWith({
    String? id,
    String? matchName,
    String? homeTeam,
    String? awayTeam,
    DateTime? createdAt,
    List<RallyRecord>? rallies,
    List<ChatMessage>? conversation,
    int? currentSet,
    int? currentRotation,
    int? scoreHome,
    int? scoreAway,
    String? coachingMode,
    String? voiceId,
  }) {
    return MatchSession(
      id: id ?? this.id,
      matchName: matchName ?? this.matchName,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      createdAt: createdAt ?? this.createdAt,
      rallies: rallies ?? List<RallyRecord>.from(this.rallies),
      conversation: conversation ?? List<ChatMessage>.from(this.conversation),
      currentSet: currentSet ?? this.currentSet,
      currentRotation: currentRotation ?? this.currentRotation,
      scoreHome: scoreHome ?? this.scoreHome,
      scoreAway: scoreAway ?? this.scoreAway,
      coachingMode: coachingMode ?? this.coachingMode,
      voiceId: voiceId ?? this.voiceId,
    );
  }
}

class RallyRecord {
  RallyRecord({
    required this.rallyNumber,
    required this.winner,
    required this.pointType,
    required this.serverTeam,
    required this.setNumber,
    required this.rotation,
    required this.scoreHome,
    required this.scoreAway,
    required this.timestamp,
  });

  final int rallyNumber;
  final String winner;
  final String? pointType;
  final String? serverTeam;
  final int setNumber;
  final int rotation;
  final int scoreHome;
  final int scoreAway;
  final DateTime timestamp;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.confidence,
    required this.mode,
    required this.followups,
    required this.timestamp,
  });

  final String id;
  final String role;
  final String text;
  final double? confidence;
  final String mode;
  final List<String> followups;
  final DateTime timestamp;
}

class AppSettings {
  const AppSettings({
    required this.apiKey,
    required this.voiceName,
    required this.voiceLocale,
    required this.speechRate,
    required this.autoSpeak,
    required this.themePreference,
    required this.activeSessionId,
  });

  const AppSettings.defaults()
    : apiKey = '',
      voiceName = '',
      voiceLocale = 'en-US',
      speechRate = 0.52,
      autoSpeak = true,
      themePreference = AppThemePreference.dark,
      activeSessionId = null;

  final String apiKey;
  final String voiceName;
  final String voiceLocale;
  final double speechRate;
  final bool autoSpeak;
  final AppThemePreference themePreference;
  final String? activeSessionId;

  ThemeMode get themeMode {
    switch (themePreference) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  String get voiceId =>
      voiceName.isEmpty ? voiceLocale : '$voiceLocale::$voiceName';

  AppSettings copyWith({
    String? apiKey,
    String? voiceName,
    String? voiceLocale,
    double? speechRate,
    bool? autoSpeak,
    AppThemePreference? themePreference,
    String? activeSessionId,
    bool clearActiveSessionId = false,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      voiceName: voiceName ?? this.voiceName,
      voiceLocale: voiceLocale ?? this.voiceLocale,
      speechRate: speechRate ?? this.speechRate,
      autoSpeak: autoSpeak ?? this.autoSpeak,
      themePreference: themePreference ?? this.themePreference,
      activeSessionId: clearActiveSessionId
          ? null
          : activeSessionId ?? this.activeSessionId,
    );
  }
}

class VoiceOption {
  const VoiceOption({required this.name, required this.locale});

  final String name;
  final String locale;

  String get id => '$locale::$name';

  String get label => name.isEmpty ? locale : '$locale - $name';
}

class CoachResponse {
  const CoachResponse({
    required this.text,
    required this.followups,
    required this.confidence,
    required this.mode,
  });

  final String text;
  final List<String> followups;
  final double confidence;
  final String mode;
}

class CoachingAlert {
  const CoachingAlert({
    required this.id,
    required this.priority,
    required this.category,
    required this.title,
    required this.message,
  });

  final String id;
  final AlertPriority priority;
  final String category;
  final String title;
  final String message;
}

class MatchSessionAdapter extends TypeAdapter<MatchSession> {
  @override
  final int typeId = 0;

  @override
  MatchSession read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    final fieldCount = reader.readByte();
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return MatchSession(
      id: fields[0] as String,
      matchName: fields[1] as String,
      homeTeam: fields[2] as String,
      awayTeam: fields[3] as String,
      createdAt: fields[4] as DateTime,
      rallies: (fields[5] as List).cast<RallyRecord>(),
      conversation: (fields[6] as List).cast<ChatMessage>(),
      currentSet: fields[7] as int,
      currentRotation: fields[8] as int,
      scoreHome: fields[9] as int,
      scoreAway: fields[10] as int,
      coachingMode: fields[11] as String,
      voiceId: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MatchSession obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.matchName)
      ..writeByte(2)
      ..write(obj.homeTeam)
      ..writeByte(3)
      ..write(obj.awayTeam)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.rallies)
      ..writeByte(6)
      ..write(obj.conversation)
      ..writeByte(7)
      ..write(obj.currentSet)
      ..writeByte(8)
      ..write(obj.currentRotation)
      ..writeByte(9)
      ..write(obj.scoreHome)
      ..writeByte(10)
      ..write(obj.scoreAway)
      ..writeByte(11)
      ..write(obj.coachingMode)
      ..writeByte(12)
      ..write(obj.voiceId);
  }
}

class RallyRecordAdapter extends TypeAdapter<RallyRecord> {
  @override
  final int typeId = 1;

  @override
  RallyRecord read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    final fieldCount = reader.readByte();
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return RallyRecord(
      rallyNumber: fields[0] as int,
      winner: fields[1] as String,
      pointType: fields[2] as String?,
      serverTeam: fields[3] as String?,
      setNumber: fields[4] as int,
      rotation: fields[5] as int,
      scoreHome: fields[6] as int,
      scoreAway: fields[7] as int,
      timestamp: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RallyRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.rallyNumber)
      ..writeByte(1)
      ..write(obj.winner)
      ..writeByte(2)
      ..write(obj.pointType)
      ..writeByte(3)
      ..write(obj.serverTeam)
      ..writeByte(4)
      ..write(obj.setNumber)
      ..writeByte(5)
      ..write(obj.rotation)
      ..writeByte(6)
      ..write(obj.scoreHome)
      ..writeByte(7)
      ..write(obj.scoreAway)
      ..writeByte(8)
      ..write(obj.timestamp);
  }
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 2;

  @override
  ChatMessage read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    final fieldCount = reader.readByte();
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ChatMessage(
      id: fields[0] as String,
      role: fields[1] as String,
      text: fields[2] as String,
      confidence: fields[3] as double?,
      mode: fields[4] as String,
      followups: (fields[5] as List).cast<String>(),
      timestamp: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.mode)
      ..writeByte(5)
      ..write(obj.followups)
      ..writeByte(6)
      ..write(obj.timestamp);
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final fields = <int, dynamic>{};
    final fieldCount = reader.readByte();
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return AppSettings(
      apiKey: fields[0] as String? ?? '',
      voiceName: fields[1] as String? ?? '',
      voiceLocale: fields[2] as String? ?? 'en-US',
      speechRate: fields[3] as double? ?? 0.52,
      autoSpeak: fields[4] as bool? ?? true,
      themePreference: AppThemePreference.values[fields[5] as int? ?? 2],
      activeSessionId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.apiKey)
      ..writeByte(1)
      ..write(obj.voiceName)
      ..writeByte(2)
      ..write(obj.voiceLocale)
      ..writeByte(3)
      ..write(obj.speechRate)
      ..writeByte(4)
      ..write(obj.autoSpeak)
      ..writeByte(5)
      ..write(obj.themePreference.index)
      ..writeByte(6)
      ..write(obj.activeSessionId);
  }
}
