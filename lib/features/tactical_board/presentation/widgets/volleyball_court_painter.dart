import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/volleyball_court_geometry.dart';

class VolleyballCourtPainter extends CustomPainter {
  const VolleyballCourtPainter({
    this.fieldColor = const Color(0xFF166534),
    this.courtColor = const Color(0xFFF97316),
    this.lineColor = Colors.white,
  });

  final Color fieldColor;
  final Color courtColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()..color = fieldColor;
    final fieldRect = Offset.zero & size;
    final courtRect = Rect.fromLTWH(
      VolleyballCourtGeometry.normalizedCourtRect.left * size.width,
      VolleyballCourtGeometry.normalizedCourtRect.top * size.height,
      VolleyballCourtGeometry.normalizedCourtRect.width * size.width,
      VolleyballCourtGeometry.normalizedCourtRect.height * size.height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(28)),
      fieldPaint,
    );

    final courtPaint = Paint()..color = courtColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(courtRect, const Radius.circular(28)),
      courtPaint,
    );

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(courtRect, const Radius.circular(28)),
      linePaint,
    );

    final dashedPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final firstVertical = Offset(
      courtRect.left + courtRect.width / 3,
      courtRect.top,
    );
    final secondVertical = Offset(
      courtRect.left + (courtRect.width * 2 / 3),
      courtRect.top,
    );
    final midHorizontal = Offset(
      courtRect.left,
      courtRect.top + courtRect.height / 2,
    );

    _drawDashedLine(
      canvas,
      firstVertical,
      Offset(firstVertical.dx, courtRect.bottom),
      dashedPaint,
    );
    _drawDashedLine(
      canvas,
      secondVertical,
      Offset(secondVertical.dx, courtRect.bottom),
      dashedPaint,
    );
    _drawDashedLine(
      canvas,
      midHorizontal,
      Offset(courtRect.right, midHorizontal.dy),
      dashedPaint,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 12,
    double gapLength = 8,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) {
      return;
    }

    final direction = Offset(delta.dx / distance, delta.dy / distance);
    double drawn = 0;

    while (drawn < distance) {
      final segmentStart = Offset(
        start.dx + (direction.dx * drawn),
        start.dy + (direction.dy * drawn),
      );
      final currentLength = math.min(dashLength, distance - drawn);
      final segmentEnd = Offset(
        segmentStart.dx + (direction.dx * currentLength),
        segmentStart.dy + (direction.dy * currentLength),
      );
      canvas.drawLine(segmentStart, segmentEnd, paint);
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant VolleyballCourtPainter oldDelegate) {
    return oldDelegate.fieldColor != fieldColor ||
        oldDelegate.courtColor != courtColor ||
        oldDelegate.lineColor != lineColor;
  }
}
