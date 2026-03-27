import 'package:flutter/material.dart';

class VolleyballCourtGeometry {
  static const Rect normalizedCourtRect = Rect.fromLTWH(0.09, 0.09, 0.82, 0.82);

  static const Map<int, ({int row, int column})> _zoneGrid = {
    4: (row: 0, column: 0),
    3: (row: 0, column: 1),
    2: (row: 0, column: 2),
    5: (row: 1, column: 0),
    6: (row: 1, column: 1),
    1: (row: 1, column: 2),
  };

  static Rect zoneRect(int zoneIndex, Size size) {
    final normalized = normalizedZoneRect(zoneIndex);
    return Rect.fromLTWH(
      normalized.left * size.width,
      normalized.top * size.height,
      normalized.width * size.width,
      normalized.height * size.height,
    );
  }

  static Rect normalizedZoneRect(int zoneIndex) {
    final grid = _zoneGrid[zoneIndex];
    if (grid == null) {
      throw ArgumentError.value(zoneIndex, 'zoneIndex', 'Zone must be 1-6.');
    }

    final zoneWidth = normalizedCourtRect.width / 3;
    final zoneHeight = normalizedCourtRect.height / 2;

    return Rect.fromLTWH(
      normalizedCourtRect.left + (grid.column * zoneWidth),
      normalizedCourtRect.top + (grid.row * zoneHeight),
      zoneWidth,
      zoneHeight,
    );
  }

  static Offset normalizedZoneCenter(int zoneIndex) {
    return normalizedZoneRect(zoneIndex).center;
  }

  static Offset denormalize(Offset normalized, Size size) {
    return Offset(normalized.dx * size.width, normalized.dy * size.height);
  }
}
