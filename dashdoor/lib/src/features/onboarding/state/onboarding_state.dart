import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All data collected during the extended onboarding flow.
class OnboardingData {
  final int? selectedSquirrelIndex; // 0, 1, or 2
  final String? squirrelName;
  final List<String> mealVibes; // quick, cheap, healthGoals, comfort, adventurous
  final int? timeAvailableMin; // 10, 20, 30
  final List<String> dietaryRules; // vegetarian, halal, glutenFree, etc.
  final List<String> dislikes; // ingredient names
  final String? pantryChoice; // receipt, groceries, manual
  final List<String> manualPantryItems; // items selected in manual pantry step
  final int? commitNights; // 2-7 nights per week
  final String? signatureData; // base64 or path of signature
  final int? reminderHour;
  final int? reminderMinute;
  final List<int> reminderDays; // 0=Sun,1=Mon,...6=Sat
  final bool notificationsAccepted;
  final bool paywallCompleted;
  final bool challengeAccepted;

  // ── Quick & Easy follow-up ──
  final List<String> kitchenAppliances;

  // ── Budget follow-up ──
  final double? weeklyBudget;
  final int? householdSize;

  // ── Health Conscious follow-up ──
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? gender; // male, female, other
  final String? activityLevel; // sedentary, light, moderate, active, veryActive
  final int? targetCalories;
  final int? targetProteinG;
  final int? targetFatG;
  final int? targetCarbsG;

  // ── Comfort Food follow-up ──
  final List<String> comfortCategories;

  // ── Adventurous follow-up ──
  final List<String> cuisineInterests;
  final int? spiceTolerance; // 1-4 (mild, medium, hot, extreme)

  const OnboardingData({
    this.selectedSquirrelIndex,
    this.squirrelName,
    this.mealVibes = const [],
    this.timeAvailableMin,
    this.dietaryRules = const [],
    this.dislikes = const [],
    this.pantryChoice,
    this.manualPantryItems = const [],
    this.commitNights,
    this.signatureData,
    this.reminderHour,
    this.reminderMinute,
    this.reminderDays = const [1, 2, 3, 4, 5], // weekdays only (Mon-Fri)
    this.notificationsAccepted = false,
    this.paywallCompleted = false,
    this.challengeAccepted = false,
    this.kitchenAppliances = const [],
    this.weeklyBudget,
    this.householdSize,
    this.age,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.activityLevel,
    this.targetCalories,
    this.targetProteinG,
    this.targetFatG,
    this.targetCarbsG,
    this.comfortCategories = const [],
    this.cuisineInterests = const [],
    this.spiceTolerance,
  });

  OnboardingData copyWith({
    int? selectedSquirrelIndex,
    String? squirrelName,
    List<String>? mealVibes,
    int? timeAvailableMin,
    List<String>? dietaryRules,
    List<String>? dislikes,
    String? pantryChoice,
    List<String>? manualPantryItems,
    int? commitNights,
    String? signatureData,
    int? reminderHour,
    int? reminderMinute,
    List<int>? reminderDays,
    bool? notificationsAccepted,
    bool? paywallCompleted,
    bool? challengeAccepted,
    List<String>? kitchenAppliances,
    double? weeklyBudget,
    int? householdSize,
    int? age,
    double? weightKg,
    double? heightCm,
    String? gender,
    String? activityLevel,
    int? targetCalories,
    int? targetProteinG,
    int? targetFatG,
    int? targetCarbsG,
    List<String>? comfortCategories,
    List<String>? cuisineInterests,
    int? spiceTolerance,
  }) {
    return OnboardingData(
      selectedSquirrelIndex:
          selectedSquirrelIndex ?? this.selectedSquirrelIndex,
      squirrelName: squirrelName ?? this.squirrelName,
      mealVibes: mealVibes ?? this.mealVibes,
      timeAvailableMin: timeAvailableMin ?? this.timeAvailableMin,
      dietaryRules: dietaryRules ?? this.dietaryRules,
      dislikes: dislikes ?? this.dislikes,
      pantryChoice: pantryChoice ?? this.pantryChoice,
      manualPantryItems: manualPantryItems ?? this.manualPantryItems,
      commitNights: commitNights ?? this.commitNights,
      signatureData: signatureData ?? this.signatureData,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderDays: reminderDays ?? this.reminderDays,
      notificationsAccepted:
          notificationsAccepted ?? this.notificationsAccepted,
      paywallCompleted: paywallCompleted ?? this.paywallCompleted,
      challengeAccepted: challengeAccepted ?? this.challengeAccepted,
      kitchenAppliances: kitchenAppliances ?? this.kitchenAppliances,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      householdSize: householdSize ?? this.householdSize,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProteinG: targetProteinG ?? this.targetProteinG,
      targetFatG: targetFatG ?? this.targetFatG,
      targetCarbsG: targetCarbsG ?? this.targetCarbsG,
      comfortCategories: comfortCategories ?? this.comfortCategories,
      cuisineInterests: cuisineInterests ?? this.cuisineInterests,
      spiceTolerance: spiceTolerance ?? this.spiceTolerance,
    );
  }

