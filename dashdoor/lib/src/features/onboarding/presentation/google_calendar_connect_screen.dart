import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/mascot_widget.dart';
import '../../integrations/state/calendar_connection_provider.dart';
import 'extended_onboarding_screen.dart';

/// OAuth via Composio (Google Calendar): backend returns a redirect URL; we poll until ACTIVE.
class GoogleCalendarConnectScreen extends ConsumerStatefulWidget {
  const GoogleCalendarConnectScreen({super.key});

  @override
  ConsumerState<GoogleCalendarConnectScreen> createState() =>
      _GoogleCalendarConnectScreenState();
}

class _GoogleCalendarConnectScreenState
    extends ConsumerState<GoogleCalendarConnectScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarConnectionProvider.notifier).refreshStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(calendarConnectionProvider.notifier).refreshStatus();
    }
  }

  void _goToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ExtendedOnboardingScreen(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cal = ref.watch(calendarConnectionProvider);
    final text = context.appText;

    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _goToOnboarding();
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppPalette.deepNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: MascotWidget(
                  state: MascotState.wave,
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Connect Google Calendar',
                style: text.h2.copyWith(
                  color: AppPalette.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We use Composio to link your calendar securely. You sign in with Google in the browser; we never see your password.',
                style: text.body.copyWith(
                  color: AppPalette.neutral500,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _StatusCard(state: cal),
              const Spacer(),
              if (cal.phase == CalendarLinkPhase.error && cal.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    cal.errorMessage!,
                    style: text.small.copyWith(color: AppPalette.urgency),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton(
                onPressed: cal.isConnected
                    ? _goToOnboarding
                    : (cal.phase == CalendarLinkPhase.loading ||
                            cal.phase == CalendarLinkPhase.openingBrowser ||
                            cal.phase == CalendarLinkPhase.polling
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(calendarConnectionProvider.notifier)
                                .startLinkFlow();
                          }),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  cal.isConnected
                      ? 'Continue'
                      : cal.phase == CalendarLinkPhase.polling
                          ? 'Waiting for Google…'
                          : cal.phase == CalendarLinkPhase.loading ||
                                  cal.phase == CalendarLinkPhase.openingBrowser
                              ? 'Opening…'
                              : 'Connect Google Calendar',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: cal.phase == CalendarLinkPhase.loading ||
                        cal.phase == CalendarLinkPhase.openingBrowser ||
                        cal.phase == CalendarLinkPhase.polling
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        _goToOnboarding();
                      },
                child: Text(
                  'Skip for now',
                  style: text.bodyStrong.copyWith(
                    color: AppPalette.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final CalendarConnectionState state;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    final IconData icon;
    final String title;
    final String subtitle;
    final Color accent;

    if (state.isConnected) {
      icon = Icons.check_circle_rounded;
      title = 'Calendar linked';
      subtitle = 'We can read busy times to suggest meals around your schedule.';
      accent = AppPalette.successMint;
    } else if (state.phase == CalendarLinkPhase.polling) {
      icon = Icons.sync_rounded;
      title = 'Finish in the browser';
      subtitle =
          'Complete Google sign-in, then return here — we detect the connection automatically.';
      accent = AppPalette.primary;
    } else {
      icon = Icons.calendar_month_rounded;
      title = 'Not connected yet';
      subtitle =
          'Recommended if your week changes often — travel and meetings shape suggestions.';
      accent = AppPalette.neutral400;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
        boxShadow: [
          BoxShadow(
            color: AppPalette.deepNavy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppPalette.deepNavy, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.h3.copyWith(
                    color: AppPalette.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: text.small.copyWith(
                    color: AppPalette.neutral500,
                    height: 1.4,
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
