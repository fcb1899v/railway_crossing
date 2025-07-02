import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:railroad_crossing/common_extension.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common_widget.dart';
import 'constant.dart';

///Class For subscription
class PurchaseManager {

  final BuildContext context;
  PurchaseManager({required this.context});

  Future<CustomerInfo> getRestoreInfo() async {
    final restoredInfo = await Purchases.restorePurchases();
    "restoreInfo: $restoredInfo".debugPrint();
    return restoredInfo;
  }

  DateTime getOriginalPurchaseDate(CustomerInfo purchaseResult) {
    final originalPurchaseDate = DateTime.parse(purchaseResult.originalPurchaseDate!);
    "originalPurchaseDate: $originalPurchaseDate".debugPrint();
    return originalPurchaseDate;
  }

  Future<CustomerInfo> getPurchaseResult(String offering, bool isSubscription) async {
    final offerings = await Purchases.getOfferings();
    final targetOffering = offerings.getOffering(offering)!;
    final purchaseResult = await Purchases.purchasePackage(isSubscription ? targetOffering.lifetime!: targetOffering.monthly!);
    "purchaseResult: $purchaseResult".debugPrint();
    return purchaseResult;
  }

  Future<CustomerInfo?> restorePlan(String currentPlan) async {
    try {
      "restorePlan".debugPrint();
      final restoredInfo = await getRestoreInfo();
      if (restoredInfo.activeSubscriptions.isNotEmpty && currentPlan == freeID) {
        if (context.mounted) purchaseSubscriptionSuccessDialog(context, restoredInfo.planID(), null, isRestore: true, isCancel: false);
        return restoredInfo;
      } else {
        if (context.mounted) purchaseErrorDialog(context, isRestore: true, isCancel: false);
        return null;
      }
    } on PlatformException catch (e) {
      if (context.mounted) purchaseExceptionDialog(context, e, isRestore: true, isCancel: false);
      return null;
    }
  }

  Future<CustomerInfo?> buySubscription(String planID, List<dynamic> activePlan) async {
    if (!activePlan.contains(planID)) {
      try {
        "buySubscription".debugPrint();
        final purchaseResult = await getPurchaseResult(planID.offeringID(), true);
        if (purchaseResult.isSubscriptionActive(planID)) {
          if (context.mounted) purchaseSubscriptionSuccessDialog(context, purchaseResult.planID(), null, isRestore: false, isCancel: false);
          return purchaseResult;
        } else {
          if (context.mounted) await purchaseErrorDialog(context, isRestore: false, isCancel: false);
          return null;
        }
      } on PlatformException catch (e) {
        if (context.mounted) await purchaseExceptionDialog(context, e, isRestore: false, isCancel: false);
        return null;
      }
    } else{
      if (context.mounted) await purchaseFinishedDialog(context, isRestore: false, isCancel: false);
      return null;
    }
  }

  Future<CustomerInfo?> buyOnetime(String offering) async {
    try {
      "buyOnetime".debugPrint();
      final purchaseResult = await getPurchaseResult(offering, false);
      if (purchaseResult.allPurchasedProductIdentifiers.isNotEmpty) {
        return purchaseResult;
      } else {
        if (context.mounted) await onetimePurchaseErrorDialog(context);
        return null;
      }
    } on PlatformException catch (e) {
      if (context.mounted) await onetimePurchaseExceptionDialog(context, e);
      return null;
    }
  }

  Future<CustomerInfo?> upgradePremium(List<dynamic> activePlan) async {
    try {
      if (!activePlan.contains(premiumID)) {
        final offerings = await Purchases.getOfferings();
        final offering = offerings.getOffering(premiumID.offeringID());
        final purchaseResult = await Purchases.purchasePackage(
          offering!.monthly!,
          googleProductChangeInfo: GoogleProductChangeInfo(standardID),
        );
        "Upgrade premium: $purchaseResult".debugPrint();
        if (purchaseResult.isSubscriptionActive(premiumID)) {
          return purchaseResult;
        } else {
          if (context.mounted) await purchaseErrorDialog(context, isRestore: false, isCancel: false);
          return null;
        }
      } else{
        if (context.mounted) await purchaseFinishedDialog(context, isRestore: false, isCancel: false);
        return null;
      }
    } on PlatformException catch (e) {
      if (context.mounted) await purchaseExceptionDialog(context, e, isRestore: false, isCancel: false);
      return null;
    }
  }

  Future<void> cancelPlan(List<dynamic> activePlan) async {
    "activePlan: $activePlan".debugPrint();
    if (activePlan.isNotEmpty) {
      try {
        final canLaunch = await canLaunchUrl(subscriptionUri);
        "canLaunchUrl: $canLaunch".debugPrint();
        if (context.mounted) context.pushHomePage();
        await launchUrl(subscriptionUri, mode: LaunchMode.externalApplication);
      } on PlatformException catch (e) {
        if (context.mounted) await purchaseExceptionDialog(context, e, isRestore: false, isCancel: true);
      }
    } else {
      if (context.mounted) await purchaseFinishedDialog(context, isRestore: false, isCancel: true);
    }
  }
}