  /// Convert to JSON for API submission.
  Map<String, dynamic> toJson() => {
        'selectedSquirrelIndex': selectedSquirrelIndex,
        'squirrelName': squirrelName,
        'mealVibes': mealVibes,
        'timeAvailableMin': timeAvailableMin,
        'dietaryRules': dietaryRules,
        'dislikes': dislikes,
        'pantryChoice': pantryChoice,
        'manualPantryItems': manualPantryItems,
        'commitNights': commitNights,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'reminderDays': reminderDays,
        'notificationsAccepted': notificationsAccepted,
        'kitchenAppliances': kitchenAppliances,
        'weeklyBudget': weeklyBudget,
        'householdSize': householdSize,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'gender': gender,
        'activityLevel': activityLevel,
        'targetCalories': targetCalories,
        'targetProteinG': targetProteinG,
        'targetFatG': targetFatG,
        'targetCarbsG': targetCarbsG,
        'comfortCategories': comfortCategories,
        'cuisineInterests': cuisineInterests,
        'spiceTolerance': spiceTolerance,
      };
}

/// Fixed steps in the extended onboarding (vibe follow-ups are dynamic).
enum OnboardingStep {
  nameSquirrel, // Name your buddy
  mealVibe, // Quick, cheap, health-conscious, comfort, adventurous (multi-select)
  // Dynamic follow-up steps are inserted here at runtime
  vibeFollowUp, // Placeholder – actual sub-steps computed from selected vibes
  timeAvailable, // 10, 20, 30+ min
  dietaryRules, // Vegetarian, halal, gluten-free, etc.
  dislikedIngredients, // Tap to exclude
  pantryCapture, // Receipt, groceries, or select manually
  beforeAfter, // Before/After transformation
  nibblContract, // Commitment signature
  mealReminder, // Set reminder time
  emotionalWin, // Personalized "your week looks doable"
}

/// The 5 possible vibe follow-up sub-steps, shown only for selected vibes.
enum VibeFollowUpType {
  quickEasy, // Kitchen Setup – appliances
  budget, // Budget & household size
  healthGoals, // Health profile + macros
  comfortFood, // Comfort food categories
  adventurous, // Cuisine explorer + spice
}

class OnboardingFlowState {
  final OnboardingStep currentStep;
  final OnboardingData data;
  final bool isSubmitting;
  final String? error;

  /// Index into the vibe follow-up sub-steps list (when currentStep == vibeFollowUp).
  final int vibeFollowUpIndex;

  const OnboardingFlowState({
    this.currentStep = OnboardingStep.nameSquirrel,
    this.data = const OnboardingData(),
    this.isSubmitting = false,
    this.error,
    this.vibeFollowUpIndex = 0,
  });

