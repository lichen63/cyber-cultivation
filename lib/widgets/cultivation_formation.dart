import 'package:flutter/material.dart';
import '../constants.dart';

import 'dart:math';

class CultivationFormation extends StatelessWidget {
  final double progress;
  final bool isRelaxing;
  final double size;
  final String? timeText;

  const CultivationFormation({
    super.key,
    required this.progress,
    required this.isRelaxing,
    required this.size,
    this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRelaxing
        ? AppConstants.pomodoroRelaxColor
        : AppConstants.pomodoroFocusColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _FormationPainter(progress: progress, color: color),
          ),
          if (timeText != null)
            Text(
              timeText!,
              style: TextStyle(
                color: color,
                fontSize: size * AppConstants.pomodoroTimeFontSizeRatio,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

class _FormationPainter extends CustomPainter {
  final double progress;
  final Color color;

  _FormationPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Calculate start angle to make it disappear clockwise
    // -pi/2 is top. We want to start after the "consumed" part.
    // consumed = 1 - progress.
    // startAngle = -pi/2 + (2 * pi * (1 - progress))
    final double startAngle = -pi / 2 + (2 * pi * (1 - progress));

    // Draw fill inside the outer circle (matching progress)
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      2 * pi * progress,
      true, // Connect to center for a pie slice
      fillPaint,
    );

    // Draw Progress Arc (Outer Ring)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw background ring for progress
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FormationPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
