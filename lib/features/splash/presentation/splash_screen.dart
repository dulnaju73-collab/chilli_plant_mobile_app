import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/chilli_brand_logo.dart';
import 'widgets/splash_ambient_painter.dart';

/// Palette tokens for the splash screen in light and dark system themes.
///
/// The background values match the native Android (`values/colors.xml` &
/// `values-night/colors.xml`) and iOS (`SplashBackground.colorset`) launch
/// screens pixel-for-pixel to guarantee a flicker-free first frame.
class SplashPalette {
  const SplashPalette._({
    required this.background,
    required this.title,
    required this.tagline,
    required this.accentStart,
    required this.accentEnd,
    required this.progressTrack,
    required this.isDark,
  });

  static const SplashPalette light = SplashPalette._(
    background: Color(0xFFF6FAF7),
    title: Color(0xFF123524),
    tagline: Color(0xFF4D6B59),
    accentStart: Color(0xFF2F7951),
    accentEnd: Color(0xFF6BC158),
    progressTrack: Color(0xFFDCEADF),
    isDark: false,
  );

  static const SplashPalette dark = SplashPalette._(
    background: Color(0xFF0D1F16),
    title: Color(0xFFF2F8F4),
    tagline: Color(0xFF9AB8A6),
    accentStart: Color(0xFF55B451),
    accentEnd: Color(0xFFA9DF74),
    progressTrack: Color(0xFF1D3B2B),
    isDark: true,
  );

  static SplashPalette resolve(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark ||
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return isDark ? dark : light;
  }

  final Color background;
  final Color title;
  final Color tagline;
  final Color accentStart;
  final Color accentEnd;
  final Color progressTrack;
  final bool isDark;
}

