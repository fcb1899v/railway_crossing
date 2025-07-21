import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'homepage.dart';
import 'constant.dart';

/// ===== BUILD CONTEXT EXTENSIONS =====
// Extensions for BuildContext to provide additional functionality
extension ContextExt on BuildContext {

  /// ===== NAVIGATION METHODS =====
  // Navigate to home page with fade transition
  void pushHomePage() => Navigator.pushReplacement(this,
    PageRouteBuilder(
      pageBuilder: (context, animation, _) => HomePage(),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 500),
    )
  );

  // Pop current page from navigation stack
  void popPage() => Navigator.of(this).pop();

  /// ===== LOCALE AND LANGUAGE METHODS =====
  // Get current locale for internationalization
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  /// ===== DATE FORMATTING METHODS =====
  // Format date according to country and language preferences
  String toCountryDate(int countryNumber, int date) =>
    (lang() == "ja") ? "${date.toDate().year}/${date.toDate().month}/${date.toDate().day}":
    (lang() == "zh") ? "${date.toDate().year}年${date.toDate().month}月${date.toDate().day}日":
    (countryNumber == 1) ? "${date.toDate().day} ${monthList[date.toDate().month - 1]} ${date.toDate().year}":
    "${monthList[date.toDate().month - 1]} ${date.toDate().day}, ${date.toDate().year}";
  
  // Format date without year according to country and language preferences
  String toCountryDateNoYear(int countryNumber, int date) =>
    (lang() == "ja") ? "${date.toDate().month}/${date.toDate().day}":
    (lang() == "zh") ? "${date.toDate().month}月${date.toDate().day}日":
    (countryNumber == 1) ? "${date.toDate().day} ${monthList[date.toDate().month - 1]}":
    "${monthList[date.toDate().month - 1]} ${date.toDate().day}";

  /// ===== LOCALIZATION METHODS =====
  // Get localized strings for app interface
  String appTitle() => AppLocalizations.of(this)!.appTitle;
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String ok() => AppLocalizations.of(this)!.ok;
  String cancel() => AppLocalizations.of(this)!.cancel;
  String shots(String number) => AppLocalizations.of(this)!.shots(number);
  String noPasses() => AppLocalizations.of(this)!.noPasses;
  String oneFree() => AppLocalizations.of(this)!.oneFree;
  String checkNetwork() => AppLocalizations.of(this)!.checkNetwork;
  String useTickets(int number) => AppLocalizations.of(this)!.useTickets(number);
  
  // Get photo shots text based on current date and ticket availability
  String photoShots(int currentDate, int lastClaimedDate, int tickets) =>
      !lastClaimedDate.isToday(currentDate) ? oneFree():
      (tickets < 1) ? noPasses():
      shots("$tickets");
  
  // Photo-related localized strings
  String photoSaved() => AppLocalizations.of(this)!.photoSaved;
  String photoCaptureFailed() => AppLocalizations.of(this)!.photoCaptureFailed;
  String photoSavingFailed() => AppLocalizations.of(this)!.photoSavingFailed;
  String photoAccessPermission() => AppLocalizations.of(this)!.photoAccessPermission;

  /// ===== MENU LOCALIZATION METHODS =====
  // Menu-related localized strings
  String upgrade() => AppLocalizations.of(this)!.upgrade;
  String buyPasses() => AppLocalizations.of(this)!.buyPasses;
  String purchasePlan(String plan) =>
    (plan == premiumID) ? buyOnetimePasses():
    (plan == standardID) ? upgrade():
    buyPasses();
  String ticket() => AppLocalizations.of(this)!.ticket;
  String todayPass() => AppLocalizations.of(this)!.todayPass;
  String ticketsLeft(int currentDate, int lastClaimedDate) =>
      !lastClaimedDate.isToday(currentDate) ? todayPass() : ticketNumber();
  String none() => AppLocalizations.of(this)!.none;
  String oneFreePerDay() => AppLocalizations.of(this)!.oneFreePerDay;
  String number(int tickets) => AppLocalizations.of(this)!.number(tickets);
  String menuTicketsNumber(int tickets, int currentDate, int lastClaimedDate) =>
    !lastClaimedDate.isToday(currentDate) ? oneFreePerDay():
    (tickets > 0) ? number(tickets):
    none();
  String buyOnetimePasses() => AppLocalizations.of(this)!.buyOnetimePasses;
  String purchaseButtonText(String plan, bool isOnetime, bool isCancel) =>
    isCancel ? cancelSubscription():
    isOnetime ? buyOnetimePasses():
    (plan == standardID) ? toUpgrade():
    toBuy();
  String contactUs() => AppLocalizations.of(this)!.contactUs;
  String contactUrl() => AppLocalizations.of(this)!.contactUrl;
  String terms() => AppLocalizations.of(this)!.terms;
  String termsUrl() => AppLocalizations.of(this)!.termsUrl;

  /// ===== PLAN TABLE LOCALIZATION METHODS =====
  // Plan table-related localized strings
  String worldsFirstApp() => AppLocalizations.of(this)!.worldsFirstApp;
  String current() => AppLocalizations.of(this)!.current;
  String plan() => AppLocalizations.of(this)!.plan;
  String tickets() => AppLocalizations.of(this)!.tickets;
  String ticketNumber() => AppLocalizations.of(this)!.ticketNumber;
  String trial() => AppLocalizations.of(this)!.trial;
  String onetime() => AppLocalizations.of(this)!.onetime;
  String timing() => AppLocalizations.of(this)!.timing;
  String rollover() => AppLocalizations.of(this)!.rollover;
  String rolloverTickets() => AppLocalizations.of(this)!.rolloverTickets;
  String adFree() => AppLocalizations.of(this)!.adFree;
  String adDisplay() => AppLocalizations.of(this)!.adDisplay;
  String adFreeDate(String date) => AppLocalizations.of(this)!.adFreeDate(date);
  String freeDate(String date) => AppLocalizations.of(this)!.freeDate(date);
  String price() => AppLocalizations.of(this)!.price;
  String buy() => AppLocalizations.of(this)!.buy;
  List<String> purchaseDataTitleList(String planID) =>
      (planID == freeID) ? [plan(), tickets(), timing(), rollover(), adFree(), price(), buy()]:
      [current(), plan(), tickets(), adFree()];
  List<String> upgradeDataTitleList() => [current(), plan(), tickets(), adFree(), price()];
  List<String> onetimeDataTitleList() => [onetime(), rolloverTickets(), price()];

  /// ===== TICKET AND PLAN DATA METHODS =====
  // Ticket-related localized strings
  String photos(int number) => (number == 0) ? "-" : AppLocalizations.of(this)!.photos(number);
  
  // Plan-related localized strings
  String premium() => AppLocalizations.of(this)!.premium;
  String standard() => AppLocalizations.of(this)!.standard;
  String free() => AppLocalizations.of(this)!.free;
  String premiumTitle() => AppLocalizations.of(this)!.premiumTitle;
  String standardTitle() => AppLocalizations.of(this)!.standardTitle;
  String currentPlanTitle(String currentPlan) =>
      "${(currentPlan == premiumID) ? premium() : (currentPlan == standardID) ? standard() : free()} ${plan()}";
  List<String> purchasePlanList(String plan) =>
      (plan == freeID) ? [premiumTitle(), standardTitle(), trial(), free()]:
      [premiumTitle(), standardTitle(), free()];
  List<String> upgradePlanList() => [premiumTitle(), standardTitle()];
  
  // Timing-related localized strings
  String renewal() => AppLocalizations.of(this)!.renewal;
  String immediate() => AppLocalizations.of(this)!.immediate;
  List<String> timingList() => [renewal(), renewal(), immediate(), "-"];
  
  // Rollover-related localized strings
  String available() => AppLocalizations.of(this)!.available;
  String expire() => AppLocalizations.of(this)!.expire;
  List<String> purchaseRolloverList(String plan) =>
      (plan == freeID) ? [expire(), expire(), available(), "-"]: [expire(), expire(), "-"];

  // Ad-free-related localized strings
  String yes() => AppLocalizations.of(this)!.yes;
  String no() => AppLocalizations.of(this)!.no;
  String adFreeText(String plan) => (plan == premiumID) ? yes() : no();
  String onetimeAdFreeText(int currentDate, int expirationDate) =>
      (currentDate > expirationDate) ? yes() : no();
  List<String> purchaseAdFreeList(String plan) =>
      (plan == freeID) ? [yes(), no(), no(), no()] : [yes(), no(), no()];
  List<String> upgradeAdFreeList() => [yes(), no()];

  // Price-related localized strings
  String monthly() => AppLocalizations.of(this)!.monthly;
  String toBuy() => AppLocalizations.of(this)!.toBuy;
  String toUpgrade() => AppLocalizations.of(this)!.toUpgrade;
  String cancelSubscription() => AppLocalizations.of(this)!.cancelSubscription;
  String nextRenewal(String date) => AppLocalizations.of(this)!.nextRenewal(date);
  String cancelPlan() => AppLocalizations.of(this)!.cancelPlan;
  String otherSelectPlan(String plan) => (plan == freeID) ? toRestore() : cancelPlan();

  /// ===== REVENUECAT LOCALIZATION METHODS =====
  // RevenueCat purchase-related localized strings
  String toRestore() => AppLocalizations.of(this)!.toRestore;
  String toOnetimeRestore() => AppLocalizations.of(this)!.toOnetimeRestore;
  String premiumPlan() => AppLocalizations.of(this)!.premiumPlan;
  String standardPlan() => AppLocalizations.of(this)!.standardPlan;
  String onetimePlan() => AppLocalizations.of(this)!.addOnPlan;
  String planName(String planID) => 
    (planID == premiumID) ? premiumPlan(): 
    (planID == standardID) ? standardPlan(): 
    onetimePlan();
  String planPurchase(String planID) =>
      AppLocalizations.of(this)!.planPurchase(planName(planID));
  String planRestore(String planID) =>
      AppLocalizations.of(this)!.planRestore(planName(planID));
  String planCancel(String planID) =>
      AppLocalizations.of(this)!.planCancel(planName(planID));
  String planPurchaseTitle(String planID, bool isRestore, bool isCancel) =>
      isRestore ? planRestore(planID): 
      isCancel ? planCancel(planID): 
      planPurchase(planID);
  String successPurchase(String planID) =>
      AppLocalizations.of(this)!.successPurchase(planName(planID));
  String successRestore(String planID) =>
      AppLocalizations.of(this)!.successRestore(planName(planID));
  String successCancel(String planID, int expirationDate) =>
      AppLocalizations.of(this)!
          .successCancel(planName(planID), expirationDate);
  String successPurchaseMessage(String planID, int? expirationDate, bool isRestore, bool isCancel) =>
      isRestore ? successRestore(planID): 
      isCancel ? successCancel(planID, expirationDate!): 
      successPurchase(planID);
  String successOnetime() => AppLocalizations.of(this)!.successOnetime;
  String successAddOn() => AppLocalizations.of(this)!.successAddOn;
  String errorPurchase() => AppLocalizations.of(this)!.errorPurchase;
  String errorRestore() => AppLocalizations.of(this)!.errorRestore;
  String errorCancel() => AppLocalizations.of(this)!.errorCancel;
  String errorPurchaseTitle(bool isRestore, bool isCancel) => 
      isRestore ? errorRestore(): 
      isCancel ? errorCancel(): 
      errorPurchase();
  String finishPurchase() => AppLocalizations.of(this)!.finishPurchase;
  String finishRestore() => AppLocalizations.of(this)!.finishRestore;
  String finishCancel() => AppLocalizations.of(this)!.finishCancel;
  String finishPurchaseMessage(bool isRestore, bool isCancel) => 
      isRestore ? finishRestore(): 
      isCancel ? finishCancel(): 
      finishPurchase();
  String failPurchase() => AppLocalizations.of(this)!.failPurchase;
  String failRestore() => AppLocalizations.of(this)!.failRestore;
  String failCancel() => AppLocalizations.of(this)!.failCancel;
  String failPurchaseMessage(bool isRestore, bool isCancel) => 
      isRestore ? failRestore(): 
      isCancel ? failCancel(): 
      failPurchase();
  String purchaseCancelledMessage() => AppLocalizations.of(this)!.purchaseCancelledMessage;
  String paymentPendingMessage() => AppLocalizations.of(this)!.paymentPendingMessage;
  String purchaseInvalidMessage() => AppLocalizations.of(this)!.purchaseInvalidMessage;
  String purchaseNotAllowedMessage() => AppLocalizations.of(this)!.purchaseNotAllowedMessage;
  String networkErrorMessage() => AppLocalizations.of(this)!.networkErrorMessage;
  String purchaseErrorMessage(PurchasesErrorCode errorCode, bool isRestore, bool isCancel) =>
      (errorCode == PurchasesErrorCode.purchaseCancelledError) ? purchaseCancelledMessage(): 
      (errorCode == PurchasesErrorCode.paymentPendingError) ? paymentPendingMessage(): 
      (errorCode == PurchasesErrorCode.purchaseInvalidError) ? purchaseInvalidMessage(): 
      (errorCode == PurchasesErrorCode.purchaseNotAllowedError) ? purchaseNotAllowedMessage(): 
      (errorCode == PurchasesErrorCode.networkError) ? networkErrorMessage(): 
      failPurchaseMessage(isRestore, isCancel);
  String onetimePurchaseErrorMessage(PurchasesErrorCode errorCode) =>
      (errorCode == PurchasesErrorCode.purchaseCancelledError) ? purchaseCancelledMessage():
      (errorCode == PurchasesErrorCode.paymentPendingError) ? paymentPendingMessage(): 
      (errorCode == PurchasesErrorCode.purchaseInvalidError) ? purchaseInvalidMessage(): 
      (errorCode == PurchasesErrorCode.purchaseNotAllowedError) ? purchaseNotAllowedMessage(): 
      (errorCode == PurchasesErrorCode.networkError) ? networkErrorMessage(): 
      failPurchase();

  /// ===== SIZE METHODS =====
  // Media query width and height
  double mediaWidth() => MediaQuery.of(this).size.width;
  double mediaHeight() => MediaQuery.of(this).size.height;
  bool isMediaWide() => mediaWidth() > mediaHeight() * aspectRatio;
  double width() => isMediaWide() ? mediaHeight() * aspectRatio : mediaWidth();
  double height() => isMediaWide() ? mediaHeight() : mediaWidth() / aspectRatio;
  double sideMargin() => isMediaWide() ? (mediaWidth() - mediaHeight() * aspectRatio) / 2 : 0;
  double upDownMargin() => isMediaWide() ? 0 : (mediaHeight() - mediaWidth() / aspectRatio) / 2;
  double widthResponsible() => (mediaWidth() < mediaHeight() / 2) ? mediaWidth() : mediaHeight() / 2;

  /// ===== ADMOB METHODS =====
  bool isAdmobEnoughSideSpace() => (isMediaWide() && sideMargin() > 60);
  bool isAdmobEnoughUpdDownSpace() => (!isMediaWide() && upDownMargin() > 100);
  bool isAdmobEnoughSpace() => isAdmobEnoughSideSpace() || isAdmobEnoughUpdDownSpace();
  double admobWidth() => !isAdmobEnoughSpace() ? 320: isMediaWide() ? mediaHeight(): mediaWidth();
  double admobHeight() => !isAdmobEnoughSpace() ? 50: isMediaWide() ? 60: 100;

  /// ===== POLE METHODS =====
  double frontPoleImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.95: 
    (countryNumber == 1) ? 0.80: 
    (countryNumber == 2) ? 0.90: 
    (countryNumber == 3) ? 0.95: 
    0.95
  );
  double frontPoleLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 0.165: 
    (countryNumber == 1) ? 0.165: 
    (countryNumber == 2) ? 1.28: 
    (countryNumber == 3) ? 1.4: 
    0.165
  );
  double frontPoleTopMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.00: 
    (countryNumber == 1) ? 0.16: 
    (countryNumber == 2) ? 0.05: 
    (countryNumber == 3) ? 0.00: 
    0.00
  );
  double backPoleImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.57: 
    (countryNumber == 1) ? 0.48: 
    (countryNumber == 2) ? 0.54: 
    (countryNumber == 3) ? 0.57: 
    0.57
  );
  double backPoleLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 1.15: 
    (countryNumber == 1) ? 1.165: 
    (countryNumber == 2) ? 0.46: 
    (countryNumber == 3) ? 0.488: 
    1.15
  );
  double backPoleTopMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.00: 
    (countryNumber == 1) ? 0.09: 
    (countryNumber == 2) ? 0.02: 
    (countryNumber == 3) ? 0.00: 
    0.00
  );

  /// ===== WARNING METHODS =====
  double frontWarningImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.12: 
    (countryNumber == 1) ? 0.12: 
    (countryNumber == 2) ? 0.3: 
    (countryNumber == 3) ? 0.35: 
    0.12
  );
  double frontWarningLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 0.131: 
    (countryNumber == 1) ? 0.212: 
    (countryNumber == 2) ? 1.267: 
    (countryNumber == 3) ? 1.3155: 
    0.131
  );
  double frontWarningBottomMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.30: 
    (countryNumber == 1) ? 0.45: 
    (countryNumber == 2) ? 0.14: 
    (countryNumber == 3) ? 0.30: 
    0.30
  );
  double backWarningImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.07: 
    (countryNumber == 1) ? 0.07: 
    (countryNumber == 2) ? 0.07: 
    (countryNumber == 3) ? 0.21: 
    0.07
  );
  double backWarningLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 1.132: 
    (countryNumber == 1) ? 1.132: 
    (countryNumber == 2) ? 1.132: 
    (countryNumber == 3) ? 0.469: 
    1.132
  );
  double backWarningBottomMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.18: 
    (countryNumber == 1) ? 0.18: 
    (countryNumber == 2) ? 0.18: 
    (countryNumber == 3) ? 0.18: 
    0.18
  );

  /// ===== EMERGENCY METHODS =====
  double frontEmergencyHeight() => height() * 0.42;
  double frontEmergencyTopMargin() => height() * 0.525;
  double frontEmergencyLeftMargin() => sideMargin() + height() * 0.085;
  double backEmergencyHeight() => height() * 0.252;
  double backEmergencyTopMargin() => height() * 0.3;
  double backEmergencyLeftMargin() => sideMargin() + height() * 1.29;
  double emergencyButtonHeight(int countryNumber) =>
      height() * ((countryNumber == 0) ? 0.13 : 0.10);
  double emergencyButtonLeftMargin(int countryNumber) =>
      sideMargin() + height() * ((countryNumber == 0) ? 0.085 : 0.27);
  double emergencyButtonTopMargin(int countryNumber) =>
      height() * ((countryNumber == 0) ? 0.445 : 0.445);

  /// ===== TRAFFIC SIGN METHODS =====
  double trafficSignHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.84: 
    (countryNumber == 1) ? 0.84: 
    (countryNumber == 2) ? 0.84: 
    (countryNumber == 3) ? 0.84: 
    0.84
  );
  double trafficSignLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 1.47: 
    (countryNumber == 1) ? 1.48: 
    (countryNumber == 2) ? 0.03: 
    (countryNumber == 3) ? 0.03: 
    1.77
  );
  double trafficSignTopMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.16: 
    (countryNumber == 1) ? 0.16: 
    (countryNumber == 2) ? 0.16: 
    (countryNumber == 3) ? 0.16: 
    0.16
  );

  /// ===== GATE METHODS =====
  double gateWidth(int countryNumber) => width() * (
    (countryNumber == 0) ? 1: 
    (countryNumber == 1) ? 1: 
    (countryNumber == 2) ? 2: 
    (countryNumber == 3) ? 1: 
    1
  );
  double frontGateImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.288: 
    (countryNumber == 1) ? 0.288: 
    (countryNumber == 2) ? 0.31: 
    (countryNumber == 3) ? 0.288: 
    0.288
  );
  double frontGateLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 1.425: 
    (countryNumber == 1) ? 1.465: 
    (countryNumber == 2) ? 0.0: 
    (countryNumber == 3) ? 1.430: 
    1.430
  );
  double frontGateTopMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.67: 
    (countryNumber == 1) ? 0.67: 
    (countryNumber == 2) ? 0.68: 
    (countryNumber == 3) ? 0.67: 
    0.67
  );
  double backGateImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.173: 
    (countryNumber == 1) ? 0.173: 
    (countryNumber == 2) ? 0.182: 
    (countryNumber == 3) ? 0.173: 
    0.173
  );
  double backGateLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 0.500: 
    (countryNumber == 1) ? 0.435: 
    (countryNumber == 2) ? 1.15: 
    (countryNumber == 3) ? 0.500: 
    0.500
  );
  double backGateTopMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.395: 
    (countryNumber == 1) ? 0.395: 
    (countryNumber == 2) ? 0.355: 
    (countryNumber == 3) ? 0.395: 
    0.395
  );

  /// ===== BAR METHODS =====
  double frontBarImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.145: 
    (countryNumber == 1) ? 0.145: 
    (countryNumber == 2) ? 0.22: 
    (countryNumber == 3) ? 0.17: 
    0.145
  );
  double frontBarLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 0.408: 
    (countryNumber == 1) ? 0.369: 
    (countryNumber == 2) ? 0.379: 
    (countryNumber == 3) ? 0.425: 
    0.408
  );
  double frontBarTopMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.55: 
    (countryNumber == 1) ? 0.55: 
    (countryNumber == 2) ? 0.72: 
    (countryNumber == 3) ? 0.35: 
    0.55
  );
  double backBarImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.084: 
    (countryNumber == 1) ? 0.084: 
    (countryNumber == 2) ? 0.13: 
    (countryNumber == 3) ? 0.105: 
    0.084
  );
  double backBarLeftMargin(int countryNumber) => sideMargin() + height() * (
    (countryNumber == 0) ? 0.424: 
    (countryNumber == 1) ? 0.430: 
    (countryNumber == 2) ? 0.585: 
    (countryNumber == 3) ? 0.38: 
    0.424
  );
  double backBarTopMargin(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.32: 
    (countryNumber == 1) ? 0.32: 
    (countryNumber == 2) ? 0.378: 
    (countryNumber == 3) ? 0.213: 
    0.32
  );
  double backBarShift(double shift) => shift * 0.575 * height();

  /// ===== DIRECTION METHODS =====
  double frontDirectionHeight() => height() * 0.11;
  double frontDirectionTopMargin() => height() * 0.16;
  double frontDirectionLeftMargin() => sideMargin() + height() * 0.238;
  double backDirectionHeight() => height() * 0.066;
  double backDirectionTopMargin() => height() * 0.096;
  double backDirectionLeftMargin() => sideMargin() + height() * 1.193;

  /// ===== FENCE METHODS =====
  double frontFenceImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.19: 
    (countryNumber == 1) ? 0.19: 
    0.228
  );
  double backFenceImageHeight(int countryNumber) => height() * (
    (countryNumber == 0) ? 0.111: 
    (countryNumber == 1) ? 0.111: 
    0.137
  );
  double backFenceBottomMargin(int countryNumber) =>
      upDownMargin() + height() * 0.235;

  /// ===== TRAIN METHODS =====
  double leftTrainOffset() => -height() * 0.050;
  double rightTrainOffset() => -height() * 0.025;
  double leftTrainHeight() => height() * 0.9;
  double rightTrainHeight() => height() * 0.7;
  double trainWidth() => height() * 40;
  double trainBeginPosition(bool isFast) => trainWidth() / (isFast ? 1.0 : 2.0);
  double trainEndPosition(bool isFast) => -trainWidth() / (isFast ? 1.0 : 2.0);
  Animation<double> leftAnimation(AnimationController leftController, bool isLeftFast) => Tween(
    begin: trainBeginPosition(isLeftFast),
    end: trainEndPosition(isLeftFast),
  ).animate(leftController);
  Animation<double> rightAnimation(AnimationController rightController, bool isRightFast) => Tween(
    begin: trainEndPosition(isRightFast),
    end: trainBeginPosition(isRightFast),
  ).animate(rightController);

  /// ===== BUTTONS METHODS =====
  double buttonSpace() => height() * 0.03;
  double buttonUpDownMargin() => upDownMargin() + buttonSpace() * 1.8;
  double buttonSideMargin() => sideMargin();
  double operationButtonSize() => height() * 0.12;
  double operationButtonIconSize() => height() * 0.08;
  double operationButtonBorderWidth() => height() * 0.01;
  double operationButtonBorderRadius() => height() * 0.02;

  /// ===== FAB CIRCULAR MENU PLUS BUTTON METHODS =====
  double fabSize() => height() * 0.16;
  double ringWidth() => height() * 0.16;
  double ringDiameter() => height() * 0.7;
  double fabSideMargin() => buttonSpace() + sideMargin();
  double fabTopMargin() => buttonSpace() + upDownMargin();
  double fabIconSize() => height() * 0.12;
  double fabChildIconSize() => height() * 0.16;
  double fabBorderWidth() => height() * 0.005;


  /// ===== PHOTO METHODS =====
  double cameraSideMargin() => buttonSpace() * 2 + sideMargin();
  double cameraTopMargin() => buttonSpace() + upDownMargin();
  double cameraIconSize() => height() * 0.1;
  double cameraTextFontSize() => height() * 0.025;
  double cameraIconTopMargin() => height() * 0.01;
  double cameraIconBottomMargin() => height() * 0.04;
  double cameraTextTopMargin() => height() * 0.08;
  double circleSize() => height() * 0.1;
  double circleStrokeWidth() => height() * 0.01;

  /// ===== MENU METHODS =====
  double menuButtonIconSize() => height() * 0.10;
  double menuWidth() => width() * (lang() == "en" ? 0.58: 0.54);
  double menuHeight(String plan) =>
      height() - menuMarginBottom(plan) - 2 * buttonSpace();
  double menuMarginBottom(String plan) =>
      height() * (plan == freeID ? 0.20 : 0.08);
  double onetimeMenuHeight() =>
      height() - onetimeMenuMarginBottom() - 2 * buttonSpace();
  double onetimeMenuMarginBottom() => height() * (lang() == "en" ? 0.18 : 0.21);
  double menuPaddingTop() => height() * 0.05;
  double menuSideMargin() => fabSideMargin();
  double menuCornerRadius() => fabSize() / 2;
  double menuTitleTextFontSize() => height() * (lang() == "en" ? 0.064 : 0.056);
  double menuTitleMargin() => height() * 0.03;
  double menuTextFontSize() => height() * 0.05;
  double menuTextSubFontSize() => height() * (lang() == "en" ? 0.06 : 0.05);
  double menuAdFreeDateFontSize() => height() * (lang() == "en" ? 0.04 : 0.04);
  double menuIconSize() => height() * 0.07;
  double menuIconMargin() => height() * 0.01;
  double menuTextSideMargin() => height() * 0.12;
  double menuTextUpDownMargin() => height() * 0.03;
  double menuDividerSideMargin() => height() * 0.1;
  double menuPurchaseButtonWidth() => menuWidth() * 0.75;
  double menuPurchaseButtonHeight() => height() * 0.1;
  double menuPurchaseButtonMargin() => height() * 0.06;
  double menuPurchaseButtonFontSize() =>
      height() * (lang() == "en" ? 0.054 : 0.050);
  double menuPurchaseButtonCornerRadius() => menuPurchaseButtonHeight() / 2;
  double menuPurchaseButtonBorderWidth() => height() * 0.005;
  double menuPurchaseButtonMarginBottom() => height() * 0.04;
  double menuUpdatedDateMarginBottom() => height() * 0.02;
  double menuUpdatedDateMarginRight() => height() * 0.1;
  double menuUpdatedDateFontSize() => height() * 0.045;
  double menuOtherSelectFontSize() => height() * 0.04;
  double menuOtherSelectMarginSide() => height() * 0.1;
  double menuOtherSelectMarginTop() => height() * 0.02;

  /// ===== BUY TICKETS METHODS =====
  double purchaseTitleFontSize() => height() * 0.050;
  double purchaseTitleMarginBottom() => height() * 0.042;
  double purchaseButtonMargin() => height() * 0.036;
  double purchaseButtonPadding() => height() * 0.005;
  double purchaseButtonBorderWidth() => height() * 0.004;
  double purchaseButtonWidth(String plan) =>
      height() * (plan == freeID ? 0.22 : 0.5);
  double purchaseButtonHeight() => height() * 0.08;
  double purchaseButtonFontSize() => height() * 0.04;
  double purchaseButtonBorderRadius() => purchaseButtonHeight() / 2;
  double purchaseTableMarginTop() => height() * 0.02;
  double purchaseTableTitleFontSize() => height() * 0.040;
  double purchaseTableFontSize() => height() * 0.040;
  double purchaseTableNumberFontSize() => height() * 0.045;
  double purchaseTableSubFontSize() => height() * 0.035;
  double purchaseTableIconSize() => height() * 0.06;
  double purchaseTableHeight() => height() * 0.135;
  double purchaseTableSpacing() => height() * 0.04;
  double purchaseTableMargin() => purchaseTableSpacing() / 2;
  double purchaseTableBorderWidth() => height() * 0.002;
  double purchaseTableDividerWidth() => height() * 0.002;
  double purchaseUpgradeButtonMarginTop() => height() * 0.03;
  double purchaseCancelButtonMarginTop() => height() * 0.04;
  double purchaseCancelButtonMarginBottom() => height() * 0.01;
  double purchaseCancelButtonMarginRight() => height() * 0.02;
  double purchaseUpdatedDateFontSize() => height() * 0.04;
  double purchaseUpdatedMarginTop() => height() * 0.03;
  double purchaseUpdatedMarginRight() => height() * 0.01;
  double onetimePurchaseTableFontSize() => height() * 0.055;
  double onetimePurchaseTableSubFontSize() => height() * 0.045;
  double onetimePurchaseTableNumberFontSize() => height() * 0.12;

  /// ===== SNACKBAR METHODS =====
  double snackBarFontSize() => height() * 0.04;
  double snackBarBorderRadius() => height() * 0.1;
  double snackBarPadding() => height() * 0.02;
  double snackBarSideMargin(TextPainter textPainter) =>
      (width() * 0.9 - textPainter.size.width) / 2;
  double snackBarBottomMargin() =>
      height() * ((isMediaWide() || !isAdmobEnoughUpdDownSpace()) ? 0.02 : 0.2);
}