  OnboardingFlowState copyWith({
    OnboardingStep? currentStep,
    OnboardingData? data,
    bool? isSubmitting,
    String? error,
    int? vibeFollowUpIndex,
  }) {
    return OnboardingFlowState(
      currentStep: currentStep ?? this.currentStep,
      data: data ?? this.data,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      vibeFollowUpIndex: vibeFollowUpIndex ?? this.vibeFollowUpIndex,
    );
  }

  /// The vibe follow-up types that should be shown, based on selected vibes.
  List<VibeFollowUpType> get activeVibeFollowUps {
    final ups = <VibeFollowUpType>[];
    for (final v in data.mealVibes) {
      switch (v) {
        case 'quick':
          ups.add(VibeFollowUpType.quickEasy);
          break;
        case 'cheap':
          ups.add(VibeFollowUpType.budget);
          break;
        case 'healthGoals':
          ups.add(VibeFollowUpType.healthGoals);
          break;
        case 'comfort':
          ups.add(VibeFollowUpType.comfortFood);
          break;
        case 'adventurous':
          ups.add(VibeFollowUpType.adventurous);
          break;
      }
    }
    return ups;
  }

  /// Current vibe follow-up type, if we're on a follow-up step.
  VibeFollowUpType? get currentVibeFollowUp {
    if (currentStep != OnboardingStep.vibeFollowUp) return null;
    final ups = activeVibeFollowUps;
    if (vibeFollowUpIndex < ups.length) return ups[vibeFollowUpIndex];
    return null;
  }

  /// Flattened list of all steps including dynamic follow-ups for progress calculation.
  int get totalSteps {
    // Fixed steps (excl. vibeFollowUp placeholder) + actual follow-ups
    final fixed = OnboardingStep.values.length - 1; // minus the placeholder
    return fixed + activeVibeFollowUps.length;
  }

  /// Current step index in the flattened list.
  int get stepIndex {
    final baseIndex = OnboardingStep.values.indexOf(currentStep);
    if (currentStep.index <= OnboardingStep.mealVibe.index) {
      return baseIndex;
    }
    if (currentStep == OnboardingStep.vibeFollowUp) {
      return OnboardingStep.mealVibe.index + 1 + vibeFollowUpIndex;
    }
    // Steps after vibeFollowUp: offset by (actual follow-ups - 1 placeholder)
    return baseIndex + activeVibeFollowUps.length - 1;
  }

  double get progress => totalSteps > 0 ? (stepIndex + 1) / totalSteps : 0;
}

class OnboardingFlowController extends StateNotifier<OnboardingFlowState> {
  OnboardingFlowController() : super(const OnboardingFlowState());

  void setSquirrel(int index) {
    state = state.copyWith(
      data: state.data.copyWith(selectedSquirrelIndex: index),
    );
  }

  void setSquirrelName(String name) {
    state = state.copyWith(
      data: state.data.copyWith(squirrelName: name),
    );
  }

  // ── Meal Vibes (multi-select) ──

  void toggleMealVibe(String vibe) {
    final current = List<String>.from(state.data.mealVibes);
    if (current.contains(vibe)) {
      current.remove(vibe);
    } else {
      current.add(vibe);
    }
    state = state.copyWith(
      data: state.data.copyWith(mealVibes: current),
    );
  }

  // ── Quick & Easy follow-up ──

  void toggleAppliance(String appliance) {
    final current = List<String>.from(state.data.kitchenAppliances);
    if (current.contains(appliance)) {
      current.remove(appliance);
    } else {
      current.add(appliance);
    }
    state = state.copyWith(
      data: state.data.copyWith(kitchenAppliances: current),
    );
  }

  // ── Budget follow-up ──

  void setWeeklyBudget(double budget) {
    state = state.copyWith(
      data: state.data.copyWith(weeklyBudget: budget),
    );
  }

  void setHouseholdSize(int size) {
    state = state.copyWith(
      data: state.data.copyWith(householdSize: size),
    );
  }

  // ── Health follow-up ──

  void setAge(int age) {
    state = state.copyWith(data: state.data.copyWith(age: age));
  }

  void setWeight(double kg) {
    state = state.copyWith(data: state.data.copyWith(weightKg: kg));
  }