/// Modern, lightweight animated splash screen displayed immediately on launch
/// while essential services and authentication state initialize in the background.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onEntranceComplete,
    this.entranceDuration = const Duration(milliseconds: 1200),
  });

  static const String appName = 'Chilli Plant Health';
  static const String tagline = 'Smart Leaf Disease Detection';

  /// Called once when the entrance animation finishes (or immediately when
  /// reduced motion is active).
  final VoidCallback? onEntranceComplete;

  /// Duration of the entrance choreography before signaling readiness.
  final Duration entranceDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Curve _springCurve = Cubic(0.22, 1.12, 0.36, 1.0);

  late final AnimationController _entranceController;
  late final AnimationController _ambientController;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoSlideY;
  late final Animation<double> _sheenProgress;

  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlideY;
  late final Animation<double> _accentReveal;

  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineSlideY;
  late final Animation<double> _loaderOpacity;

  bool _started = false;
  bool _notifiedComplete = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: widget.entranceDuration,
    )..addStatusListener(_handleEntranceStatus);

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.04, 0.34, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.74, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.62, curve: _springCurve),
      ),
    );
    _logoSlideY = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.56, curve: Curves.easeOutCubic),
      ),
    );
    _sheenProgress = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.36, 0.86, curve: Curves.easeInOut),
    );

    _titleOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.32, 0.68, curve: Curves.easeOut),
    );
    _titleSlideY = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.32, 0.70, curve: Curves.easeOutCubic),
      ),
    );
    _accentReveal = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.44, 0.78, curve: Curves.easeOutCubic),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.86, curve: Curves.easeOut),
    );
    _taglineSlideY = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.48, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _loaderOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.58, 0.94, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    _reducedMotion = disableAnimations;

    if (!_started) {
      _started = true;
      if (_reducedMotion) {
        _entranceController.value = 1.0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notifyEntranceComplete();
        });
      } else {
        _entranceController.forward();
        _ambientController.repeat();
      }
    } else if (_reducedMotion && _ambientController.isAnimating) {
      _ambientController.stop();
      _entranceController.value = 1.0;
      _notifyEntranceComplete();
    }
  }

  void _handleEntranceStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _notifyEntranceComplete();
    }
  }

  void _notifyEntranceComplete() {
    if (_notifiedComplete || !mounted) return;
    _notifiedComplete = true;
    widget.onEntranceComplete?.call();
  }

  @override
  void dispose() {
    _entranceController.removeStatusListener(_handleEntranceStatus);
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SplashPalette.resolve(context);
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness:
          palette.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: palette.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness:
          palette.isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: palette.background,
        body: Semantics(
          label: '${SplashScreen.appName}. ${SplashScreen.tagline}.',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 480;
              final logoSize =
                  (constraints.maxHeight * 0.22).clamp(64.0, 114.0).toDouble();
              final logoCenterYFactor = isCompact ? 0.37 : 0.42;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // GPU-friendly ambient botanical glow, pulse rings, and particles
                  ExcludeSemantics(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _entranceController,
                          _ambientController,
                        ]),
                        builder: (context, _) {
                          return CustomPaint(
                            painter: SplashAmbientPainter(
                              entranceProgress: _entranceController.value,
                              ambientProgress: _ambientController.value,
                              isDark: palette.isDark,
                              reducedMotion: _reducedMotion,
                              logoCenterYFactor: logoCenterYFactor,
                            ),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  ),

                  // Foreground branding & minimal progress cue
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: isCompact ? 16 : 28,
                      ),
                      child: Column(
                        children: [
                          const Spacer(flex: 5),
                          _buildAnimatedBrandMark(logoSize, palette),
                          SizedBox(height: isCompact ? 18 : 28),
                          _buildAnimatedTitle(palette, isCompact),
                          SizedBox(height: isCompact ? 10 : 14),
                          _buildAnimatedAccentRule(palette),
                          SizedBox(height: isCompact ? 10 : 14),
                          _buildAnimatedTagline(palette, isCompact),
                          const Spacer(flex: 6),
                          _buildProgressIndicator(palette),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBrandMark(double logoSize, SplashPalette palette) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _ambientController]),
        builder: (context, _) {
          final settleFactor =
              ((_entranceController.value - 0.65) / 0.35).clamp(0.0, 1.0);
          final floatOffset = _reducedMotion
              ? 0.0
              : math.sin(_ambientController.value * math.pi * 2.0) *
                  2.2 *
                  settleFactor;

          return Opacity(
            opacity: _logoOpacity.value,
            child: Transform.translate(
              offset: Offset(0, _logoSlideY.value + floatOffset),
              child: Transform.scale(
                scale: _logoScale.value,
                child: ChilliBrandLogo(
                  size: logoSize,
                  sheenProgress: _reducedMotion ? 0.0 : _sheenProgress.value,
                  isDark: palette.isDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedTitle(SplashPalette palette, bool isCompact) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _titleOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _titleSlideY.value),
            child: child,
          ),
        );
      },
      child: Text(
        SplashScreen.appName,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isCompact ? 22 : 27,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.15,
          color: palette.title,
        ),
      ),
    );
  }

  Widget _buildAnimatedAccentRule(SplashPalette palette) {
    return AnimatedBuilder(
      animation: _accentReveal,
      builder: (context, _) {
        return Opacity(
          opacity: _accentReveal.value,
          child: Transform.scale(
            scaleX: _accentReveal.value.clamp(0.001, 1.0),
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [palette.accentStart, palette.accentEnd],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTagline(SplashPalette palette, bool isCompact) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _taglineOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _taglineSlideY.value),
            child: child,
          ),
        );
      },
      child: Text(
        SplashScreen.tagline,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isCompact ? 13 : 14.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
          height: 1.35,
          color: palette.tagline,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(SplashPalette palette) {
    return AnimatedBuilder(
      animation: Listenable.merge([_loaderOpacity, _ambientController]),
      builder: (context, _) {
        return Opacity(
          opacity: _loaderOpacity.value,
          child: SizedBox(
            width: 112,
            height: 3.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: CustomPaint(
                painter: _SplashProgressBarPainter(
                  progress: _reducedMotion ? 0.5 : _ambientController.value,
                  trackColor: palette.progressTrack,
                  barStartColor: palette.accentStart,
                  barEndColor: palette.accentEnd,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SplashProgressBarPainter extends CustomPainter {
  const _SplashProgressBarPainter({
    required this.progress,
    required this.trackColor,
    required this.barStartColor,
    required this.barEndColor,
  });

  final double progress;
  final Color trackColor;
  final Color barStartColor;
  final Color barEndColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()..color = trackColor;
    canvas.drawRect(Offset.zero & size, trackPaint);

    // Smooth back-and-forth gliding capsule shimmer
    final wave = 0.5 - 0.5 * math.cos(progress * math.pi * 2.0);
    final barWidth = size.width * 0.42;
    final left = (size.width - barWidth) * wave;
    final barRect = Rect.fromLTWH(left, 0, barWidth, size.height);
    final barPaint = Paint()
      ..shader = LinearGradient(
        colors: [barStartColor, barEndColor],
      ).createShader(barRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(size.height)),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.barStartColor != barStartColor ||
        oldDelegate.barEndColor != barEndColor;
  }
}
