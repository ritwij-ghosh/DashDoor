import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../auth/presentation/login_screen.dart';

/// Opening screen — vibrant coral gradient, cinematic text-forward hero.
class ValuePitchScreen extends ConsumerStatefulWidget {
  const ValuePitchScreen({super.key});

  @override
  ConsumerState<ValuePitchScreen> createState() => _ValuePitchScreenState();
}

class _ValuePitchScreenState extends ConsumerState<ValuePitchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _enterCtrl.forward();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _shimmerCtrl.dispose();
    _glowCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: a, curve: Curves.easeOutQuart),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // Vivid coral-to-deep gradient
  static const _bgTop = Color(0xFFFF8A65);
  static const _bgMid = Color(0xFFFF4D2E);
  static const _bgBottom = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgTop, _bgMid, _bgBottom],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Geometric background pattern ──
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowCtrl,
                  builder: (context, _) {
                    return AnimatedBuilder(
                      animation: _floatCtrl,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _HeroPatternPainter(
                            breathe: _glowCtrl.value,
                            drift: _floatCtrl.value,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Main content ──
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // ── Mascot ──
                    AnimatedBuilder(
                      animation: _enterCtrl,
                      builder: (context, child) {
                        final t = const Interval(0.0, 0.35,
                                curve: Curves.easeOutCubic)
                            .transform(_enterCtrl.value);
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - t)),
                          child: Opacity(opacity: t, child: child),
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _floatCtrl,
                        builder: (context, child) {
                          final drift =
                              math.sin(_floatCtrl.value * math.pi * 2) * 4;
                          return Transform.translate(
                            offset: Offset(0, drift),
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: 110,
                          height: 110,
                          child: Transform.translate(
                            offset: const Offset(7.5, 0),
                            child: Lottie.asset(
                              'assets/animations/excited_idle_animation.json',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const MascotWidget(
                                state: MascotState.happy,
                                width: 110,
                                height: 110,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── "Meals, decided." — white with traveling shimmer ──
                    AnimatedBuilder(
                      animation: _enterCtrl,
                      builder: (context, child) {
                        final t = const Interval(0.1, 0.42,
                                curve: Curves.easeOutCubic)
                            .transform(_enterCtrl.value);
                        return Transform.translate(
                          offset: Offset(0, 40 * (1 - t)),
                          child: Opacity(opacity: t, child: child),
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (context, _) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              final dx =
                                  _shimmerCtrl.value * bounds.width * 3 -
                                      bounds.width;
                              return LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.5),
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                transform: _SlidingGradientTransform(
                                    dx / bounds.width),
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              'Meals,\ndecided.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 58,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                letterSpacing: -2.0,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ── "Goals, hit." — dark overlay for contrast ──
                    AnimatedBuilder(
                      animation: _enterCtrl,
                      builder: (context, child) {
                        final t = const Interval(0.2, 0.52,
                                curve: Curves.easeOutCubic)
                            .transform(_enterCtrl.value);
                        return Transform.translate(
                          offset: Offset(0, 32 * (1 - t)),
                          child: Opacity(opacity: t, child: child),
                        );
                      },
                      child: Text(
                        'Goals, hit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -2.0,
                          color: const Color(0xFF1A0A06),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Subtitle ──
                    AnimatedBuilder(
                      animation: _enterCtrl,
                      builder: (context, child) {
                        final t = const Interval(0.3, 0.58,
                                curve: Curves.easeOutCubic)
                            .transform(_enterCtrl.value);
                        return Opacity(opacity: t, child: child);
                      },
                      child: Text(
                        '3 picks in 20 seconds — from what\nyou already have at home.',
                        textAlign: TextAlign.center,
                        style: context.appText.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 15,
                          height: 1.55,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),

                    const Spacer(flex: 4),

                    // ── CTA ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: AnimatedBuilder(
                        animation: _enterCtrl,
                        builder: (context, child) {
                          final t = const Interval(0.48, 0.78,
                                  curve: Curves.easeOutCubic)
                              .transform(_enterCtrl.value);
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - t)),
                            child: Opacity(opacity: t, child: child),
                          );
                        },
                        child: BounceInteraction(
                          onTap: _onGetStarted,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF000000)
                                      .withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get started',
                                  style:
                                      context.appText.bodyStrong.copyWith(
                                    color: _bgBottom,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded,
                                    color: _bgBottom, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Already have account ──
                    AnimatedBuilder(
                      animation: _enterCtrl,
                      builder: (context, child) {
                        final t = const Interval(0.58, 0.85,
                                curve: Curves.easeOutCubic)
                            .transform(_enterCtrl.value);
                        return Opacity(opacity: t, child: child);
                      },
                      child: GestureDetector(
                        onTap: _onGetStarted,
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'I already have an account',
                            style: context.appText.small.copyWith(
                              color:
                                  Colors.white.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: bottomPad + 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter — layered geometric patterns on the hero background.
class _HeroPatternPainter extends CustomPainter {
  final double breathe; // 0..1 pulsing
  final double drift;   // 0..1 floating

  _HeroPatternPainter({required this.breathe, required this.drift});

  /// Draw an acorn outline at [center] with given [s] scale, [angle] rotation.
  void _drawAcorn(Canvas canvas, Offset center, double s, double angle, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final path = Path();

    // Cap (top rounded bumpy part)
    path.moveTo(-s * 0.5, -s * 0.05);
    path.quadraticBezierTo(-s * 0.52, -s * 0.45, -s * 0.3, -s * 0.55);
    path.quadraticBezierTo(-s * 0.1, -s * 0.7, 0, -s * 0.72);
    path.quadraticBezierTo(s * 0.1, -s * 0.7, s * 0.3, -s * 0.55);
    path.quadraticBezierTo(s * 0.52, -s * 0.45, s * 0.5, -s * 0.05);

    // Cap brim (slight widening)
    path.lineTo(s * 0.52, s * 0.05);

    // Body (rounded bottom nut shape)
    path.quadraticBezierTo(s * 0.5, s * 0.4, s * 0.32, s * 0.62);
    path.quadraticBezierTo(s * 0.15, s * 0.8, 0, s * 0.85);
    path.quadraticBezierTo(-s * 0.15, s * 0.8, -s * 0.32, s * 0.62);
    path.quadraticBezierTo(-s * 0.5, s * 0.4, -s * 0.52, s * 0.05);

    path.close();

    // Cap texture line
    final capLine = Path();
    capLine.moveTo(-s * 0.48, 0);
    capLine.quadraticBezierTo(0, s * 0.08, s * 0.48, 0);

    // Small stem on top
    final stem = Path();
    stem.moveTo(0, -s * 0.72);
    stem.quadraticBezierTo(s * 0.06, -s * 0.9, s * 0.02, -s * 0.98);

    canvas.drawPath(path, paint);
    canvas.drawPath(capLine, paint);
    canvas.drawPath(stem, paint);

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Acorn positions: (x%, y%, scale, base rotation, opacity)
    final acorns = [
      (0.08, 0.06, 22.0, -0.2, 0.20),
      (0.78, 0.04, 18.0, 0.3, 0.16),
      (0.92, 0.18, 26.0, -0.15, 0.18),
      (0.05, 0.30, 16.0, 0.4, 0.14),
      (0.60, 0.20, 20.0, -0.35, 0.12),
      (0.35, 0.12, 14.0, 0.25, 0.15),
      (0.88, 0.38, 19.0, -0.1, 0.16),
      (0.15, 0.52, 24.0, 0.2, 0.17),
      (0.72, 0.50, 15.0, -0.3, 0.13),
      (0.42, 0.42, 21.0, 0.15, 0.14),
      (0.95, 0.60, 17.0, 0.35, 0.15),
      (0.28, 0.68, 20.0, -0.25, 0.16),
      (0.65, 0.65, 23.0, 0.1, 0.18),
      (0.08, 0.78, 18.0, -0.4, 0.14),
      (0.50, 0.80, 16.0, 0.3, 0.12),
      (0.82, 0.75, 25.0, -0.2, 0.17),
      (0.35, 0.92, 19.0, 0.25, 0.15),
      (0.70, 0.90, 14.0, -0.15, 0.13),
      (0.12, 0.95, 22.0, 0.1, 0.16),
    ];

    for (var i = 0; i < acorns.length; i++) {
      final (xp, yp, s, baseAngle, alpha) = acorns[i];
      // Each acorn drifts gently with a unique phase
      final phase = i * 0.33;
      final dy = math.sin((drift + phase) * math.pi * 2) * 5;
      final dx = math.cos((drift + phase * 0.7) * math.pi * 2) * 3;
      final rotWobble = math.sin((breathe + phase) * math.pi * 2) * 0.06;

      paint.color = Colors.white.withValues(alpha: alpha + breathe * 0.04);

      _drawAcorn(
        canvas,
        Offset(w * xp + dx, h * yp + dy),
        s,
        baseAngle + rotWobble,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) =>
      oldDelegate.breathe != breathe || oldDelegate.drift != drift;
}

/// Slides a gradient along its axis for the shimmer effect.
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}
