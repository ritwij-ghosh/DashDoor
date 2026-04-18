import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

import '../../auth/presentation/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background dot grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),

          // Decorative background icons
          const _BackgroundDecorations(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top header: Dots on left, Skip on right
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PaginationDots(currentIndex: _currentPage),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Skip',
                          style: context.appText.bodyStrong.copyWith(
                            color: AppPalette.neutral500,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _OnboardingStep1(),
                      _OnboardingStep2(),
                      _OnboardingStep3(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Footer CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < 2) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.primary,
                            foregroundColor: AppPalette.deepNavy,
                            elevation: 8,
                            shadowColor: AppPalette.primary.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == 0
                                    ? "Show me how"
                                    : "Sounds right — next",
                                style: context.appText.bodyStrong.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.deepNavy,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.arrow_forward,
                                size: 20,
                                color: AppPalette.deepNavy,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Built for packed calendars and weird travel days',
                        style: context.appText.small.copyWith(
                          color: AppPalette.neutral500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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

class _OnboardingStep3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Image Container with Floating Badges
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // The main image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/onboarding-3.png',
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Top-right: timely nudge
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _FloatingBadge(
                        icon: Icons.schedule_rounded,
                        iconColor: AppPalette.successMint,
                        label: 'Next gap',
                        value: 'Order by 12:15',
                      ),
                    ),

                    // Bottom-left: travel context
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: _FloatingBadge(
                        icon: Icons.flight_land_rounded,
                        iconColor: AppPalette.sunRewards,
                        label: 'Lands',
                        value: '8:40 PM',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Text Content below the card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: context.appText.h1.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.deepNavy,
                      height: 1.1,
                    ),
                    children: [
                      const TextSpan(text: 'Land tired, eat '),
                      TextSpan(
                        text: 'on purpose',
                        style: const TextStyle(color: AppPalette.sunRewards),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'When you touch down or step out of back-to-backs, we surface nearby meals and one-tap orders that still match your goals.',
                  textAlign: TextAlign.center,
                  style: context.appText.body.copyWith(
                    color: AppPalette.neutral700,
                    fontSize: 16,
                    height: 1.5,
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

class _OnboardingStep2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Image Container
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/onboarding-2.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Text Content below the card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  'Your calendar, decoded',
                  textAlign: TextAlign.center,
                  style: context.appText.h1.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppPalette.deepNavy,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Meetings stacked through lunch? Flight at 6am? We plan the next 8–12 hours so you are not guessing when hunger hits.',
                  textAlign: TextAlign.center,
                  style: context.appText.body.copyWith(
                    color: AppPalette.neutral700,
                    fontSize: 16,
                    height: 1.5,
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

class _OnboardingStep1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Image Container
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppPalette.surfaceWhite,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // The main image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/onboarding-1.png',
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Badges are hidden for Step 1, but logic is kept for future steps
                    /*
                    // Top-right "Saved" badge
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _FloatingBadge(
                        icon: Icons.savings_rounded,
                        iconColor: AppPalette.successMint,
                        label: 'Saved',
                        value: '\$12.50',
                      ),
                    ),

                    // Bottom-left "Achievement" badge
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: _FloatingBadge(
                        icon: Icons.emoji_events_rounded,
                        iconColor: AppPalette.sunRewards,
                        label: 'Achievement',
                        value: 'Fridge Hero',
                      ),
                    ),
                    */
                  ],
                ),
              ),
            ),
          ),

          // Text Content below the card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: context.appText.h1.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.deepNavy,
                      height: 1.1,
                    ),
                    children: [
                      const TextSpan(text: "Before you're hungry, "),
                      TextSpan(
                        text: 'a plan.',
                        style: const TextStyle(color: AppPalette.sunRewards),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Healthy Autopilot reads your rhythm — calendar blocks, travel, and where you are — then pushes timely picks and order links.',
                  textAlign: TextAlign.center,
                  style: context.appText.body.copyWith(
                    color: AppPalette.neutral700,
                    fontSize: 16,
                    height: 1.5,
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

class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _FloatingBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.appText.caption.copyWith(
                  color: AppPalette.neutral500,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: context.appText.smallStrong.copyWith(
                  color: AppPalette.deepNavy,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundDecorations extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    final color = AppPalette.sunRewards.withOpacity(0.2);
    return Stack(
      children: [
        Positioned(
          top: 60,
          left: 40,
          child: Transform.rotate(
            angle: -0.2,
            child: Icon(Icons.restaurant, size: 40, color: color),
          ),
        ),
        Positioned(
          bottom: 180,
          right: 40,
          child: Transform.rotate(
            angle: 0.3,
            child: Icon(Icons.bakery_dining, size: 48, color: color),
          ),
        ),
      ],
    );
  }
}

class _PaginationDots extends StatelessWidget {
  final int currentIndex;
  const _PaginationDots({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppPalette.neutral500.withOpacity(0.5);
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
