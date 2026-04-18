import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const String _kEntitlementId = 'plus';

enum PurchaseOutcome { success, cancelled, error }

class PurchaseResult {
  final PurchaseOutcome outcome;
  final CustomerInfo? customerInfo;
  final String? errorMessage;
  final PurchasesErrorCode? errorCode;

  const PurchaseResult._({
    required this.outcome,
    this.customerInfo,
    this.errorMessage,
    this.errorCode,
  });

  const PurchaseResult.success(CustomerInfo info)
      : this._(outcome: PurchaseOutcome.success, customerInfo: info);

  const PurchaseResult.cancelled()
      : this._(outcome: PurchaseOutcome.cancelled);

  const PurchaseResult.error(String message, {PurchasesErrorCode? code})
      : this._(
          outcome: PurchaseOutcome.error,
          errorMessage: message,
          errorCode: code,
        );

  bool get isSuccess => outcome == PurchaseOutcome.success;
  bool get isCancelled => outcome == PurchaseOutcome.cancelled;
  bool get isError => outcome == PurchaseOutcome.error;
}

class RestoreResult {
  final bool success;
  final CustomerInfo? customerInfo;
  final String? errorMessage;

  const RestoreResult._({
    required this.success,
    this.customerInfo,
    this.errorMessage,
  });

  const RestoreResult.success(CustomerInfo info)
      : this._(success: true, customerInfo: info);

  const RestoreResult.error(String message)
      : this._(success: false, errorMessage: message);
}

enum SubscriptionStatus { free, trial, active, expired, cancelled }

class SubscriptionInfo {
  final SubscriptionStatus status;
  final bool isPlus;
  final DateTime? expirationDate;
  final String? productId;
  final String? managementUrl;

  const SubscriptionInfo({
    this.status = SubscriptionStatus.free,
    this.isPlus = false,
    this.expirationDate,
    this.productId,
    this.managementUrl,
  });

  const SubscriptionInfo.free()
      : status = SubscriptionStatus.free,
        isPlus = false,
        expirationDate = null,
        productId = null,
        managementUrl = null;
}

/// Stub: does not configure the native Purchases SDK (no backend / keys yet).
class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[RevenueCat] Stub init — SDK not configured.');
  }

  Future<void> login(String userId) async {}

  Future<void> logout() async {}

  Future<Offerings?> getOfferings() async => null;

  Future<PurchaseResult> purchasePackage(Package package) async {
    return const PurchaseResult.cancelled();
  }

  Future<RestoreResult> restorePurchases() async {
    return const RestoreResult.error('Purchases are not configured yet.');
  }

  Future<CustomerInfo?> getCustomerInfo() async => null;

  SubscriptionInfo parseCustomerInfo(CustomerInfo? info) {
    if (info == null) return const SubscriptionInfo.free();

    final entitlement = info.entitlements.all[_kEntitlementId];
    if (entitlement == null || !entitlement.isActive) {
      return const SubscriptionInfo.free();
    }

    final expDate = entitlement.expirationDate != null
        ? DateTime.tryParse(entitlement.expirationDate!)
        : null;

    SubscriptionStatus status;
    if (entitlement.periodType == PeriodType.trial) {
      status = SubscriptionStatus.trial;
    } else if (entitlement.isActive) {
      status = SubscriptionStatus.active;
    } else if (entitlement.unsubscribeDetectedAt != null) {
      status = SubscriptionStatus.cancelled;
    } else {
      status = SubscriptionStatus.expired;
    }

    return SubscriptionInfo(
      status: status,
      isPlus: entitlement.isActive,
      expirationDate: expDate,
      productId: entitlement.productIdentifier,
      managementUrl: info.managementURL,
    );
  }

  void addCustomerInfoListener(void Function(CustomerInfo) listener) {}
}

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService.instance;
});

final subscriptionInfoProvider =
    StateNotifierProvider<SubscriptionInfoNotifier, SubscriptionInfo>((ref) {
  final rc = ref.watch(revenueCatServiceProvider);
  return SubscriptionInfoNotifier(rc);
});

class SubscriptionInfoNotifier extends StateNotifier<SubscriptionInfo> {
  SubscriptionInfoNotifier(this._rc) : super(const SubscriptionInfo.free()) {
    _init();
  }

  final RevenueCatService _rc;

  Future<void> _init() async {
    final info = await _rc.getCustomerInfo();
    state = _rc.parseCustomerInfo(info);
    _rc.addCustomerInfoListener((info) {
      state = _rc.parseCustomerInfo(info);
    });
  }

  Future<void> refresh() async {
    final info = await _rc.getCustomerInfo();
    state = _rc.parseCustomerInfo(info);
  }
}

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  final rc = ref.watch(revenueCatServiceProvider);
  return rc.getOfferings();
});
