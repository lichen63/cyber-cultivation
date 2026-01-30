import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';

/// A widget that wraps a child with a glowing border effect when triggered
/// Uses an overlay approach to avoid affecting the child's layout
class LevelUpEffectWrapper extends StatefulWidget {
  final Widget child;
  final AppThemeColors themeColors;
  final double scale;

  const LevelUpEffectWrapper({
    super.key,
    required this.child,
    required this.themeColors,
    this.scale = 1.0,
  });

  @override
  State<LevelUpEffectWrapper> createState() => LevelUpEffectWrapperState();
}

class LevelUpEffectWrapperState extends State<LevelUpEffectWrapper>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  bool _isPlaying = false;

  /// Trigger the level-up effect
  /// If called while an effect is playing, it stops and restarts from the beginning
  void triggerLevelUp() {
    if (!mounted) return;

    // Cancel existing animation if playing
    _stopCurrentEffect();

    // Start new effect
    _startEffect();
  }

  void _stopCurrentEffect() {
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
    _isPlaying = false;
  }

  void _startEffect() {
    _isPlaying = true;

    _controller = AnimationController(
      duration: LevelUpEffectConstants.totalDuration,
      vsync: this,
    );

    setState(() {});

    _controller!.forward().then((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        _stopCurrentEffect();
      }
    });
  }

  @override
  void dispose() {
    _stopCurrentEffect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always return a fixed-size widget to prevent layout shifts
    // The effect is rendered as an overlay that doesn't affect layout
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The child widget - always positioned the same
        widget.child,
        // The effect overlay - positioned absolutely so it doesn't affect layout
        if (_isPlaying && _controller != null)
          Positioned.fill(
            child: IgnorePointer(
              child: _LevelUpEffect(
                animation: _controller!,
                themeColors: widget.themeColors,
                scale: widget.scale,
              ),
            ),
          ),
      ],
    );
  }
}

/// The actual level-up effect with glow, particles and rings
class _LevelUpEffect extends StatelessWidget {
  final Animation<double> animation;
  final AppThemeColors themeColors;
  final double scale;

  const _LevelUpEffect({
    required this.animation,
    required this.themeColors,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _LevelUpEffectPainter(
            progress: animation.value,
            accentColor: themeColors.accent,
            secondaryColor: themeColors.accentSecondary,
            scale: scale,
          ),
        );
      },
    );
  }
}

/// Custom painter for the complete level-up effect
class _LevelUpEffectPainter extends CustomPainter {
  final double progress;
  final Color accentColor;
  final Color secondaryColor;
  final double scale;
  final List<_Particle> particles;

  _LevelUpEffectPainter({
    required this.progress,
    required this.accentColor,
    required this.secondaryColor,
    required this.scale,
  }) : particles = _generateParticles();

  static List<_Particle> _generateParticles() {
    final random = Random(42);
    final particles = <_Particle>[];

    for (int i = 0; i < LevelUpEffectConstants.particleCount; i++) {
      final angle = (i / LevelUpEffectConstants.particleCount) * 2 * pi;
      final speed =
          LevelUpEffectConstants.particleSpeed *
          (0.8 + random.nextDouble() * 0.4);
      final size =
          LevelUpEffectConstants.particleMinSize +
          random.nextDouble() *
              (LevelUpEffectConstants.particleMaxSize -
                  LevelUpEffectConstants.particleMinSize);
      final isSecondary = random.nextBool();

      particles.add(
        _Particle(
          angle: angle,
          speed: speed,
          size: size,
          isSecondary: isSecondary,
        ),
      );
    }

    return particles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Use the full canvas size for the effect (the game border dimensions)
    final innerWidth = size.width;
    final innerHeight = size.height;
    final borderRadius = AppConstants.borderRadius * scale;

    // Animation phases
    final glowIntensity = _calculateGlowIntensity(progress);
    final particleProgress = _calculateParticleProgress(progress);
    final ringProgress = _calculateRingProgress(progress);

    // Draw outer glow layers (largest first)
    _drawGlowLayers(
      canvas,
      center,
      innerWidth,
      innerHeight,
      borderRadius,
      glowIntensity,
    );

    // Draw expanding ring
    _drawExpandingRing(
      canvas,
      center,
      innerWidth,
      innerHeight,
      borderRadius,
      ringProgress,
    );

    // Draw particles bursting outward
    _drawParticles(canvas, center, particleProgress);

    // Draw inner bright border
    _drawInnerBorder(
      canvas,
      center,
      innerWidth,
      innerHeight,
      borderRadius,
      glowIntensity,
    );
  }

  double _calculateGlowIntensity(double p) {
    // Fade in quickly, pulse, then fade out
    if (p < 0.15) {
      return Curves.easeOutCubic.transform(p / 0.15);
    } else if (p < 0.6) {
      // Pulsing effect
      final pulsePhase = (p - 0.15) / 0.45;
      return 0.7 + 0.3 * sin(pulsePhase * pi * 3);
    } else {
      return Curves.easeInCubic.transform(1.0 - (p - 0.6) / 0.4);
    }
  }

