import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../setup/presentation/setup_screen.dart';

/// "Personalizing your plan" loading screen shown after paywall,
/// before the user reaches the home screen.
class PersonalizingPlanScreen extends ConsumerStatefulWidget {
  const PersonalizingPlanScreen({super.key});

  @override
  ConsumerState<PersonalizingPlanScreen> createState() =>
      _PersonalizingPlanScreenState();
}

class _PersonalizingPlanScreenState
    extends ConsumerState<PersonalizingPlanScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final AnimationController _pulseCtrl;
  int _currentStep = 0;
  int _currentReviewIndex = 0;
  Timer? _stepTimer;
  Timer? _reviewTimer;

  static const _steps = [
    'Reading your priorities',
    'Mapping meals to your week',
    'Scouting options for the next 8–12 hours',
    'Pairing goals with real locations',
    'Locking in your autopilot',
  ];

  static const _reviews = [
    _ReviewData(
      text:
          "Back-to-back interviews from 1 to 5 — it told me to order lunch "
          "before I got hangry. Game changer.",
      author: 'Sarah M.',
      stars: 5,
    ),
    _ReviewData(
      text:
          "I landed in Denver at 8:40 PM starving. Three nearby picks "
          "actually fit my macros. I didn’t have to think.",
      author: 'James K.',
      stars: 5,
    ),
    _ReviewData(
      text:
          "Most apps react after I mess up. This one plans around chaos — "
          "flights, hotels, weird days.",
      author: 'Priya R.',
      stars: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Progress through steps
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (!mounted) return;
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
        HapticFeedback.selectionClick();
      } else {
        t.cancel();
      }
    });

    // Rotate reviews
    _reviewTimer = Timer.periodic(const Duration(milliseconds: 3500), (t) {
      if (!mounted) return;
      setState(() =>
          _currentReviewIndex = (_currentReviewIndex + 1) % _reviews.length);
    });

    // Navigate after loading completes
    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const SetupScreen(),
              transitionsBuilder: (_, a, __, child) {
                return FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                          parent: a, curve: Curves.easeOutQuart),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
            (route) => false,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    _stepTimer?.cancel();
    _reviewTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F7F0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Progress ring ──
                AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (context, _) {
                    final pct =
                        (_progressCtrl.value * 100).round().clamp(0, 100);
                    return SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 136,
                            height: 136,
                            child: CircularProgressIndicator(
                              value: _progressCtrl.value,
                              strokeWidth: 8,
                              color: AppPalette.successMint,
                              backgroundColor:
                                  AppPalette.successMint.withValues(alpha: 0.12),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, _) {
                              final scale = 1.0 + _pulseCtrl.value * 0.04;
                              return Transform.scale(
                                scale: scale,
                                child: Text(
                                  '$pct%',
                                  style: context.appText.h1.copyWith(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: AppPalette.deepNavy,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // ── Title ──
                Text(
                  'Personalizing plan',
                  style: context.appText.h1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Step checklist ──
                ...List.generate(_steps.length, (i) {
                  final isActive = i <= _currentStep;
                  final isCurrent = i == _currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? AppPalette.successMint
                                : AppPalette.neutral100,
                            border: isCurrent
                                ? Border.all(
                                    color: AppPalette.successMint,
                                    width: 2)
                                : null,
                          ),
                          child: isActive && !isCurrent
                              ? const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: context.appText.body.copyWith(
                              color: isActive
                                  ? AppPalette.deepNavy
                                  : AppPalette.neutral400,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            child: Text(_steps[i]),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Spacer(flex: 2),

                // ── Review carousel ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _buildReviewCard(
                    context,
                    _reviews[_currentReviewIndex],
                    key: ValueKey(_currentReviewIndex),
                  ),
                ),
                const SizedBox(height: 12),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_reviews.length, (i) {
                    final isActive = i == _currentReviewIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isActive ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppPalette.deepNavy
                            : AppPalette.neutral200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),

                const Spacer(flex: 1),
                SizedBox(height: bottomPad),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, _ReviewData review,
      {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars + author
          Row(
            children: [
              ...List.generate(
                review.stars,
                (_) => const Icon(Icons.star_rounded,
                    size: 16, color: AppPalette.sunRewards),
              ),
              const Spacer(),
              Text(
                review.author,
                style: context.appText.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.neutral500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.text,
            style: context.appText.body.copyWith(
              color: AppPalette.deepNavy,
              fontWeight: FontWeight.w500,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewData {
  final String text;
  final String author;
  final int stars;

  const _ReviewData({
    required this.text,
    required this.author,
    required this.stars,
  });
}
