import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:railroad_crossing/extension.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'common_widget.dart';
import 'analytics_manager.dart';
import 'common_function.dart';
import 'constant.dart';

/// ===== PURCHASE MANAGER CLASS =====
// Purchase Manager Class - Handles in-app purchases and subscription management
class PurchaseManager {
  final BuildContext context;
  
  PurchaseManager({
    required this.context,
  });

  /// ===== PRICE LOADING METHODS =====
  /// The live store price, empty while unknown. Purchase entry points are drawn only
  /// from it: never from a stored price or a fixed fallback, which may not be what is charged
  static final ValueNotifier<String> onetimePrice = ValueNotifier("");
  /// The fetch in flight, joined by a second caller instead of starting another
  static Future<String?>? _pricing;
  /// The one prefetch per process, however often the home screen is rebuilt
  static Future<String?>? _prefetch;

  /// Fetches the price once, a few seconds after launch work, so the menu opens with it
  static Future<String?> prefetchOnetimePrice() =>
    _prefetch ??= Future.delayed(pricePrefetchDelay, loadOnetimePrice);

  /// The known price, else the fetch in flight, else a new fetch
  static Future<String?> loadOnetimePrice() async => onetimePrice.value.isNotEmpty
    ? onetimePrice.value
    : await (_pricing ??= _fetchOnetimePrice().whenComplete(() => _pricing = null));

  static Future<String?> _fetchOnetimePrice() async {
    try {
      await ensurePurchaseInitialized();
      final offerings = await Purchases.getOfferings();
      final price = onetimePackage(offerings, normalOffering)?.storeProduct.priceString;
      "onetime price: $price".debugPrint();
      onetimePrice.value = price ?? "";
      return price;
    } catch (e) {
      "onetime price unavailable: $e".debugPrint();
      onetimePrice.value = "";
      return null;
    }
  }

  /// The one-time package: both the displayed price and the purchase come from it,
  /// so what is shown is what is charged. Null means nothing to sell
  static Package? onetimePackage(Offerings offerings, String offering) =>
    offerings.getOffering(offering)?.lifetime;

  /// ===== PURCHASE EXECUTION METHODS =====
  // Execute purchase transaction with specified offering and subscription type
  Future<CustomerInfo> getPurchaseResult({
    required String offering,
    required bool isSubscription
  }) async {
    await ensurePurchaseInitialized();
    final offerings = await Purchases.getOfferings();
    "offering: $offerings".debugPrint();
    final package = isSubscription
      ? offerings.getOffering(offering)?.monthly
      : onetimePackage(offerings, offering);
    // Caught by the caller's error dialog, instead of a null check crashing the flow
    if (package == null) throw StateError("No package to purchase in $offering");
    final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
    "purchaseResult: $purchaseResult".debugPrint();
    return purchaseResult.customerInfo;
  }

  /// Execute the one-time purchase and report purchased, cancelled or failed
  /// Cancelled and failed are told apart so the caller can count them separately
  /// Exceptions other than PlatformException (e.g. StateError) propagate to the caller
  Future<OnetimePurchaseResult> buyOnetime() async {
    try {
      "buyOnetime".debugPrint();
      final purchaseResult = await getPurchaseResult(
        offering: normalOffering,
        isSubscription: false
      );
      return onetimeResultOf(purchaseResult.allPurchasedProductIdentifiers, purchaseResult);
    } on PlatformException catch (e) {
      "onetimePurchaseError: $e".debugPrint();
      return onetimeResultOfError(e);
    }
  }

  /// ===== UNUSED FUNCTIONS (COMMENTED OUT) =====
  // Subscription management kept for future use
  