  double _calculateParticleProgress(double p) {
    // Play particle burst 3 times during the animation
    // Each burst takes ~30% of the total animation time
    final cycleCount = 3;
    final cycleDuration =
        0.9 / cycleCount; // 0.3 each cycle, leaving 0.1 at start

    if (p < 0.1) return 0.0;

    final adjustedP = p - 0.1;
    final cycleIndex = (adjustedP / cycleDuration).floor();

    if (cycleIndex >= cycleCount) return 1.0;

    final cycleProgress = (adjustedP % cycleDuration) / cycleDuration;
    return Curves.easeOutCubic.transform(cycleProgress);
  }

  double _calculateRingProgress(double p) {
    if (p < 0.05) return 0.0;
    if (p > 0.5) return 1.0;
    return Curves.easeOutCubic.transform((p - 0.05) / 0.45);
  }

  void _drawGlowLayers(
    Canvas canvas,
    Offset center,
    double innerWidth,
    double innerHeight,
    double borderRadius,
    double intensity,
  ) {
    if (intensity <= 0) return;

    final layerCount = LevelUpEffectConstants.glowLayerCount.toInt();

    for (int i = layerCount - 1; i >= 0; i--) {
      final spread = (i + 1) * LevelUpEffectConstants.glowLayerSpacing * scale;
      final layerOpacity = intensity * (0.4 - i * 0.05);

      if (layerOpacity <= 0) continue;

      final glowRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: innerWidth + spread * 2,
          height: innerHeight + spread * 2,
        ),
        Radius.circular(borderRadius + spread),
      );

      // Create gradient paint
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            secondaryColor.withValues(alpha: layerOpacity),
            accentColor.withValues(alpha: layerOpacity * 0.8),
            secondaryColor.withValues(alpha: layerOpacity),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(glowRect.outerRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = LevelUpEffectConstants.borderGlowWidth * scale
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          LevelUpEffectConstants.borderBlurRadius * scale * (i + 1) * 0.3,
        );

      canvas.drawRRect(glowRect, paint);

      // Also draw a filled glow for more depth
      final fillPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            accentColor.withValues(alpha: layerOpacity * 0.3),
            secondaryColor.withValues(alpha: layerOpacity * 0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(glowRect.outerRect)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          LevelUpEffectConstants.borderBlurRadius * scale * (i + 1) * 0.5,
        );

      canvas.drawRRect(glowRect, fillPaint);
    }
  }

  void _drawExpandingRing(
    Canvas canvas,
    Offset center,
    double innerWidth,
    double innerHeight,
    double borderRadius,
    double ringProgress,
  ) {
    if (ringProgress <= 0 || ringProgress >= 1) return;

    final ringOpacity = (1.0 - ringProgress) * 0.8;
    final ringExpand = ringProgress * LevelUpEffectConstants.glowSpread * scale;

    final ringRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: innerWidth + ringExpand * 2,
        height: innerHeight + ringExpand * 2,
      ),
      Radius.circular(borderRadius + ringExpand),
    );

    final ringPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          secondaryColor.withValues(alpha: ringOpacity),
          accentColor.withValues(alpha: ringOpacity * 0.8),
          secondaryColor.withValues(alpha: ringOpacity),
        ],
      ).createShader(ringRect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (4.0 - ringProgress * 3.0) * scale;

    canvas.drawRRect(ringRect, ringPaint);
  }

  void _drawParticles(Canvas canvas, Offset center, double particleProgress) {
    if (particleProgress <= 0) return;

    for (final particle in particles) {
      final distance = particle.speed * scale * particleProgress;
      final opacity = (1.0 - particleProgress).clamp(0.0, 1.0);
      final currentSize =
          particle.size * scale * (1.0 - particleProgress * 0.5);

      if (opacity <= 0 || currentSize <= 0) continue;

      final x = center.dx + cos(particle.angle) * distance;
      final y = center.dy + sin(particle.angle) * distance;

      final color = particle.isSecondary ? secondaryColor : accentColor;

      // Draw particle glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), currentSize * 2.5, glowPaint);

      // Draw particle core
      final corePaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), currentSize, corePaint);
    }
  }

  void _drawInnerBorder(
    Canvas canvas,
    Offset center,
    double innerWidth,
    double innerHeight,
    double borderRadius,
    double intensity,
  ) {
    if (intensity <= 0) return;

    final innerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: innerWidth, height: innerHeight),
      Radius.circular(borderRadius),
    );

    // Draw bright inner border
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: intensity * 0.95),
          secondaryColor.withValues(alpha: intensity * 0.8),
          accentColor.withValues(alpha: intensity * 0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(innerRect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = LevelUpEffectConstants.innerBorderWidth * scale;

    canvas.drawRRect(innerRect, borderPaint);

    // Add extra glow on inner border
    final innerGlowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: intensity * 0.5),
          secondaryColor.withValues(alpha: intensity * 0.4),
          accentColor.withValues(alpha: intensity * 0.5),
        ],
      ).createShader(innerRect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = LevelUpEffectConstants.innerBorderWidth * scale * 2
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        LevelUpEffectConstants.borderBlurRadius * scale * 0.5,
      );

    canvas.drawRRect(innerRect, innerGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _LevelUpEffectPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Individual particle data
class _Particle {
  final double angle;
  final double speed;
  final double size;
  final bool isSecondary;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.isSecondary,
  });
}