  void setHeight(double cm) {
    state = state.copyWith(data: state.data.copyWith(heightCm: cm));
  }

  void setGender(String gender) {
    state = state.copyWith(data: state.data.copyWith(gender: gender));
  }

  void setActivityLevel(String level) {
    state = state.copyWith(data: state.data.copyWith(activityLevel: level));
  }

  void setTargetCalories(int cal) {
    state = state.copyWith(data: state.data.copyWith(targetCalories: cal));
  }

  void setTargetProtein(int g) {
    state = state.copyWith(data: state.data.copyWith(targetProteinG: g));
  }

  void setTargetFat(int g) {
    state = state.copyWith(data: state.data.copyWith(targetFatG: g));
  }

  void setTargetCarbs(int g) {
    state = state.copyWith(data: state.data.copyWith(targetCarbsG: g));
  }

  // ── Comfort follow-up ──

  void toggleComfortCategory(String cat) {
    final current = List<String>.from(state.data.comfortCategories);
    if (current.contains(cat)) {
      current.remove(cat);
    } else {
      current.add(cat);
    }
    state = state.copyWith(
      data: state.data.copyWith(comfortCategories: current),
    );
  }

  // ── Adventurous follow-up ──

  void toggleCuisine(String cuisine) {
    final current = List<String>.from(state.data.cuisineInterests);
    if (current.contains(cuisine)) {
      current.remove(cuisine);
    } else {
      current.add(cuisine);
    }
    state = state.copyWith(
      data: state.data.copyWith(cuisineInterests: current),
    );
  }

  void setSpiceTolerance(int level) {
    state = state.copyWith(
      data: state.data.copyWith(spiceTolerance: level),
    );
  }

  // ── Existing step setters ──

  void setTimeAvailable(int minutes) {
    state = state.copyWith(
      data: state.data.copyWith(timeAvailableMin: minutes),
    );
  }

  void toggleDietaryRule(String rule) {
    final current = List<String>.from(state.data.dietaryRules);
    if (current.contains(rule)) {
      current.remove(rule);
    } else {
      current.add(rule);
    }
    state = state.copyWith(
      data: state.data.copyWith(dietaryRules: current),
    );
  }

  void toggleDislike(String ingredient) {
    final current = List<String>.from(state.data.dislikes);
    if (current.contains(ingredient)) {
      current.remove(ingredient);
    } else {
      current.add(ingredient);
    }
    state = state.copyWith(
      data: state.data.copyWith(dislikes: current),
    );
  }

  void setPantryChoice(String choice) {
    state = state.copyWith(
      data: state.data.copyWith(pantryChoice: choice),
    );
  }

  void toggleManualPantryItem(String item) {
    final current = List<String>.from(state.data.manualPantryItems);
    if (current.contains(item)) {
      current.remove(item);
    } else {
      current.add(item);
    }
    state = state.copyWith(
      data: state.data.copyWith(manualPantryItems: current),
    );
  }

  void setCommitNights(int nights) {
    state = state.copyWith(
      data: state.data.copyWith(commitNights: nights),
    );
  }

  void setSignature(String data) {
    state = state.copyWith(
      data: state.data.copyWith(signatureData: data),
    );
  }

  void setReminderTime(int hour, int minute) {
    state = state.copyWith(
      data: state.data.copyWith(reminderHour: hour, reminderMinute: minute),
    );
  }

  void setReminderDays(List<int> days) {
    state = state.copyWith(
      data: state.data.copyWith(reminderDays: days),
    );
  }

  void setNotificationsAccepted(bool accepted) {
    state = state.copyWith(
      data: state.data.copyWith(notificationsAccepted: accepted),
    );
  }

  void setPaywallCompleted(bool completed) {
    state = state.copyWith(
      data: state.data.copyWith(paywallCompleted: completed),
    );
  }

  void setChallengeAccepted(bool accepted) {
    state = state.copyWith(
      data: state.data.copyWith(challengeAccepted: accepted),
    );
  }

  // ── Navigation ──

