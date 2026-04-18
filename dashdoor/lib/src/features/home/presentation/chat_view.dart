import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../state/chat_provider.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.unfocus();
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    if (state.messages.isNotEmpty) _scrollToBottom();

    return Column(
      children: [
        Expanded(
          child: state.isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : state.messages.isEmpty
                  ? _WelcomeBanner(onPromptTap: (p) async {
                      await ref.read(chatProvider.notifier).sendMessage(p);
                      _scrollToBottom();
                    })
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return const _TypingIndicator();
                        }
                        return _ChatBubble(message: state.messages[index]);
                      },
                    ),
        ),
        if (state.error != null)
          _ErrorBanner(
            error: state.error!,
            onDismiss: () => ref.read(chatProvider.notifier).clearError(),
          ),
        _ChatInput(
          controller: _controller,
          focusNode: _focusNode,
          onSend: _send,
          isLoading: state.isLoading,
        ),
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final void Function(String) onPromptTap;
  const _WelcomeBanner({required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: AppPalette.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Healthy Autopilot',
            style: context.appText.h3.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "I plan your meals around your schedule before you get hungry. Connect your calendar and I'll handle the rest.",
            style: context.appText.body.copyWith(
              color: AppPalette.neutral500,
              height: 1.5,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _prompt(context, "What should I eat today?"),
          const SizedBox(height: 10),
          _prompt(context, "I have back-to-back meetings all afternoon"),
          const SizedBox(height: 10),
          _prompt(context, "Find me something healthy near me"),
          const SizedBox(height: 10),
          _prompt(context, "Plan my meals for the next 8 hours"),
        ],
      ),
    );
  }

  Widget _prompt(BuildContext context, String text) {
    return GestureDetector(
      onTap: () => onPromptTap(text),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppPalette.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: context.appText.small.copyWith(
                  color: AppPalette.deepNavy,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppPalette.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: const BoxDecoration(
                color: AppPalette.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppPalette.primary : AppPalette.surfaceWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: context.appText.body.copyWith(
                  color: isUser ? Colors.white : AppPalette.deepNavy,
                  height: 1.55,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: AppPalette.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppPalette.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                _Dot(delay: 0),
                SizedBox(width: 4),
                _Dot(delay: 200),
                SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 6,
        height: 6 + _anim.value * 4,
        decoration: BoxDecoration(
          color: AppPalette.neutral500.withValues(alpha: 0.35 + _anim.value * 0.55),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppPalette.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppPalette.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: context.appText.small.copyWith(color: AppPalette.primary),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded, size: 16, color: AppPalette.primary),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isLoading;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.creamBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPalette.border),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 5,
                minLines: 1,
                style: context.appText.body.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ask about your next meal...',
                  hintStyle: context.appText.body.copyWith(
                    color: AppPalette.neutral400,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLoading ? AppPalette.neutral200 : AppPalette.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: isLoading ? AppPalette.neutral500 : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
