import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum MascotState {
  idle,
  wave,
  chef,
  thinking,
  happy,
  sad,
}

class MascotWidget extends StatefulWidget {
  final MascotState state;
  final double width;
  final double height;
  final bool animate;

  const MascotWidget({
    super.key,
    this.state = MascotState.idle,
    this.width = 120,
    this.height = 120,
    this.animate = true,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const String _idleLottiePath =
      'assets/animations/excited_idle_animation.json';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getAssetPath() {
    switch (widget.state) {
      case MascotState.idle:
        return 'assets/mascots/mascot_0.png';
      case MascotState.wave:
        return 'assets/mascots/mascot_1.png';
      case MascotState.chef:
        return 'assets/mascots/mascot_2.png';
      case MascotState.thinking:
        return 'assets/mascots/mascot_3.png';
      case MascotState.happy:
        return 'assets/mascots/mascot_4.png';
      case MascotState.sad:
        return 'assets/mascots/mascot_5.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      _getAssetPath(),
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      // Using filterQuality: FilterQuality.medium to help with low-res images
      filterQuality: FilterQuality.medium,
    );

    final mascotChild = Transform.translate(
      offset: const Offset(7.5, 0),
      child: Lottie.asset(
        _idleLottiePath,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
        repeat: widget.animate,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[MascotWidget] Lottie load failed: $error');
          return fallback;
        },
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatValue = math.sin(_controller.value * 2 * math.pi);
        final tiltValue = math.sin(_controller.value * 2 * math.pi) * 0.05;
        
        return Transform.translate(
          offset: Offset(0, floatValue * 4.0),
          child: Transform.rotate(
            angle: tiltValue,
            child: child,
          ),
        );
      },
      child: mascotChild,
    );
  }
}
