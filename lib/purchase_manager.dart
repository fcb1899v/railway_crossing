import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:railroad_crossing/common_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'common_widget.dart';
import 'constant.dart';

/// ===== PURCHASE MANAGER CLASS =====
// Purchase Manager Class - Handles in-app purchases and subscription management
class PurchaseManager {
  final BuildContext context;
  
  PurchaseManager({
    required this.context,
  });

  /// ===== OFFERING MANAGEMENT =====
  // Get one-time purchase offerings from RevenueCat
  Future<Offering?> getOnetimeOfferings() async {
    final offerings = await Purchases.getOfferings();
    return offerings.getOffering(normalOffering);
  }

  /// ===== PRICE LOADING METHODS =====
  // Load and cache one-time purchase price from RevenueCat
  Future<String> loadOnetimePrice(SharedPreferences prefs) async {
    final price = "onetime_price".getSharedPrefString(prefs, defaultPrice);
    if (price == defaultPrice) {
      try {
        final targetOffering = await getOnetimeOfferings();
        final package = targetOffering!.availablePackages[0];
        final storeProduct = package.storeProduct;
        final newPrice = storeProduct.priceString;
        "onetime_price".setSharedPrefString(prefs, newPrice);
        return newPrice;
      } catch (e) {
        "default_price: $defaultOnetimePrice".debugPrint();
        return defaultOnetimePrice;
      }
    } else {
      return price;
    }
  }

  /// ===== PURCHASE EXECUTION METHODS =====
  // Execute purchase transaction with specified offering and subscription type
  Future<CustomerInfo> getPurchaseResult({
    required String offering,
    required bool isSubscription
  }) async {
    final offerings = await Purchases.getOfferings();
    "offering: $offerings".debugPrint();
    final targetOffering = offerings.getOffering(offering)!;
    final purchaseResult = await Purchases.purchasePackage(isSubscription ? targetOffering.monthly!: targetOffering.lifetime!);
    "purchaseResult: $purchaseResult".debugPrint();
    return purchaseResult;
  }

  // Execute one-time purchase transaction
  Future<CustomerInfo?> buyOnetime() async {
    try {
      "buyOnetime".debugPrint();
      final purchaseResult = await getPurchaseResult(
        offering: normalOffering,
        isSubscription: false
      );
      if (purchaseResult.allPurchasedProductIdentifiers.isNotEmpty) {
        return purchaseResult;
      } else {
        "onetimePurchaseError".debugPrint();
        return null;
      }
    } on PlatformException catch (e) {
      "onetimePurchaseError: $e".debugPrint();
      return null;
    }
  }

  /// ===== UNUSED FUNCTIONS (COMMENTED OUT) =====
  // Note: The following functions are commented out and not currently used
  // They provide subscription management functionality for future use
  
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


