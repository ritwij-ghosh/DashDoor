import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'chat_bubble.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AssistantContentWrapper(
      child: Container(
        margin: const EdgeInsets.only(right: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceWhite,
          border: Border.all(color: AppPalette.border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.deepNavy.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    child: _Dot(phase: (_ctrl.value - i * 0.15) % 1.0),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.phase});
  final double phase;

  @override
  Widget build(BuildContext context) {
    final t = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.0, 1.0);
    final scale = 0.75 + 0.45 * t;
    final alpha = 0.35 + 0.55 * t;
    return Transform.translate(
      offset: Offset(0, -3 * t),
      child: Container(
        width: 8 * scale,
        height: 8 * scale,
        decoration: BoxDecoration(
          color: AppPalette.deepNavy.withValues(alpha: alpha),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