  // Restore purchase information from app stores
  // Future<CustomerInfo> getRestoreInfo() async {
  //   final restoredInfo = await Purchases.restorePurchases();
  //   "restoreInfo: $restoredInfo".debugPrint();
  //   return restoredInfo;
  // }
  //
  // Get original purchase date from customer info
  // DateTime getOriginalPurchaseDate(CustomerInfo purchaseResult) {
  //   final originalPurchaseDate = DateTime.parse(purchaseResult.originalPurchaseDate!);
  //   "originalPurchaseDate: $originalPurchaseDate".debugPrint();
  //   return originalPurchaseDate;
  // }
  //
  // Restore subscription plan with validation
  // Future<CustomerInfo?> restorePlan({
  //   required String currentPlan,
  //   required int expirationDate,
  // }) async {
  //   try {
  //     "restorePlan".debugPrint();
  //     final restoredInfo = await getRestoreInfo();
  //     if (restoredInfo.activeSubscriptions.isNotEmpty && currentPlan == freeID) {
  //       if (context.mounted) purchaseSubscriptionSuccessDialog(restoredInfo.planID(), expirationDate: expirationDate, isRestore: true, isCancel: false);
  //       return restoredInfo;
  //     } else {
  //       if (context.mounted) purchaseErrorDialog(isRestore: true, isCancel: false);
  //       return null;
  //     }
  //   } on PlatformException catch (e) {
  //     if (context.mounted) purchaseExceptionDialog(e: e, isRestore: true, isCancel: false);
  //     return null;
  //   }
  // }
  //
  // Purchase subscription plan with validation
  // Future<CustomerInfo?> buySubscription({
  //   required String planID,
  //   required List<dynamic> activePlan,
  //   required int expirationDate,
  // }) async {
  //   if (!activePlan.contains(planID)) {
  //     try {
  //       "buySubscription".debugPrint();
  //       final purchaseResult = await getPurchaseResult(
  //           offering: planID.offeringID(),
  //           isSubscription: true
  //       );
  //       if (purchaseResult.isSubscriptionActive(planID)) {
  //         if (context.mounted) purchaseSubscriptionSuccessDialog(purchaseResult.planID(), expirationDate: expirationDate, isRestore: false, isCancel: false);
  //         return purchaseResult;
  //       } else {
  //         if (context.mounted) purchaseErrorDialog(isRestore: false, isCancel: false);
  //         return null;
  //       }
  //     } on PlatformException catch (e) {
  //       if (context.mounted) purchaseExceptionDialog(e: e, isRestore: false, isCancel: false);
  //       return null;
  //     }
  //   } else{
  //     if (context.mounted) purchaseFinishedDialog(isRestore: false, isCancel: false);
  //     return null;
  //   }
  // }
  //
  // Upgrade to premium subscription plan
  // Future<CustomerInfo?> upgradePremium(List<dynamic> activePlan) async {
  //   try {
  //     if (!activePlan.contains(premiumID)) {
  //       final offerings = await Purchases.getOfferings();
  //       final offering = offerings.getOffering(premiumID.offeringID());
  //       final purchaseResult = await Purchases.purchasePackage(
  //         offering!.monthly!,
  //         googleProductChangeInfo: GoogleProductChangeInfo(standardID),
  //       );
  //       "Upgrade premium: $purchaseResult".debugPrint();
  //       if (purchaseResult.isSubscriptionActive(premiumID)) {
  //         return purchaseResult;
  //       } else {
  //         if (context.mounted) purchaseErrorDialog(isRestore: false, isCancel: false);
  //         return null;
  //       }
  //     } else{
  //       if (context.mounted) purchaseFinishedDialog(isRestore: false, isCancel: false);
  //       return null;
  //     }
  //   } on PlatformException catch (e) {
  //     if (context.mounted) purchaseExceptionDialog(e: e, isRestore: false, isCancel: false);
  //     return null;
  //   }
  // }
  //
  // Cancel subscription plan by opening external URL
  // Future<void> cancelPlan(List<dynamic> activePlan) async {
  //   "activePlan: $activePlan".debugPrint();
  //   if (activePlan.isNotEmpty) {
  //     try {
  //       final canLaunch = await canLaunchUrl(subscriptionUri);
  //       "canLaunchUrl: $canLaunch".debugPrint();
  //       if (context.mounted) context.pushHomePage();
  //       await launchUrl(subscriptionUri, mode: LaunchMode.externalApplication);
  //     } on PlatformException catch (e) {
  //       if (context.mounted) purchaseExceptionDialog(e: e, isRestore: false, isCancel: true);
  //     }
  //   } else {
  //     if (context.mounted) purchaseFinishedDialog(isRestore: false, isCancel: true);
  //   }
  // }
  //
  // Show purchase exception dialog with error details
  // void purchaseExceptionDialog({
  //   required bool isRestore,
  //   required bool isCancel,
  //   required PlatformException e,
  // }) {
  //   final errorCode = PurchasesErrorHelper.getErrorCode(e);
  //   "${isRestore ? "Restore": isCancel ? "Cancel": "Purchase"} Error: $e".debugPrint();
  //   return CommonWidget(context: context).customDialog(
  //     title: context.errorPurchaseTitle(isRestore, isCancel),
  //     content: context.purchaseErrorMessage(errorCode, isRestore, isCancel),
  //     isPositive: false,
  //   );
  // }
  //
  // Show purchase error dialog for general errors
  // void purchaseErrorDialog({
  //   required bool isRestore,
  //   required bool isCancel
  // }) {
  //   "${isRestore ? "Restore": isCancel ? "Cancel": "Purchase"} Error".debugPrint();
  //   return CommonWidget(context: context).customDialog(
  //     title: context.errorPurchaseTitle(isRestore, isCancel),
  //     content: "",
  //     isPositive: false,
  //   );
  // }
  //
  // Show purchase finished dialog for completed transactions
  // void purchaseFinishedDialog({
  //   required bool isRestore,
  //   required bool isCancel
  // }) {
  //   "Have already finished purchase".debugPrint();
  //   return CommonWidget(context: context).customDialog(
  //     title: context.errorPurchaseTitle(isRestore, isCancel),
  //     content: context.finishPurchaseMessage(isRestore, isCancel),
  //     isPositive: false,
  //   );
  // }
  //
  // Show subscription purchase success dialog
  // void purchaseSubscriptionSuccessDialog(String planID, {
  //   required bool isRestore,
  //   required bool isCancel,
  //   required int expirationDate,
  // }) {
  //   "${isRestore ? "Restore": isCancel ? "Cancel": "Purchase"} Success: $planID".debugPrint();
  //   return CommonWidget(context: context).customDialog(
  //     title: context.planPurchaseTitle(planID, isRestore, isCancel),
  //     content: context.successPurchaseMessage(planID, expirationDate, isRestore, isCancel),
  //     isPositive: true,
  //   );
  // }
  //
  // Show one-time purchase success dialog
  // void purchaseOnetimeSuccessDialog(String plan) {
  //   "Purchase Success: Buy onetime passes".debugPrint();
  //   return CommonWidget(context: context).customDialog(
  //     title: (plan == freeID) ? context.onetime(): context.onetime(),
  //     content: (plan == freeID) ? context.successOnetime(): context.successAddOn(),
  //     isPositive: true,
  //   );
  // }

}