  void nextStep() {
    final current = state.currentStep;

    // If we're on mealVibe, move to the first vibe follow-up (or skip if none)
    if (current == OnboardingStep.mealVibe) {
      if (state.activeVibeFollowUps.isNotEmpty) {
        state = state.copyWith(
          currentStep: OnboardingStep.vibeFollowUp,
          vibeFollowUpIndex: 0,
        );
      } else {
        state = state.copyWith(currentStep: OnboardingStep.timeAvailable);
      }
      return;
    }

    // If we're in vibe follow-ups, advance through them
    if (current == OnboardingStep.vibeFollowUp) {
      final nextIdx = state.vibeFollowUpIndex + 1;
      if (nextIdx < state.activeVibeFollowUps.length) {
        state = state.copyWith(vibeFollowUpIndex: nextIdx);
      } else {
        state = state.copyWith(currentStep: OnboardingStep.timeAvailable);
      }
      return;
    }

    // Normal linear progression (skipping the vibeFollowUp placeholder)
    final steps = OnboardingStep.values;
    final idx = steps.indexOf(current);
    for (var i = idx + 1; i < steps.length; i++) {
      if (steps[i] == OnboardingStep.vibeFollowUp) continue;
      state = state.copyWith(currentStep: steps[i]);
      return;
    }
  }

  void previousStep() {
    final current = state.currentStep;

    // If we're at the start of vibe follow-ups, go back to mealVibe
    if (current == OnboardingStep.vibeFollowUp) {
      if (state.vibeFollowUpIndex > 0) {
        state = state.copyWith(
          vibeFollowUpIndex: state.vibeFollowUpIndex - 1,
        );
      } else {
        state = state.copyWith(currentStep: OnboardingStep.mealVibe);
      }
      return;
    }

    // If timeAvailable and there were follow-ups, go to last follow-up
    if (current == OnboardingStep.timeAvailable &&
        state.activeVibeFollowUps.isNotEmpty) {
      state = state.copyWith(
        currentStep: OnboardingStep.vibeFollowUp,
        vibeFollowUpIndex: state.activeVibeFollowUps.length - 1,
      );
      return;
    }

    // Normal linear regression (skipping the vibeFollowUp placeholder)
    final steps = OnboardingStep.values;
    final idx = steps.indexOf(current);
    for (var i = idx - 1; i >= 0; i--) {
      if (steps[i] == OnboardingStep.vibeFollowUp) continue;
      state = state.copyWith(currentStep: steps[i]);
      return;
    }
  }

  void goToStep(OnboardingStep step) {
    state = state.copyWith(currentStep: step);
  }

  void setSubmitting(bool v) {
    state = state.copyWith(isSubmitting: v);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const OnboardingFlowState();
  }
}

final onboardingFlowProvider =
    StateNotifierProvider<OnboardingFlowController, OnboardingFlowState>(
  (ref) => OnboardingFlowController(),
);

/// Paywall state for tracking dismissal count and offers.
class PaywallState {
  final int dismissCount;
  final bool hasSeenSpinner;
  final int? discountPercent;
  final DateTime? countdownEnd;
  final bool trialStarted;

  const PaywallState({
    this.dismissCount = 0,
    this.hasSeenSpinner = false,
    this.discountPercent,
    this.countdownEnd,
    this.trialStarted = false,
  });

  PaywallState copyWith({
    int? dismissCount,
    bool? hasSeenSpinner,
    int? discountPercent,
    DateTime? countdownEnd,
    bool? trialStarted,
  }) {
    return PaywallState(
      dismissCount: dismissCount ?? this.dismissCount,
      hasSeenSpinner: hasSeenSpinner ?? this.hasSeenSpinner,
      discountPercent: discountPercent ?? this.discountPercent,
      countdownEnd: countdownEnd ?? this.countdownEnd,
      trialStarted: trialStarted ?? this.trialStarted,
    );
  }
}

class PaywallController extends StateNotifier<PaywallState> {
  PaywallController() : super(const PaywallState());

