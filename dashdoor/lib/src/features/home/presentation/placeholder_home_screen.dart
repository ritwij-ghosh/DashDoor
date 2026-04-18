import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// Temporary home after onboarding + setup (no product UI yet).
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      appBar: AppBar(
        title: Text('DashDoor', style: context.appText.h2),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'You’re in. Backend isn’t wired yet — this is a shell after setup.',
            textAlign: TextAlign.center,
            style: context.appText.body.copyWith(color: AppPalette.neutral500),
          ),
        ),
      ),
    );
  }
}
