import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/chat_message.dart';

class QuickReplyChips extends StatelessWidget {
  const QuickReplyChips({
    super.key,
    required this.replies,
    required this.onTap,
  });

  final List<QuickReply> replies;
  final void Function(QuickReply reply) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 44, right: 12),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = replies[i];
          return _Chip(reply: r, onTap: () => onTap(r));
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.reply, required this.onTap});
  final QuickReply reply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppPalette.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppPalette.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded,
                size: 14, color: AppPalette.primary),
            const SizedBox(width: 6),
            Text(
              reply.label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppPalette.deepNavy,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
