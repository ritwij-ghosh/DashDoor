import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoinModel {
  final int balance;
  final int totalEarned;
  final int dailyFuel;
  final int maxFuel;

  const CoinModel({
    required this.balance,
    required this.totalEarned,
    required this.dailyFuel,
    required this.maxFuel,
  });
}

class ChallengeModel {
  final String id;
  final String type;
  final bool isActive;
  final int currentDay;
  final List<bool> daysCompleted;

  const ChallengeModel({
    required this.id,
    required this.type,
    required this.isActive,
    required this.currentDay,
    required this.daysCompleted,
  });
}

/// Local stub — no API calls.
class GamificationRepository {
  const GamificationRepository();

  Future<void> saveOnboarding(Map<String, dynamic> data) async {}

  Future<void> saveNotificationPrefs(Map<String, dynamic> prefs) async {}

  Future<void> saveContract(int commitNights) async {}

  Future<void> updateSubscription(Map<String, dynamic> data) async {}

  Future<void> earnCoins({
    required int amount,
    required String type,
    String? sourceRefId,
    required String idempotencyKey,
  }) async {}

  Future<ChallengeModel> startChallenge(String type) async {
    return ChallengeModel(
      id: 'local',
      type: type,
      isActive: true,
      currentDay: 0,
      daysCompleted: const [false, false, false],
    );
  }

  Future<CoinModel> getCoins() async {
    return const CoinModel(
      balance: 0,
      totalEarned: 0,
      dailyFuel: 5,
      maxFuel: 5,
    );
  }

  Future<ChallengeModel?> getActiveChallenge() async => null;
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return const GamificationRepository();
});

final coinsProvider = FutureProvider<CoinModel>((ref) async {
  return ref.watch(gamificationRepositoryProvider).getCoins();
});

final activeChallengeProvider = FutureProvider<ChallengeModel?>((ref) async {
  return ref.watch(gamificationRepositoryProvider).getActiveChallenge();
});
