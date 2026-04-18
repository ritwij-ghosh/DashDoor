import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/revenuecat_service.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../home/data/gamification_repository.dart';
import '../state/onboarding_state.dart';
import 'three_day_challenge_screen.dart';
import 'personalizing_plan_screen.dart';

/// 4-step paywall funnel with narrative conversion.
class PaywallFunnelScreen extends ConsumerStatefulWidget {
  const PaywallFunnelScreen({super.key});

  @override
  ConsumerState<PaywallFunnelScreen> createState() =>
      _PaywallFunnelScreenState();
}

class _PaywallFunnelScreenState extends ConsumerState<PaywallFunnelScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _sendReminder = true;
  bool _purchasing = false;
  Package? _monthlyPackage;
  Package? _annualPackage;
  Package? _selectedPackage;
  late final PageController _pageController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final rc = ref.read(revenueCatServiceProvider);
    final offerings = await rc.getOfferings();
    if (offerings?.current != null && mounted) {
      final packages = offerings!.current!.availablePackages;
      setState(() {
        for (final pkg in packages) {
          if (pkg.packageType == PackageType.monthly) {
            _monthlyPackage = pkg;
          } else if (pkg.packageType == PackageType.annual) {
            _annualPackage = pkg;
          }
        }
        // Default to annual if available, else monthly
        _selectedPackage = _annualPackage ?? _monthlyPackage;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
  }

  void _dismiss() {
    ref.read(paywallControllerProvider.notifier).dismiss();
    // Route to 3-day challenge
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ThreeDayChallengeScreen(),
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(opacity: a, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _startTrial() async {
    if (_purchasing) return;
    final package = _selectedPackage;
    if (package == null) {
      // No offering loaded – fall through to navigate anyway so the UX
      // isn't broken while RC is being configured.
      _fallbackStartTrial();
      return;
    }

    setState(() => _purchasing = true);
    HapticFeedback.heavyImpact();

    final rc = ref.read(revenueCatServiceProvider);
    final result = await rc.purchasePackage(package);

    if (!mounted) return;
    setState(() => _purchasing = false);

    if (result.isCancelled) {
      // User dismissed the payment sheet – just stay here, nothing to show.
      return;
    }

    if (result.isError) {
      // Show a contextual error snackbar.
      _showPurchaseError(result.errorMessage!);
      return;
    }

    // Purchase succeeded – update local state
    ref.read(paywallControllerProvider.notifier).startTrial();
    ref.read(onboardingFlowProvider.notifier).setPaywallCompleted(true);
    ref.read(subscriptionInfoProvider.notifier).refresh();

    // Persist subscription to our backend
    final repo = ref.read(gamificationRepositoryProvider);
    final now = DateTime.now();
    repo.updateSubscription({
      'status': 'trial',
      'plan': package.packageType == PackageType.annual ? 'annual' : 'monthly',
      'trialStartDate': now.toIso8601String(),
      'trialEndDate': now.add(const Duration(days: 7)).toIso8601String(),
    });
    // Award starter coins
    repo.earnCoins(
      amount: 300,
      type: 'EARN_TRIAL_BONUS',
      idempotencyKey: 'trial_bonus_${now.millisecondsSinceEpoch}',
    );
    ref.invalidate(coinsProvider);

    _navigateToHome();
  }

  /// Show a purchase error message as a themed bottom snackbar.
  void _showPurchaseError(String message) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppPalette.deepNavy,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppPalette.coralUrgency.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppPalette.coralUrgency,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fallback for when RevenueCat offerings haven't loaded yet.
  void _fallbackStartTrial() {
    HapticFeedback.heavyImpact();
    ref.read(paywallControllerProvider.notifier).startTrial();
    ref.read(onboardingFlowProvider.notifier).setPaywallCompleted(true);

    final repo = ref.read(gamificationRepositoryProvider);
    final now = DateTime.now();
    repo.updateSubscription({
      'status': 'trial',
      'plan': 'annual',
      'trialStartDate': now.toIso8601String(),
      'trialEndDate': now.add(const Duration(days: 7)).toIso8601String(),
    });
    repo.earnCoins(
      amount: 300,
      type: 'EARN_TRIAL_BONUS',
      idempotencyKey: 'trial_bonus_${now.millisecondsSinceEpoch}',
    );
    ref.invalidate(coinsProvider);

    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PersonalizingPlanScreen(),
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
    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final isActive = i == _currentStep;
                  final isDone = i < _currentStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isActive ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppPalette.primary
                            : isDone
                                ? AppPalette.primary.withOpacity(0.4)
                                : AppPalette.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PaywallStep1(
                    onContinue: () => _goToStep(1),
                    onDismiss: _dismiss,
                  ),
                  _PaywallStep2(
                    sendReminder: _sendReminder,
                    onToggleReminder: (v) =>
                        setState(() => _sendReminder = v),
                    onContinue: () => _goToStep(2),
                  ),
                  _PaywallStep3(
                    onContinue: () => _goToStep(3),
                  ),
                  _PaywallStep4(
                    onStartTrial: _startTrial,
                    onSkip: _dismiss,
                    pulseController: _pulseController,
                    purchasing: _purchasing,
                    monthlyPackage: _monthlyPackage,
                    annualPackage: _annualPackage,
                    onError: _showPurchaseError,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Step 1: "7 days free" offer
// ──────────────────────────────────────────────────────────────────

class _PaywallStep1 extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const _PaywallStep1({
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Premium icon
          FadeInEntrance(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppPalette.sunRewards, AppPalette.primary],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInEntrance(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Start your\nNibbl journey',
              textAlign: TextAlign.center,
              style: context.appText.h1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInEntrance(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Get nutrition-optimized options, smarter pantry\ntracking, and Cook Mode upgrades.',
              textAlign: TextAlign.center,
              style: context.appText.body.copyWith(
                color: AppPalette.neutral500,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Feature list
          FadeInEntrance(
            delay: const Duration(milliseconds: 400),
            child: Column(
              children: [
                _buildFeatureRow(context, Icons.fitness_center_rounded,
                    'Nutrition Boost toggle', AppPalette.primary),
                const SizedBox(height: 14),
                _buildFeatureRow(context, Icons.auto_awesome_rounded,
                    'Smart pantry auto-tracking', AppPalette.successMint),
                const SizedBox(height: 14),
                _buildFeatureRow(context, Icons.restaurant_menu_rounded,
                    'Cook Mode upgrades', AppPalette.sunRewards),
                const SizedBox(height: 14),
                _buildFeatureRow(context, Icons.remove_red_eye_rounded,
                    'Expiry Vision prioritization', AppPalette.primary),
              ],
            ),
          ),
          const Spacer(flex: 3),
          // CTA
          FadeInEntrance(
            delay: const Duration(milliseconds: 500),
            child: BounceInteraction(
              onTap: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
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
                  'Start trial',
                  textAlign: TextAlign.center,
                  style: context.appText.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInEntrance(
            delay: const Duration(milliseconds: 600),
            child: GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Not now',
                  style: context.appText.body.copyWith(
                    color: AppPalette.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: bottomPad + 8),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: context.appText.bodyStrong.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Step 2: Anxiety remover
// ──────────────────────────────────────────────────────────────────

class _PaywallStep2 extends StatelessWidget {
  final bool sendReminder;
  final ValueChanged<bool> onToggleReminder;
  final VoidCallback onContinue;

  const _PaywallStep2({
    required this.sendReminder,
    required this.onToggleReminder,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          FadeInEntrance(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppPalette.successMint.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppPalette.successMint,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInEntrance(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Cancel anytime',
              textAlign: TextAlign.center,
              style: context.appText.h1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeInEntrance(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'We\'ll remind you 2 days before\nyour trial ends.',
              textAlign: TextAlign.center,
              style: context.appText.body.copyWith(
                color: AppPalette.neutral500,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Reminder toggle
          FadeInEntrance(
            delay: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppPalette.sunRewards.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppPalette.sunRewards,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Send my reminder',
                      style: context.appText.bodyStrong.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: sendReminder,
                    onChanged: onToggleReminder,
                    activeColor: AppPalette.successMint,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInEntrance(
            delay: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.successMint.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppPalette.successMint,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No charge today. You won\'t be billed until the trial ends.',
                      style: context.appText.small.copyWith(
                        color: AppPalette.deepNavy,
                        fontWeight: FontWeight.w600,
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
            delay: const Duration(milliseconds: 500),
            child: BounceInteraction(
              onTap: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppPalette.deepNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Continue',
                  textAlign: TextAlign.center,
                  style: context.appText.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: bottomPad + 24),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Step 3: Bonus Starter Pack
// ──────────────────────────────────────────────────────────────────

class _PaywallStep3 extends StatelessWidget {
  final VoidCallback onContinue;
  const _PaywallStep3({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          FadeInEntrance(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.sunRewards, Color(0xFFFF8A65)],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.sunRewards.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInEntrance(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Starter Pack\nincluded today',
              textAlign: TextAlign.center,
              style: context.appText.h1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Bonus items
          FadeInEntrance(
            delay: const Duration(milliseconds: 400),
            child: Column(
              children: [
                _buildBonusItem(
                  context,
                  Icons.monetization_on_rounded,
                  '+300 Nibbl Coins',
                  'Spend on upgrades and cosmetics',
                  AppPalette.sunRewards,
                ),
                const SizedBox(height: 16),
                _buildBonusItem(
                  context,
                  Icons.checkroom_rounded,
                  '1 Exclusive Squirrel Outfit',
                  'Chef hat for your kitchen buddy',
                  AppPalette.primary,
                ),
                const SizedBox(height: 16),
                _buildBonusItem(
                  context,
                  Icons.fitness_center_rounded,
                  'Nutrition Boost Recipe Toggles',
                  'Optimize nutrition in every meal',
                  AppPalette.successMint,
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
          // CTA
          FadeInEntrance(
            delay: const Duration(milliseconds: 500),
            child: BounceInteraction(
              onTap: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.sunRewards, AppPalette.primary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'Claim Starter Pack',
                  textAlign: TextAlign.center,
                  style: context.appText.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: bottomPad + 24),
        ],
      ),
    );
  }

  Widget _buildBonusItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
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
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Step 4: Final Checkout
// ──────────────────────────────────────────────────────────────────

class _PaywallStep4 extends StatelessWidget {
  final VoidCallback onStartTrial;
  final VoidCallback onSkip;
  final AnimationController pulseController;
  final bool purchasing;
  final Package? monthlyPackage;
  final Package? annualPackage;
  final void Function(String message) onError;

  const _PaywallStep4({
    required this.onStartTrial,
    required this.onSkip,
    required this.pulseController,
    required this.onError,
    this.purchasing = false,
    this.monthlyPackage,
    this.annualPackage,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final trialEnd = DateTime.now().add(const Duration(days: 7));
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final endDate = '${months[trialEnd.month - 1]} ${trialEnd.day}, ${trialEnd.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          FadeInEntrance(
            child: const MascotWidget(
              state: MascotState.chef,
              width: 100,
              height: 100,
            ),
          ),
          const SizedBox(height: 24),
          // Pricing card
          FadeInEntrance(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Nibbl Plus',
                    style: context.appText.h2.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthlyPackage?.storeProduct.currencyCode ?? '\$',
                        style: context.appText.h3.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppPalette.neutral500,
                        ),
                      ),
                      Text(
                        monthlyPackage?.storeProduct.priceString.replaceAll(RegExp(r'[^0-9.]'), '') ?? '4.99',
                        style: context.appText.h1.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/mo',
                        style: context.appText.body.copyWith(
                          color: AppPalette.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.successMint.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '7-day trial included',
                      style: context.appText.smallStrong.copyWith(
                        color: AppPalette.successMint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppPalette.creamBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppPalette.neutral500,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Trial ends on $endDate',
                            style: context.appText.small.copyWith(
                              color: AppPalette.neutral500,
                              fontWeight: FontWeight.w600,
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
          const SizedBox(height: 16),
          // Annual option
          FadeInEntrance(
            delay: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPalette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Annual Plan',
                          style: context.appText.bodyStrong.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${annualPackage?.storeProduct.priceString ?? '\$29.99'}/year — save 50%',
                          style: context.appText.small.copyWith(
                            color: AppPalette.successMint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.sunRewards.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'BEST VALUE',
                      style: context.appText.caption.copyWith(
                        color: AppPalette.sunRewards,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 3),
          // Start trial CTA
          FadeInEntrance(
            delay: const Duration(milliseconds: 400),
            child: AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                final scale = 1.0 + pulseController.value * 0.02;
                return Transform.scale(scale: scale, child: child);
              },
              child: BounceInteraction(
                onTap: purchasing ? () {} : onStartTrial,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: purchasing
                        ? AppPalette.deepNavy.withOpacity(0.6)
                        : AppPalette.deepNavy,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.deepNavy.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: purchasing
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : Text(
                          'Start my trial',
                          textAlign: TextAlign.center,
                          style: context.appText.bodyStrong.copyWith(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onSkip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    'Skip this offer',
                    style: context.appText.small.copyWith(
                      color: AppPalette.neutral400,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppPalette.neutral400,
                    ),
                  ),
                ),
              ),
              Text('·', style: context.appText.small.copyWith(color: AppPalette.neutral200)),
              GestureDetector(
                onTap: () async {
                  final result = await RevenueCatService.instance.restorePurchases();
                  if (result.success && result.customerInfo != null) {
                    final sub = RevenueCatService.instance
                        .parseCustomerInfo(result.customerInfo);
                    if (sub.isPlus) {
                      onStartTrial(); // will navigate home
                    } else {
                      onError('No active subscription found for this account.');
                    }
                  } else if (result.errorMessage != null) {
                    onError(result.errorMessage!);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    'Restore purchases',
                    style: context.appText.small.copyWith(
                      color: AppPalette.neutral400,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppPalette.neutral400,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: bottomPad + 8),
        ],
      ),
    );
  }
}
