import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Named expressions of the bee mascot. Each maps to one cropped pose from
/// `assets/mascots/bee/`; add new slots by extending the enum and the map.
enum MascotState {
  idle,
  wave,
  chef,
  thinking,
  happy,
  sad,
  busy,
  drinking,
  presenting,
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

  static const Map<MascotState, String> _assets = {
    MascotState.idle: 'assets/mascots/bee/happy.png',
    MascotState.wave: 'assets/mascots/bee/cheer.png',
    MascotState.chef: 'assets/mascots/bee/eating.png',
    MascotState.thinking: 'assets/mascots/bee/checking.png',
    MascotState.happy: 'assets/mascots/bee/encouraging.png',
    MascotState.sad: 'assets/mascots/bee/worried.png',
    MascotState.busy: 'assets/mascots/bee/busy.png',
    MascotState.drinking: 'assets/mascots/bee/drinking.png',
    MascotState.presenting: 'assets/mascots/bee/presenting.png',
  };

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

  @override
  Widget build(BuildContext context) {
    final path = _assets[widget.state] ?? _assets[MascotState.idle]!;

    final image = Image.asset(
      path,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[MascotWidget] asset load failed for $path: $error');
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Icon(Icons.emoji_nature_rounded, size: 48),
        );
      },
    );

    if (!widget.animate) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: image,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final floatValue = math.sin(_controller.value * 2 * math.pi);
        final tiltValue = math.sin(_controller.value * 2 * math.pi) * 0.04;
        return Transform.translate(
          offset: Offset(0, floatValue * 4.0),
          child: Transform.rotate(
            angle: tiltValue,
            child: child,
          ),
        );
      },
      child: image,
    );
  }
}