  void dismiss() {
    final count = state.dismissCount + 1;
    int? discount;
    if (count == 1) {
      discount = 20;
    } else if (count == 2) {
      discount = null; // Will show spinner
    }
    state = state.copyWith(
      dismissCount: count,
      discountPercent: discount,
      countdownEnd:
          count >= 1 ? DateTime.now().add(const Duration(hours: 24)) : null,
    );
  }

  void setSpinnerSeen() {
    state = state.copyWith(hasSeenSpinner: true);
  }

  void setSpinnerDiscount(int percent) {
    state = state.copyWith(discountPercent: percent);
  }

  void startTrial() {
    state = state.copyWith(trialStarted: true);
  }
}

final paywallControllerProvider =
    StateNotifierProvider<PaywallController, PaywallState>(
  (ref) => PaywallController(),
);

/// Challenge state for the 3-day cooking sprint.
class ChallengeState {
  final bool isActive;
  final int currentDay; // 0-based
  final List<bool> daysCompleted;
  final DateTime? startedAt;

  const ChallengeState({
    this.isActive = false,
    this.currentDay = 0,
    this.daysCompleted = const [false, false, false],
    this.startedAt,
  });

  ChallengeState copyWith({
    bool? isActive,
    int? currentDay,
    List<bool>? daysCompleted,
    DateTime? startedAt,
  }) {
    return ChallengeState(
      isActive: isActive ?? this.isActive,
      currentDay: currentDay ?? this.currentDay,
      daysCompleted: daysCompleted ?? this.daysCompleted,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  bool get allComplete => daysCompleted.every((d) => d);
}

class ChallengeController extends StateNotifier<ChallengeState> {
  ChallengeController() : super(const ChallengeState());

  void startChallenge() {
    state = ChallengeState(
      isActive: true,
      currentDay: 0,
      daysCompleted: [false, false, false],
      startedAt: DateTime.now(),
    );
  }

  void completeDay(int day) {
    final days = List<bool>.from(state.daysCompleted);
    if (day >= 0 && day < days.length) {
      days[day] = true;
    }
    state = state.copyWith(
      daysCompleted: days,
      currentDay: day + 1,
    );
  }

  void reset() {
    state = const ChallengeState();
  }
}

final challengeControllerProvider =
    StateNotifierProvider<ChallengeController, ChallengeState>(
  (ref) => ChallengeController(),
);

/// Gamification coin state.
class CoinState {
  final int balance;
  final int totalEarned;
  final int dailyFuel; // Energy system: Nibbl Fuel (0-5)
  final int maxFuel;
  final DateTime? lastFuelRefill;
  final int kitchenJourneyMeals; // Total meals for progress map

  const CoinState({
    this.balance = 0,
    this.totalEarned = 0,
    this.dailyFuel = 5,
    this.maxFuel = 5,
    this.lastFuelRefill,
    this.kitchenJourneyMeals = 0,
  });

  CoinState copyWith({
    int? balance,
    int? totalEarned,
    int? dailyFuel,
    int? maxFuel,
    DateTime? lastFuelRefill,
    int? kitchenJourneyMeals,
  }) {
    return CoinState(
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      dailyFuel: dailyFuel ?? this.dailyFuel,
      maxFuel: maxFuel ?? this.maxFuel,
      lastFuelRefill: lastFuelRefill ?? this.lastFuelRefill,
      kitchenJourneyMeals: kitchenJourneyMeals ?? this.kitchenJourneyMeals,
    );
  }

  /// Kitchen Journey milestone.
  String get currentMilestone {
    if (kitchenJourneyMeals >= 50) return 'Master Chef';
    if (kitchenJourneyMeals >= 20) return 'Seasoned Cook';
    if (kitchenJourneyMeals >= 10) return 'Home Cook';
    if (kitchenJourneyMeals >= 5) return 'Kitchen Apprentice';
    return 'Beginner';
  }

  int get nextMilestoneTarget {
    if (kitchenJourneyMeals >= 50) return 100;
    if (kitchenJourneyMeals >= 20) return 50;
    if (kitchenJourneyMeals >= 10) return 20;
    if (kitchenJourneyMeals >= 5) return 10;
    return 5;
  }
}

class CoinController extends StateNotifier<CoinState> {
  CoinController() : super(const CoinState());

  void earnCoins(int amount) {
    state = state.copyWith(
      balance: state.balance + amount,
      totalEarned: state.totalEarned + amount,
    );
  }

  void spendCoins(int amount) {
    if (state.balance >= amount) {
      state = state.copyWith(balance: state.balance - amount);
    }
  }

  void useFuel() {
    if (state.dailyFuel > 0) {
      state = state.copyWith(dailyFuel: state.dailyFuel - 1);
    }
  }

  void refillFuel() {
    state = state.copyWith(
      dailyFuel: state.maxFuel,
      lastFuelRefill: DateTime.now(),
    );
  }

  void addMeal() {
    state = state.copyWith(
      kitchenJourneyMeals: state.kitchenJourneyMeals + 1,
    );
  }

  void setFromServer(Map<String, dynamic> data) {
    state = state.copyWith(
      balance: (data['coinBalance'] as num?)?.toInt() ?? state.balance,
      totalEarned:
          (data['totalCoinsEarned'] as num?)?.toInt() ?? state.totalEarned,
      dailyFuel: (data['dailyFuel'] as num?)?.toInt() ?? state.dailyFuel,
      kitchenJourneyMeals:
          (data['totalMeals'] as num?)?.toInt() ?? state.kitchenJourneyMeals,
    );
  }
}

final coinControllerProvider =
    StateNotifierProvider<CoinController, CoinState>(
  (ref) => CoinController(),
);

/// Rating engine state.
class RatingEngineState {
  final int cookModeCompletions;
  final int currentStreak;
  final int savedRecipes;
  final bool hasRated;
  final DateTime? lastPromptDate;
  final DateTime? snoozedUntil;

  const RatingEngineState({
    this.cookModeCompletions = 0,
    this.currentStreak = 0,
    this.savedRecipes = 0,
    this.hasRated = false,
    this.lastPromptDate,
    this.snoozedUntil,
  });

  RatingEngineState copyWith({
    int? cookModeCompletions,
    int? currentStreak,
    int? savedRecipes,
    bool? hasRated,
    DateTime? lastPromptDate,
    DateTime? snoozedUntil,
  }) {
    return RatingEngineState(
      cookModeCompletions:
          cookModeCompletions ?? this.cookModeCompletions,
      currentStreak: currentStreak ?? this.currentStreak,
      savedRecipes: savedRecipes ?? this.savedRecipes,
      hasRated: hasRated ?? this.hasRated,
      lastPromptDate: lastPromptDate ?? this.lastPromptDate,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }

  /// Should we show the rating prompt?
  bool get shouldPrompt {
    if (hasRated) return false;
    if (snoozedUntil != null && DateTime.now().isBefore(snoozedUntil!)) {
      return false;
    }
    // Trigger A: first cook mode completion
    if (cookModeCompletions == 1) return true;
    // Trigger B: 3-day streak
    if (currentStreak == 3) return true;
    // Trigger C: 5 saved recipes
    if (savedRecipes == 5) return true;
    return false;
  }
}

class RatingEngineController extends StateNotifier<RatingEngineState> {
  RatingEngineController() : super(const RatingEngineState());

  void onCookModeComplete() {
    state = state.copyWith(
      cookModeCompletions: state.cookModeCompletions + 1,
    );
  }

  void onStreakUpdate(int streak) {
    state = state.copyWith(currentStreak: streak);
  }

  void onRecipeSaved() {
    state = state.copyWith(savedRecipes: state.savedRecipes + 1);
  }

  void markRated() {
    state = state.copyWith(hasRated: true, lastPromptDate: DateTime.now());
  }

  void snooze() {
    state = state.copyWith(
      snoozedUntil: DateTime.now().add(const Duration(days: 14)),
    );
  }
}

final ratingEngineProvider =
    StateNotifierProvider<RatingEngineController, RatingEngineState>(
  (ref) => RatingEngineController(),
);
