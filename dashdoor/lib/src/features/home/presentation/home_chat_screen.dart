import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/chat_message.dart';
import '../state/chat_controller.dart';
import 'widgets/alternatives_rail.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_composer.dart';
import 'widgets/day_plan_card.dart';
import 'widgets/quick_reply_chips.dart';
import 'widgets/typing_indicator.dart';

class HomeChatScreen extends ConsumerStatefulWidget {
  const HomeChatScreen({super.key});

  @override
  ConsumerState<HomeChatScreen> createState() => _HomeChatScreenState();
}

class _HomeChatScreenState extends ConsumerState<HomeChatScreen> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider);
    if (chat.messages.length != _lastMessageCount) {
      _lastMessageCount = chat.messages.length;
      _scheduleScrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppPalette.creamBackground,
      body: Stack(
        children: [
          const _BackdropGradient(),
          Column(
            children: [
              const _GlassAppBar(),
              Expanded(
                child: _ChatFeed(
                  messages: chat.messages,
                  suggestions: chat.suggestions,
                  scrollController: _scrollController,
                  onQuickReply: (r) =>
                      ref.read(chatControllerProvider.notifier).tapQuickReply(r),
                ),
              ),
              ChatComposer(
                onSend: (text) =>
                    ref.read(chatControllerProvider.notifier).sendUserText(text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackdropGradient extends StatelessWidget {
  const _BackdropGradient();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFE9E0),
                    AppPalette.creamBackground,
                  ],
                  stops: [0.0, 0.32],
                ),
              ),
            ),
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppPalette.primary.withValues(alpha: 0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -100,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppPalette.sunRewards.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassAppBar extends StatelessWidget {
  const _GlassAppBar();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: AppPalette.creamBackground.withValues(alpha: 0.55),
          padding: EdgeInsets.only(top: topPad + 6, bottom: 10, left: 16, right: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8B6A), AppPalette.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Healthy Autopilot',
                      style: context.appText.bodyStrong
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppPalette.successMint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Auto-planning today',
                          style: context.appText.small.copyWith(
                            color: AppPalette.neutral500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppPalette.creamBackground,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    builder: (_) => const _ProfileSheet(),
                  );
                },
                icon: const Icon(Icons.tune_rounded),
                color: AppPalette.deepNavy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatFeed extends ConsumerWidget {
  const _ChatFeed({
    required this.messages,
    required this.suggestions,
    required this.scrollController,
    required this.onQuickReply,
  });

  final List<ChatMessage> messages;
  final Map<String, dynamic> suggestions;
  final ScrollController scrollController;
  final void Function(QuickReply reply) onQuickReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];
        final prev = i == 0 ? null : messages[i - 1];
        final isSameSender = prev != null && prev.sender == m.sender;
        final topPad = isSameSender ? 6.0 : 16.0;
        return Padding(
          padding: EdgeInsets.only(top: topPad),
          child: _AnimatedInsert(
            key: ValueKey(m.id),
            child: _MessageSwitch(message: m, onQuickReply: onQuickReply),
          ),
        );
      },
    );
  }
}

class _MessageSwitch extends ConsumerWidget {
  const _MessageSwitch({required this.message, required this.onQuickReply});

  final ChatMessage message;
  final void Function(QuickReply reply) onQuickReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (message) {
      case TextMessage m:
        return ChatBubble(message: m);
      case TypingMessage _:
        return const TypingIndicator();
      case DayPlanMessage m:
        final suggestions = ref.read(chatControllerProvider).suggestions;
        return AssistantContentWrapper(
          child: DayPlanCard(message: m, suggestions: suggestions),
        );
      case AlternativesMessage m:
        return AssistantContentWrapper(child: AlternativesRail(message: m));
      case QuickRepliesMessage m:
        return QuickReplyChips(replies: m.replies, onTap: onQuickReply);
    }
  }
}

class _AnimatedInsert extends StatefulWidget {
  const _AnimatedInsert({super.key, required this.child});
  final Widget child;

  @override
  State<_AnimatedInsert> createState() => _AnimatedInsertState();
}

class _AnimatedInsertState extends State<_AnimatedInsert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppPalette.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text('Preferences',
                style: text.h2.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              'Tell me what you want different, and I\'ll bias today\'s picks.',
              style: text.small.copyWith(color: AppPalette.neutral500),
            ),
            const SizedBox(height: 20),
            _row(Icons.local_fire_department_rounded, 'Protein target',
                '≥ 120g / day', context),
            const SizedBox(height: 10),
            _row(Icons.eco_rounded, 'Plant-forward bias', 'On', context),
            const SizedBox(height: 10),
            _row(Icons.schedule_rounded, 'Time budget per meal',
                'Under 30 min total', context),
            const SizedBox(height: 10),
            _row(Icons.paid_rounded, 'Budget', r'$$  weekly cap $280', context),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppPalette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppPalette.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppPalette.deepNavy,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppPalette.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}
