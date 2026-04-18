import 'package:flutter/material.dart';

enum MealSlot { breakfast, lunch, snack, dinner }

extension MealSlotX on MealSlot {
  String get label => switch (this) {
        MealSlot.breakfast => 'Breakfast',
        MealSlot.lunch => 'Lunch',
        MealSlot.snack => 'Snack',
        MealSlot.dinner => 'Dinner',
      };

  IconData get icon => switch (this) {
        MealSlot.breakfast => Icons.wb_sunny_rounded,
        MealSlot.lunch => Icons.ramen_dining_rounded,
        MealSlot.snack => Icons.cookie_rounded,
        MealSlot.dinner => Icons.dinner_dining_rounded,
      };
}

@immutable
class NutritionFacts {
  const NutritionFacts({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final int sugar;
  final int sodium;
}

@immutable
class MenuItem {
  const MenuItem({
    required this.name,
    required this.calories,
    required this.price,
    this.description,
    this.tags = const [],
    this.isStarred = false,
  });

  final String name;
  final int calories;
  final double price;
  final String? description;
  final List<String> tags;
  final bool isStarred;
}

@immutable
class FoodSuggestion {
  const FoodSuggestion({
    required this.id,
    required this.slot,
    required this.restaurant,
    required this.headline,
    required this.cuisine,
    required this.rating,
    required this.priceBand,
    required this.windowStart,
    required this.windowEnd,
    required this.distanceMin,
    required this.reason,
    required this.nutrition,
    required this.menuItems,
    required this.tags,
    required this.artworkSeed,
    this.neighborhood,
  });

  final String id;
  final MealSlot slot;
  final String restaurant;
  final String headline;
  final String cuisine;
  final double rating;

  /// 1–4: `$`, `$$`, `$$$`, `$$$$`.
  final int priceBand;
  final double windowStart;
  final double windowEnd;
  final int distanceMin;
  final String? neighborhood;

  /// One-line rationale from the assistant ("High protein before your workout").
  final String reason;

  final NutritionFacts nutrition;
  final List<MenuItem> menuItems;
  final List<String> tags;

  /// Integer seed used to generate deterministic gradient artwork so we don't
  /// ship bundled photos during the no-backend prototype phase.
  final int artworkSeed;

  String get priceLabel => r'$' * priceBand;

  FoodSuggestion copyWith({
    double? windowStart,
    double? windowEnd,
  }) {
    return FoodSuggestion(
      id: id,
      slot: slot,
      restaurant: restaurant,
      headline: headline,
      cuisine: cuisine,
      rating: rating,
      priceBand: priceBand,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      distanceMin: distanceMin,
      neighborhood: neighborhood,
      reason: reason,
      nutrition: nutrition,
      menuItems: menuItems,
      tags: tags,
      artworkSeed: artworkSeed,
    );
  }
}
