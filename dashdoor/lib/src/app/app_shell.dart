import 'package:flutter/material.dart';

import '../features/splash/presentation/splash_screen.dart';

/// Entry after [MaterialApp] — cold-open splash → value pitch → onboarding.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
