import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints lightweight botanical glow, soft concentric ripple rings, and
/// subtle drifting micro-particles behind the splash screen branding.
class SplashAmbientPainter extends CustomPainter {
  const SplashAmbientPainter({
    required this.entranceProgress,
    required this.ambientProgress,
    required this.isDark,
    required this.reducedMotion,
    required this.logoCenterYFactor,
  });

  final double entranceProgress;
  final double ambientProgress;
  final bool isDark;
  final bool reducedMotion;
  final double logoCenterYFactor;

  static const List<_ParticleSeed> _particles = [
    _ParticleSeed(angle: 0.25, radiusFactor: 0.24, size: 3.2, phase: 0.08, isWarm: false),
    _ParticleSeed(angle: 0.92, radiusFactor: 0.34, size: 2.4, phase: 0.24, isWarm: true),
    _ParticleSeed(angle: 1.58, radiusFactor: 0.28, size: 2.8, phase: 0.41, isWarm: false),
    _ParticleSeed(angle: 2.26, radiusFactor: 0.38, size: 3.5, phase: 0.56, isWarm: false),
    _ParticleSeed(angle: 2.84, radiusFactor: 0.26, size: 2.2, phase: 0.72, isWarm: true),
    _ParticleSeed(angle: 3.48, radiusFactor: 0.35, size: 3.0, phase: 0.16, isWarm: false),
    _ParticleSeed(angle: 4.12, radiusFactor: 0.25, size: 2.6, phase: 0.63, isWarm: false),
    _ParticleSeed(angle: 4.78, radiusFactor: 0.37, size: 3.4, phase: 0.85, isWarm: false),
    _ParticleSeed(angle: 5.36, radiusFactor: 0.29, size: 2.3, phase: 0.33, isWarm: true),
    _ParticleSeed(angle: 5.92, radiusFactor: 0.40, size: 2.9, phase: 0.49, isWarm: false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * logoCenterYFactor);
    final shortest = size.shortestSide;
    final glowProgress = Curves.easeOutCubic.transform(
      (entranceProgress / 0.65).clamp(0.0, 1.0),
    );
    final breathe = reducedMotion
        ? 0.0
        : math.sin(ambientProgress * math.pi * 2.0);

    // 1. Soft atmospheric emerald radial wash (starts at 0 so frame 1 matches native background)
    if (glowProgress > 0.0) {
      final primaryRadius = shortest * (0.58 + 0.035 * breathe);
      final primaryRect = Rect.fromCircle(center: center, radius: primaryRadius);
      final primaryGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            (isDark ? const Color(0xFF2F7951) : const Color(0xFF3E9460))
                .withValues(alpha: (isDark ? 0.30 : 0.12) * glowProgress),
            (isDark ? const Color(0xFF17452F) : const Color(0xFF77C65C))
                .withValues(alpha: (isDark ? 0.10 : 0.04) * glowProgress),
            Colors.transparent,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(primaryRect);
      canvas.drawCircle(center, primaryRadius, primaryGlow);

      // Subtle warm coral-chili tint offset softly behind the emblem
      final warmCenter = center + Offset(shortest * 0.05, -shortest * 0.03);
      final warmRadius = shortest * 0.30;
      final warmGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF04F43)
                .withValues(alpha: (isDark ? 0.11 : 0.055) * glowProgress),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: warmCenter, radius: warmRadius));
      canvas.drawCircle(warmCenter, warmRadius, warmGlow);
    }

    if (reducedMotion) {
      return;
    }

    // 2. Subtle expanding concentric botanical rings
    _paintRippleRing(
      canvas: canvas,
      center: center,
      baseRadius: shortest * 0.16,
      maxRadius: shortest * 0.36,
      t: ((entranceProgress - 0.06) / 0.78).clamp(0.0, 1.0),
      maxAlpha: isDark ? 0.24 : 0.16,
      strokeWidth: 1.5,
    );

    if (entranceProgress > 0.75) {
      final loopFade = ((entranceProgress - 0.75) / 0.25).clamp(0.0, 1.0);
      _paintRippleRing(
        canvas: canvas,
        center: center,
        baseRadius: shortest * 0.17,
        maxRadius: shortest * 0.34,
        t: ambientProgress,
        maxAlpha: (isDark ? 0.14 : 0.09) * loopFade,
        strokeWidth: 1.1,
      );
    }

    // 3. Lightweight floating botanical dew/pollen micro-particles
    final particleFade = Curves.easeOut.transform(
      ((entranceProgress - 0.18) / 0.55).clamp(0.0, 1.0),
    );
    if (particleFade > 0.0) {
      final particlePaint = Paint()..style = PaintingStyle.fill;
      for (final seed in _particles) {
        final cycle = (ambientProgress + seed.phase) % 1.0;
        final driftAngle = seed.angle + math.sin(cycle * math.pi * 2.0) * 0.08;
        final distance = shortest * seed.radiusFactor +
            math.sin(cycle * math.pi * 2.0) * 9.0;
        final verticalDrift = -cycle * 14.0 + 7.0;
        final position = Offset(
          center.dx + math.cos(driftAngle) * distance,
          center.dy + math.sin(driftAngle) * distance + verticalDrift,
        );
        final twinkle = 0.35 + 0.65 * math.sin(cycle * math.pi);
        final color = seed.isWarm
            ? const Color(0xFFFF7960)
            : (isDark ? const Color(0xFFA9DF74) : const Color(0xFF4A9660));
        final alpha = (isDark ? 0.42 : 0.34) * particleFade * twinkle;
        particlePaint.color = color.withValues(alpha: alpha);
        canvas.drawCircle(position, seed.size, particlePaint);
      }
    }
  }

  void _paintRippleRing({
    required Canvas canvas,
    required Offset center,
    required double baseRadius,
    required double maxRadius,
    required double t,
    required double maxAlpha,
    required double strokeWidth,
  }) {
    if (t <= 0.0 || t >= 1.0) return;
    final eased = Curves.easeOutCubic.transform(t);
    final alpha = math.sin(t * math.pi) * maxAlpha;
    final radius = baseRadius + (maxRadius - baseRadius) * eased;
    final ringPaint = Paint()
      ..color = (isDark ? const Color(0xFF77C65C) : const Color(0xFF2F7951))
          .withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant SplashAmbientPainter oldDelegate) {
    return oldDelegate.entranceProgress != entranceProgress ||
        oldDelegate.ambientProgress != ambientProgress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.reducedMotion != reducedMotion ||
        oldDelegate.logoCenterYFactor != logoCenterYFactor;
  }
}

class _ParticleSeed {
  const _ParticleSeed({
    required this.angle,
    required this.radiusFactor,
    required this.size,
    required this.phase,
    required this.isWarm,
  });

  final double angle;
  final double radiusFactor;
  final double size;
  final double phase;
  final bool isWarm;
}
