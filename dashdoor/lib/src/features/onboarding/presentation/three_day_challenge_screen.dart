import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/animations.dart';
import '../../home/data/gamification_repository.dart';
import '../state/onboarding_state.dart';
import '../../home/presentation/placeholder_home_screen.dart';

/// 3-Day Dinner Sprint — triggered when user dismisses paywall.
/// Creates a commitment loop that leads back to a paywall offer on Day 3.
class ThreeDayChallengeScreen extends ConsumerStatefulWidget {
  const ThreeDayChallengeScreen({super.key});

  @override
  ConsumerState<ThreeDayChallengeScreen> createState() =>
      _ThreeDayChallengeScreenState();
}

class _ThreeDayChallengeScreenState
    extends ConsumerState<ThreeDayChallengeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _joinChallenge() {
    HapticFeedback.heavyImpact();
    // Start challenge on the backend
    ref.read(gamificationRepositoryProvider).startChallenge('THREE_DAY_SPRINT');
    ref.read(onboardingFlowProvider.notifier).setChallengeAccepted(true);
    // Invalidate so home screen fetches the fresh challenge
    ref.invalidate(activeChallengeProvider);
    _navigateToHome();
  }

  void _skipChallenge() {
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PlaceholderHomeScreen(),
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: a, curve: Curves.easeOutQuart),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Hero
              FadeInEntrance(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _bounceController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppPalette.primary, AppPalette.sunRewards],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.primary.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '3',
                          style: context.appText.h1.copyWith(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        Text(
                          'DAYS',
                          style: context.appText.caption.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              FadeInEntrance(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  '3-Day Autopilot streak',
                  textAlign: TextAlign.center,
                  style: context.appText.h1.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              FadeInEntrance(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Follow a timely suggestion once per day — build the habit before hunger decides.',
                  textAlign: TextAlign.center,
                  style: context.appText.body.copyWith(
                    color: AppPalette.neutral500,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Challenge days
              FadeInEntrance(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    _buildDayCard(
                      context,
                      day: 1,
                      title: 'Tap one suggestion',
                      subtitle: 'Before your calendar gap closes',
                      icon: Icons.touch_app_rounded,
                      color: AppPalette.primary,
                    ),
                    const SizedBox(height: 12),
                    _buildDayCard(
                      context,
                      day: 2,
                      title: 'Use an order link',
                      subtitle: 'Or a saved template — your call',
                      icon: Icons.link_rounded,
                      color: AppPalette.successMint,
                    ),
                    const SizedBox(height: 12),
                    _buildDayCard(
                      context,
                      day: 3,
                      title: 'Add travel or location',
                      subtitle: 'So tomorrow’s picks fit where you’ll be',
                      icon: Icons.flight_rounded,
                      color: AppPalette.sunRewards,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Reward preview
              FadeInEntrance(
                delay: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.sunRewards.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppPalette.sunRewards.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        color: AppPalette.sunRewards,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Day 3: template pack + discounted Autopilot Plus',
                          style: context.appText.small.copyWith(
                            color: AppPalette.deepNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // CTA
              FadeInEntrance(
                delay: const Duration(milliseconds: 700),
                child: BounceInteraction(
                  onTap: _joinChallenge,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppPalette.deepNavy,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.deepNavy.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      'Join challenge',
                      textAlign: TextAlign.center,
                      style: context.appText.bodyStrong.copyWith(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              GestureDetector(
                onTap: _skipChallenge,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Maybe later',
                    style: context.appText.body.copyWith(
                      color: AppPalette.neutral400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: bottomPad + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context, {
    required int day,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'D$day',
                style: context.appText.bodyStrong.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.appText.bodyStrong.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.appText.caption.copyWith(
                    color: AppPalette.neutral500,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: color, size: 24),
        ],
      ),
    );
  }
}
