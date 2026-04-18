import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../onboarding/presentation/google_calendar_connect_screen.dart';

/// Same layout as the source app — OTP flow is local-only (no backend).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  late final AnimationController _heroAnim;

  bool _isCodeStep = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _heroAnim.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_loading) return;
    if (!_isCodeStep) {
      HapticFeedback.mediumImpact();
      setState(() => _isCodeStep = true);
      return;
    }

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GoogleCalendarConnectScreen(),
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: a,
                curve: Curves.easeOutQuart,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  void _backToIdentifier() {
    HapticFeedback.selectionClick();
    setState(() {
      _isCodeStep = false;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCode = _isCodeStep;

    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppPalette.primary.withValues(alpha: 0.08),
                    AppPalette.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppPalette.sunRewards.withValues(alpha: 0.06),
                    AppPalette.sunRewards.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  FadeInEntrance(
                    child: AnimatedBuilder(
                      animation: _heroAnim,
                      builder: (context, child) {
                        final dy = 6.0 * (0.5 - _heroAnim.value);
                        return Transform.translate(
                          offset: Offset(0, dy),
                          child: child,
                        );
                      },
                      child: const MascotWidget(
                        state: MascotState.wave,
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeInEntrance(
                    delay: const Duration(milliseconds: 200),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        isCode ? 'Check your inbox' : 'Welcome to Healthy Autopilot',
                        key: ValueKey(isCode),
                        textAlign: TextAlign.center,
                        style: context.appText.h1.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppPalette.deepNavy,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInEntrance(
                    delay: const Duration(milliseconds: 300),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        isCode
                            ? 'Enter the 6-digit code we just sent you.'
                            : 'Sign in or create an account to get started.',
                        key: ValueKey('sub_$isCode'),
                        textAlign: TextAlign.center,
                        style: context.appText.body.copyWith(
                          color: AppPalette.neutral500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeInEntrance(
                    delay: const Duration(milliseconds: 400),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: isCode ? _buildCodeCard() : _buildIdentifierCard(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInEntrance(
                    delay: const Duration(milliseconds: 500),
                    child: BounceInteraction(
                      onTap: _loading ? null : _onSubmit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 19),
                        decoration: BoxDecoration(
                          color: AppPalette.deepNavy,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.deepNavy.withValues(alpha: 0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _loading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : Text(
                                isCode ? 'Verify & Continue' : 'Send Code',
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
                  const SizedBox(height: 32),
                  FadeInEntrance(
                    delay: const Duration(milliseconds: 700),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.successMint.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: AppPalette.successMint,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Join people who stopped deciding meals at 9pm',
                            style: context.appText.caption.copyWith(
                              color: AppPalette.deepNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentifierCard() {
    return Container(
      key: const ValueKey('identifier'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMAIL OR PHONE',
            style: context.appText.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppPalette.neutral400,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            style: context.appText.bodyStrong.copyWith(
              color: AppPalette.deepNavy,
              fontSize: 17,
            ),
            decoration: InputDecoration(
              hintText: 'hello@example.com',
              hintStyle: context.appText.body.copyWith(
                color: AppPalette.neutral400,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 4, right: 12),
                child: Icon(
                  Icons.alternate_email_rounded,
                  color: AppPalette.neutral400,
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPalette.primary.withValues(alpha: 0.5),
                  AppPalette.sunRewards.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard() {
    return Container(
      key: const ValueKey('code'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VERIFICATION CODE',
            style: context.appText.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppPalette.neutral400,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            style: context.appText.h2.copyWith(
              fontWeight: FontWeight.w900,
              color: AppPalette.deepNavy,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: context.appText.h2.copyWith(
                color: AppPalette.neutral200,
                letterSpacing: 8,
              ),
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPalette.successMint.withValues(alpha: 0.5),
                  AppPalette.primary.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: _loading ? null : _backToIdentifier,
              child: Text(
                'Change email/phone',
                style: context.appText.smallStrong.copyWith(
                  color: AppPalette.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
