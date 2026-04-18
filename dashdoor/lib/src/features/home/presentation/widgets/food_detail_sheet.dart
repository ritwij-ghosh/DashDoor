import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/food_suggestion.dart';
import '../../state/chat_controller.dart';
import 'food_artwork.dart';
import 'nutrition_ring.dart';

Future<void> showFoodDetailSheet(
  BuildContext context, {
  required FoodSuggestion suggestion,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppPalette.deepNavy.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => _FoodDetailSheet(suggestion: suggestion),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _FoodDetailSheet extends ConsumerWidget {
  const _FoodDetailSheet({required this.suggestion});

  final FoodSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.appText;
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(top: media.padding.top + 12),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: Container(
                color: AppPalette.creamBackground,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      stretch: true,
                      backgroundColor: AppPalette.creamBackground,
                      surfaceTintColor: AppPalette.creamBackground,
                      elevation: 0,
                      expandedHeight: 320,
                      automaticallyImplyLeading: false,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 12, top: 8),
                        child: _circleButton(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12, top: 8),
                          child: _circleButton(
                            icon: Icons.bookmark_border_rounded,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text('Saved to favourites'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [
                          StretchMode.zoomBackground,
                          StretchMode.blurBackground,
                        ],
                        background: Hero(
                          tag: 'food_artwork_${suggestion.id}',
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32),
                                bottom: Radius.circular(28),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  FoodArtwork(
                                    suggestion: suggestion,
                                    radius: 0,
                                    showGlyph: false,
                                  ),
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _slotPill(suggestion.slot),
                                          const SizedBox(height: 12),
                                          Text(
                                            suggestion.restaurant,
                                            style: text.h1.copyWith(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.w900,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 8,
                                                  color: AppPalette.deepNavy
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            suggestion.headline,
                                            style: text.body.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.92),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MetaRow(suggestion: suggestion),
                            const SizedBox(height: 20),
                            _ReasonCard(reason: suggestion.reason),
                            const SizedBox(height: 20),
                            _NutritionBlock(nutrition: suggestion.nutrition),
                            const SizedBox(height: 20),
                            _TagsWrap(tags: suggestion.tags),
                            const SizedBox(height: 28),
                            Text('On the menu',
                                style: text.h3
                                    .copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            for (final item in suggestion.menuItems) ...[
                              _MenuItemRow(item: item),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 24),
                            _ActionBar(suggestion: suggestion),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppPalette.deepNavy.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppPalette.deepNavy, size: 20),
      ),
    );
  }

  Widget _slotPill(MealSlot slot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(slot.icon, size: 14, color: AppPalette.deepNavy),
          const SizedBox(width: 6),
          Text(
            slot.label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppPalette.deepNavy,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.suggestion});
  final FoodSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(Icons.star_rounded, suggestion.rating.toStringAsFixed(1),
                  AppPalette.sunRewards),
              _chip(Icons.directions_walk_rounded,
                  '${suggestion.distanceMin} min', AppPalette.successMint),
              _chip(Icons.attach_money_rounded, suggestion.priceLabel,
                  AppPalette.neutral100),
            ],
          ),
        ),
        if (suggestion.neighborhood != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              suggestion.neighborhood!,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppPalette.neutral500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPalette.deepNavy),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppPalette.deepNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppPalette.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: AppPalette.deepNavy,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionBlock extends StatelessWidget {
  const _NutritionBlock({required this.nutrition});
  final NutritionFacts nutrition;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NutritionRing(nutrition: nutrition),
          const SizedBox(width: 20),
          Expanded(child: NutritionLegend(nutrition: nutrition)),
        ],
      ),
    );
  }
}

class _TagsWrap extends StatelessWidget {
  const _TagsWrap({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map((t) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.successMint.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.deepNavy,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({required this.item});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final text = context.appText;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isStarred
              ? AppPalette.primary.withValues(alpha: 0.4)
              : AppPalette.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.isStarred)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 2),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppPalette.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: text.bodyStrong,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: text.bodyStrong,
                    ),
                  ],
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: text.small.copyWith(color: AppPalette.neutral500),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${item.calories} kcal',
                      style: text.smallStrong.copyWith(
                        color: AppPalette.neutral500,
                      ),
                    ),
                    for (final t in item.tags)
                      Text(
                        '· $t',
                        style: text.small.copyWith(
                          color: AppPalette.neutral500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.suggestion});
  final FoodSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Directions open in Maps (coming soon)'),
                ),
              );
            },
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Directions'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppPalette.border),
              foregroundColor: AppPalette.deepNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).maybePop();
              ref
                  .read(chatControllerProvider.notifier)
                  .requestSwap(suggestion.id);
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: const Text('Swap this'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppPalette.primary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
