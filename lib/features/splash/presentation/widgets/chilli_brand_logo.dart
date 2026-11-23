import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Crisp vector reproduction of the Chilli Plant Health launcher emblem
/// (`assets/branding/app_icon.svg`) that renders synchronously on frame 1
/// without async image decoding flicker.
class ChilliBrandLogo extends StatelessWidget {
  const ChilliBrandLogo({
    super.key,
    this.size = 116,
    this.sheenProgress = 0.0,
    this.isDark = false,
  });

  final double size;
  final double sheenProgress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.275);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: (isDark
                    ? const Color(0xFF2F7951)
                    : const Color(0xFF17452F))
                .withValues(alpha: isDark ? 0.42 : 0.24),
            blurRadius: isDark ? 36 : 28,
            spreadRadius: isDark ? 2 : 0,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFFF04F43)
                .withValues(alpha: isDark ? 0.16 : 0.09),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _ChilliBrandLogoPainter(
                sheenProgress: sheenProgress,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  color: (isDark
                          ? const Color(0xFFA9DF74)
                          : Colors.white)
                      .withValues(alpha: isDark ? 0.26 : 0.34),
                  width: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChilliBrandLogoPainter extends CustomPainter {
  const _ChilliBrandLogoPainter({required this.sheenProgress});

  final double sheenProgress;

  static const double _viewBox = 1024.0;
  static const Rect _canvasRect = Rect.fromLTWH(0, 0, _viewBox, _viewBox);

  static const RadialGradient _backgroundGradient = RadialGradient(
    center: Alignment(0.0, -0.16),
    radius: 0.72,
    colors: [
      Color(0xFF2F7951),
      Color(0xFF17452F),
    ],
  );

  static const LinearGradient _pepperGradient = LinearGradient(
    begin: Alignment(-0.52, -0.76),
    end: Alignment(0.56, 0.88),
    colors: [
      Color(0xFFFF7960),
      Color(0xFFF04F43),
      Color(0xFFC92F37),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient _leafGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA9DF74),
      Color(0xFF55B451),
    ],
  );

  static final Path _pepperPath = Path()
    ..moveTo(654, 207)
    ..cubicTo(703, 215, 741, 255, 748, 302)
    ..cubicTo(760, 375, 712, 496, 634, 596)
    ..cubicTo(563, 688, 463, 758, 360, 799)
    ..cubicTo(305, 821, 260, 784, 278, 729)
    ..cubicTo(321, 590, 381, 482, 467, 382)
    ..cubicTo(523, 316, 586, 254, 632, 221)
    ..cubicTo(639, 216, 647, 211, 654, 207)
    ..close();

  static final Path _highlightPath = Path()
    ..moveTo(616, 328)
    ..cubicTo(527, 420, 431, 548, 337, 719);

  static final Path _stemPath = Path()
    ..moveTo(650, 230)
    ..cubicTo(672, 190, 677, 151, 659, 111);

  static final Path _leafPath = Path()
    ..moveTo(647, 188)
    ..cubicTo(610, 151, 569, 147, 530, 166)
    ..cubicTo(550, 203, 590, 220, 638, 207)
    ..close();

  static final Path _leafVeinPath = Path()
    ..moveTo(614, 176)
    ..cubicTo(589, 174, 568, 174, 545, 179);

  static final Path _calyxPath = Path()
    ..moveTo(650, 253)
    ..cubicTo(621, 244, 600, 224, 588, 197)
    ..cubicTo(614, 203, 636, 218, 654, 237)
    ..cubicTo(644, 210, 646, 181, 657, 153)
    ..cubicTo(677, 182, 679, 211, 667, 239)
    ..cubicTo(689, 216, 712, 204, 741, 205)
    ..cubicTo(726, 232, 701, 248, 671, 255)
    ..cubicTo(703, 253, 730, 267, 749, 289)
    ..cubicTo(715, 291, 687, 278, 665, 260)
    ..cubicTo(648, 270, 625, 271, 602, 265)
    ..cubicTo(614, 251, 631, 242, 650, 238)
    ..close();

  static final Rect _pepperBounds = _pepperPath.getBounds();
  static final Rect _leafBounds = _leafPath.getBounds();
  static final Rect _calyxBounds = _calyxPath.getBounds();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _viewBox;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Emerald radial background
    final backgroundPaint = Paint()
      ..shader = _backgroundGradient.createShader(_canvasRect);
    canvas.drawRect(_canvasRect, backgroundPaint);

    // 2. Subtle inner botanical halo
    final haloPaint = Paint()
      ..color = const Color(0xFF4A9660).withValues(alpha: 0.18);
    canvas.drawCircle(const Offset(512, 512), 373, haloPaint);

    // 3. Pepper body
    final pepperPaint = Paint()
      ..shader = _pepperGradient.createShader(_pepperBounds);
    canvas.drawPath(_pepperPath, pepperPaint);

    // 4. Specular highlight along pepper contour
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFB09A).withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_highlightPath, highlightPaint);

    // 5. Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF77C65C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 27
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_stemPath, stemPaint);

    // 6. Leaf + vein
    final leafPaint = Paint()..shader = _leafGradient.createShader(_leafBounds);
    canvas.drawPath(_leafPath, leafPaint);

    final veinPaint = Paint()
      ..color = const Color(0xFFD2F2A2).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_leafVeinPath, veinPaint);

    // 7. Calyx
    final calyxPaint = Paint()
      ..shader = _leafGradient.createShader(_calyxBounds);
    canvas.drawPath(_calyxPath, calyxPaint);

    // 8. Subtle diagonal glassmorphic light sheen during entrance
    if (sheenProgress > 0.0 && sheenProgress < 1.0) {
      final sheenEnvelope = math.sin(sheenProgress * math.pi);
      final sweepCenter = -420.0 + sheenProgress * 1860.0;
      canvas.save();
      canvas.translate(sweepCenter, 512);
      canvas.rotate(-0.46);
      const sheenRect = Rect.fromLTWH(-180, -900, 360, 1800);
      final sheenPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.22 * sheenEnvelope),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(sheenRect);
      canvas.drawRect(sheenRect, sheenPaint);
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChilliBrandLogoPainter oldDelegate) {
    return oldDelegate.sheenProgress != sheenProgress;
  }
}
