import 'package:flutter/material.dart';
import '../constants.dart';

import 'dart:math';

class CultivationFormation extends StatefulWidget {
  final double progress;
  final bool isRelaxing;
  final double size;

  const CultivationFormation({
    super.key,
    required this.progress,
    required this.isRelaxing,
    required this.size,
  });

  @override
  State<CultivationFormation> createState() => _CultivationFormationState();
}

class _CultivationFormationState extends State<CultivationFormation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isRelaxing
        ? AppConstants.pomodoroRelaxColor
        : AppConstants.pomodoroFocusColor;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _FormationPainter(
              progress: widget.progress,
              color: color,
              rotation: _controller.value * 2 * pi,
            ),
          );
        },
      ),
    );
  }
}

class _FormationPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double rotation;

  _FormationPainter({
    required this.progress,
    required this.color,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw rotating inner circle (The Array)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Inner geometric shape (Triangle/Hexagon)
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * pi / 180;
      final point = Offset(
        (radius * 0.7) * cos(angle),
        (radius * 0.7) * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    
    // Inner dashed circle
    final dashPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius * 0.5, dashPaint);
    
    canvas.restore();

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
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
    );

    // Draw active progress
    // Calculate start angle to make it disappear clockwise
    // -pi/2 is top. We want to start after the "consumed" part.
    // consumed = 1 - progress.
    // startAngle = -pi/2 + (2 * pi * (1 - progress))
    final double startAngle = -pi / 2 + (2 * pi * (1 - progress));
    
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
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.rotation != rotation;
  }
}
