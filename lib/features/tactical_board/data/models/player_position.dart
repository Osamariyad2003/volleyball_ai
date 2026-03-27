import 'package:flutter/material.dart';

class PlayerPosition {
  const PlayerPosition({
    required this.id,
    required this.jerseyNumber,
    required this.position,
    required this.zoneIndex,
  });

  final String id;
  final int jerseyNumber;
  final Offset position;
  final int zoneIndex;

  PlayerPosition copyWith({
    String? id,
    int? jerseyNumber,
    Offset? position,
    int? zoneIndex,
  }) {
    return PlayerPosition(
      id: id ?? this.id,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      position: position ?? this.position,
      zoneIndex: zoneIndex ?? this.zoneIndex,
    );
  }
}
