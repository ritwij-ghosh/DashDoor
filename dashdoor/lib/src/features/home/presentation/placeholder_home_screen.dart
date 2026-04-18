import 'package:flutter/material.dart';

import 'home_chat_screen.dart';

/// Post-onboarding home entry point.
///
/// The name is retained for legacy navigation targets (setup + challenge
/// screens already push `PlaceholderHomeScreen`); the actual experience is the
/// chat-first [HomeChatScreen].
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeChatScreen();
}
