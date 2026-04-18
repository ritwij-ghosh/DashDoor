import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/chat_message.dart';
import '../../domain/food_suggestion.dart';
import '../../state/chat_controller.dart';
import 'food_artwork.dart';
import 'food_detail_sheet.dart';

class AlternativesRail extends ConsumerWidget {
  const AlternativesRail({super.key, required this.message});

  final AlternativesMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: message.options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final option = message.options[i];
          return _AlternativeCard(
            option: option,
            onPreview: () => showFoodDetailSheet(context, suggestion: option),
            onPick: () {
              HapticFeedback.mediumImpact();
              ref.read(chatControllerProvider.notifier).pickAlternative(
                    message.replacingSuggestionId,
                    option,
                  );
            },
          );
        },
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.option,
    required this.onPick,
    required this.onPreview,
  });

  final FoodSuggestion option;
  final VoidCallback onPick;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    // Parent rail is exactly 260px tall; intrinsic Column content was ~288px.
    // Fixed height + Expanded headline region prevents overflow at any text scale.
    const railH = 260.0;
    const imageH = 96.0;

    return SizedBox(
      width: 236,
      height: railH,
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppPalette.border),
          boxShadow: [
            BoxShadow(
              color: AppPalette.deepNavy.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: onPreview,
                child: SizedBox(
                  height: imageH,
                  child: FoodArtwork(suggestion: option, radius: 0),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: _miniBadge(
                              '${option.nutrition.calories} cal',
                              AppPalette.neutral100,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _miniBadge(
                              '${option.nutrition.protein}g protein',
                              AppPalette.primary.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        option.restaurant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyStrong
                            .copyWith(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            option.headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.small.copyWith(
                              color: AppPalette.neutral500,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onPreview,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: const BorderSide(color: AppPalette.border),
                                foregroundColor: AppPalette.deepNavy,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Preview',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: FilledButton(
                              onPressed: onPick,
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: AppPalette.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Pick',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: AppPalette.deepNavy,
        ),
      ),
    );
  }
}