/// The outcome of one one-time purchase attempt
enum OnetimePurchaseStatus { purchased, cancelled, failed }

class OnetimePurchaseResult {
  final OnetimePurchaseStatus status;
  /// Set for purchased only
  final CustomerInfo? customerInfo;
  /// Set for failed only: PurchasesErrorCode.name, store_unavailable, empty_result or other
  final String? reason;

  const OnetimePurchaseResult._(this.status, this.customerInfo, this.reason);
  const OnetimePurchaseResult.purchased([CustomerInfo? info]) : this._(OnetimePurchaseStatus.purchased, info, null);
  const OnetimePurchaseResult.cancelled() : this._(OnetimePurchaseStatus.cancelled, null, null);
  const OnetimePurchaseResult.failed(String reason) : this._(OnetimePurchaseStatus.failed, null, reason);

  bool get isPurchased => status == OnetimePurchaseStatus.purchased;
}

/// Purchased when the store reports a purchased product, else failed with empty_result
OnetimePurchaseResult onetimeResultOf(Iterable<String> purchasedProductIds, CustomerInfo? info) =>
  purchasedProductIds.isNotEmpty
    ? OnetimePurchaseResult.purchased(info)
    : const OnetimePurchaseResult.failed("empty_result");

/// Cancelled for purchaseCancelledError, else failed with the error code name
OnetimePurchaseResult onetimeResultOfError(PlatformException e) {
  final code = purchaseErrorCode(e);
  return code == PurchasesErrorCode.purchaseCancelledError
    ? const OnetimePurchaseResult.cancelled()
    : OnetimePurchaseResult.failed(code.name);
}

/// The RevenueCat error code of a PlatformException, unknownError when its code is not a number
PurchasesErrorCode purchaseErrorCode(PlatformException e) {
  try {
    return PurchasesErrorHelper.getErrorCode(e);
  } on FormatException {
    return PurchasesErrorCode.unknownError;
  }
}

/// The short fixed `reason` for an exception thrown out of the purchase
String onetimeFailureReason(Object e) {
  if (e is PlatformException) return purchaseErrorCode(e).name;
  if (e is StateError) return "store_unavailable";
  return "other";
}

/// Run a purchase and log its outcome: purchased, cancelled or failed, once each
/// Only the purchase call is inside the catch, so work done after it cannot be counted as a failure
Future<OnetimePurchaseResult> trackOnetimePurchase(
  Future<OnetimePurchaseResult> Function() buy, {
  required String source,
}) async {
  final OnetimePurchaseResult result;
  try {
    result = await buy();
  } catch (e) {
    final reason = onetimeFailureReason(e);
    unawaited(AnalyticsManager.upgradeFailed(source: source, flow: "purchase", reason: reason));
    return OnetimePurchaseResult.failed(reason);
  }
  switch (result.status) {
    case OnetimePurchaseStatus.purchased:
      unawaited(AnalyticsManager.upgradePurchased(source));
    case OnetimePurchaseStatus.cancelled:
      unawaited(AnalyticsManager.upgradeCancelled(source));
    case OnetimePurchaseStatus.failed:
      unawaited(AnalyticsManager.upgradeFailed(source: source, flow: "purchase", reason: result.reason ?? "other"));
  }
  return result;
}
