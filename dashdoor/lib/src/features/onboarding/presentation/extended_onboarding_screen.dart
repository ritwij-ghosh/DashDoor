import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../home/data/gamification_repository.dart';
import '../../integrations/state/calendar_connection_provider.dart';
import '../state/onboarding_state.dart';
import 'paywall_screen.dart';

/// Extended onboarding — priorities, calendar/travel context, and goals
/// before paywall. Same structure as the original flow; copy is for Healthy Autopilot.
class ExtendedOnboardingScreen extends ConsumerStatefulWidget {
  const ExtendedOnboardingScreen({super.key});

  @override
  ConsumerState<ExtendedOnboardingScreen> createState() =>
      _ExtendedOnboardingScreenState();
}

class _ExtendedOnboardingScreenState
    extends ConsumerState<ExtendedOnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  final GlobalKey<_HealthProfileStepState> _healthProfileStepKey =
      GlobalKey<_HealthProfileStepState>();
  final GlobalKey<_PantryCaptureStepState> _pantryCaptureStepKey =
      GlobalKey<_PantryCaptureStepState>();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    final pages = _buildPages();

    // If we're on the last page, finish onboarding
    if (_currentPage >= pages.length - 1) {
      _finishOnboarding();
      return;
    }

    ref.read(onboardingFlowProvider.notifier).nextStep();
    _currentPage++;
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
    HapticFeedback.lightImpact();
  }

  /// Advance the page only (no state step change). Used for transition pages
  /// that are pure UI bookmarks between actual data-collecting steps.
  void _goNextPageOnly() {
    final pages = _buildPages();
    if (_currentPage >= pages.length - 1) {
      _finishOnboarding();
      return;
    }
    _currentPage++;
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
    HapticFeedback.lightImpact();
  }

  /// Whether the page at [index] is a pure-UI transition (no step data).
  bool _isTransitionPage(List<Widget> pages, int index) {
    if (index < 0 || index >= pages.length) return false;
    final p = pages[index];
    return p is _TransitionPage || p is _YourStoryTransition;
  }

  void _goBack() {
    if (_currentPage <= 0) return;

    // Let nested sub-pages consume back first (unified with main back button).
    if (_healthProfileStepKey.currentState?.handleMainBack() == true) return;
    if (_pantryCaptureStepKey.currentState?.handleMainBack() == true) return;

    final pages = _buildPages();
    // Only call previousStep if the page we're leaving is NOT a transition
    if (!_isTransitionPage(pages, _currentPage)) {
      ref.read(onboardingFlowProvider.notifier).previousStep();
    }
    _currentPage--;
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
  }

  void _finishOnboarding() {
    _persistOnboardingData();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PaywallFunnelScreen(),
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutQuart)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _persistOnboardingData() {
    try {
      final data = ref.read(onboardingFlowProvider).data;
      final repo = ref.read(gamificationRepositoryProvider);

      repo.saveOnboarding({
        if (data.squirrelName != null) 'squirrelName': data.squirrelName,
        if (data.selectedSquirrelIndex != null)
          'squirrelColor': 'squirrel_${data.selectedSquirrelIndex}',
        if (data.mealVibes.isNotEmpty) 'mealVibes': data.mealVibes,
        if (data.timeAvailableMin != null)
          'timeAvailable': '${data.timeAvailableMin}min',
        if (data.dietaryRules.isNotEmpty) 'dietaryRules': data.dietaryRules,
        if (data.dislikes.isNotEmpty) 'dislikes': data.dislikes,
        if (data.pantryChoice != null) 'pantryChoice': data.pantryChoice,
        if (data.manualPantryItems.isNotEmpty)
          'manualPantryItems': data.manualPantryItems,
        if (data.kitchenAppliances.isNotEmpty)
          'kitchenAppliances': data.kitchenAppliances,
        if (data.weeklyBudget != null) 'weeklyBudget': data.weeklyBudget,
        if (data.householdSize != null) 'householdSize': data.householdSize,
        if (data.age != null) 'age': data.age,
        if (data.weightKg != null) 'weightKg': data.weightKg,
        if (data.heightCm != null) 'heightCm': data.heightCm,
        if (data.gender != null) 'gender': data.gender,
        if (data.activityLevel != null) 'activityLevel': data.activityLevel,
        if (data.targetCalories != null) 'targetCalories': data.targetCalories,
        if (data.targetProteinG != null) 'targetProteinG': data.targetProteinG,
        if (data.targetFatG != null) 'targetFatG': data.targetFatG,
        if (data.targetCarbsG != null) 'targetCarbsG': data.targetCarbsG,
        if (data.comfortCategories.isNotEmpty)
          'comfortCategories': data.comfortCategories,
        if (data.cuisineInterests.isNotEmpty)
          'cuisineInterests': data.cuisineInterests,
        if (data.spiceTolerance != null) 'spiceTolerance': data.spiceTolerance,
      });

      if (data.reminderHour != null) {
        repo.saveNotificationPrefs({
          'dinnerReminderEnabled': true,
          'dinnerReminderTime':
              '${data.reminderHour}:${(data.reminderMinute ?? 0).toString().padLeft(2, '0')}',
          'permissionGranted': data.notificationsAccepted,
        });
      }

      if (data.commitNights != null) {
        repo.saveContract(data.commitNights!);
      }

      // Persist to backend (fire-and-forget)
      final profileUpdate = <String, dynamic>{};
      if (data.dietaryRules.isNotEmpty) {
        profileUpdate['dietary_preferences'] = data.dietaryRules;
      }
      if (data.mealVibes.isNotEmpty) {
        profileUpdate['health_goals'] = data.mealVibes.join(', ');
      }
      final onboardingPayload = <String, dynamic>{};
      if (data.squirrelName != null) {
        onboardingPayload['mascot_name'] = data.squirrelName;
      }
      if (data.mealVibes.isNotEmpty) {
        onboardingPayload['meal_vibes'] = data.mealVibes;
      }
      if (data.timeAvailableMin != null) {
        onboardingPayload['time_available_min'] = data.timeAvailableMin;
      }
      if (data.manualPantryItems.isNotEmpty) {
        onboardingPayload['pantry_items'] = data.manualPantryItems;
      }
      if (data.dietaryRules.isNotEmpty) {
        onboardingPayload['dietary_rules'] = data.dietaryRules;
      }
      if (onboardingPayload.isNotEmpty) {
        profileUpdate['onboarding_data'] = onboardingPayload;
      }
      if (profileUpdate.isNotEmpty) {
        ApiService.updateProfile(profileUpdate).ignore();
      }
    } catch (_) {
      // Fire-and-forget
    }
  }

  /// Build the list of pages dynamically based on selected vibes.
  List<Widget> _buildPages() {
    final flow = ref.watch(onboardingFlowProvider);
    final pages = <Widget>[
      _NameSquirrelStep(onNext: _goNext),

      // ── Transition: Getting to know you ──
      _TransitionPage(
        onNext: _goNextPageOnly,
        backgroundColor: const Color(0xFFFFF5F0),
        title: "We're all ears",
        subtitle:
            "The next few questions tune your autopilot — how you eat, "
            "how busy life gets, and where you land — so suggestions "
            "arrive before decision fatigue does.",
        ctaLabel: "Let's do it",
        accentColor: AppPalette.primary,
        decorations: const [
          _FloatingShape(icon: Icons.favorite_rounded, top: 0.08, left: 0.08, size: 22, color: AppPalette.primary),
          _FloatingShape(icon: Icons.restaurant_rounded, top: 0.12, right: 0.1, size: 18, color: AppPalette.sunRewards),
          _FloatingShape(icon: Icons.star_rounded, top: 0.32, left: 0.06, size: 16, color: AppPalette.sunRewards),
          _FloatingShape(icon: Icons.star_rounded, top: 0.28, right: 0.08, size: 20, color: AppPalette.primary),
        ],
      ),

      _MealVibeStep(onNext: _goNext),
    ];

    // Dynamic vibe follow-ups
    for (final vfu in flow.activeVibeFollowUps) {
      switch (vfu) {
        case VibeFollowUpType.quickEasy:
          pages.add(_KitchenSetupStep(onNext: _goNext));
          break;
        case VibeFollowUpType.budget:
          pages.add(_BudgetStep(onNext: _goNext));
          break;
        case VibeFollowUpType.healthGoals:
          pages.add(_HealthProfileStep(
            key: _healthProfileStepKey,
            onNext: _goNext,
          ));
          break;
        case VibeFollowUpType.comfortFood:
          pages.add(_ComfortFoodStep(onNext: _goNext));
          break;
        case VibeFollowUpType.adventurous:
          pages.add(_AdventureStep(onNext: _goNext));
          break;
      }
    }

    pages.addAll([
      _TimeAvailableStep(onNext: _goNext),
      _DietaryRulesStep(onNext: _goNext),
      _DislikesStep(onNext: _goNext),

      // ── Transition: Your story so far ──
      _YourStoryTransition(onNext: _goNextPageOnly),

      // ── Transition: Pantry time ──
      _TransitionPage(
        onNext: _goNextPageOnly,
        backgroundColor: const Color(0xFFF0F7F4),
        title: "Calendar &\ntravel context",
        subtitle:
            "Next we’ll capture how you eat on the ground — home, office, "
            "and trips — so the next 8–12 hours of picks make sense.",
        ctaLabel: 'Continue',
        accentColor: AppPalette.successMint,
        decorations: const [
          _FloatingShape(icon: Icons.kitchen_rounded, top: 0.08, right: 0.1, size: 22, color: AppPalette.successMint),
          _FloatingShape(icon: Icons.eco_rounded, top: 0.12, left: 0.08, size: 18, color: AppPalette.successMint),
          _FloatingShape(icon: Icons.local_grocery_store_rounded, top: 0.3, right: 0.06, size: 16, color: AppPalette.sunRewards),
          _FloatingShape(icon: Icons.spa_rounded, top: 0.28, left: 0.1, size: 20, color: AppPalette.successMint),
        ],
      ),

      _PantryCaptureStep(
        key: _pantryCaptureStepKey,
        onNext: _goNext,
      ),
      _BeforeAfterStep(onNext: _goNext),

      // ── Transition: Commitment ──
      _TransitionPage(
        onNext: _goNextPageOnly,
        backgroundColor: const Color(0xFFF5F0FF),
        title: 'Small habits,\nbig calm',
        subtitle:
            "Letting something else decide what to eat — on time — "
            "frees your brain for everything else on your plate.",
        ctaLabel: "I'm ready",
        accentColor: const Color(0xFF8B5CF6),
        decorations: const [
          _FloatingShape(icon: Icons.local_fire_department_rounded, top: 0.08, left: 0.1, size: 22, color: Color(0xFF8B5CF6)),
          _FloatingShape(icon: Icons.bolt_rounded, top: 0.12, right: 0.08, size: 18, color: AppPalette.sunRewards),
          _FloatingShape(icon: Icons.emoji_events_rounded, top: 0.3, left: 0.06, size: 16, color: Color(0xFF8B5CF6)),
          _FloatingShape(icon: Icons.favorite_rounded, top: 0.28, right: 0.1, size: 20, color: AppPalette.primary),
        ],
      ),

      _NibblContractStep(onNext: _goNext),
      _MealReminderStep(onNext: _goNext),
      _EmotionalWinStep(onNext: _goNext),

      // ── Transition: Start your journey ──
      _TransitionPage(
        onNext: _goNextPageOnly,
        backgroundColor: const Color(0xFFF0FBF4),
        title: "Your autopilot\nis almost on",
        subtitle:
            "We’ll connect Calendar next, add travel when you have it, "
            "and start surfacing timely meals and one-tap orders.",
        ctaLabel: "Let's go",
        accentColor: AppPalette.successMint,
        isLastTransition: true,
        decorations: const [
          _FloatingShape(icon: Icons.rocket_launch_rounded, top: 0.08, right: 0.1, size: 24, color: AppPalette.primary),
          _FloatingShape(icon: Icons.auto_awesome_rounded, top: 0.12, left: 0.08, size: 18, color: AppPalette.sunRewards),
          _FloatingShape(icon: Icons.celebration_rounded, top: 0.3, right: 0.06, size: 20, color: AppPalette.successMint),
          _FloatingShape(icon: Icons.star_rounded, top: 0.32, left: 0.1, size: 16, color: AppPalette.sunRewards),
        ],
      ),
    ]);

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(onboardingFlowProvider);
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _goBack,
                      icon:
                          const Icon(Icons.arrow_back_rounded, size: 24),
                      color: AppPalette.deepNavy,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: _OnboardingProgressBar(progress: flow.progress),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Progress Bar
// ══════════════════════════════════════════════════════════════

class _OnboardingProgressBar extends StatelessWidget {
  final double progress;
  const _OnboardingProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppPalette.neutral200.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuart,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppPalette.primary, AppPalette.sunRewards],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared step layout
// ══════════════════════════════════════════════════════════════

class _StepLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? mascotReaction;
  final Widget content;
  final String ctaLabel;
  final VoidCallback onCta;
  final bool ctaEnabled;

  const _StepLayout({
    required this.title,
    required this.subtitle,
    this.mascotReaction,
    required this.content,
    required this.ctaLabel,
    required this.onCta,
    this.ctaEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const MascotWidget(
                state: MascotState.happy,
                width: 56,
                height: 56,
              ),
              if (mascotReaction != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceWhite,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      mascotReaction!,
                      style: context.appText.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.deepNavy,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          FadeInEntrance(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: context.appText.h1.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInEntrance(
            delay: const Duration(milliseconds: 100),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: context.appText.body.copyWith(
                  color: AppPalette.neutral500,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: FadeInEntrance(
              delay: const Duration(milliseconds: 200),
              child: content,
            ),
          ),
          FadeInEntrance(
            delay: const Duration(milliseconds: 300),
            child: BounceInteraction(
              onTap: ctaEnabled ? onCta : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color:
                      ctaEnabled ? AppPalette.deepNavy : AppPalette.neutral200,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ctaEnabled
                          ? AppPalette.deepNavy.withValues(alpha: 0.2)
                          : Colors.transparent,
                      blurRadius: ctaEnabled ? 16 : 0,
                      offset: ctaEnabled
                          ? const Offset(0, 6)
                          : Offset.zero,
                    ),
                  ],
                ),
                child: Text(
                  ctaLabel,
                  textAlign: TextAlign.center,
                  style: context.appText.bodyStrong.copyWith(
                    color: ctaEnabled ? Colors.white : AppPalette.neutral500,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step 1: Adopt Squirrel – "Choose your kitchen buddy's look"
// ══════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════
// Reusable Transition Page – full-screen "bookmark" between sections
// ══════════════════════════════════════════════════════════════

class _FloatingShape {
  final IconData icon;
  final double? top;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  const _FloatingShape({
    required this.icon,
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });
}

class _TransitionPage extends StatefulWidget {
  final VoidCallback onNext;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final Color accentColor;
  final List<_FloatingShape> decorations;
  final bool isLastTransition;

  const _TransitionPage({
    required this.onNext,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.accentColor,
    this.decorations = const [],
    this.isLastTransition = false,
  });

  @override
  State<_TransitionPage> createState() => _TransitionPageState();
}

class _TransitionPageState extends State<_TransitionPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Container(
      color: widget.backgroundColor,
      child: Stack(
        children: [
          // ── Floating decorative icons ──
          ...widget.decorations.map((d) {
            final delay = widget.decorations.indexOf(d) * 0.15;
            return AnimatedBuilder(
              animation: _floatCtrl,
              builder: (context, child) {
                final drift = math.sin(
                        (_floatCtrl.value + delay) * math.pi * 2) *
                    6;
                return Positioned(
                  top: d.top != null ? screenH * d.top! + drift : null,
                  left: d.left != null ? screenW * d.left! : null,
                  right: d.right != null ? screenW * d.right! : null,
                  child: AnimatedBuilder(
                    animation: _entranceCtrl,
                    builder: (context, child) {
                      final t = Interval(
                              (0.2 + delay).clamp(0.0, 1.0),
                              (0.6 + delay).clamp(0.0, 1.0),
                              curve: Curves.easeOutCubic)
                          .transform(
                              _entranceCtrl.value.clamp(0.0, 1.0));
                      return Opacity(
                        opacity: t * 0.35,
                        child: Transform.scale(
                          scale: 0.5 + t * 0.5,
                          child: Icon(d.icon, size: d.size, color: d.color),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Mascot
                AnimatedBuilder(
                  animation: _entranceCtrl,
                  builder: (context, _) {
                    final t = Interval(0.0, 0.5, curve: Curves.easeOutCubic)
                        .transform(_entranceCtrl.value);
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - t)),
                      child: Opacity(
                        opacity: t,
                        child: const MascotWidget(
                          state: MascotState.happy,
                          width: 140,
                          height: 140,
                          animate: false,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Title
                AnimatedBuilder(
                  animation: _entranceCtrl,
                  builder: (context, _) {
                    final t = Interval(0.15, 0.55, curve: Curves.easeOutCubic)
                        .transform(_entranceCtrl.value);
                    return Transform.translate(
                      offset: Offset(0, 24 * (1 - t)),
                      child: Opacity(
                        opacity: t,
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: context.appText.h1.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppPalette.deepNavy,
                            height: 1.15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Subtitle
                AnimatedBuilder(
                  animation: _entranceCtrl,
                  builder: (context, _) {
                    final t = Interval(0.25, 0.65, curve: Curves.easeOutCubic)
                        .transform(_entranceCtrl.value);
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - t)),
                      child: Opacity(
                        opacity: t,
                        child: Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: context.appText.body.copyWith(
                            color: AppPalette.neutral500,
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 3),

                // CTA
                AnimatedBuilder(
                  animation: _entranceCtrl,
                  builder: (context, _) {
                    final t = Interval(0.45, 0.85, curve: Curves.easeOutCubic)
                        .transform(_entranceCtrl.value);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - t)),
                        child: BounceInteraction(
                          onTap: widget.onNext,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: AppPalette.deepNavy,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppPalette.deepNavy.withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.ctaLabel,
                                  style: context.appText.bodyStrong.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: bottomPad + 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Transition: Your Story – rich "about you" summary
// ══════════════════════════════════════════════════════════════

class _YourStoryTransition extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _YourStoryTransition({required this.onNext});

  @override
  ConsumerState<_YourStoryTransition> createState() =>
      _YourStoryTransitionState();
}

class _YourStoryTransitionState extends ConsumerState<_YourStoryTransition>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _floatCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  List<_StoryChip> _buildChips(OnboardingData data) {
    final chips = <_StoryChip>[];

    if (data.mealVibes.isNotEmpty) {
      final vibeEmoji = {
        'quick': '\u26A1',
        'cheap': '\uD83D\uDCB0',
        'healthGoals': '\uD83D\uDCAA',
        'comfort': '\u2764\uFE0F',
        'adventurous': '\uD83C\uDF0D',
      };
      final vibeLabel = {
        'quick': 'Chaotic calendar',
        'cheap': 'Budget-smart',
        'healthGoals': 'Health & energy',
        'comfort': 'Reliable favorites',
        'adventurous': 'Travel & new spots',
      };
      for (final v in data.mealVibes) {
        chips.add(_StoryChip(
          emoji: vibeEmoji[v] ?? '\uD83C\uDF7D',
          label: vibeLabel[v] ?? v,
          color: const Color(0xFFFFF0ED),
          borderColor: AppPalette.primary.withValues(alpha: 0.15),
        ));
      }
    }

    if (data.timeAvailableMin != null) {
      chips.add(_StoryChip(
        emoji: '\u23F1',
        label: '${data.timeAvailableMin} min to eat',
        color: const Color(0xFFEDF7F0),
        borderColor: AppPalette.successMint.withValues(alpha: 0.2),
      ));
    }

    if (data.commitNights != null) {
      chips.add(_StoryChip(
        emoji: '\uD83D\uDCC5',
        label: '${data.commitNights} nights/week',
        color: const Color(0xFFF0EDFF),
        borderColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
      ));
    }

    if (data.dietaryRules.isNotEmpty) {
      for (final rule in data.dietaryRules.take(3)) {
        chips.add(_StoryChip(
          emoji: '\u2705',
          label: rule,
          color: const Color(0xFFF0EDFF),
          borderColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
        ));
      }
    }

    if (data.dislikes.isNotEmpty) {
      for (final d in data.dislikes.take(3)) {
        chips.add(_StoryChip(
          emoji: '\uD83D\uDEAB',
          label: 'No $d',
          color: const Color(0xFFFFF5F5),
          borderColor: AppPalette.primary.withValues(alpha: 0.12),
        ));
      }
    }

    if (data.comfortCategories.isNotEmpty) {
      for (final c in data.comfortCategories.take(2)) {
        chips.add(_StoryChip(
          emoji: '\uD83E\uDD70',
          label: c,
          color: const Color(0xFFFFF0ED),
          borderColor: AppPalette.primary.withValues(alpha: 0.12),
        ));
      }
    }

    if (data.cuisineInterests.isNotEmpty) {
      for (final c in data.cuisineInterests.take(2)) {
        chips.add(_StoryChip(
          emoji: '\uD83C\uDF0D',
          label: c,
          color: const Color(0xFFEDF7F0),
          borderColor: AppPalette.successMint.withValues(alpha: 0.2),
        ));
      }
    }

    if (data.spiceTolerance != null) {
      final spiceLabels = {1: 'Mild', 2: 'Medium', 3: 'Hot', 4: 'Extreme'};
      final spiceEmojis = {1: '\uD83C\uDF36', 2: '\uD83C\uDF36\uD83C\uDF36', 3: '\uD83D\uDD25', 4: '\uD83E\uDD76'};
      chips.add(_StoryChip(
        emoji: spiceEmojis[data.spiceTolerance] ?? '\uD83C\uDF36',
        label: '${spiceLabels[data.spiceTolerance] ?? 'Medium'} spice',
        color: const Color(0xFFFFF0ED),
        borderColor: AppPalette.primary.withValues(alpha: 0.12),
      ));
    }

    if (data.kitchenAppliances.isNotEmpty) {
      for (final a in data.kitchenAppliances.take(2)) {
        chips.add(_StoryChip(
          emoji: '\uD83E\uDD73',
          label: a,
          color: const Color(0xFFFFF8E7),
          borderColor: AppPalette.sunRewards.withValues(alpha: 0.2),
        ));
      }
    }

    return chips;
  }

  bool get _hasMacros {
    final data = ref.read(onboardingFlowProvider).data;
    return data.targetCalories != null || data.targetProteinG != null;
  }

  /// Build contextual stat pills based on what data the user actually provided.
  List<_StatPillData> _buildStatPills(OnboardingData data) {
    final pills = <_StatPillData>[];

    if (data.targetCalories != null) {
      pills.add(_StatPillData(
        value: '${data.targetCalories}',
        unit: 'kcal',
        label: 'Daily target',
        icon: Icons.local_fire_department_rounded,
        iconColor: AppPalette.sunRewards,
        bgColor: const Color(0xFFFFF8E7),
      ));
    }

    if (data.targetProteinG != null) {
      pills.add(_StatPillData(
        value: '${data.targetProteinG}g',
        unit: '',
        label: 'Protein',
        icon: Icons.fitness_center_rounded,
        iconColor: AppPalette.successMint,
        bgColor: const Color(0xFFEDF7F0),
      ));
    }

    if (data.timeAvailableMin != null) {
      pills.add(_StatPillData(
        value: '${data.timeAvailableMin}',
        unit: 'min',
        label: 'Time to eat',
        icon: Icons.timer_rounded,
        iconColor: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF3F0FF),
      ));
    }

    if (data.commitNights != null) {
      pills.add(_StatPillData(
        value: '${data.commitNights}',
        unit: 'nights',
        label: 'Per week',
        icon: Icons.calendar_today_rounded,
        iconColor: AppPalette.primary,
        bgColor: const Color(0xFFFFF0ED),
      ));
    }

    if (data.weeklyBudget != null) {
      pills.add(_StatPillData(
        value: '\$${data.weeklyBudget!.round()}',
        unit: '',
        label: 'Weekly',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: AppPalette.sunRewards,
        bgColor: const Color(0xFFFFF8E7),
      ));
    }

    if (data.householdSize != null) {
      pills.add(_StatPillData(
        value: '${data.householdSize}',
        unit: '',
        label: data.householdSize == 1 ? 'Person' : 'People',
        icon: Icons.people_rounded,
        iconColor: AppPalette.successMint,
        bgColor: const Color(0xFFEDF7F0),
      ));
    }

    // Always show at least 3 pills — fill with available data
    return pills.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingFlowProvider).data;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final name = data.squirrelName ?? 'Autopilot';
    final chips = _buildChips(data);
    final statPills = _buildStatPills(data);
    final hasMacros = _hasMacros;

    return Container(
      color: const Color(0xFFF8F6F2),
      child: Column(
        children: [
          // ── Hero section — dark card with mascot + title ──
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t =
                  const Interval(0.0, 0.4, curve: Curves.easeOutCubic)
                      .transform(_ctrl.value);
              return Transform.translate(
                offset: Offset(0, 24 * (1 - t)),
                child: Opacity(
                  opacity: t,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A1A2E)
                              .withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Sparkle decorations
                        ...List.generate(4, (i) {
                          final positions = [
                            const Offset(-8, -12),
                            const Offset(50, -8),
                            const Offset(-4, 60),
                            const Offset(40, 55),
                          ];
                          return AnimatedBuilder(
                            animation: _sparkleCtrl,
                            builder: (context, _) {
                              final phase = i * 0.25;
                              final opacity = (math.sin(
                                          (_sparkleCtrl.value + phase) *
                                              math.pi *
                                              2) *
                                      0.3 +
                                  0.4);
                              return Positioned(
                                right: positions[i].dx,
                                top: positions[i].dy,
                                child: Opacity(
                                  opacity: opacity.clamp(0.0, 1.0),
                                  child: Icon(
                                    i.isEven
                                        ? Icons.auto_awesome
                                        : Icons.star_rounded,
                                    size: 12 + i * 2.0,
                                    color: i.isEven
                                        ? AppPalette.sunRewards
                                        : AppPalette.successMint
                                            .withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            },
                          );
                        }),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                // Mascot avatar
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppPalette.primary
                                            .withValues(alpha: 0.25),
                                        AppPalette.sunRewards
                                            .withValues(alpha: 0.2),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.15),
                                      width: 2,
                                    ),
                                  ),
                                  child: const ClipOval(
                                    child: MascotWidget(
                                      state: MascotState.happy,
                                      width: 52,
                                      height: 52,
                                      animate: false,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your autopilot\nsnapshot',
                                        style: context.appText.h1
                                            .copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 13,
                                    color: AppPalette.sunRewards,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${name.substring(0, 1).toUpperCase()}${name.substring(1)} will use this to time suggestions',
                                      style:
                                          context.appText.caption.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.65),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Stats row — only shown if we have meaningful stats ──
          if (statPills.isNotEmpty)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t =
                    const Interval(0.15, 0.5, curve: Curves.easeOutCubic)
                        .transform(_ctrl.value);
                return Transform.translate(
                  offset: Offset(0, 16 * (1 - t)),
                  child: Opacity(
                    opacity: t,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          for (int i = 0; i < statPills.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            _buildStatPill(context, pill: statPills[i]),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // ── "What we'll focus on" card — shown when no macros/stats ──
          if (statPills.isEmpty)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t =
                    const Interval(0.15, 0.5, curve: Curves.easeOutCubic)
                        .transform(_ctrl.value);
                return Transform.translate(
                  offset: Offset(0, 16 * (1 - t)),
                  child: Opacity(
                    opacity: t,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppPalette.successMint
                                  .withValues(alpha: 0.08),
                              AppPalette.sunRewards
                                  .withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppPalette.successMint
                                .withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppPalette.successMint
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                size: 22,
                                color: AppPalette.successMint,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Timely picks, your goals',
                                    style: context.appText.bodyStrong
                                        .copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppPalette.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Calendar, travel, and taste — weighted the way you chose',
                                    style:
                                        context.appText.caption.copyWith(
                                      color: AppPalette.neutral500,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          SizedBox(height: statPills.isNotEmpty ? 20 : 16),

          // ── Section label ──
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t =
                  const Interval(0.22, 0.52, curve: Curves.easeOutCubic)
                      .transform(_ctrl.value);
              return Opacity(
                opacity: t,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'What we’ll prioritize',
                      style: context.appText.bodyStrong.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppPalette.deepNavy,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // ── Chip cloud ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                children: [
                  // Chips
                  if (chips.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          List.generate(chips.length, (i) {
                        final chip = chips[i];
                        final delay = 0.25 + i * 0.04;
                        return AnimatedBuilder(
                          animation: _ctrl,
                          builder: (context, _) {
                            final t = Interval(
                              delay.clamp(0.0, 0.8),
                              (delay + 0.3).clamp(0.0, 1.0),
                              curve: Curves.easeOutCubic,
                            ).transform(_ctrl.value);
                            return Transform.scale(
                              scale: 0.7 + 0.3 * t,
                              child: Opacity(
                                opacity: t,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: chip.color,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: chip.borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(chip.emoji,
                                          style: const TextStyle(
                                              fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Text(
                                        chip.label,
                                        style: context
                                            .appText.bodyStrong
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppPalette.deepNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),

                  // Empty state — only when no chips at all
                  if (chips.isEmpty)
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) {
                        final t = const Interval(0.3, 0.6,
                                curve: Curves.easeOutCubic)
                            .transform(_ctrl.value);
                        return Opacity(
                          opacity: t,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppPalette.surfaceWhite,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppPalette.border,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text('\uD83E\uDD0C',
                                    style: TextStyle(fontSize: 32)),
                                const SizedBox(height: 10),
                                Text(
                                  "You're keeping it simple — we love that!",
                                  textAlign: TextAlign.center,
                                  style: context.appText.body.copyWith(
                                    color: AppPalette.neutral500,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // ── "Ready to go" encouragement — when no macros, fills space ──
                  if (!hasMacros) ...[
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) {
                        final t = const Interval(0.4, 0.7,
                                curve: Curves.easeOutCubic)
                            .transform(_ctrl.value);
                        return Transform.translate(
                          offset: Offset(0, 12 * (1 - t)),
                          child: Opacity(
                            opacity: t,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppPalette.surfaceWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppPalette.border,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _buildPlanItem(
                                        context,
                                        icon: Icons
                                            .auto_awesome_mosaic_rounded,
                                        iconColor:
                                            AppPalette.sunRewards,
                                        label:
                                            '8–12 hour lookahead',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildPlanItem(
                                        context,
                                        icon: Icons
                                            .shopping_bag_rounded,
                                        iconColor:
                                            AppPalette.successMint,
                                        label:
                                            'One-tap orders & templates',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildPlanItem(
                                        context,
                                        icon: Icons
                                            .explore_rounded,
                                        iconColor:
                                            const Color(0xFF8B5CF6),
                                        label:
                                            'Travel & local context',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── CTA ──
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t =
                  const Interval(0.55, 0.9, curve: Curves.easeOutCubic)
                      .transform(_ctrl.value);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - t)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BounceInteraction(
                      onTap: widget.onNext,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppPalette.deepNavy,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.deepNavy
                                  .withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Looks right',
                              style:
                                  context.appText.bodyStrong.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: bottomPad + 12),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required _StatPillData pill,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: pill.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: pill.iconColor.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(pill.icon, size: 18, color: pill.iconColor),
            const SizedBox(height: 6),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: pill.value,
                    style: context.appText.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.deepNavy,
                    ),
                  ),
                  if (pill.unit.isNotEmpty)
                    TextSpan(
                      text: ' ${pill.unit}',
                      style: context.appText.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppPalette.neutral500,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pill.label,
              style: context.appText.caption.copyWith(
                color: AppPalette.neutral400,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: context.appText.bodyStrong.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppPalette.deepNavy,
              ),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppPalette.successMint.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

class _StoryChip {
  final String emoji;
  final String label;
  final Color color;
  final Color borderColor;
  const _StoryChip({
    required this.emoji,
    required this.label,
    required this.color,
    required this.borderColor,
  });
}

class _StatPillData {
  final String value;
  final String unit;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  const _StatPillData({
    required this.value,
    required this.unit,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

// ══════════════════════════════════════════════════════════════
// Step: Name Squirrel
// ══════════════════════════════════════════════════════════════

class _NameSquirrelStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _NameSquirrelStep({required this.onNext});

  @override
  ConsumerState<_NameSquirrelStep> createState() => _NameSquirrelStepState();
}

class _NameSquirrelStepState extends ConsumerState<_NameSquirrelStep> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(
      onboardingFlowProvider.select((s) => s.data.squirrelName),
    );

    return _StepLayout(
      title: 'Name your autopilot',
      subtitle: "Something you’ll trust nudging you before hunger hits.",
      mascotReaction: name != null && name.isNotEmpty
          ? "Nice to meet you! I'm $name!"
          : 'What should I go by?',
      content: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: context.appText.h2.copyWith(fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  hintText: 'e.g. Scout, Harbor, Dash',
                  hintStyle: context.appText.body.copyWith(
                    color: AppPalette.neutral400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(24),
                ),
                onChanged: (v) {
                  ref
                      .read(onboardingFlowProvider.notifier)
                      .setSquirrelName(v.trim());
                },
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: ['Scout', 'Harbor', 'Pilot', 'Dash'].map((s) {
                return GestureDetector(
                  onTap: () {
                    _nameController.text = s;
                    ref
                        .read(onboardingFlowProvider.notifier)
                        .setSquirrelName(s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceWhite,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Text(s, style: context.appText.smallStrong),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      ctaLabel: "That's the one!",
      onCta: widget.onNext,
      ctaEnabled: name != null && name.trim().isNotEmpty,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step 3: Meal Vibe – MULTI-SELECT
// ══════════════════════════════════════════════════════════════

class _MealVibeStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _MealVibeStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingFlowProvider.select((s) => s.data.mealVibes),
    );

    final vibes = [
      _VibeOption('quick', 'Chaotic calendar', Icons.calendar_month_rounded,
          'Back-to-backs, tight gaps between meetings'),
      _VibeOption('cheap', 'Budget-smart orders', Icons.savings_rounded,
          'Keep delivery and pickup within reach'),
      _VibeOption('healthGoals', 'Health & energy',
          Icons.monitor_heart_rounded, 'Macros and goals stay on track'),
      _VibeOption('comfort', 'Reliable favorites', Icons.favorite_rounded,
          'Known quantities when you’re fried'),
      _VibeOption('adventurous', 'New cities & spots', Icons.explore_rounded,
          'Local gems when you travel'),
    ];

    return _StepLayout(
      title: "What should we optimize for?",
      subtitle: "Pick all that apply — we’ll weight suggestions accordingly.",
      mascotReaction: selected.isNotEmpty
          ? _getVibeReaction(selected.last)
          : 'What are we going for?',
      content: ListView(
        physics: const BouncingScrollPhysics(),
        children: vibes.map((v) {
          final isSelected = selected.contains(v.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(onboardingFlowProvider.notifier).toggleMealVibe(v.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppPalette.primary.withValues(alpha: 0.08)
                      : AppPalette.surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppPalette.primary : AppPalette.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.primary.withValues(alpha: 0.15)
                            : AppPalette.neutral100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        v.icon,
                        color: isSelected
                            ? AppPalette.primary
                            : AppPalette.neutral500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.label,
                              style: context.appText.bodyStrong
                                  .copyWith(fontWeight: FontWeight.w800)),
                          Text(v.desc,
                              style: context.appText.caption
                                  .copyWith(color: AppPalette.neutral500)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.primary
                            : AppPalette.neutral100,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? null
                            : Border.all(color: AppPalette.border),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      ctaLabel: 'Continue',
      onCta: onNext,
      ctaEnabled: selected.isNotEmpty,
    );
  }

  String _getVibeReaction(String vibe) {
    switch (vibe) {
      case 'quick':
        return 'We’ll stay ahead of the clock.';
      case 'cheap':
        return 'Smart spend, zero guilt.';
      case 'healthGoals':
        return 'Goals stay in the loop.';
      case 'comfort':
        return 'Familiar wins when you need them.';
      case 'adventurous':
        return 'Love it — we’ll scout local picks.';
      default:
        return 'Nice pick!';
    }
  }
}

class _VibeOption {
  final String id;
  final String label;
  final IconData icon;
  final String desc;
  const _VibeOption(this.id, this.label, this.icon, this.desc);
}

// ══════════════════════════════════════════════════════════════
// Vibe Follow-Up: Kitchen Setup (Quick & Easy)
// ══════════════════════════════════════════════════════════════

class _KitchenSetupStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _KitchenSetupStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingFlowProvider.select((s) => s.data.kitchenAppliances),
    );

    final appliances = [
      ('stovetop', 'Cook at home', Icons.home_rounded),
      ('oven', 'Meal prep batches', Icons.inventory_2_outlined),
      ('microwave', 'Heat & run', Icons.sensors_rounded),
      ('airFryer', 'Grab something fast', Icons.flash_on_rounded),
      ('instantPot', 'One-pot wins', Icons.soup_kitchen_rounded),
      ('blender', 'Shakes & smoothies', Icons.blender_rounded),
      ('toasterOven', 'Quick toast & melts', Icons.breakfast_dining_rounded),
      ('noCook', 'Order / pickup mostly', Icons.takeout_dining_rounded),
    ];

    return _StepLayout(
      title: "How do you usually fuel up?",
      subtitle: "We’ll tune suggestions to your real day — kitchen, desk, or on the go.",
      mascotReaction: selected.isEmpty
          ? 'Where do meals happen?'
          : '${selected.length} contexts noted!',
      content: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: appliances.length,
        itemBuilder: (context, i) {
          final a = appliances[i];
          final isSelected = selected.contains(a.$1);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(onboardingFlowProvider.notifier).toggleAppliance(a.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppPalette.primary.withValues(alpha: 0.08)
                    : AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppPalette.primary : AppPalette.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          a.$3,
                          size: 32,
                          color: isSelected
                              ? AppPalette.primary
                              : AppPalette.neutral500,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.$2,
                          style: context.appText.smallStrong.copyWith(
                            color: isSelected
                                ? AppPalette.primary
                                : AppPalette.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppPalette.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      ctaLabel: selected.isEmpty ? 'Skip' : 'Continue',
      onCta: onNext,
      ctaEnabled: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Vibe Follow-Up: Budget & Household
// ══════════════════════════════════════════════════════════════

class _BudgetStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _BudgetStep({required this.onNext});

  @override
  ConsumerState<_BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends ConsumerState<_BudgetStep> {
  double _budget = 80;
  int _household = 1;

  @override
  Widget build(BuildContext context) {
    final costPerMeal = _household > 0
        ? (_budget / (_household * 7)).toStringAsFixed(1)
        : '0.0';

    return _StepLayout(
      title: "Weekly food spend (groceries + orders)?",
      subtitle: "We’ll keep suggestions realistic when links and menus have prices.",
      mascotReaction: 'Smart spend, fewer surprises.',
      content: Column(
        children: [
          const SizedBox(height: 16),
          // Budget amount
          Text(
            '\$${_budget.round()}',
            style: context.appText.h1.copyWith(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: AppPalette.deepNavy,
            ),
          ),
          Text(
            'per week',
            style: context.appText.body.copyWith(color: AppPalette.neutral500),
          ),
          const SizedBox(height: 24),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppPalette.primary,
              inactiveTrackColor: AppPalette.neutral100,
              thumbColor: AppPalette.deepNavy,
              overlayColor: AppPalette.primary.withValues(alpha: 0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: _budget,
              min: 20,
              max: 200,
              divisions: 36,
              onChanged: (v) {
                setState(() => _budget = v);
                HapticFeedback.selectionClick();
                ref.read(onboardingFlowProvider.notifier).setWeeklyBudget(v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$20',
                    style: context.appText.caption
                        .copyWith(color: AppPalette.neutral400)),
                Text('\$200',
                    style: context.appText.caption
                        .copyWith(color: AppPalette.neutral400)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Household size
          Text(
            'Household size',
            style: context.appText.bodyStrong
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final n = i + 1;
              final label = n == 6 ? '6+' : '$n';
              final isSel = _household == n;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _household = n);
                    HapticFeedback.selectionClick();
                    ref
                        .read(onboardingFlowProvider.notifier)
                        .setHouseholdSize(n);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppPalette.deepNavy
                          : AppPalette.surfaceWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSel ? AppPalette.deepNavy : AppPalette.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: context.appText.bodyStrong.copyWith(
                        color: isSel ? Colors.white : AppPalette.deepNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // Cost per meal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppPalette.successMint.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_rounded,
                    color: AppPalette.successMint, size: 20),
                const SizedBox(width: 10),
                Text(
                  '~\$$costPerMeal per meal',
                  style: context.appText.bodyStrong.copyWith(
                    color: AppPalette.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ctaLabel: 'Continue',
      onCta: () {
        ref.read(onboardingFlowProvider.notifier).setWeeklyBudget(_budget);
        ref.read(onboardingFlowProvider.notifier).setHouseholdSize(_household);
        widget.onNext();
      },
      ctaEnabled: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Vibe Follow-Up: Health Profile + Macros
// ══════════════════════════════════════════════════════════════

class _HealthProfileStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _HealthProfileStep({super.key, required this.onNext});

  @override
  ConsumerState<_HealthProfileStep> createState() => _HealthProfileStepState();
}

class _HealthProfileStepState extends ConsumerState<_HealthProfileStep> {
  String _gender = '';
  int _age = 25;
  double _weightKg = 70;
  double _heightCm = 170;
  String _activity = '';
  String _macroGoal = 'maintain'; // maintain, cut, bulk
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';

  /// When true, show the macros review page instead of the body info form.
  bool _showMacroReview = false;

  // Editable macros (initially calculated, user can override)
  int _editCalories = 0;
  int _editProtein = 0;
  int _editFat = 0;
  int _editCarbs = 0;

  // Calculated macros via Mifflin-St Jeor + goal profile
  double get _activityMultiplier {
    const multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'veryActive': 1.9,
    };
    return multipliers[_activity] ?? 1.55;
  }

  double get _goalCalorieMultiplier {
    switch (_macroGoal) {
      case 'cut':
        return 0.85;
      case 'bulk':
        return 1.10;
      default:
        return 1.0;
    }
  }

  double get _proteinPerKg {
    switch (_macroGoal) {
      case 'cut':
        return 2.0;
      case 'bulk':
        return 1.8;
      default:
        return 1.6;
    }
  }

  String get _goalLabel {
    switch (_macroGoal) {
      case 'cut':
        return 'Cut';
      case 'bulk':
        return 'Bulk';
      default:
        return 'Maintain';
    }
  }

  int get _bmr {
    if (_gender.isEmpty || _activity.isEmpty) return 0;
    double bmr;
    if (_gender == 'male') {
      bmr = 10 * _weightKg + 6.25 * _heightCm - 5 * _age + 5;
    } else {
      bmr = 10 * _weightKg + 6.25 * _heightCm - 5 * _age - 161;
    }
    return bmr.round();
  }

  int get _tdee => (_bmr * _activityMultiplier).round();
  int get _calcCalories => (_tdee * _goalCalorieMultiplier).round();
  int get _calcProtein => (_weightKg * _proteinPerKg).round();
  int get _calcFat => (_calcCalories * 0.30 / 9).round();
  int get _calcCarbs {
    final carbCalories = _calcCalories - (_calcProtein * 4) - (_calcFat * 9);
    return (carbCalories / 4).round().clamp(0, 9999);
  }

  String get _weightDisplay {
    if (_weightUnit == 'lb') {
      final lbs = (_weightKg * 2.2046226218).round();
      return '$lbs lb';
    }
    return '${_weightKg.round()} kg';
  }

  String get _heightDisplay {
    if (_heightUnit == 'ft') {
      final totalInches = (_heightCm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet' $inches\"";
    }
    return '${_heightCm.round()} cm';
  }

  void _goToMacroReview() {
    // Seed editable values from calculation
    setState(() {
      _editCalories = _calcCalories;
      _editProtein = _calcProtein;
      _editFat = _calcFat;
      _editCarbs = _calcCarbs;
      _showMacroReview = true;
    });
    final n = ref.read(onboardingFlowProvider.notifier);
    n.setAge(_age);
    n.setWeight(_weightKg);
    n.setHeight(_heightCm);
  }

  void _approveMacros() {
    final n = ref.read(onboardingFlowProvider.notifier);
    n.setTargetCalories(_editCalories);
    n.setTargetProtein(_editProtein);
    n.setTargetFat(_editFat);
    n.setTargetCarbs(_editCarbs);
    widget.onNext();
  }

  bool handleMainBack() {
    if (_showMacroReview) {
      setState(() => _showMacroReview = false);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_showMacroReview) return _buildMacroReview(context);
    return _buildBodyInfoForm(context);
  }

  // ── Page 1: Body info form ──

  Widget _buildBodyInfoForm(BuildContext context) {
    final hasAll = _gender.isNotEmpty && _activity.isNotEmpty;

    return _StepLayout(
      title: "Goals for meals out & on the go",
      subtitle: "We use this to filter suggestions and portions — not to shame you.",
      mascotReaction: hasAll
          ? '$_goalLabel plan: ${_calcCalories} cal/day'
          : 'Tell me about yourself!',
      content: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Gender
          Text('Gender',
              style: context.appText.bodyStrong
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final g in [
                ('male', 'Male', Icons.male_rounded),
                ('female', 'Female', Icons.female_rounded),
                ('other', 'Other', Icons.transgender_rounded),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _gender = g.$1);
                        HapticFeedback.selectionClick();
                        ref
                            .read(onboardingFlowProvider.notifier)
                            .setGender(g.$1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _gender == g.$1
                              ? AppPalette.primary.withValues(alpha: 0.1)
                              : AppPalette.surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _gender == g.$1
                                ? AppPalette.primary
                                : AppPalette.border,
                            width: _gender == g.$1 ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(g.$3,
                                size: 28,
                                color: _gender == g.$1
                                    ? AppPalette.primary
                                    : AppPalette.neutral500),
                            const SizedBox(height: 6),
                            Text(g.$2,
                                style: context.appText.smallStrong.copyWith(
                                  color: _gender == g.$1
                                      ? AppPalette.primary
                                      : AppPalette.deepNavy,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Age
          _buildSliderSection(context, label: 'Age', value: '$_age',
            slider: Slider(
              value: _age.toDouble(), min: 14, max: 80, divisions: 66,
              onChanged: (v) {
                setState(() => _age = v.round());
                ref.read(onboardingFlowProvider.notifier).setAge(v.round());
              },
            ),
          ),

          // Weight
          _buildSliderSection(context,
            label: 'Weight',
            value: _weightDisplay,
            unitToggle: _buildUnitToggle(
              context,
              value: _weightUnit,
              options: const {'kg': 'kg', 'lb': 'lb'},
              onChanged: (v) {
                if (v == null) return;
                HapticFeedback.selectionClick();
                setState(() => _weightUnit = v);
              },
            ),
            slider: Slider(
              value: _weightUnit == 'kg'
                  ? _weightKg
                  : (_weightKg * 2.2046226218).clamp(66.0, 440.0),
              min: _weightUnit == 'kg' ? 30 : 66,
              max: _weightUnit == 'kg' ? 200 : 440,
              divisions: _weightUnit == 'kg' ? 170 : 374,
              onChanged: (v) {
                final nextKg = _weightUnit == 'kg' ? v : (v / 2.2046226218);
                setState(() => _weightKg = nextKg);
                ref.read(onboardingFlowProvider.notifier).setWeight(nextKg);
              },
            ),
          ),

          // Height
          _buildSliderSection(context,
            label: 'Height',
            value: _heightDisplay,
            unitToggle: _buildUnitToggle(
              context,
              value: _heightUnit,
              options: const {'cm': 'cm', 'ft': 'ft + in'},
              onChanged: (v) {
                if (v == null) return;
                HapticFeedback.selectionClick();
                setState(() => _heightUnit = v);
              },
            ),
            slider: Slider(
              value: _heightUnit == 'cm'
                  ? _heightCm
                  : (_heightCm / 2.54).clamp(48.0, 87.0),
              min: _heightUnit == 'cm' ? 120 : 48,
              max: _heightUnit == 'cm' ? 220 : 87,
              divisions: _heightUnit == 'cm' ? 100 : 39,
              onChanged: (v) {
                final nextCm = _heightUnit == 'cm' ? v : (v * 2.54);
                setState(() => _heightCm = nextCm);
                ref.read(onboardingFlowProvider.notifier).setHeight(nextCm);
              },
            ),
          ),

          // Activity level
          Text('Activity Level',
              style: context.appText.bodyStrong
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final a in [
                  ('sedentary', 'Sedentary', Icons.weekend_rounded),
                  ('light', 'Light', Icons.directions_walk_rounded),
                  ('moderate', 'Moderate', Icons.directions_run_rounded),
                  ('active', 'Active', Icons.fitness_center_rounded),
                  ('veryActive', 'Very Active', Icons.sports_rounded),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _activity = a.$1);
                        HapticFeedback.selectionClick();
                        ref
                            .read(onboardingFlowProvider.notifier)
                            .setActivityLevel(a.$1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 90,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _activity == a.$1
                              ? AppPalette.primary.withValues(alpha: 0.1)
                              : AppPalette.surfaceWhite,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _activity == a.$1
                                ? AppPalette.primary
                                : AppPalette.border,
                            width: _activity == a.$1 ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(a.$3,
                                size: 24,
                                color: _activity == a.$1
                                    ? AppPalette.primary
                                    : AppPalette.neutral500),
                            const SizedBox(height: 4),
                            Text(a.$2,
                                textAlign: TextAlign.center,
                                style: context.appText.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _activity == a.$1
                                      ? AppPalette.primary
                                      : AppPalette.deepNavy,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Goal profile (Maintain / Cut / Bulk)
          Text('Goal',
              style: context.appText.bodyStrong
                  .copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _buildUnitToggle(
            context,
            value: _macroGoal,
            options: const {
              'maintain': 'Maintain',
              'cut': 'Cut',
              'bulk': 'Bulk',
            },
            onChanged: (v) {
              if (v == null) return;
              HapticFeedback.selectionClick();
              setState(() => _macroGoal = v);
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppPalette.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.border),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded,
                    size: 16, color: AppPalette.neutral500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BMR $_bmr  •  TDEE $_tdee  •  Target $_calcCalories kcal',
                    style: context.appText.caption.copyWith(
                      color: AppPalette.neutral500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      ctaLabel: hasAll ? 'See your targets' : 'Continue',
      onCta: () {
        if (hasAll) {
          _goToMacroReview();
        } else {
          // Skip macros if not enough info
          final n = ref.read(onboardingFlowProvider.notifier);
          n.setAge(_age);
          n.setWeight(_weightKg);
          n.setHeight(_heightCm);
          widget.onNext();
        }
      },
      ctaEnabled: true,
    );
  }

  // ── Page 2: Macro review & edit ──

  Widget _buildMacroReview(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final anyEdited = _editCalories != _calcCalories ||
        _editProtein != _calcProtein ||
        _editFat != _calcFat ||
        _editCarbs != _calcCarbs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // ── Title ──
                FadeInEntrance(
                  child: Text(
                    'Your personalized plan',
                    style: context.appText.h1.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Calculated from your profile using Mifflin-St Jeor.',
                    style: context.appText.small.copyWith(
                      color: AppPalette.neutral500,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Calculation breakdown card ──
                FadeInEntrance(
                  delay: const Duration(milliseconds: 120),
                  child: _buildCalculationCard(context),
                ),
                const SizedBox(height: 12),

                // ── Goal toggle ──
                FadeInEntrance(
                  delay: const Duration(milliseconds: 160),
                  child: _buildGoalToggleCard(context),
                ),
                const SizedBox(height: 20),

                // ── Macro target cards ──
                FadeInEntrance(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Daily macro targets',
                    style: context.appText.bodyStrong.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 220),
                  child: Text(
                    'These are calculated for you. Adjust if needed.',
                    style: context.appText.small.copyWith(
                      color: AppPalette.neutral400,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                FadeInEntrance(
                  delay: const Duration(milliseconds: 250),
                  child: _buildMacroSplitBar(context),
                ),
                const SizedBox(height: 16),

                FadeInEntrance(
                  delay: const Duration(milliseconds: 280),
                  child: _MacroTargetCard(
                    label: 'Calories',
                    value: _editCalories,
                    suggestedValue: _calcCalories,
                    unit: 'kcal',
                    color: AppPalette.primary,
                    icon: Icons.local_fire_department_rounded,
                    min: 1000,
                    max: 5000,
                    step: 50,
                    onChanged: (v) => setState(() => _editCalories = v),
                    onReset: () =>
                        setState(() => _editCalories = _calcCalories),
                  ),
                ),
                const SizedBox(height: 10),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 320),
                  child: _MacroTargetCard(
                    label: 'Protein',
                    value: _editProtein,
                    suggestedValue: _calcProtein,
                    unit: 'g',
                    color: AppPalette.successMint,
                    icon: Icons.fitness_center_rounded,
                    min: 30,
                    max: 400,
                    step: 5,
                    onChanged: (v) => setState(() => _editProtein = v),
                    onReset: () =>
                        setState(() => _editProtein = _calcProtein),
                  ),
                ),
                const SizedBox(height: 10),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 360),
                  child: _MacroTargetCard(
                    label: 'Fat',
                    value: _editFat,
                    suggestedValue: _calcFat,
                    unit: 'g',
                    color: AppPalette.sunRewards,
                    icon: Icons.water_drop_rounded,
                    min: 20,
                    max: 250,
                    step: 5,
                    onChanged: (v) => setState(() => _editFat = v),
                    onReset: () => setState(() => _editFat = _calcFat),
                  ),
                ),
                const SizedBox(height: 10),
                FadeInEntrance(
                  delay: const Duration(milliseconds: 400),
                  child: _MacroTargetCard(
                    label: 'Carbs',
                    value: _editCarbs,
                    suggestedValue: _calcCarbs,
                    unit: 'g',
                    color: const Color(0xFF7C6AE8),
                    icon: Icons.grain_rounded,
                    min: 50,
                    max: 600,
                    step: 5,
                    onChanged: (v) => setState(() => _editCarbs = v),
                    onReset: () => setState(() => _editCarbs = _calcCarbs),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Reset all ──
                if (anyEdited)
                  FadeInEntrance(
                    delay: const Duration(milliseconds: 420),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _editCalories = _calcCalories;
                            _editProtein = _calcProtein;
                            _editFat = _calcFat;
                            _editCarbs = _calcCarbs;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppPalette.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded,
                                  size: 16, color: AppPalette.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Reset all to suggested',
                                style: context.appText.smallStrong.copyWith(
                                  color: AppPalette.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Approve button ──
          FadeInEntrance(
            delay: const Duration(milliseconds: 440),
            child: BounceInteraction(
              onTap: _approveMacros,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppPalette.deepNavy,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.deepNavy.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  anyEdited ? 'Use my custom targets' : 'Use suggested targets',
                  textAlign: TextAlign.center,
                  style: context.appText.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }

  // ── Calculation breakdown card ──
  Widget _buildCalculationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Pipeline: BMR → TDEE → Target
          Row(
            children: [
              _buildCalcStep(
                context,
                label: 'BMR',
                value: '$_bmr',
                subtitle: 'Base rate',
                color: AppPalette.neutral500,
              ),
              _buildCalcArrow(),
              _buildCalcStep(
                context,
                label: 'TDEE',
                value: '$_tdee',
                subtitle: _activity.isEmpty ? 'Activity' : _activity,
                color: AppPalette.neutral500,
              ),
              _buildCalcArrow(),
              _buildCalcStep(
                context,
                label: 'Target',
                value: '$_calcCalories',
                subtitle: '${_goalLabel.toLowerCase()} kcal',
                color: AppPalette.primary,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Profile summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppPalette.creamBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_gender.isNotEmpty ? _gender[0].toUpperCase() + _gender.substring(1) : "—"}'
              '  •  ${_age}y  •  $_weightDisplay  •  $_heightDisplay',
              style: context.appText.caption.copyWith(
                color: AppPalette.neutral500,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcStep(
    BuildContext context, {
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    bool bold = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: context.appText.caption.copyWith(
              color: AppPalette.neutral400,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.appText.h3.copyWith(
              fontWeight: FontWeight.w900,
              color: bold ? color : AppPalette.deepNavy,
              fontSize: bold ? 24 : 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.appText.caption.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcArrow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 12,
        color: AppPalette.neutral400.withValues(alpha: 0.5),
      ),
    );
  }

  // ── Goal toggle card ──
  Widget _buildGoalToggleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your goal',
            style: context.appText.smallStrong.copyWith(
              fontWeight: FontWeight.w800,
              color: AppPalette.neutral500,
            ),
          ),
          const SizedBox(height: 10),
          _buildUnitToggle(
            context,
            value: _macroGoal,
            options: const {
              'maintain': 'Maintain',
              'cut': 'Cut',
              'bulk': 'Bulk',
            },
            onChanged: (v) {
              if (v == null) return;
              HapticFeedback.selectionClick();
              setState(() {
                _macroGoal = v;
                // Recalculate when goal changes
                _editCalories = _calcCalories;
                _editProtein = _calcProtein;
                _editFat = _calcFat;
                _editCarbs = _calcCarbs;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _macroGoal == 'cut'
                ? '15% calorie deficit  •  Higher protein for muscle retention'
                : _macroGoal == 'bulk'
                    ? '10% calorie surplus  •  Extra carbs for energy'
                    : 'Balanced macros to maintain your current weight',
            style: context.appText.caption.copyWith(
              color: AppPalette.neutral400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Macro split bar ──
  Widget _buildMacroSplitBar(BuildContext context) {
    final totalCal = (_editProtein * 4) + (_editFat * 9) + (_editCarbs * 4);
    if (totalCal == 0) return const SizedBox.shrink();
    final proteinPct = (_editProtein * 4) / totalCal;
    final fatPct = (_editFat * 9) / totalCal;
    final carbsPct = (_editCarbs * 4) / totalCal;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Flexible(
                  flex: (proteinPct * 100).round().clamp(1, 100),
                  child: Container(color: AppPalette.successMint),
                ),
                const SizedBox(width: 2),
                Flexible(
                  flex: (fatPct * 100).round().clamp(1, 100),
                  child: Container(color: AppPalette.sunRewards),
                ),
                const SizedBox(width: 2),
                Flexible(
                  flex: (carbsPct * 100).round().clamp(1, 100),
                  child: Container(color: const Color(0xFF7C6AE8)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSplitLabel(context, 'Protein',
                '${(proteinPct * 100).round()}%', AppPalette.successMint),
            const Spacer(),
            _buildSplitLabel(context, 'Fat', '${(fatPct * 100).round()}%',
                AppPalette.sunRewards),
            const Spacer(),
            _buildSplitLabel(context, 'Carbs',
                '${(carbsPct * 100).round()}%', const Color(0xFF7C6AE8)),
          ],
        ),
      ],
    );
  }

  Widget _buildSplitLabel(
      BuildContext context, String label, String pct, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $pct',
          style: context.appText.caption.copyWith(
            color: AppPalette.neutral500,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSection(
    BuildContext context, {
    required String label,
    required String value,
    Widget? unitToggle,
    required Slider slider,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: context.appText.bodyStrong
                      .copyWith(fontWeight: FontWeight.w800)),
              Text(value,
                  style: context.appText.h3.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppPalette.primary,
                  )),
            ],
          ),
          if (unitToggle != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: unitToggle),
          ],
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppPalette.primary,
              inactiveTrackColor: AppPalette.neutral100,
              thumbColor: AppPalette.deepNavy,
              overlayColor: AppPalette.primary.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: slider,
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(
    BuildContext context, {
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: value,
        thumbColor: AppPalette.deepNavy,
        backgroundColor: Colors.transparent,
        children: {
          for (final entry in options.entries)
            entry.key: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                entry.value,
                style: context.appText.smallStrong.copyWith(
                  color: value == entry.key
                      ? Colors.white
                      : AppPalette.neutral500,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        },
        onValueChanged: onChanged,
      ),
    );
  }
}

/// A full-width editable macro card with +/- controls and a slider.
class _MacroTargetCard extends StatefulWidget {
  final String label;
  final int value;
  final int suggestedValue;
  final String unit;
  final Color color;
  final IconData icon;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final VoidCallback onReset;

  const _MacroTargetCard({
    required this.label,
    required this.value,
    required this.suggestedValue,
    required this.unit,
    required this.color,
    required this.icon,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    required this.onReset,
  });

  @override
  State<_MacroTargetCard> createState() => _MacroTargetCardState();
}

class _MacroTargetCardState extends State<_MacroTargetCard> {
  bool _expanded = false;

  bool get _isEdited => widget.value != widget.suggestedValue;
  int get _delta => widget.value - widget.suggestedValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isEdited
              ? widget.color.withValues(alpha: 0.3)
              : AppPalette.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main row: icon + label + value + edit toggle ──
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Row(
              children: [
                // Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 18),
                ),
                const SizedBox(width: 12),
                // Label + suggested
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: context.appText.bodyStrong.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (_isEdited)
                        Text(
                          'Suggested: ${widget.suggestedValue}${widget.unit}',
                          style: context.appText.caption.copyWith(
                            color: AppPalette.neutral400,
                            fontSize: 11,
                          ),
                        )
                      else
                        Text(
                          'Calculated for you',
                          style: context.appText.caption.copyWith(
                            color: widget.color.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                // Value
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${widget.value}',
                          style: context.appText.h3.copyWith(
                            fontWeight: FontWeight.w900,
                            color: widget.color,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.unit,
                          style: context.appText.caption.copyWith(
                            color: widget.color.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_isEdited)
                      Text(
                        '${_delta > 0 ? "+" : ""}$_delta',
                        style: context.appText.caption.copyWith(
                          color: _delta > 0
                              ? AppPalette.successMint
                              : AppPalette.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                // Expand chevron
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _expanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: AppPalette.neutral400,
                  ),
                ),
              ],
            ),
          ),

          // ── Expandable slider section ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSliderSection(context),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          // +/- row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  final v = widget.value - widget.step;
                  if (v >= widget.min) {
                    widget.onChanged(v);
                    HapticFeedback.selectionClick();
                  }
                },
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: widget.color,
                    inactiveTrackColor: AppPalette.neutral100,
                    thumbColor: AppPalette.deepNavy,
                    overlayColor: widget.color.withValues(alpha: 0.1),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: widget.value
                        .toDouble()
                        .clamp(widget.min.toDouble(), widget.max.toDouble()),
                    min: widget.min.toDouble(),
                    max: widget.max.toDouble(),
                    divisions: ((widget.max - widget.min) / widget.step).round(),
                    onChanged: (v) {
                      widget.onChanged(v.round());
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ),
              _buildStepButton(
                icon: Icons.add_rounded,
                color: widget.color,
                onTap: () {
                  final v = widget.value + widget.step;
                  if (v <= widget.max) {
                    widget.onChanged(v);
                    HapticFeedback.selectionClick();
                  }
                },
              ),
            ],
          ),
          if (_isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  widget.onReset();
                  HapticFeedback.selectionClick();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 13, color: AppPalette.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Reset to ${widget.suggestedValue}${widget.unit}',
                      style: context.appText.caption.copyWith(
                        color: AppPalette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: (color ?? AppPalette.neutral400).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon,
            size: 18, color: color ?? AppPalette.deepNavy),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Vibe Follow-Up: Comfort Food Categories
// ══════════════════════════════════════════════════════════════

class _ComfortFoodStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _ComfortFoodStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingFlowProvider.select((s) => s.data.comfortCategories),
    );

    final categories = [
      ('soups', 'Soups & Stews', '🍲'),
      ('pasta', 'Pasta & Noodles', '🍝'),
      ('casseroles', 'Casseroles & Bakes', '🫕'),
      ('macCheese', 'Mac & Cheese', '🧀'),
      ('fried', 'Fried Favorites', '🍗'),
      ('bbq', 'BBQ & Grilled', '🔥'),
      ('curries', 'Curries', '🍛'),
      ('pizza', 'Pizza & Flatbreads', '🍕'),
      ('sandwiches', 'Sandwiches & Wraps', '🌯'),
      ('sweet', 'Sweet Treats', '🍰'),
    ];

    return _StepLayout(
      title: 'Comfort orders when you’re drained?',
      subtitle: "We’ll bias toward these when the day wins and you still need fuel.",
      mascotReaction: selected.isEmpty
          ? 'What warms your heart?'
          : '${selected.length} comfort picks!',
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((c) {
            final isSelected = selected.contains(c.$1);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(onboardingFlowProvider.notifier)
                    .toggleComfortCategory(c.$1);
              },
              child: AnimatedScale(
                scale: isSelected ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: (MediaQuery.of(context).size.width - 48 - 10) / 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppPalette.sunRewards.withValues(alpha: 0.1)
                        : AppPalette.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? AppPalette.sunRewards : AppPalette.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(c.$3, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.$2,
                          style: context.appText.smallStrong.copyWith(
                            color: isSelected
                                ? AppPalette.deepNavy
                                : AppPalette.neutral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      ctaLabel: selected.isEmpty ? 'Skip' : 'Continue',
      onCta: onNext,
      ctaEnabled: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Vibe Follow-Up: Cuisine Explorer (Adventurous)
// ══════════════════════════════════════════════════════════════

class _AdventureStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _AdventureStep({required this.onNext});

  @override
  ConsumerState<_AdventureStep> createState() => _AdventureStepState();
}

class _AdventureStepState extends ConsumerState<_AdventureStep> {
  int _spice = 2;

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(
      onboardingFlowProvider.select((s) => s.data.cuisineInterests),
    );

    final cuisines = [
      ('japanese', 'Japanese', '🇯🇵'),
      ('korean', 'Korean', '🇰🇷'),
      ('thai', 'Thai', '🇹🇭'),
      ('indian', 'Indian', '🇮🇳'),
      ('mexican', 'Mexican', '🇲🇽'),
      ('ethiopian', 'Ethiopian', '🇪🇹'),
      ('middleEastern', 'Middle Eastern', '🌍'),
      ('mediterranean', 'Mediterranean', '🇬🇷'),
      ('french', 'French', '🇫🇷'),
      ('italian', 'Italian', '🇮🇹'),
      ('chinese', 'Chinese', '🇨🇳'),
      ('caribbean', 'Caribbean', '🌴'),
    ];

    final spiceLabels = ['', 'Mild', 'Medium', 'Hot', 'Extreme'];
    final spiceEmoji = ['', '🌶️', '🌶️🌶️', '🔥🔥', '🔥🔥🔥'];

    return _StepLayout(
      title: 'When you’re somewhere new…',
      subtitle: 'Pick cuisines you’d actually try from a short list nearby.',
      mascotReaction: selected.isEmpty
          ? 'Where to next?'
          : 'Great taste! Literally!',
      content: Column(
        children: [
          // Cuisine grid
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: cuisines.length,
              itemBuilder: (context, i) {
                final c = cuisines[i];
                final isSelected = selected.contains(c.$1);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(onboardingFlowProvider.notifier)
                        .toggleCuisine(c.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppPalette.primary.withValues(alpha: 0.08)
                          : AppPalette.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppPalette.primary
                            : AppPalette.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.$3, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          c.$2,
                          textAlign: TextAlign.center,
                          style: context.appText.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppPalette.primary
                                : AppPalette.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Spice tolerance
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppPalette.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppPalette.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(spiceEmoji[_spice],
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'Spice: ${spiceLabels[_spice]}',
                      style: context.appText.bodyStrong
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Color.lerp(
                        AppPalette.sunRewards, AppPalette.primary,
                        (_spice - 1) / 3)!,
                    inactiveTrackColor: AppPalette.neutral100,
                    thumbColor: AppPalette.deepNavy,
                    overlayColor: AppPalette.primary.withValues(alpha: 0.1),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _spice.toDouble(),
                    min: 1,
                    max: 4,
                    divisions: 3,
                    onChanged: (v) {
                      setState(() => _spice = v.round());
                      HapticFeedback.selectionClick();
                      ref
                          .read(onboardingFlowProvider.notifier)
                          .setSpiceTolerance(v.round());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ctaLabel: selected.isEmpty ? 'Skip' : 'Continue',
      onCta: () {
        ref.read(onboardingFlowProvider.notifier).setSpiceTolerance(_spice);
        widget.onNext();
      },
      ctaEnabled: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step: Time Available – updated title
// ══════════════════════════════════════════════════════════════

class _TimeAvailableStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _TimeAvailableStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingFlowProvider.select((s) => s.data.timeAvailableMin),
    );

    final times = [
      (10, 'Grab & go', '10 min', Icons.flash_on_rounded),
      (20, 'Quick sit-down', '20 min', Icons.timer_rounded),
      (30, 'Full lunch break', '30+ min', Icons.restaurant_rounded),
    ];

    return _StepLayout(
      title: 'How much time to eat on a slammed day?',
      subtitle: "We’ll only suggest what fits the window before your next block.",
      mascotReaction: selected != null
          ? '$selected min — noted.'
          : 'Typical gap between meetings?',
      content: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: times.map((t) {
            final isSelected = selected == t.$1;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(onboardingFlowProvider.notifier)
                    .setTimeAvailable(t.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 105,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppPalette.deepNavy
                      : AppPalette.surfaceWhite,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color:
                        isSelected ? AppPalette.deepNavy : AppPalette.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppPalette.deepNavy.withValues(alpha: 0.15)
                          : Colors.transparent,
                      blurRadius: isSelected ? 20 : 0,
                      offset: isSelected
                          ? const Offset(0, 8)
                          : Offset.zero,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$4,
                        size: 32,
                        color: isSelected
                            ? AppPalette.primary
                            : AppPalette.neutral500),
                    const SizedBox(height: 12),
                    Text(t.$3,
                        style: context.appText.h3.copyWith(
                          color:
                              isSelected ? Colors.white : AppPalette.deepNavy,
                          fontWeight: FontWeight.w900,
                        )),
                    const SizedBox(height: 4),
                    Text(t.$2,
                        style: context.appText.caption.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppPalette.neutral500,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      ctaLabel: "Let's go",
      onCta: onNext,
      ctaEnabled: selected != null,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step: Dietary Rules (unchanged)
// ══════════════════════════════════════════════════════════════

class _DietaryRulesStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _DietaryRulesStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(
      onboardingFlowProvider.select((s) => s.data.dietaryRules),
    );

    final allRules = [
      ('vegetarian', 'Vegetarian', Icons.eco_rounded),
      ('vegan', 'Vegan', Icons.grass_rounded),
      ('halal', 'Halal', Icons.restaurant_rounded),
      ('kosher', 'Kosher', Icons.star_rounded),
      ('glutenFree', 'Gluten-Free', Icons.no_food_rounded),
      ('dairyFree', 'Dairy-Free', Icons.water_drop_rounded),
      ('nutFree', 'Nut-Free', Icons.warning_rounded),
      ('pescatarian', 'Pescatarian', Icons.set_meal_rounded),
      ('keto', 'Keto', Icons.local_fire_department_rounded),
    ];

    return _StepLayout(
      title: 'Any dietary rules?',
      subtitle: 'So we don’t suggest the wrong menu when you’re ordering fast.',
      mascotReaction:
          rules.isEmpty ? 'Anything I should know?' : "Got it, I'll remember!",
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: allRules.map((r) {
          final isSelected = rules.contains(r.$1);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(onboardingFlowProvider.notifier)
                  .toggleDietaryRule(r.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppPalette.primary.withValues(alpha: 0.1)
                    : AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppPalette.primary : AppPalette.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(r.$3,
                      size: 20,
                      color: isSelected
                          ? AppPalette.primary
                          : AppPalette.neutral500),
                  const SizedBox(width: 8),
                  Text(r.$2,
                      style: context.appText.smallStrong.copyWith(
                        color: isSelected
                            ? AppPalette.primary
                            : AppPalette.deepNavy,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      ctaLabel: rules.isEmpty ? 'No rules, skip' : 'Continue',
      onCta: onNext,
      ctaEnabled: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step: Dislikes (unchanged)
// ══════════════════════════════════════════════════════════════

class _DislikesStep extends ConsumerWidget {
  final VoidCallback onNext;
  const _DislikesStep({required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dislikes = ref.watch(
      onboardingFlowProvider.select((s) => s.data.dislikes),
    );

    final ingredients = [
      'Cilantro', 'Mushrooms', 'Olives', 'Anchovies', 'Blue Cheese',
      'Tofu', 'Liver', 'Brussels Sprouts', 'Eggplant', 'Beets',
      'Okra', 'Cottage Cheese', 'Sardines', 'Pickles', 'Fennel',
      'Turnips', 'Coconut', 'Raisins',
    ];

    return _StepLayout(
      title: "Ingredients to avoid?",
      subtitle: "Tap to exclude — we’ll filter picks and saved templates.",
      mascotReaction: dislikes.isNotEmpty
          ? 'Noted! No ${dislikes.first.toLowerCase()} ever.'
          : 'Any deal-breakers?',
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ingredients.map((ing) {
            final isExcluded = dislikes.contains(ing);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(onboardingFlowProvider.notifier).toggleDislike(ing);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isExcluded
                      ? AppPalette.primary.withValues(alpha: 0.12)
                      : AppPalette.surfaceWhite,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isExcluded ? AppPalette.primary : AppPalette.border,
                    width: isExcluded ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isExcluded) ...[
                      const Icon(Icons.close_rounded,
                          size: 16, color: AppPalette.primary),
                      const SizedBox(width: 4),
                    ],
                    Text(ing,
                        style: context.appText.smallStrong.copyWith(
                          color: isExcluded
                              ? AppPalette.primary
                              : AppPalette.deepNavy,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      ctaLabel: dislikes.isEmpty ? 'I eat everything!' : 'Continue',
      onCta: onNext,
      ctaEnabled: true,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step: Pantry Capture – "Select manually" option
// ══════════════════════════════════════════════════════════════

class _PantryCaptureStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _PantryCaptureStep({super.key, required this.onNext});

  @override
  ConsumerState<_PantryCaptureStep> createState() => _PantryCaptureStepState();
}

class _PantryCaptureStepState extends ConsumerState<_PantryCaptureStep> {
  bool _showManualPicker = false;
  bool _manualPickerOpenedFromCta = false;
  String _search = '';

  static const _groceryCategories = {
    'Proteins': [
      'Chicken', 'Beef', 'Pork', 'Fish/Salmon', 'Shrimp', 'Eggs', 'Tofu',
      'Turkey'
    ],
    'Dairy': ['Milk', 'Cheese', 'Yogurt', 'Butter', 'Cream', 'Sour Cream'],
    'Grains & Carbs': [
      'Rice', 'Pasta', 'Bread', 'Oats', 'Flour', 'Tortillas', 'Quinoa'
    ],
    'Vegetables': [
      'Onions', 'Garlic', 'Tomatoes', 'Potatoes', 'Bell Peppers', 'Broccoli',
      'Spinach', 'Carrots', 'Lettuce', 'Zucchini', 'Mushrooms', 'Corn'
    ],
    'Fruits': [
      'Bananas', 'Apples', 'Lemons/Limes', 'Berries', 'Avocado', 'Oranges'
    ],
    'Canned/Jarred': [
      'Canned Tomatoes', 'Beans', 'Coconut Milk', 'Broth/Stock', 'Tuna'
    ],
    'Condiments & Sauces': [
      'Soy Sauce', 'Hot Sauce', 'Ketchup', 'Mustard', 'Mayo', 'Olive Oil',
      'Vinegar', 'Honey'
    ],
    'Spices': [
      'Salt', 'Pepper', 'Garlic Powder', 'Paprika', 'Cumin', 'Oregano',
      'Chili Flakes', 'Cinnamon'
    ],
  };

  bool handleMainBack() {
    if (_showManualPicker) {
      setState(() {
        _manualPickerOpenedFromCta = false;
        _showManualPicker = false;
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_showManualPicker) return _buildManualPicker(context);

    final choice = ref.watch(
      onboardingFlowProvider.select((s) => s.data.pantryChoice),
    );
    final manualItems = ref.watch(
      onboardingFlowProvider.select((s) => s.data.manualPantryItems),
    );
    final hasItems = choice == 'manual' && manualItems.isNotEmpty;

    final calConnected = ref.watch(
      calendarConnectionProvider.select((s) => s.isConnected),
    );

    final options = [
      (
        'receipt',
        calConnected ? 'Google Calendar' : 'Google Calendar (next)',
        calConnected
            ? 'Calendar linked — suggestions can follow your busy times.'
            : 'Link from the previous screen, or connect later in settings.',
        Icons.calendar_month_rounded,
      ),
      ('groceries', 'Travel & flights (manual for now)',
          "Add trips, hotels, or city changes you already know", Icons.flight_rounded),
      ('manual', 'Mostly local / routine', 'Pick staples we should bias toward',
          Icons.location_on_rounded),
    ];

    return _StepLayout(
      title: "Where will suggestions meet you?",
      subtitle: 'MVP: Calendar sync and travel entry come next — set expectations now.',
      mascotReaction: hasItems
          ? '${manualItems.length} staples saved'
          : 'Home, road, or both?',
      content: ListView(
        physics: const BouncingScrollPhysics(),
        children: options.map((o) {
          final isSelected = choice == o.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(onboardingFlowProvider.notifier).setPantryChoice(o.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppPalette.deepNavy
                      : AppPalette.surfaceWhite,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color:
                        isSelected ? AppPalette.deepNavy : AppPalette.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppPalette.deepNavy.withValues(alpha: 0.15)
                          : Colors.transparent,
                      blurRadius: isSelected ? 20 : 0,
                      offset: isSelected
                          ? const Offset(0, 8)
                          : Offset.zero,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.primary.withValues(alpha: 0.2)
                            : AppPalette.neutral100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(o.$4,
                          color: isSelected
                              ? AppPalette.primary
                              : AppPalette.neutral500,
                          size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.$2,
                              style: context.appText.bodyStrong.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppPalette.deepNavy,
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 2),
                          Text(o.$3,
                              style: context.appText.small.copyWith(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppPalette.neutral500,
                              )),
                        ],
                      ),
                    ),
                    if (isSelected && hasItems)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppPalette.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${manualItems.length}',
                            style: context.appText.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            )),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      ctaLabel:
          choice != null ? 'Continue' : 'Skip for now',
      onCta: () {
        if (choice == null) {
          _showSkipWarning(context);
        } else if (choice == 'manual') {
          setState(() {
            _manualPickerOpenedFromCta = true;
            _showManualPicker = true;
          });
        } else {
          widget.onNext();
        }
      },
      ctaEnabled: true,
    );
  }

  Widget _buildManualPicker(BuildContext context) {
    final selectedItems = ref.watch(
      onboardingFlowProvider.select((s) => s.data.manualPantryItems),
    );
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Back + title
          Row(
            children: [
              Text("Staples & go-tos to bias toward",
                  style: context.appText.h3
                      .copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          // Search
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search staples...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppPalette.neutral400),
              fillColor: AppPalette.surfaceWhite,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          // Categories
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: _groceryCategories.entries.map((cat) {
                final filtered = _search.isEmpty
                    ? cat.value
                    : cat.value
                        .where((i) =>
                            i.toLowerCase().contains(_search.toLowerCase()))
                        .toList();
                if (filtered.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.key,
                          style: context.appText.bodyStrong
                              .copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filtered.map((item) {
                          final isSel = selectedItems.contains(item);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(onboardingFlowProvider.notifier)
                                  .toggleManualPantryItem(item);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppPalette.primary
                                        .withValues(alpha: 0.1)
                                    : AppPalette.surfaceWhite,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: isSel
                                      ? AppPalette.primary
                                      : AppPalette.border,
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSel) ...[
                                    const Icon(Icons.check_rounded,
                                        size: 14, color: AppPalette.primary),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(item,
                                      style:
                                          context.appText.smallStrong.copyWith(
                                        color: isSel
                                            ? AppPalette.primary
                                            : AppPalette.deepNavy,
                                      )),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Done button
          BounceInteraction(
            onTap: () {
              if (_manualPickerOpenedFromCta) {
                setState(() {
                  _manualPickerOpenedFromCta = false;
                  _showManualPicker = false;
                });
                widget.onNext();
              } else {
                setState(() => _showManualPicker = false);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppPalette.deepNavy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.deepNavy.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                selectedItems.isEmpty
                    ? 'Done'
                    : 'Done (${selectedItems.length} items)',
                textAlign: TextAlign.center,
                style: context.appText.bodyStrong.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }

  void _showSkipWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Skip this step?',
            style: context.appText.h3.copyWith(fontWeight: FontWeight.w900)),
        content: Text(
          'Staples and context help us bias suggestions. '
          "You can add them later in settings.",
          style: context.appText.body.copyWith(color: AppPalette.neutral500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Add items',
                style: context.appText.bodyStrong
                    .copyWith(color: AppPalette.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(onboardingFlowProvider.notifier).setPantryChoice('skip');
              widget.onNext();
            },
            child: Text('Skip anyway',
                style: context.appText.body
                    .copyWith(color: AppPalette.neutral500)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step: Before / After (messaging updated)
// ══════════════════════════════════════════════════════════════

class _BeforeAfterStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _BeforeAfterStep({required this.onNext});

  @override
  ConsumerState<_BeforeAfterStep> createState() => _BeforeAfterStepState();
}

class _BeforeAfterStepState extends ConsumerState<_BeforeAfterStep>
    with TickerProviderStateMixin {
  // Scratch state
  final List<Offset> _scratchPoints = [];
  final Set<int> _scratchedCells = {};
  static const int _gridSize = 20; // 20x20 grid = 400 cells
  bool _revealed = false;
  bool _scratching = false;
  double _scratchPercent = 0;

  // Entrance
  late final AnimationController _entranceCtrl;
  late final Animation<double> _imageFade;
  late final Animation<double> _imageSlide;

  // Fade-out for the remaining overlay after 50%
  late final AnimationController _fadeOutCtrl;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _imageFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _imageSlide = Tween(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _fadeOutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeOutCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _revealed = true);
      }
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  void _onScratchStart(Offset localPos, Size size) {
    if (_revealed || _fadeOutCtrl.isAnimating) return;
    _scratching = true;
    _addScratchPoint(localPos, size);
  }

  void _onScratchUpdate(Offset localPos, Size size) {
    if (!_scratching || _revealed || _fadeOutCtrl.isAnimating) return;
    _addScratchPoint(localPos, size);
  }

  void _onScratchEnd() {
    if (!_scratching) return;
    _scratching = false;
    if (_scratchPercent >= 0.50 && !_revealed && !_fadeOutCtrl.isAnimating) {
      HapticFeedback.mediumImpact();
      _fadeOutCtrl.forward();
    }
  }

  void _addScratchPoint(Offset pos, Size size) {
    // Clamp to bounds
    final dx = pos.dx.clamp(0.0, size.width);
    final dy = pos.dy.clamp(0.0, size.height);
    final clamped = Offset(dx, dy);

    setState(() {
      _scratchPoints.add(clamped);

      // Mark grid cells as scratched (brush radius ~24px)
      final cellW = size.width / _gridSize;
      final cellH = size.height / _gridSize;
      const brushRadius = 24.0;

      for (int gx = 0; gx < _gridSize; gx++) {
        for (int gy = 0; gy < _gridSize; gy++) {
          final cellCenterX = (gx + 0.5) * cellW;
          final cellCenterY = (gy + 0.5) * cellH;
          final dist = (Offset(cellCenterX, cellCenterY) - clamped).distance;
          if (dist <= brushRadius) {
            _scratchedCells.add(gx * _gridSize + gy);
          }
        }
      }

      _scratchPercent =
          _scratchedCells.length / (_gridSize * _gridSize);
    });

    // Light haptic every ~8% scratched
    if (_scratchedCells.length % (_gridSize * _gridSize ~/ 12) == 0) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final screenW = MediaQuery.of(context).size.width;
    final imageSize = screenW - 48;
    final progressPercent = (_scratchPercent * 100).round().clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ── Title ──
          FadeInEntrance(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _revealed ? 'Healthy Autopilot' : "Here's the shift",
                key: ValueKey('title_$_revealed'),
                style: context.appText.h1.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          FadeInEntrance(
            delay: const Duration(milliseconds: 80),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _revealed
                    ? 'Proactive plans — not reactive guilt.'
                    : 'Scratch to see what changes.',
                key: ValueKey('sub_$_revealed'),
                style: context.appText.body.copyWith(
                  color: _revealed
                      ? AppPalette.successMint
                      : AppPalette.neutral500,
                  height: 1.5,
                  fontWeight: _revealed ? FontWeight.w700 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Scratch area ──
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entranceCtrl, _fadeOutCtrl]),
              builder: (context, _) {
                return Center(
                  child: Opacity(
                    opacity: _imageFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _imageSlide.value),
                      child: SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: _buildScratchCard(context, imageSize),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Progress / CTA ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            child: _revealed
                ? BounceInteraction(
                    key: const ValueKey('cta_done'),
                    onTap: widget.onNext,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppPalette.deepNavy,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.deepNavy.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        "Let's make this happen",
                        textAlign: TextAlign.center,
                        style: context.appText.bodyStrong.copyWith(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey('progress'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppPalette.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _scratchPercent > 0
                              ? Icons.auto_awesome_rounded
                              : Icons.touch_app_rounded,
                          size: 20,
                          color: _scratchPercent > 0.3
                              ? AppPalette.successMint
                              : AppPalette.neutral400,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _scratchPercent == 0
                                    ? 'Scratch the image to reveal'
                                    : _scratchPercent < 0.5
                                        ? 'Keep going... $progressPercent%'
                                        : 'Almost there! Lift your finger',
                                style: context.appText.smallStrong.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _scratchPercent > 0.3
                                      ? AppPalette.successMint
                                      : AppPalette.deepNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _scratchPercent.clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor: AppPalette.neutral100,
                                  valueColor: AlwaysStoppedAnimation(
                                    _scratchPercent > 0.5
                                        ? AppPalette.successMint
                                        : AppPalette.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: bottomPad + 16),
        ],
      ),
    );
  }

  Widget _buildScratchCard(BuildContext context, double size) {
    final fadeOutValue = Curves.easeOutCubic
        .transform(_fadeOutCtrl.value.clamp(0.0, 1.0));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _revealed
                ? AppPalette.successMint.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── After image (underneath) ──
            Image.asset(
              'assets/images/onboarding-after.jpg',
              fit: BoxFit.cover,
            ),

            // ── Before image overlay (scratchable) ──
            if (!_revealed)
              Opacity(
                opacity: 1.0 - fadeOutValue,
                child: GestureDetector(
                  onPanStart: (d) =>
                      _onScratchStart(d.localPosition, Size(size, size)),
                  onPanUpdate: (d) =>
                      _onScratchUpdate(d.localPosition, Size(size, size)),
                  onPanEnd: (_) => _onScratchEnd(),
                  child: _ScratchLayer(
                    scratchPoints: _scratchPoints,
                    child: Image.asset(
                      'assets/images/onboarding-before.png',
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                    ),
                  ),
                ),
              ),

            // ── Label badge ──
            Positioned(
              top: 16,
              left: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  key: ValueKey('badge_$_revealed'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _revealed
                        ? AppPalette.successMint
                        : Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _revealed ? 'WITH AUTOPILOT' : 'WITHOUT AUTOPILOT',
                    style: context.appText.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),

            // ── Scratch hint overlay (initial state) ──
            if (_scratchPercent == 0 && !_revealed)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppPalette.deepNavy.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swipe_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Scratch to reveal',
                          style: context.appText.smallStrong.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
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

/// Loads the before image as a dart:ui.Image and paints it with scratch
/// holes using saveLayer + BlendMode.clear — the standard scratch card
/// technique. Scratched areas become transparent, revealing whatever is
/// behind this widget in the Stack.
class _ScratchLayer extends StatefulWidget {
  final List<Offset> scratchPoints;
  final Widget child; // fallback while image loads

  const _ScratchLayer({
    required this.scratchPoints,
    required this.child,
  });

  @override
  State<_ScratchLayer> createState() => _ScratchLayerState();
}

class _ScratchLayerState extends State<_ScratchLayer> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/images/onboarding-before.png');
    final codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _image = frame.image);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) return widget.child;

    return CustomPaint(
      painter: _ScratchCardPainter(
        image: _image!,
        points: widget.scratchPoints,
      ),
      isComplex: true,
      willChange: true,
    );
  }
}

class _ScratchCardPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> points;

  _ScratchCardPainter({required this.image, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // Save a compositing layer — BlendMode.clear will erase within this layer
    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw the before image desaturated + darkened so it's visually distinct
    // from the vibrant after image underneath.
    final src = Rect.fromLTWH(
      0, 0, image.width.toDouble(), image.height.toDouble(),
    );
    final dst = Offset.zero & size;
    final imagePaint = Paint()
      ..colorFilter = const ColorFilter.matrix(<double>[
        // Desaturate (grayscale) + darken by ~25%
        0.18, 0.14, 0.08, 0, 0,   // R
        0.14, 0.20, 0.06, 0, 0,   // G
        0.10, 0.10, 0.20, 0, 0,   // B
        0,    0,    0,    1, 0,    // A
      ]);
    canvas.drawImageRect(image, src, dst, imagePaint);

    // Dark semi-transparent overlay for extra contrast
    canvas.drawRect(
      dst,
      Paint()..color = const Color(0x40000000),
    );

    // Erase scratched areas
    if (points.isNotEmpty) {
      final erasePaint = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;

      // Draw circles at each touch point
      for (final p in points) {
        canvas.drawCircle(p, 24, erasePaint);
      }

      // Connect consecutive points with thick strokes for smooth coverage
      if (points.length > 1) {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..blendMode = BlendMode.clear
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke
            ..strokeWidth = 48.0,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchCardPainter old) => true;
}

// ══════════════════════════════════════════════════════════════
// Step: Nibbl Contract (unchanged)
// ══════════════════════════════════════════════════════════════

class _NibblContractStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _NibblContractStep({required this.onNext});

  @override
  ConsumerState<_NibblContractStep> createState() => _NibblContractStepState();
}

class _NibblContractStepState extends ConsumerState<_NibblContractStep> {
  final List<Offset> _signaturePoints = [];

  @override
  void initState() {
    super.initState();
    // Ensure a default is set so the visual "3" matches the state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(onboardingFlowProvider).data.commitNights;
      if (current == null) {
        ref.read(onboardingFlowProvider.notifier).setCommitNights(3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nights = ref.watch(
      onboardingFlowProvider.select((s) => s.data.commitNights),
    );
    final hasSigned = _signaturePoints.length > 20;

    return _StepLayout(
      title: 'Make it real',
      subtitle: 'A small habit — trusting a plan before you are depleted.',
      mascotReaction: hasSigned ? "That's a promise!" : 'I believe in you!',
      content: Column(
        children: [
          // ── Commitment sentence with hero number ──
          Text('I’ll use timely suggestions',
              style: context.appText.body
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 16,
                      color: AppPalette.neutral500)),
          const SizedBox(height: 12),

          // Hero number with +/- controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (nights != null && nights > 1) {
                    HapticFeedback.selectionClick();
                    ref
                        .read(onboardingFlowProvider.notifier)
                        .setCommitNights(nights - 1);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (nights ?? 3) > 1
                        ? AppPalette.surfaceWhite
                        : AppPalette.neutral100.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: Icon(Icons.remove_rounded,
                      size: 20,
                      color: (nights ?? 3) > 1
                          ? AppPalette.deepNavy
                          : AppPalette.neutral400),
                ),
              ),
              const SizedBox(width: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) {
                  return ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: Text(
                  '${nights ?? 3}',
                  key: ValueKey(nights),
                  style: context.appText.h1.copyWith(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.deepNavy,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  if (nights != null && nights < 7) {
                    HapticFeedback.selectionClick();
                    ref
                        .read(onboardingFlowProvider.notifier)
                        .setCommitNights(nights + 1);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (nights ?? 3) < 7
                        ? AppPalette.surfaceWhite
                        : AppPalette.neutral100.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.border),
                  ),
                  child: Icon(Icons.add_rounded,
                      size: 20,
                      color: (nights ?? 3) < 7
                          ? AppPalette.deepNavy
                          : AppPalette.neutral400),
                ),
              ),
            ],
          ),
          Text('days a week',
              style: context.appText.bodyStrong
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 14),

          // Encouragement text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _commitEncouragement(nights ?? 3),
              key: ValueKey(nights),
              style: context.appText.small.copyWith(
                color: AppPalette.successMint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Sign with your finger',
              style: context.appText.small.copyWith(
                color: AppPalette.neutral500,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppPalette.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasSigned ? AppPalette.primary : AppPalette.border,
                width: hasSigned ? 2 : 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                Offset clamp(Offset pos) => Offset(
                      pos.dx.clamp(0, constraints.maxWidth),
                      pos.dy.clamp(0, constraints.maxHeight),
                    );
                return GestureDetector(
                  onPanStart: (d) =>
                      setState(() => _signaturePoints.add(clamp(d.localPosition))),
                  onPanUpdate: (d) =>
                      setState(() => _signaturePoints.add(clamp(d.localPosition))),
                  onPanEnd: (d) {
                    setState(() => _signaturePoints.add(Offset.infinite));
                    if (_signaturePoints.length > 20) {
                      ref
                          .read(onboardingFlowProvider.notifier)
                          .setSignature('signed');
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: CustomPaint(
                      painter: _SignaturePainter(
                          points: _signaturePoints, color: AppPalette.deepNavy),
                      size: Size.infinite,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_signaturePoints.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _signaturePoints.clear()),
              child: Text('Clear',
                  style: context.appText.caption.copyWith(
                    color: AppPalette.primary,
                    fontWeight: FontWeight.w700,
                  )),
            ),
        ],
      ),
      ctaLabel: "I'm committed",
      onCta: widget.onNext,
      ctaEnabled: nights != null && hasSigned,
    );
  }

  String _commitEncouragement(int n) {
    switch (n) {
      case 1:
        return 'One day — great start!';
      case 2:
        return 'Two days — building the habit!';
      case 3:
        return 'Three days — solid routine!';
      case 4:
        return 'Four days — you are on a roll!';
      case 5:
        return 'Five days — serious commitment!';
      case 6:
        return 'Six days — almost every day!';
      case 7:
        return 'Every day — legendary! 🔥';
      default:
        return 'A great commitment!';
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  _SignaturePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}

// ══════════════════════════════════════════════════════════════
// Step: Meal Reminder – ListWheelScrollView time picker
// ══════════════════════════════════════════════════════════════

class _MealReminderStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _MealReminderStep({required this.onNext});

  @override
  ConsumerState<_MealReminderStep> createState() => _MealReminderStepState();
}

class _MealReminderStepState extends ConsumerState<_MealReminderStep> {
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  int _hour = 17;
  int _minute = 6; // index: 6 * 5 = 30

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(
      onboardingFlowProvider.select((s) => s.data.reminderDays),
    );

    // Sunday first: S M T W T F S → day numbers 0,1,2,3,4,5,6
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final dayNumbers = [0, 1, 2, 3, 4, 5, 6]; // 0=Sun,1=Mon,...6=Sat

    return _StepLayout(
      title: 'Nudge before the crash?',
      subtitle: "We’ll ping when it’s time to order or grab food — not after you’re hangry.",
      mascotReaction: 'Timely beats hangry.',
      content: Column(
        children: [
          const SizedBox(height: 8),
          // Time picker
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppPalette.surfaceWhite,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Pick your reminder time',
                    style: context.appText.bodyStrong
                        .copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hour wheel
                      SizedBox(
                        width: 80,
                        child: _TimeWheel(
                          controller: _hourController,
                          itemCount: 24,
                          labelBuilder: (i) => i.toString().padLeft(2, '0'),
                          onChanged: (i) {
                            setState(() => _hour = i);
                            HapticFeedback.selectionClick();
                            ref
                                .read(onboardingFlowProvider.notifier)
                                .setReminderTime(_hour, _minute * 5);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(':',
                            style: context.appText.h1.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            )),
                      ),
                      // Minute wheel (step 5)
                      SizedBox(
                        width: 80,
                        child: _TimeWheel(
                          controller: _minuteController,
                          itemCount: 12,
                          labelBuilder: (i) =>
                              (i * 5).toString().padLeft(2, '0'),
                          onChanged: (i) {
                            setState(() => _minute = i);
                            HapticFeedback.selectionClick();
                            ref
                                .read(onboardingFlowProvider.notifier)
                                .setReminderTime(_hour, _minute * 5);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Day selector – Sunday first
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final dayNum = dayNumbers[i];
              final isSelected = days.contains(dayNum);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final newDays = List<int>.from(days);
                  if (isSelected) {
                    newDays.remove(dayNum);
                  } else {
                    newDays.add(dayNum);
                  }
                  ref
                      .read(onboardingFlowProvider.notifier)
                      .setReminderDays(newDays);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppPalette.deepNavy
                        : AppPalette.surfaceWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? AppPalette.deepNavy : AppPalette.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(dayLabels[i],
                      style: context.appText.smallStrong.copyWith(
                        color: isSelected ? Colors.white : AppPalette.deepNavy,
                      )),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // Coin reward badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppPalette.sunRewards.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: AppPalette.sunRewards, size: 20),
                const SizedBox(width: 8),
                Text('Turn on notifications for proactive nudges',
                    style: context.appText.caption.copyWith(
                      color: AppPalette.deepNavy,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
      ctaLabel: 'Set my reminder',
      onCta: () {
        ref
            .read(onboardingFlowProvider.notifier)
            .setReminderTime(_hour, _minute * 5);
        widget.onNext();
      },
      ctaEnabled: true,
    );
  }
}

/// iOS-style drum roller time wheel using ListWheelScrollView.
class _TimeWheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onChanged;

  const _TimeWheel({
    required this.controller,
    required this.itemCount,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Center highlight band
        Center(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppPalette.neutral100,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        // Wheel
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 48,
          physics: const FixedExtentScrollPhysics(),
          diameterRatio: 1.8,
          magnification: 1.15,
          useMagnifier: true,
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, i) {
              return Center(
                child: Text(
                  labelBuilder(i),
                  style: context.appText.h2.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppPalette.deepNavy,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step: Emotional Win – Bold value showcase
// ══════════════════════════════════════════════════════════════

class _EmotionalWinStep extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _EmotionalWinStep({required this.onNext});

  @override
  ConsumerState<_EmotionalWinStep> createState() => _EmotionalWinStepState();
}

class _EmotionalWinStepState extends ConsumerState<_EmotionalWinStep>
    with TickerProviderStateMixin {
  late final AnimationController _countAnim;

  @override
  void initState() {
    super.initState();
    _countAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _countAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingFlowProvider).data;
    final nights = data.commitNights ?? 3;
    final time = data.timeAvailableMin ?? 20;
    final name = data.squirrelName ?? 'Autopilot';
    final vibes = data.mealVibes;

    final targetDay = DateTime.now().add(const Duration(days: 3));
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final targetDayName = dayNames[targetDay.weekday - 1];

    return _StepLayout(
      title: 'Your week, pre-thought',
      subtitle: '$name is tuned to your calendar, travel, and goals.',
      mascotReaction: "You're going to crush this!",
      content: AnimatedBuilder(
        animation: _countAnim,
        builder: (context, _) {
          final t = Curves.easeOutQuart.transform(_countAnim.value);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 4),

                // ── Hero Plan Card (dark) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    color: AppPalette.deepNavy,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.deepNavy.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Progress ring + hero number ──
                      SizedBox(
                        width: 116,
                        height: 116,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ring
                            SizedBox(
                              width: 112,
                              height: 112,
                              child: CircularProgressIndicator(
                                value: (nights / 7) * t,
                                strokeWidth: 7,
                                color: AppPalette.primary,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.08),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            // Number
                            Text(
                              '${(nights * t).round()}',
                              style: context.appText.h1.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'days with a plan this week',
                        style: context.appText.bodyStrong.copyWith(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Divider
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 14),

                      // ── Stat rows with staggered entrance ──
                      _buildStatRow(
                        context,
                        Icons.timer_rounded,
                        'Under ${(time * t).round()} min',
                        'per meal window',
                        AppPalette.successMint,
                        0.15,
                      ),
                      _buildStatRow(
                        context,
                        Icons.track_changes_rounded,
                        '${vibes.length} ${vibes.length > 1 ? 'goals' : 'goal'}',
                        'aligned to you',
                        AppPalette.sunRewards,
                        0.3,
                      ),
                      _buildStatRow(
                        context,
                        Icons.local_fire_department_rounded,
                        'By ${targetDayName.substring(0, 3)}',
                        'first streak',
                        AppPalette.primary,
                        0.45,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Trust icons ──
                Opacity(
                  opacity: Interval(0.55, 1.0, curve: Curves.easeOut)
                      .transform(_countAnim.value),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTrustIcon(
                          context, Icons.lock_outline_rounded, 'Private'),
                      _buildTrustIcon(
                          context, Icons.block_rounded, 'No ads'),
                      _buildTrustIcon(
                          context, Icons.tune_rounded, 'Your control'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
      ctaLabel: "Let's make it happen",
      onCta: widget.onNext,
      ctaEnabled: true,
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
    double delay,
  ) {
    final stagger =
        Interval(delay, (delay + 0.55).clamp(0, 1), curve: Curves.easeOutCubic);
    final st = stagger.transform(_countAnim.value);
    return Transform.translate(
      offset: Offset(20 * (1 - st), 0),
      child: Opacity(
        opacity: st,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: context.appText.bodyStrong.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: context.appText.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustIcon(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppPalette.neutral400),
        const SizedBox(height: 5),
        Text(
          label,
          style: context.appText.caption.copyWith(
            color: AppPalette.neutral400,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