/// ===== STRING EXTENSIONS =====
// Extensions for String to provide additional functionality
extension StringExt on String {

  /// ===== DEBUG UTILITIES =====
  // Provides debug printing functionality for development
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  /// ===== SHAREDPREFERENCES HELPERS =====
  // Comprehensive set of methods for storing and retrieving data from SharedPreferences
  // All methods include debug logging for development tracking
  void setSharedPrefString(SharedPreferences prefs, String value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setString(this, value);
  }
  void setSharedPrefInt(SharedPreferences prefs, int value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setInt(this, value);
  }
  void setSharedPrefBool(SharedPreferences prefs, bool value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setBool(this, value);
  }
  void setSharedPrefListString(SharedPreferences prefs, List<String> value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setStringList(this, value);
  }
  void setSharedPrefListInt(SharedPreferences prefs, List<int> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setInt("$this$i", value[i]);
    }
    "${replaceAll("Key", "")}: $value".debugPrint();
  }
  void setSharedPrefListBool(SharedPreferences prefs, List<bool> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setBool("$this$i", value[i]);
    }
    "${replaceAll("Key", "")}: $value".debugPrint();
  }
  String getSharedPrefString(SharedPreferences prefs, String defaultString) {
    String value = prefs.getString(this) ?? defaultString;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  int getSharedPrefInt(SharedPreferences prefs, int defaultInt) {
    int value = prefs.getInt(this) ?? defaultInt;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  bool getSharedPrefBool(SharedPreferences prefs, bool defaultBool) {
    bool value = prefs.getBool(this) ?? defaultBool;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  List<String> getSharedPrefListString(SharedPreferences prefs, List<String> defaultList) {
    List<String> values = prefs.getStringList(this) ?? defaultList;
    "${replaceAll("Key", "")}: $values".debugPrint();
    return values;
  }
  List<int> getSharedPrefListInt(SharedPreferences prefs, List<int> defaultList) {
    List<int> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      int v = prefs.getInt("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }
  List<bool> getSharedPrefListBool(SharedPreferences prefs, List<bool> defaultList) {
    List<bool> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      bool v = prefs.getBool("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList : values;
  }

  /// ===== COUNTRY NUMBER METHODS =====
  // Get country number based on country code
  int getCountryNumber() {
    final countryNumber =
      (this == "JPN" || this == "JP") ? 0:
      (this == "GBR" || this == "GB") ? 1:
      (this == "CHN" || this == "CN") ? 2:
      3;
    "countryCode: $this, countryNumber: $countryNumber".debugPrint();
    return countryNumber;
  }
  // bool getIsMainLandChina() =>　(this == "CHN" || this == "OTH");

  /// ===== AI IMAGE GENERATION METHODS =====
  // Generate image using Dall-E 3 API
  dynamic dallEResponse() async => http.post(
    Uri.https('api.openai.com', 'v1/images/generations'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${dotenv.get("OPEN_AI_API_KEY")}',
    },
    body: jsonEncode(<String, dynamic>{
      "model": "dall-e-3",
      "prompt": this,
      "n": generatePhotoNumber,
      "size": "1024x1024",
      "quality": "standard",
    }),
  );

  // Generate image using Vertex AI API
  dynamic vertexAIResponse(String accessToken) async => http.post(
  Uri.parse(vertexAIPostUrl),
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json'
    },
    body: jsonEncode(<String, dynamic>{
      "instances": [
        {
          "prompt": this,
        }
      ],
      "parameters": {
        "sampleCount": generatePhotoNumber,
        "negativePrompt": vertexAINegativePrompt,
        "aspectRatio": vertexAIAspectRatio,
        "personGeneration": vertexAIPersonGeneration,
      }
    }),
  );

  /// ===== PLAN CONFIGURATION METHODS =====
  // Plan-related configuration and ticket allocation
  
  // Get photo list for different plans
  List<int> photosList() => (this == freeID) ?
    [premiumTicketNumber, standardTicketNumber, trialTicketNumber, 0]:
    [premiumTicketNumber, standardTicketNumber, 0];
  
  // Get rollover settings for different plans
  List<bool?> isPurchaseRolloverList() => (this == freeID) ?
    [false, false, true, null]:
    [false, false, null];
  
  // Get ad-free settings for different plans
  List<bool?> isPurchaseAdFreeList() => (this == freeID) ?
    [true, false, false, false]:
    [true, false, false];

  // Get ticket number for plan refresh
  int refreshTicketNumber() =>
    (this == premiumID) ? premiumTicketNumber:
    (this == standardID) ? standardTicketNumber:
    0;

  // Get plan number identifier
  int planNumber() =>
    (this == premiumID) ? 0:
    (this == standardID) ? 1:
    2;
  // Get offering ID for subscription
  String offeringID() => (this == premiumID) ? defaultOffering : premiumOffering;
  // Get user access level
  String userAccess() =>
    (this == premiumID) ? premiumUserAccess:
    (this == standardID) ? standardUserAccess:
    freeUserAccess;
  // Get updated tickets for current date
  int updatedTickets(DateTime currentDate) =>
    (this == premiumID) ? premiumTicketNumber:
    (this == standardID) ? standardTicketNumber:
    0;
  // Get Apple updated tickets with purchase date check
  int appleUpdatedTickets(DateTime currentDate, DateTime purchaseDate) =>
      (currentDate.intDiffDateTime(purchaseDate) < 1000)
          ? updatedTickets(currentDate)
          : 0;

  // Get ad-free icon based on plan
  IconData adFreeIcon() => (this == premiumID)
      ? CupertinoIcons.check_mark_circled_solid
      : CupertinoIcons.multiply_circle_fill;
  // Get ad-free icon color based on plan
  Color adFreeIconColor() => (this == premiumID) ? redColor : grayColor;
}

/// ===== CUSTOMER INFO EXTENSIONS =====
// Extensions for CustomerInfo to handle subscription and plan management
extension CustomerInfoExt on CustomerInfo {
  // Get subscription entitlement info for plan
  EntitlementInfo? subscriptionEntitlementInfo(String planID) => entitlements.all[planID.userAccess()];
  // Check if subscription is active for plan
  bool isSubscriptionActive(String planID) =>
      subscriptionEntitlementInfo(planID) == null ? false: 
      subscriptionEntitlementInfo(planID)!.isActive;
  // Get current plan ID
  String planID() => 
      (isSubscriptionActive(premiumID)) ? premiumID:
      (isSubscriptionActive(standardID)) ? standardID:
      freeID;
  // Get ticket number to add based on active subscription
  int addTicket() => 
      (isSubscriptionActive(premiumID)) ? premiumTicketNumber:
      (isSubscriptionActive(standardID)) ? standardTicketNumber:
      0;
  // Get subscription expiration date
  int subscriptionExpirationDate() => 
      (subscriptionEntitlementInfo(planID()) == null) ? 20240101000000: 
      DateTime.parse(subscriptionEntitlementInfo(planID())!.expirationDate!).intDateTime();

  // Get updated plan based on active subscriptions
  String updatedPlan() => 
      (isSubscriptionActive(premiumID)) ? premiumID:
      (isSubscriptionActive(standardID)) ? standardID:
      freeID;
}

/// ===== INTEGER EXTENSIONS =====
// Extensions for int to provide date/time conversion and UI utilities
extension IntExt on int {
  // Convert integer date/time to DateTime object
  DateTime toDate() {
    final year = this ~/ 10000000000;
    final month = (this % 10000000000) ~/ 100000000;
    final day = (this % 100000000) ~/ 1000000;
    final hour = (this % 1000000) ~/ 10000;
    final minute = (this % 10000) ~/ 100;
    final second = (this % 100);
    return DateTime(year, month, day, hour, minute, second);
  }

  // Check if date is today
  bool isToday(int currentDate) => (this ~/ 1000000 == currentDate ~/ 1000000);
  // Get next month DateTime
  DateTime nextMonthDateTime() => DateTime(toDate().year, toDate().month + 1,
      toDate().day, toDate().hour, toDate().minute, toDate().second);
  // Get next month as integer
  int nextMonth() => nextMonthDateTime().intDateTime();

  /// ===== TICKET ICON METHODS =====
  // Get icon for one-time tickets based on availability
  IconData onetimeHaveTicketsIcon(bool isUseTodayTicket) =>
      (this == 0 && isUseTodayTicket) ? CupertinoIcons.multiply_circle_fill: 
      CupertinoIcons.star_circle_fill;
  // Get color for one-time tickets based on availability
  Color onetimeHaveTicketsColor(bool isUseTodayTicket) =>
      (this == 0 && isUseTodayTicket) ? redColor : greenColor;

  /// ===== AD-FREE ICON METHODS =====
  // Get icon for ad-free status based on expiration date
  IconData onetimeAdFreeIcon(int expirationDate) => 
      (this > expirationDate) ? CupertinoIcons.multiply_circle_fill:
      CupertinoIcons.star_circle_fill;
  // Get color for ad-free status based on expiration date
  Color onetimeAdFreeIconColor(int expirationDate) =>
      (this > expirationDate) ? redColor : greenColor;

  /// ===== ASSET PATH METHODS =====
  // Get country string for asset paths
  String countryString() =>
    (this == 0) ? "jp":
    (this == 1) ? "uk":
    (this == 2) ? "cn":
    "us";
  // Get crossing assets path
  String crossingAssets() => "assets/images/crossing/${countryString()}/";
  // Get train name for country
  String countryTrain() =>
    (this == 0) ? "n700s":
    (this == 1) ? "374":
    (this == 2) ? "cr400af":
    "avelia_liberty";
  // Generate train image list
  List<String> trainImage() => List.generate(6, (i) =>
    "assets/images/train/${countryString()}/${countryTrain()}_${i + 1}.png"
  );
  // Get photo assets path
  String photoAssets() => "assets/images/photo/${countryString()}/";
  // Get country free photo path
  String countryFreePhoto(int currentDate) =>
      "${photoAssets()}${countryString()}0${currentNumber(currentDate)}.jpg";

  /// ===== AI PROMPT METHODS =====
  // Get train name for AI prompts
  String inputTrain() =>
    (this == 0) ? "Shinkansen N700S":
    (this == 1) ? "Eurostar e320":
    (this == 2) ? "Fu Xing Hao CR400AF":
    "Amtrak Acela Express Avelia Liberty";
  // Get train primary color for AI prompts
  String trainPrimaryColor() =>
    (this == 0) ? "white":
    (this == 1) ? "blue":
    (this == 2) ? "silver":
    "white";
  // Get train accent color for AI prompts
  String trainAccentColor() => 
    (this == 0) ? "blue": 
    (this == 1) ? "yellow and white": 
    (this == 2) ? "red and black": 
    "blue and red";
  // Get background spots for AI prompts
  List<String> inputBackGround() => 
    (this == 0) ? jpSpot: 
    (this == 1) ? ukSpot: 
    (this == 2) ? cnSpot: 
    usSpot;
  // Get country name for AI prompts
  String inputCountry() => 
    (this == 0) ? "Japan":
    (this == 1) ? "United Kingdom":
    (this == 2) ? "China": 
    "USA";
  // Generate random number for background selection
  int randomNumber() => math.Random().nextInt(inputBackGround().length);
  // Get current number based on date
  int currentNumber(int currentDate) => (currentDate ~/ 1000000) % 10;

  /// ===== AI IMAGE GENERATION PROMPTS =====
  // Generate Dall-E 3 prompt for train images
  String dallEPrompt() => [
    "Realistic Image of a high-speed train called the ${inputTrain()} "
        "featuring primary ${trainPrimaryColor()} with accents of ${trainAccentColor()}, ",
    "with ${inputBackGround()[randomNumber()]} in ${inputCountry()} in the background."
  ].join();
  // Generate Vertex AI prompt for train images
  String vertexAIPrompt() => [
    "Digital art of a high-speed train called the ${inputTrain()}, "
        "featuring primary ${trainPrimaryColor()} with accents of ${trainAccentColor()}, ",
    "with ${inputBackGround()[randomNumber()]} in ${inputCountry()} in the background."
  ].join();

  /// ===== IMAGE ASSET METHODS =====
  // Get flag image path
  String flagImage() => "assets/images/flag/${countryString()}.png";
  // Get flag map with image and country number
  Map<String, Object> flagMap() => {'image': flagImage(), 'countryNumber': this};
  // Get background image path
  String backgroundImage() => "${crossingAssets()}background.png";
  // Get pole image paths
  String poleFrontImage() => "${crossingAssets()}pole_front.png";
  String poleBackImage() => "${crossingAssets()}pole_back.png";
  // Get bar image paths
  String barFrontOff() => "${crossingAssets()}bar_front_off.png";
  String barFrontOn() => "${crossingAssets()}bar_front_on.png";
  String barBackOff() => "${crossingAssets()}bar_back_off.png";
  String barBackOn() => "${crossingAssets()}bar_back_on.png";
  // Get bar image based on wait state and index
  String barFrontImage(bool isWait, int index) =>
      isWait ? [barFrontOff(), barFrontOn()][index]: barFrontOff();
  String barBackImage(bool isWait, int index) =>
      isWait ? [barBackOff(), barBackOn()][index]: barBackOff();
  // Get bar angle based on country and wait state
  double barAngle(bool isWait) => (this == 2 || isWait) ? 0.0 : barUpAngle;
  // Get bar shift based on country and wait state
  double barShift(bool isWait) => (this == 2 && !isWait) ? 1.0 : 0.0;
  // Get warning image paths
  String warningFrontImageOff() => "${crossingAssets()}warning_off.png";
  String warningFrontImageLeft() => "${crossingAssets()}warning_left.png";
  String warningFrontImageRight() => "${crossingAssets()}warning_right.png";
  String warningFrontImageYellow() => "${crossingAssets()}warning_yellow.png";
  // Get warning image based on state
  String warningFrontImage(bool isYellow, bool isWait, int index) =>
      isYellow ? warningFrontImageYellow():
      isWait ? [warningFrontImageLeft(), warningFrontImageRight()][index]:
      warningFrontImageOff();
  String warningBackImageOff() => "${crossingAssets()}warning_back_off.png";
  String warningBackImageLeft() => "${crossingAssets()}warning_back_left.png";
  String warningBackImageRight() => "${crossingAssets()}warning_back_right.png";
  String warningBackImageYellow() => "${crossingAssets()}warning_back_yellow.png";
  String warningBackImage(bool isYellow, bool isWait, int index) =>
      isYellow ? warningBackImageYellow():
      isWait ? [warningBackImageLeft(), warningBackImageRight()][index]:
      warningBackImageOff();
  // Get direction image paths
  String directionImageOff() => "${crossingAssets()}direction_off.png";
  String directionImageLeft() => "${crossingAssets()}direction_left.png";
  String directionImageRight() => "${crossingAssets()}direction_right.png";
  String directionImageBoth() => "${crossingAssets()}direction_both.png";
  // Get direction image based on wait states
  String directionImage(bool isLeftWait, bool isRightWait) =>
    (isLeftWait && isRightWait) ? directionImageBoth():
    (isLeftWait) ? directionImageLeft():
    (isRightWait) ? directionImageRight():
    directionImageOff();
  // Get emergency image path
  String emergencyImage() => "${crossingAssets()}emergency.png";
  // Get traffic sign image path
  String signImage() => "${crossingAssets()}sign.png";
  // Get gate image paths
  String gateFrontImage() => "${crossingAssets()}gate_front.png";
  String gateBackImage() => "${crossingAssets()}gate_back.png";
  // Get fence image paths
  String fenceFrontLeftImage() => "${crossingAssets()}fence_front_left.png";
  String fenceFrontRightImage() => "${crossingAssets()}fence_front_right.png";
  String fenceBackLeftImage() => "${crossingAssets()}fence_back_left.png";
  String fenceBackRightImage() => "${crossingAssets()}fence_back_right.png";

  /// ===== AUDIO ASSET METHODS =====
  // Get sound assets path
  String soundAssets() => "assets/audios/${countryString()}/";
  // Get warning sound path
  String warningSound() => "${soundAssets()}warning_${countryString()}.mp3";

  /// ===== TIMING METHODS =====
  // Get flash time based on country
  int flashTime() => (this == 1) ? 500 : 1000;

  /// ===== BAR POSITION METHODS =====
  // Get front bar alignment X position
  double frontBarAlignmentX() => 
    (this == 0) ? 0.6947:
    (this == 1) ? 0.7637:
    (this == 2) ? 0.7637:
    (this == 3) ? 0.63:
    0.6947;
  // Get front bar alignment Y position
  double frontBarAlignmentY() => 
    (this == 0) ? -0.4122:
    (this == 1) ? -0.4122:
    (this == 2) ? -0.4122:
    (this == 3) ? -0.3:
    -0.4122;
  // Get back bar alignment X position
  double backBarAlignmentX() => 
    (this == 0) ? -0.6947:
    (this == 1) ? -0.7637:
    (this == 2) ? -0.7637:
    (this == 3) ? -0.63:
    -0.6947;
  // Get back bar alignment Y position
  double backBarAlignmentY() => 
    (this == 0) ? -0.4122:
    (this == 1) ? -0.4122:
    (this == 2) ? -0.4122:
    (this == 3) ? -0.3:
    -0.4122;
}

/// ===== BOOLEAN EXTENSIONS =====
// Extensions for bool to provide utility methods
extension BoolExt on bool {
  // Returns 1 if the value is false, 0 if true
  int isFalseNumber() => this ? 0 : 1;
}

/// ===== DATETIME EXTENSIONS =====
// Extensions for DateTime to provide formatting and difference calculation
extension DateTimeExt on DateTime {
  // Converts DateTime to int in 'yyyyMMddHHmmss' format
  int intDateTime() {
    final DateFormat formatter = DateFormat('yyyyMMddHHmmss');
    return int.parse(formatter.format(this));
  }

  // Converts DateTime to int in 'yyyyMMdd' format
  int intDate() {
    final DateFormat formatter = DateFormat('yyyyMMdd');
    return int.parse(formatter.format(this));
  }

  // Calculates the difference between two DateTime objects as an int
  // Format: MddHHmmss (M: months, dd: days, HH: hours, mm: minutes, ss: seconds)
  int intDiffDateTime(DateTime dateTime) {
    final diffDateTime = difference(dateTime);
    // Get total days difference
    final totalDays = diffDateTime.inDays;
    // Calculate months and remaining days (1 month = 30 days)
    final months = totalDays ~/ 30;
    final days = totalDays % 30;
    final hours = diffDateTime.inHours % 24;
    final minutes = diffDateTime.inMinutes % 60;
    final seconds = diffDateTime.inSeconds % 60;
    // Format each part with zero padding where needed
    final monthPart = '$months';
    final dayPart = days.toString().padLeft(2, '0');
    final hourPart = hours.toString().padLeft(2, '0');
    final minutePart = minutes.toString().padLeft(2, '0');
    final secondPart = seconds.toString().padLeft(2, '0');
    // Concatenate all parts and convert to int
    final diff = '$monthPart$dayPart$hourPart$minutePart$secondPart';
    "diffDateTime: $diff".debugPrint();
    return int.parse(diff).abs();
  }
}

