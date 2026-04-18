import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../home/presentation/placeholder_home_screen.dart';
import '../state/setup_controller.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_pageController.page == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ref.read(setupControllerProvider.notifier).setStep(1);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PlaceholderHomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _QuickStockStep(onContinue: _nextPage),
          _CalibrateStep(onContinue: _nextPage),
        ],
      ),
    );
  }
}

class _CalibrateStep extends ConsumerWidget {
  final Future<void> Function() onContinue;

  const _CalibrateStep({required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final vibes = [
      ('Healthy', '🥗'),
      ('Asian', '🍜'),
      ('Comfort', '🍝'),
      ('Spicy', '🌶️'),
      ('Italian', '🍕'),
      ('Mexican', '🌮'),
    ];

    return Stack(
      children: [
        // ── Scrollable content ──────────────────────────────
        Column(
          children: [
            // Top header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SetupPaginationDots(currentIndex: 1),
                  TextButton(
                    onPressed: () {
                      // TODO: Skip
                    },
                    child: Text(
                      'Skip',
                      style: context.appText.bodyStrong.copyWith(
                        color: AppPalette.neutral500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title area with mascot ────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Let's calibrate\nyour autopilot",
                                style: context.appText.h1.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Tell us what you like — we'll handle the decisions.",
                                style: context.appText.body.copyWith(
                                  color: AppPalette.neutral500,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const MascotWidget(
                          state: MascotState.chef,
                          width: 72,
                          height: 72,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Section: How much time? ──────────
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: AppPalette.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'How much time do you have?',
                          style: context.appText.bodyStrong.copyWith(
                            fontSize: 17,
                            color: AppPalette.deepNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Three large time cards ───────────
                    _TimeCard(
                      minutes: '15',
                      title: 'Quick & Easy',
                      subtitle: 'Lightning-fast meals for busy nights',
                      mascotState: MascotState.happy,
                      accentColor: const Color(0xFFFF6B6B),
                      gradientColors: const [
                        Color(0xFFFF6B6B),
                        Color(0xFFFF8E53)
                      ],
                      isSelected: state.selectedTimeLimit == '15',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.setTimeLimit('15');
                      },
                    ),
                    const SizedBox(height: 12),
                    _TimeCard(
                      minutes: '30',
                      title: 'Weeknight Classic',
                      subtitle: 'The sweet spot — flavorful & doable',
                      mascotState: MascotState.chef,
                      accentColor: AppPalette.sunRewards,
                      gradientColors: const [
                        Color(0xFFFFD93D),
                        Color(0xFFFFA726)
                      ],
                      isSelected: state.selectedTimeLimit == '30',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.setTimeLimit('30');
                      },
                    ),
                    const SizedBox(height: 12),
                    _TimeCard(
                      minutes: '60',
                      title: 'Slow & Savory',
                      subtitle: 'Cooking is therapy — take your time',
                      mascotState: MascotState.idle,
                      accentColor: AppPalette.successMint,
                      gradientColors: const [
                        Color(0xFF6BCB77),
                        Color(0xFF4CAF50)
                      ],
                      isSelected: state.selectedTimeLimit == '60',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.setTimeLimit('60');
                      },
                    ),

                    const SizedBox(height: 36),

                    // ── Section: What's your vibe? ───────
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu_rounded,
                            color: AppPalette.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "What's the vibe?",
                          style: context.appText.bodyStrong.copyWith(
                            fontSize: 17,
                            color: AppPalette.deepNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pick as many as you like',
                      style: context.appText.small.copyWith(
                        color: AppPalette.neutral400,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Vibe chips ────────────────────────
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: vibes.map((v) {
                        final isSelected = controller.isVibeSelected(v.$1);
                        return _VibeChip(
                          label: v.$1,
                          emoji: v.$2,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            controller.toggleVibe(v.$1);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // ── XP Bonus Card ────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppPalette.sunRewards.withOpacity(0.12),
                            AppPalette.sunRewards.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppPalette.sunRewards.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD93D), Color(0xFFFFA726)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppPalette.sunRewards.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'XP Bonus Available',
                                  style: context.appText.bodyStrong.copyWith(
                                    fontSize: 15,
                                    color: AppPalette.deepNavy,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Complete setup to earn your first 50 XP',
                                  style: context.appText.small.copyWith(
                                    color: AppPalette.neutral500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Space for the footer
                    SizedBox(height: 140 + bottomPad),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Footer CTA ─────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 28, 24, bottomPad + 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppPalette.creamBackground.withOpacity(0),
                  AppPalette.creamBackground.withOpacity(0.85),
                  AppPalette.creamBackground,
                ],
                stops: const [0, 0.25, 0.5],
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 62,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF4D2E), Color(0xFFFF8A65)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => onContinue(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Start Cooking",
                        style: context.appText.bodyStrong.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 22, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String minutes;
  final String title;
  final String subtitle;
  final MascotState mascotState;
  final Color accentColor;
  final List<Color> gradientColors;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeCard({
    required this.minutes,
    required this.title,
    required this.subtitle,
    required this.mascotState,
    required this.accentColor,
    required this.gradientColors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
        decoration: BoxDecoration(
          color: isSelected ? null : AppPalette.surfaceWhite,
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppPalette.neutral200.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.30),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: accentColor.withOpacity(0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ── Left: time hero + text ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time badge
                  Row(
                    children: [
                      Text(
                        minutes,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: isSelected ? Colors.white : AppPalette.deepNavy,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'min',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white.withOpacity(0.8)
                                : AppPalette.neutral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: context.appText.bodyStrong.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppPalette.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.appText.small.copyWith(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : AppPalette.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Right: mascot ──
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  MascotWidget(
                    state: mascotState,
                    width: 64,
                    height: 64,
                    animate: isSelected,
                  ),
                ],
              ),
            ),

            // ── Check indicator ──
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : AppPalette.neutral200,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: accentColor, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _VibeChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _VibeChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.primary : AppPalette.surfaceWhite,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppPalette.neutral200.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppPalette.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: isSelected ? Colors.white : AppPalette.deepNavy,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickStockStep extends ConsumerWidget {
  final Future<void> Function() onContinue;

  const _QuickStockStep({required this.onContinue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupControllerProvider);
    final allIngredients = ref.watch(allIngredientsProvider);
    final controller = ref.read(setupControllerProvider.notifier);

    // Group ingredients by category
    final categories = <String, List<Ingredient>>{};
    for (final ing in allIngredients) {
      if (state.searchQuery.isEmpty ||
          ing.name.toLowerCase().contains(state.searchQuery.toLowerCase())) {
        categories.putIfAbsent(ing.category, () => []).add(ing);
      }
    }

    return Stack(
      children: [
        Column(
          children: [
            // Top header: Dots on left, Skip on right
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SetupPaginationDots(currentIndex: 0),
                  TextButton(
                    onPressed: () {
                      // TODO: Skip
                    },
                    child: Text(
                      'Skip',
                      style: context.appText.bodyStrong.copyWith(
                        color: AppPalette.neutral500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Header Image Placeholder
                  SliverToBoxAdapter(
                    child: Container(
                      height: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/onboarding-3.png'), // Placeholder
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppPalette.surfaceWhite,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department, color: AppPalette.sunRewards, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+50 XP',
                                    style: context.appText.smallStrong.copyWith(
                                      color: AppPalette.deepNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Title & Subtitle
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            'Quick-Stock Your Pantry',
                            textAlign: TextAlign.center,
                            style: context.appText.h1.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: context.appText.body.copyWith(
                                color: AppPalette.neutral700,
                                fontSize: 16,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'Select '),
                                TextSpan(
                                  text: '5 ingredients',
                                  style: TextStyle(
                                    color: AppPalette.sunRewards,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: ' to unlock your first recipe recommendation.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Progress Card
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceWhite,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppPalette.sunRewards.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.inventory_2_rounded, color: AppPalette.sunRewards, size: 26),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: AppPalette.successMint,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.check, color: Colors.white, size: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROGRESS',
                                  style: context.appText.caption.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: AppPalette.neutral500,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${controller.selectedCount} of 5 Items',
                                  style: context.appText.bodyStrong.copyWith(
                                    fontSize: 18,
                                    color: AppPalette.deepNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 90,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (controller.selectedCount / 5).clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: AppPalette.neutral200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppPalette.sunRewards),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (v) => controller.setSearchQuery(v),
                          decoration: InputDecoration(
                            hintText: "What's in your fridge?",
                            prefixIcon: const Icon(Icons.search, color: AppPalette.neutral500),
                            fillColor: AppPalette.surfaceWhite,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(99),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Categories & Chips
                  ...categories.entries.map((entry) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                entry.key,
                                style: context.appText.caption.copyWith(
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.neutral500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: entry.value.map((ing) {
                                  final isSelected = controller.isIngredientSelected(ing.id);
                                  return _IngredientChip(
                                    ingredient: ing,
                                    isSelected: isSelected,
                                    onTap: () => controller.toggleIngredient(ing.id),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Bottom Spacing for footer
                  const SliverToBoxAdapter(child: SizedBox(height: 220)),
                ],
              ),
            ),
          ],
        ),

        // Footer
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppPalette.creamBackground.withOpacity(0),
                  AppPalette.creamBackground.withOpacity(0.9),
                  AppPalette.creamBackground,
                ],
                stops: const [0, 0.2, 0.4],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: controller.selectedCount < 5 ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Add ${5 - controller.selectedCount} more to unlock recommendations',
                      style: context.appText.body.copyWith(
                        color: AppPalette.neutral700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 68,
                  child: ElevatedButton(
                    onPressed: controller.selectedCount >= 5 ? () => onContinue() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.primary,
                      foregroundColor: AppPalette.deepNavy,
                      disabledBackgroundColor: AppPalette.neutral200,
                      disabledForegroundColor: AppPalette.neutral500,
                      elevation: controller.selectedCount >= 5 ? 12 : 0,
                      shadowColor: AppPalette.primary.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Continue",
                          style: context.appText.bodyStrong.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.deepNavy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward,
                          size: 22,
                          color: AppPalette.deepNavy,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // TODO: Skip
                  },
                  child: Text(
                    'Skip for now',
                    style: context.appText.bodyStrong.copyWith(
                      color: AppPalette.neutral500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupPaginationDots extends StatelessWidget {
  final int currentIndex;
  const _SetupPaginationDots({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 28 : 8,
          decoration: BoxDecoration(
            color: active ? AppPalette.sunRewards : AppPalette.neutral200,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _IngredientChip extends StatelessWidget {
  final Ingredient ingredient;
  final bool isSelected;
  final VoidCallback onTap;

  const _IngredientChip({
    required this.ingredient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.sunRewards : AppPalette.surfaceWhite,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(
            color: isSelected ? Colors.transparent : AppPalette.neutral200.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : AppPalette.sunRewards.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForIngredient(ingredient.id),
                size: 16,
                color: isSelected ? Colors.white : AppPalette.sunRewards,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              ingredient.name,
              style: TextStyle(
                color: isSelected ? Colors.white : AppPalette.deepNavy,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.close : Icons.add,
              size: 16,
              color: isSelected ? Colors.white : AppPalette.neutral500,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForIngredient(String id) {
    switch (id) {
      case 'eggs': return Icons.egg_rounded;
      case 'milk': return Icons.water_drop_rounded;
      case 'rice': return Icons.grain_rounded;
      case 'bread': return Icons.bakery_dining_rounded;
      case 'tomatoes': return Icons.fiber_manual_record_rounded;
      case 'onions': return Icons.eco_rounded;
      default: return Icons.restaurant_rounded;
    }
  }
}


