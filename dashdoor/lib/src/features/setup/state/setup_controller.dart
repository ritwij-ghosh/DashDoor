import 'package:flutter_riverpod/flutter_riverpod.dart';

class Ingredient {
  final String id;
  final String name;
  final String category;
  final String icon; // Icon name or character

  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    this.icon = '',
  });
}

class SetupState {
  final int currentStep;
  final Set<String> selectedIngredientIds;
  final String searchQuery;
  final String? selectedTimeLimit;
  final Set<String> selectedVibes;

  const SetupState({
    this.currentStep = 0,
    this.selectedIngredientIds = const {},
    this.searchQuery = '',
    this.selectedTimeLimit = '15',
    this.selectedVibes = const {'High protein', 'Fresh / light'},
  });

  SetupState copyWith({
    int? currentStep,
    Set<String>? selectedIngredientIds,
    String? searchQuery,
    String? selectedTimeLimit,
    Set<String>? selectedVibes,
  }) {
    return SetupState(
      currentStep: currentStep ?? this.currentStep,
      selectedIngredientIds: selectedIngredientIds ?? this.selectedIngredientIds,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTimeLimit: selectedTimeLimit ?? this.selectedTimeLimit,
      selectedVibes: selectedVibes ?? this.selectedVibes,
    );
  }
}

class SetupController extends StateNotifier<SetupState> {
  SetupController() : super(const SetupState());

  void setStep(int step) => state = state.copyWith(currentStep: step);

  void toggleIngredient(String id) {
    final current = Set<String>.from(state.selectedIngredientIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(selectedIngredientIds: current);
  }

  void setTimeLimit(String limit) {
    state = state.copyWith(selectedTimeLimit: limit);
  }

  void toggleVibe(String vibe) {
    final current = Set<String>.from(state.selectedVibes);
    if (current.contains(vibe)) {
      current.remove(vibe);
    } else {
      current.add(vibe);
    }
    state = state.copyWith(selectedVibes: current);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  bool isIngredientSelected(String id) => state.selectedIngredientIds.contains(id);
  bool isVibeSelected(String vibe) => state.selectedVibes.contains(vibe);
  
  int get selectedCount => state.selectedIngredientIds.length;
}

final setupControllerProvider =
    StateNotifierProvider<SetupController, SetupState>((ref) {
  return SetupController();
});

// Exhaustive list of relevant ingredients
final allIngredientsProvider = Provider<List<Ingredient>>((ref) {
  return [
    // KITCHEN ESSENTIALS
    const Ingredient(id: 'eggs', name: 'Eggs', category: 'KITCHEN ESSENTIALS'),
    const Ingredient(id: 'milk', name: 'Milk', category: 'KITCHEN ESSENTIALS'),
    const Ingredient(id: 'rice', name: 'Rice', category: 'KITCHEN ESSENTIALS'),
    const Ingredient(id: 'bread', name: 'Bread', category: 'KITCHEN ESSENTIALS'),
    const Ingredient(id: 'pasta', name: 'Pasta', category: 'KITCHEN ESSENTIALS'),
    const Ingredient(id: 'butter', name: 'Butter', category: 'KITCHEN ESSENTIALS'),
    const Ingredient(id: 'flour', name: 'Flour', category: 'KITCHEN ESSENTIALS'),
    const Ingredient(id: 'olive_oil', name: 'Olive Oil', category: 'KITCHEN ESSENTIALS'),
    
    // FRESH PRODUCE
    const Ingredient(id: 'tomatoes', name: 'Tomatoes', category: 'FRESH PRODUCE'),
    const Ingredient(id: 'onions', name: 'Onions', category: 'FRESH PRODUCE'),
    const Ingredient(id: 'garlic', name: 'Garlic', category: 'FRESH PRODUCE'),
    const Ingredient(id: 'spinach', name: 'Spinach', category: 'FRESH PRODUCE'),
    const Ingredient(id: 'potatoes', name: 'Potatoes', category: 'FRESH PRODUCE'),
    const Ingredient(id: 'broccoli', name: 'Broccoli', category: 'FRESH PRODUCE'),
    const Ingredient(id: 'avocado', name: 'Avocado', category: 'FRESH PRODUCE'),
    const Ingredient(id: 'lemon', name: 'Lemon', category: 'FRESH PRODUCE'),
    
    // PROTEINS
    const Ingredient(id: 'chicken', name: 'Chicken Breast', category: 'PROTEINS'),
    const Ingredient(id: 'beef', name: 'Ground Beef', category: 'PROTEINS'),
    const Ingredient(id: 'salmon', name: 'Salmon', category: 'PROTEINS'),
    const Ingredient(id: 'tofu', name: 'Tofu', category: 'PROTEINS'),
    const Ingredient(id: 'tuna', name: 'Canned Tuna', category: 'PROTEINS'),
    const Ingredient(id: 'yogurt', name: 'Greek Yogurt', category: 'PROTEINS'),
    
    // PANTRY & SPICES
    const Ingredient(id: 'beans', name: 'Black Beans', category: 'PANTRY'),
    const Ingredient(id: 'peanut_butter', name: 'Peanut Butter', category: 'PANTRY'),
    const Ingredient(id: 'oats', name: 'Oats', category: 'PANTRY'),
    const Ingredient(id: 'soy_sauce', name: 'Soy Sauce', category: 'PANTRY'),
    const Ingredient(id: 'honey', name: 'Honey', category: 'PANTRY'),
  ];
});

