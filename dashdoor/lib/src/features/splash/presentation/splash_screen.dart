import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../onboarding/presentation/value_pitch_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _progressController;
  late final AnimationController _fadeInController;
  late final VideoPlayerController _videoController;
  bool _hasNavigated = false;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/animations/launch-happy.mp4',
    );
    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() => _videoReady = true);
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
      }
    });

    _mainController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start fade-in animation
    _fadeInController.forward();

    // Start progress animation after fade-in completes
    _fadeInController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _progressController.forward();
      }
    });

    // When progress completes, navigate with fade transition
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasNavigated) {
        _hasNavigated = true;
        // Small delay to ensure progress bar is fully visible at 100%
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ValuePitchScreen(),
                transitionDuration: const Duration(milliseconds: 500),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
              ),
            );
          }
        });
      }
    });

    // Provide animation value to child widgets
    _mainController.addListener(() => setState(() {}));
    _progressController.addListener(() => setState(() {}));
    _fadeInController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mainController.dispose();
    _progressController.dispose();
    _fadeInController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _fadeInController.value,
      child: Scaffold(
        backgroundColor: AppPalette.creamBackground,
        body: Stack(
          children: [
            // Subtle dot grid on the background.
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  dotColor: AppPalette.neutral500.withOpacity(0.10),
                  spacing: 18,
                  radius: 1.0,
                ),
              ),
            ),
            // Full-screen splash surface (no framed card / no title).
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppPalette.creamBackground,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.15),
                    radius: 0.95,
                    colors: [
                      AppPalette.sunRewards.withOpacity(0.022),
                      AppPalette.creamBackground,
                    ],
                    stops: const [0.0, 0.55],
                  ),
                ),
                child: Stack(
                  children: [
                    _SplashBgIcons(animationValue: _mainController.value),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 28),
                              _HeroBadge(
                                floatValue: _mainController.value,
                                videoController: _videoController,
                                videoReady: _videoReady,
                              ),
                              const SizedBox(height: 26),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 10 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  'Healthy Autopilot',
                                  style: context.appText.h1.copyWith(
                                    fontSize: 42,
                                    height: 1.05,
                                    fontWeight: FontWeight.w900,
                                    color: AppPalette.neutral900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOut,
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 8 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  "Eat well before\nyou're hangry.",
                                  textAlign: TextAlign.center,
                                  style: context.appText.h3.copyWith(
                                    fontSize: 20,
                                    height: 1.25,
                                    fontWeight: FontWeight.w500,
                                    color: AppPalette.neutral700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              _ProgressBlock(
                                progress: _progressController.value,
                              ),
                              const SizedBox(height: 34),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.floatValue,
    required this.videoController,
    required this.videoReady,
  });

  final double floatValue;
  final VideoPlayerController videoController;
  final bool videoReady;

  @override
  Widget build(BuildContext context) {
    const double heroSize = 230;

    // Gentle floating animation (sine wave)
    final floatOffset = math.sin(floatValue * 2 * math.pi) * 6.0;
    final rotationValue = math.sin(floatValue * 2 * math.pi) * 0.03;
    final scaleValue = 1.0 + (math.sin(floatValue * 2 * math.pi) * 0.015);
    final shadowOpacity = 0.18 + (math.sin(floatValue * 2 * math.pi) * 0.03);
    final shadowBlur = 28.0 + (math.sin(floatValue * 2 * math.pi) * 3.0);

    // Heart pulse animation (slightly out of phase)
    final heartPulseValue = math.sin((floatValue * 2 * math.pi) + 0.5) * 0.08;
    final heartScale = 1.0 + heartPulseValue;
    final heartRotation =
        15 * math.pi / 180 + (math.sin(floatValue * 2 * math.pi + 1.0) * 0.08);

    return Transform.translate(
      offset: Offset(0, floatOffset),
      child: SizedBox(
        width: heroSize + 20,
        height: heroSize + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hero circle
            Transform.rotate(
              angle: rotationValue,
              child: Transform.scale(
                scale: scaleValue,
                child: Container(
                  width: heroSize,
                  height: heroSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          shadowOpacity.clamp(0.15, 0.21),
                        ),
                        blurRadius: shadowBlur.clamp(25.0, 31.0),
                        offset: Offset(0, 18 + floatOffset * 0.3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: videoReady
                        ? Transform.translate(
                            offset: const Offset(-10, 0),
                            child: Transform.scale(
                              scale: 0.82,
                              child: _CroppedSquareVideo(
                                controller: videoController,
                                size: heroSize,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Heart bubble
            Positioned(
              right: 8,
              top: 30,
              child: Transform.rotate(
                angle: heartRotation,
                child: Transform.scale(
                  scale: heartScale,
                  child: Container(
                    width: 46,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceWhite,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite,
                        size: 22,
                        color: AppPalette.sunRewards,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crops a rectangular video to a square by centering and clipping.
class _CroppedSquareVideo extends StatelessWidget {
  const _CroppedSquareVideo({
    required this.controller,
    required this.size,
  });

  final VideoPlayerController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    final videoSize = controller.value.size;
    if (videoSize == Size.zero) return const SizedBox.shrink();

    final videoAspect = videoSize.width / videoSize.height;

    // We want to fill a square. If video is wider than tall (aspect > 1),
    // we match height to the square and let width overflow.
    // If video is taller than wide (aspect < 1),
    // we match width to the square and let height overflow.
    final double renderW;
    final double renderH;
    if (videoAspect >= 1.0) {
      // Landscape or square: fit height, crop width
      renderH = size;
      renderW = size * videoAspect;
    } else {
      // Portrait: fit width, crop height
      renderW = size;
      renderH = size / videoAspect;
    }

    return SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        maxWidth: renderW,
        maxHeight: renderH,
        child: SizedBox(
          width: renderW,
          height: renderH,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    const double width = 260;
    const double height = 8;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, fadeValue, child) {
        return Opacity(
          opacity: fadeValue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: width,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: AppPalette.neutral200,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: width * progress.clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            color: AppPalette.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SYNCING YOUR DAY...',
                style: context.appText.smallStrong.copyWith(
                  color: AppPalette.primary,
                  letterSpacing: 2.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SplashBgIcons extends StatelessWidget {
  const _SplashBgIcons({required this.animationValue});

  final double animationValue;

  @override
  Widget build(BuildContext context) {
    final iconColor = AppPalette.sunRewards.withOpacity(0.25);

    Widget faintIcon({
      required IconData icon,
      required double size,
      required Offset offset,
      double rotation = 0,
      double opacity = 1,
      double floatPhase = 0,
      double floatAmplitude = 0,
    }) {
      // Very subtle floating animation for background icons (parallax effect)
      final floatOffset =
          math.sin((animationValue * 2 * math.pi) + floatPhase) *
          floatAmplitude;
      final iconRotation =
          rotation +
          (math.sin((animationValue * 2 * math.pi) + floatPhase) * 0.05);

      return Positioned(
        left: offset.dx,
        top: offset.dy + floatOffset,
        child: Transform.rotate(
          angle: iconRotation,
          child: Opacity(
            opacity: opacity,
            child: Icon(icon, size: size, color: iconColor),
          ),
        ),
      );
    }

    // Use LayoutBuilder so positions scale across devices while keeping the
    // screenshot-like composition.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Top-left burger
            faintIcon(
              icon: Icons.lunch_dining,
              size: 46,
              offset: Offset(w * 0.08, h * 0.12),
              rotation: -0.15,
              opacity: 1.0,
              floatPhase: 0.0,
              floatAmplitude: 3.0,
            ),
            // Mid-right small toast/food
            faintIcon(
              icon: Icons.bakery_dining,
              size: 40,
              offset: Offset(w * 0.82, h * 0.21),
              rotation: 0.18,
              opacity: 0.91,
              floatPhase: 1.2,
              floatAmplitude: 2.5,
            ),
            // Mid-left donut
            faintIcon(
              icon: Icons.donut_large,
              size: 36,
              offset: Offset(w * 0.08, h * 0.46),
              rotation: 0.0,
              opacity: 0.91,
              floatPhase: 0.8,
              floatAmplitude: 2.0,
            ),
            // Bottom-right utensils
            Positioned(
              right: w * 0.10,
              bottom: h * 0.20,
              child: Transform.rotate(
                angle:
                    -0.25 +
                    (math.sin((animationValue * 2 * math.pi) + 2.0) * 0.05),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    math.sin((animationValue * 2 * math.pi) + 2.0) * 2.5,
                  ),
                  child: Opacity(
                    opacity: 0.91,
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 48,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-left pizza slice
            faintIcon(
              icon: Icons.local_pizza,
              size: 46,
              offset: Offset(w * 0.08, h * 0.74),
              rotation: -0.35,
              opacity: 1.0,
              floatPhase: 1.5,
              floatAmplitude: 3.5,
            ),

            // A couple of soft circular blotches to mimic the warm background.
            Positioned(
              left: -w * 0.15,
              top: h * 0.05,
              child: _SoftBlob(
                size: w * 0.75,
                color: AppPalette.sunRewards.withOpacity(0.03),
              ),
            ),
            Positioned(
              right: -w * 0.2,
              bottom: -h * 0.05,
              child: _SoftBlob(
                size: w * 0.85,
                color: AppPalette.sunRewards.withOpacity(0.028),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({
    required this.dotColor,
    required this.spacing,
    required this.radius,
  });

  final Color dotColor;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    final cols = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();

    // Slight stagger for a softer, less rigid grid.
    for (var r = 0; r <= rows; r++) {
      final y = r * spacing;
      final xOffset = (r.isEven ? 0.0 : spacing / 2);
      for (var c = 0; c <= cols; c++) {
        final x = c * spacing + xOffset;
        if (x < 0 || x > size.width || y < 0 || y > size.height) continue;
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }

    // A couple of extra subtle speckles for texture.
    final rnd = math.Random(7);
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        radius * 0.7,
        Paint()..color = dotColor.withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}
