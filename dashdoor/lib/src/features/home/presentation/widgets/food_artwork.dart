import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/food_suggestion.dart';

/// Deterministic gradient artwork that stands in for a real photograph during
/// the no-backend prototype. Carefully tuned so a row of four feels editorial
/// rather than a screen of stock placeholders.
class FoodArtwork extends StatelessWidget {
  const FoodArtwork({
    super.key,
    required this.suggestion,
    this.radius = 24,
    this.showGlyph = true,
  });

  final FoodSuggestion suggestion;
  final double radius;
  final bool showGlyph;

  static const _palettes = <List<Color>>[
    [Color(0xFFFFB07C), Color(0xFFFF5E62), Color(0xFF8E2DE2)],
    [Color(0xFF8EE3A1), Color(0xFF3AC47D), Color(0xFF0F5C3C)],
    [Color(0xFFFFD86F), Color(0xFFFB7D5B), Color(0xFFC72C41)],
    [Color(0xFF9AD1FF), Color(0xFF3563E9), Color(0xFF0B1F4B)],
    [Color(0xFFFFD3A5), Color(0xFFFD6585), Color(0xFF632085)],
    [Color(0xFFB8F2E6), Color(0xFF5EEAD4), Color(0xFF134E4A)],
    [Color(0xFFF8BBD0), Color(0xFFF06292), Color(0xFF6A1B4D)],
  ];

  List<Color> get _gradient {
    final idx = suggestion.artworkSeed % _palettes.length;
    return _palettes[idx];
  }

  String get _glyph => switch (suggestion.slot) {
        MealSlot.breakfast => '🥣',
        MealSlot.lunch => '🥗',
        MealSlot.snack => '🥑',
        MealSlot.dinner => '🍣',
      };

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
          ),
          CustomPaint(
            painter: _OrbPainter(
              seed: suggestion.artworkSeed,
              accent: Colors.white.withValues(alpha: 0.22),
              deep: AppPalette.deepNavy.withValues(alpha: 0.14),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppPalette.deepNavy.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          if (showGlyph)
            Align(
              alignment: const Alignment(0.72, -0.55),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.deepNavy.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(_glyph, style: const TextStyle(fontSize: 18)),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.seed, required this.accent, required this.deep});

  final int seed;
  final Color accent;
  final Color deep;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed * 31 + 7);
    // Light orbs
    for (var i = 0; i < 3; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height * 0.9;
      final r = size.shortestSide * (0.25 + rnd.nextDouble() * 0.35);
      final p = Paint()
        ..shader = RadialGradient(
          colors: [accent, accent.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: r));
      canvas.drawCircle(Offset(dx, dy), r, p);
    }
    // Deep shadow blob in bottom-left
    final p = Paint()
      ..shader = RadialGradient(
        colors: [deep, deep.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 1.05),
        radius: size.shortestSide * 0.9,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 1.05),
      size.shortestSide * 0.9,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
