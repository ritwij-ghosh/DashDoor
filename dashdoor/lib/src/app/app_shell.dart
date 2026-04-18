import 'package:flutter/material.dart';

import '../features/splash/presentation/splash_screen.dart';

/// Entry after [MaterialApp] — starts the same cold-open flow as What2Eat (splash → onboarding).
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
