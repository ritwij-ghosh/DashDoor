import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/food_suggestion.dart';

class NutritionRing extends StatelessWidget {
  const NutritionRing({
    super.key,
    required this.nutrition,
    this.size = 128,
  });

  final NutritionFacts nutrition;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = math.max(1, nutrition.protein * 4 + nutrition.carbs * 4 + nutrition.fat * 9);
    final pShare = (nutrition.protein * 4) / total;
    final cShare = (nutrition.carbs * 4) / total;
    final fShare = (nutrition.fat * 9) / total;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          protein: pShare,
          carbs: cShare,
          fat: fShare,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${nutrition.calories}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  color: AppPalette.deepNavy,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.protein, required this.carbs, required this.fat});

  final double protein;
  final double carbs;
  final double fat;

  static const proteinColor = AppPalette.primary;
  static const carbColor = AppPalette.sunRewards;
  static const fatColor = AppPalette.successMint;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.shortestSide / 2 - strokeWidth / 2,
    );

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppPalette.neutral100;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);

    double start = -math.pi / 2;
    void arc(double share, Color color) {
      if (share <= 0) return;
      final sweep = math.pi * 2 * share;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = color;
      canvas.drawArc(rect, start + 0.03, sweep - 0.06, false, paint);
      start += sweep;
    }

    arc(protein, proteinColor);
    arc(carbs, carbColor);
    arc(fat, fatColor);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.protein != protein ||
      oldDelegate.carbs != carbs ||
      oldDelegate.fat != fat;
}

class NutritionLegend extends StatelessWidget {
  const NutritionLegend({super.key, required this.nutrition});

  final NutritionFacts nutrition;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row('Protein', '${nutrition.protein} g', _RingPainter.proteinColor),
        const SizedBox(height: 10),
        _row('Carbs', '${nutrition.carbs} g', _RingPainter.carbColor),
        const SizedBox(height: 10),
        _row('Fat', '${nutrition.fat} g', _RingPainter.fatColor),
      ],
    );
  }

  Widget _row(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppPalette.deepNavy,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppPalette.deepNavy,
          ),
        ),
      ],
    );
  }
}
