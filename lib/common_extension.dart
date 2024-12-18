import 'dart:math';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'my_homepage.dart';
import 'constant.dart';

extension ContextExt on BuildContext {

  void pushHomePage() => Navigator.pushReplacement(this, PageRouteBuilder(
    pageBuilder: (context, animation, _) =>  MyHomePage(),
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 500),
  ));

  void popPage() => Navigator.of(this).pop();

  ///Locale
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  ///Date
  String toCountryDate(int countryNumber, DateTime date) =>
      (lang() == "ja") ? "${date.year}/${date.month}/${date.day}":
      (lang() == "zh") ? "${date.year}年${date.month}月${date.day}日":
      (countryNumber == 1) ? "${date.day} ${monthList[date.month - 1]} ${date.year}":
      "${monthList[date.month - 1]} ${date.day}, ${date.year}";

  ///Localization
  String appTitle() => AppLocalizations.of(this)!.appTitle;
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String ok() => AppLocalizations.of(this)!.ok;
  String cancel() => AppLocalizations.of(this)!.cancel;
  String shots(String number) => AppLocalizations.of(this)!.shots(number);
  String noPasses() => AppLocalizations.of(this)!.noPasses;
  String oneFree() => AppLocalizations.of(this)!.oneFree;
  String checkNetwork() => AppLocalizations.of(this)!.checkNetwork;
  String useTickets(int number) => AppLocalizations.of(this)!.useTickets(number);
  String photoShots(int currentDate, int lastClaimedDate, int tickets) =>
      !lastClaimedDate.isToday(currentDate) ? oneFree():
      (tickets < 1) ? noPasses():
      shots("$tickets");
  String photoSaved() => AppLocalizations.of(this)!.photoSaved;
  String photoCaptureFailed() => AppLocalizations.of(this)!.photoCaptureFailed;
  String photoSavingFailed() => AppLocalizations.of(this)!.photoSavingFailed;
  String photoAccessPermission() => AppLocalizations.of(this)!.photoAccessPermission;

  ///Menu
  String upgrade() => AppLocalizations.of(this)!.upgrade;
  String buyPasses() => AppLocalizations.of(this)!.buyPasses;
  String purchasePlan(String plan) =>
      (plan == premiumID) ? buyOnetimePasses():
      (plan == standardID) ? upgrade():
      buyPasses();
  String ticket() => AppLocalizations.of(this)!.ticket;
  String todayPass() => AppLocalizations.of(this)!.todayPass;
  String ticketsLeft(int tickets, int currentDate, int lastClaimedDate) =>
      (tickets > 0 || lastClaimedDate.isToday(currentDate)) ? ticket(): todayPass();
  String none() => AppLocalizations.of(this)!.none;
  String oneFreePerDay() => AppLocalizations.of(this)!.oneFreePerDay;
  String number(int tickets) => AppLocalizations.of(this)!.number(tickets);
  String menuTicketsNumber(int tickets, int currentDate, int lastClaimedDate) =>
      (tickets < 1 && lastClaimedDate.isToday(currentDate)) ? none():
      (tickets < 1) ? oneFreePerDay():
      number(lastClaimedDate.currentTickets(tickets, currentDate));
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

  ///Plan Table
  String worldsFirstApp() => AppLocalizations.of(this)!.worldsFirstApp;
  String current() => AppLocalizations.of(this)!.current;
  String plan() => AppLocalizations.of(this)!.plan;
  String tickets() => AppLocalizations.of(this)!.tickets;
  String trial() => AppLocalizations.of(this)!.trial;
  String onetime() => AppLocalizations.of(this)!.onetime;
  String timing() => AppLocalizations.of(this)!.timing;
  String rollover() => AppLocalizations.of(this)!.rollover;
  String rolloverTickets() => AppLocalizations.of(this)!.rolloverTickets;
  String adFree() => AppLocalizations.of(this)!.adFree;
  String price() => AppLocalizations.of(this)!.price;
  String buy() => AppLocalizations.of(this)!.buy;
  List<String> purchaseDataTitleList(String planID) => (planID == freeID) ?
      [plan(), tickets(), timing(), rollover(), adFree(), price(), buy()]:
      [current(), plan(), tickets(), adFree()];
  List<String> upgradeDataTitleList() =>
      [current(), plan(), tickets(), adFree(), price()];
  List<String> onetimeDataTitleList() =>
      [onetime(), rolloverTickets(), price()];
  //Tickets
  String photos(int number) => (number == 0) ? "-": AppLocalizations.of(this)!.photos(number);
  //Plan
  String premium() => AppLocalizations.of(this)!.premium;
  String standard() => AppLocalizations.of(this)!.standard;
  String free() => AppLocalizations.of(this)!.free;
  String premiumTitle() => AppLocalizations.of(this)!.premiumTitle;
  String standardTitle() => AppLocalizations.of(this)!.standardTitle;
  String currentPlanTitle(String currentPlan) =>
      "${(currentPlan == premiumID) ? premium(): (currentPlan == standardID) ? standard(): free()} ${plan()}";
  List<String> purchasePlanList(String plan) => (plan == freeID) ?
      [premiumTitle(), standardTitle(), trial(), free()]:
      [premiumTitle(), standardTitle(), free()];
  List<String> upgradePlanList() =>
      [premiumTitle(), standardTitle()];
  //Timing
  String renewal() => AppLocalizations.of(this)!.renewal;
  String immediate() => AppLocalizations.of(this)!.immediate;
  List<String> timingList() => [renewal(), renewal(), immediate(), "-"];
  //Rollover
  String available() => AppLocalizations.of(this)!.available;
  String expire() => AppLocalizations.of(this)!.expire;
  List<String> purchaseRolloverList(String plan) => (plan == freeID) ?
      [expire(), expire(), available(), "-"]:
      [expire(), expire(), "-"];

  //AdFree
  String yes() => AppLocalizations.of(this)!.yes;
  String no() => AppLocalizations.of(this)!.no;
  String adFreeText(String plan) => (plan == premiumID) ? yes(): no();
  List<String> purchaseAdFreeList(String plan) => (plan == freeID) ?
      [yes(), no(), no(), no()]:
      [yes(), no(), no()];
  List<String> upgradeAdFreeList() =>
      [yes(), no()];

  //Price
  String monthly() => AppLocalizations.of(this)!.monthly;
  String toBuy() => AppLocalizations.of(this)!.toBuy;
  String toUpgrade() => AppLocalizations.of(this)!.toUpgrade;
  String cancelSubscription() => AppLocalizations.of(this)!.cancelSubscription;
  String nextRenewal(String date) => AppLocalizations.of(this)!.nextRenewal(date);
  String cancelPlan() => AppLocalizations.of(this)!.cancelPlan;
  String otherSelectPlan(String plan) => (plan == freeID) ? toRestore(): cancelPlan();
  ///RevenueCat
  String toRestore() => AppLocalizations.of(this)!.toRestore;
  String premiumPlan() => AppLocalizations.of(this)!.premiumPlan;
  String standardPlan() => AppLocalizations.of(this)!.standardPlan;
  String onetimePlan() => AppLocalizations.of(this)!.addOnPlan;
  String planName(String planID) => (planID == premiumID) ? premiumPlan(): (planID == standardID) ? standardPlan(): onetimePlan();
  String planPurchase(String planID) => AppLocalizations.of(this)!.planPurchase(planName(planID));
  String planRestore(String planID) => AppLocalizations.of(this)!.planRestore(planName(planID));
  String planCancel(String planID) => AppLocalizations.of(this)!.planCancel(planName(planID));
  String planPurchaseTitle(String planID, bool isRestore, bool isCancel) =>
      isRestore ? planRestore(planID):
      isCancel ? planCancel(planID):
      planPurchase(planID);
  String successPurchase(String planID) => AppLocalizations.of(this)!.successPurchase(planName(planID));
  String successRestore(String planID) => AppLocalizations.of(this)!.successRestore(planName(planID));
  String successCancel(String planID, int expirationDate) => AppLocalizations.of(this)!.successCancel(planName(planID), expirationDate);
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

  ///Size
  double mediaWidth() => MediaQuery.of(this).size.width;
  double mediaHeight() => MediaQuery.of(this).size.height;
  bool isMediaWide() => mediaWidth() > mediaHeight() * aspectRatio;
  double width() => isMediaWide() ? mediaHeight() * aspectRatio: mediaWidth();
  double height() => isMediaWide() ? mediaHeight(): mediaWidth() / aspectRatio;
  double sideMargin() => isMediaWide() ? (mediaWidth() - mediaHeight() * aspectRatio) / 2: 0;
  double upDownMargin() => isMediaWide() ? 0: (mediaHeight() - mediaWidth() / aspectRatio) / 2;
  double widthResponsible() => (mediaWidth() < mediaHeight() / 2) ? mediaWidth(): mediaHeight() / 2;

  ///Admob
  bool isAdmobEnoughSideSpace() => (isMediaWide() && sideMargin() > 60);
  bool isAdmobEnoughUpdDownSpace() => (!isMediaWide() && upDownMargin() > 100);
  bool isAdmobEnoughSpace() => isAdmobEnoughSideSpace() || isAdmobEnoughUpdDownSpace();
  double admobWidth() => !isAdmobEnoughSpace() ? 320: isMediaWide() ? mediaHeight(): mediaWidth();
  double admobHeight() => !isAdmobEnoughSpace() ? 50: isMediaWide() ? 60: 100;
  double admobTopMargin() => !isAdmobEnoughSpace() ? 0 : isMediaWide() ? (mediaHeight() - admobHeight()) / 2: (mediaHeight() - admobHeight());
  double admobOffset() => !isAdmobEnoughSpace() ? 0 : isMediaWide() ? (admobWidth() - admobHeight()) / 2: 0;
  double admobRotationAngle() => (isMediaWide() && isAdmobEnoughSpace()) ? pi * 3 / 2: 0;

  ///Pole
  double frontPoleImageHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.95:
      (countryNumber == 1) ? 0.80:
      (countryNumber == 2) ? 0.9:
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

  ///Warning
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

  ///Emergency
  double frontEmergencyHeight() => height() * 0.42;
  double frontEmergencyTopMargin() => height() * 0.525;
  double frontEmergencyLeftMargin() => sideMargin() + height() * 0.085;

  double backEmergencyHeight() => height() * 0.252;
  double backEmergencyTopMargin() => height() * 0.3;
  double backEmergencyLeftMargin() => sideMargin() + height() * 1.29;

  double emergencyButtonHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.13: 0.10
  );
  double emergencyButtonLeftMargin(int countryNumber) => sideMargin() + height() * (
      (countryNumber == 0) ? 0.085: 0.27
  );
  double emergencyButtonTopMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.445: 0.445
  );

  ///Traffic Sign
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

  ///Gate
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

  ///Bar
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

  ///Direction
  double frontDirectionHeight() => height() * 0.11;
  double frontDirectionTopMargin() => height() * 0.16;
  double frontDirectionLeftMargin() => sideMargin() + height() * 0.238;
  double backDirectionHeight() => height() * 0.066;
  double backDirectionTopMargin() => height() * 0.096;
  double backDirectionLeftMargin() => sideMargin() + height() * 1.193;

  ///Fence
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
  double backFenceBottomMargin(int countryNumber) => upDownMargin() + height() * 0.235;

  ///Train
  double leftTrainOffset()  => - height() * 0.050;
  double rightTrainOffset() => - height() * 0.025;
  double leftTrainHeight()  => height() * 0.9;
  double rightTrainHeight() => height() * 0.7;
  double trainWidth() => height() * 40;
  double trainBeginPosition(bool isFast) => trainWidth() / (isFast ? 1.0: 2.0);
  double trainEndPosition(bool isFast) => -trainWidth() / (isFast ? 1.0: 2.0);
  Animation<double> leftAnimation(AnimationController leftController, bool isLeftFast) => Tween(
    begin: trainBeginPosition(isLeftFast),
    end: trainEndPosition(isLeftFast),
  ).animate(leftController);
  Animation<double> rightAnimation(AnimationController rightController, bool isRightFast) => Tween(
    begin: trainEndPosition(isRightFast),
    end: trainBeginPosition(isRightFast),
  ).animate(rightController);



  ///Buttons
  double buttonSpace() => height() * 0.03;
  double buttonUpDownMargin() => upDownMargin() + buttonSpace();
  double buttonSideMargin() => sideMargin();
  double operationButtonSize() => height() * 0.12;
  double operationButtonIconSize() => height() * 0.08;
  double operationButtonBorderWidth() => height() * 0.01;
  double operationButtonBorderRadius() => height() * 0.02;

  ///FabCircularMenuPlusButton
  double fabSize() => height() * 0.15;
  double ringWidth() => height() * 0.15;
  double ringDiameter() => height() * 0.75;
  double fabSideMargin() => buttonSpace() + sideMargin();
  double fabTopMargin() => buttonSpace() + upDownMargin();
  double fabIconSize() => height() * 0.10;
  double fabChildIconSize() => height() * 0.15;

  ///Photo
  double cameraIconSize() => height() * 0.08;
  double cameraTextFontSize() => height() * 0.025;
  double cameraIconBottomMargin() => height() * 0.03;
  double cameraTextTopMargin() => height() * 0.07;
  double circleIconSize() => height() * 0.12;
  double circleSize() => height() * 0.1;
  double circleStrokeWidth() => height() * 0.01;

  ///Menu
  double menuButtonIconSize() => height() * 0.07;
  double menuWidth() => width() * 0.5;
  double menuHeight(String plan) => height() - menuMarginBottom(plan) - 2 * buttonSpace();
  double menuMarginBottom(String plan) => height() * (plan == freeID ? 0.20: 0.08);
  double menuPaddingTop() => height() * 0.06;
  double menuSideMargin() => fabSideMargin();
  double menuCornerRadius() => fabSize() / 2;
  double menuTitleTextFontSize() => height() * (lang() == "en" ? 0.06: 0.05);
  double menuTitleMargin() => height() * 0.03;
  double menuTextFontSize() => height() * (lang() == "en" ? 0.05: 0.045);
  double menuIconSize() => height() * 0.07;
  double menuIconMargin() => height() * 0.01;
  double menuTextSideMargin() => height() * 0.12;
  double menuTextUpDownMargin() => height() * 0.03;
  double menuDividerSideMargin() => height() * 0.1;
  double menuPurchaseButtonWidth() => menuWidth() * 0.75;
  double menuPurchaseButtonHeight() => height() * 0.1;
  double menuPurchaseButtonMargin() => height() * 0.06;
  double menuPurchaseButtonFontSize() => height() * (lang() == "en" ? 0.054: 0.05);
  double menuPurchaseButtonCornerRadius() => menuPurchaseButtonHeight() / 2;
  double menuPurchaseButtonBorderWidth() => height() * 0.005;
  double menuPurchaseButtonMarginBottom() => height() * 0.04;
  double menuUpdatedDateMarginBottom() => height() * 0.02;
  double menuUpdatedDateMarginRight() => height() * 0.1;
  double menuUpdatedDateFontSize() => height() * 0.045;
  double menuOtherSelectFontSize() => height() * (lang() == "en" ? 0.033: 0.036);
  double menuOtherSelectMarginSide() => height() * 0.1;
  double menuOtherSelectMarginTop() => height() * 0.02;

  ///Buy tickets
  double purchaseTitleFontSize() => height() * 0.050;
  double purchaseTitleMarginBottom() => height() * 0.042;
  double purchaseButtonMargin() => height() * 0.036;
  double purchaseButtonPadding() => height() * 0.005;
  double purchaseButtonBorderWidth() => height() * 0.004;
  double purchaseButtonWidth(String plan) => height() * (plan == freeID ? 0.22: 0.5);
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

  ///SnackBar
  double snackBarFontSize() => height() * 0.04;
  double snackBarBorderRadius() => height() * 0.1;
  double snackBarPadding() => height() * 0.02;
  double snackBarSideMargin(TextPainter textPainter) => (width() * 0.9 - textPainter.size.width) / 2;
  double snackBarBottomMargin() => height() * ((isMediaWide() || !isAdmobEnoughUpdDownSpace()) ? 0.02: 0.2);

}

extension StringExt on String {

  void debugPrint() async {
    if (kDebugMode) {
      print(this);
    }
  }

  //Generate Image from AI
  ///Dall-E
  dallEResponse() async => http.post(
    Uri.https('api.openai.com', 'v1/images/generations'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${dotenv.get("OPEN_AI_API_KEY")}',
    },
    body: jsonEncode(<String, dynamic>{
      "model": "dall-e-3",    // モデル
      "prompt": this,  // 指示メッセージ
      "n" : generatePhotoNumber,                // 生成枚数
      "size": "1024x1024",    // 画像サイズ
      "quality": "standard",  // クオリティ
    }),
  );

  ///Vertex AI
  vertexAIResponse(String accessToken) async => http.post(
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
        "aspectRatio": "1:1",
        "personGeneration": "off",
      }
    }),
  );

  //this is plan
  List<int> photosList() =>
    (this == freeID) ? [premiumTicketNumber, standardTicketNumber, trialTicketNumber, 0]:
                       [premiumTicketNumber, standardTicketNumber, 0];
  List<bool?> isPurchaseRolloverList() =>
      (this == freeID) ? [false, false, true, null]: [false, false, null];
  List<bool?> isPurchaseAdFreeList() =>
      (this == freeID) ? [true, false, false, false]: [true, false, false];

  int refreshTicketNumber() =>
      (this == premiumID) ? premiumTicketNumber:
      (this == standardID) ? standardTicketNumber:
      0;
  //This is planID
  int planNumber() =>
      (this == premiumID)  ? 0:
      (this == standardID) ? 1:
      2;
  String offeringID() =>
      (this == premiumID) ? defaultOffering: premiumOffering;
  String userAccess() =>
      (this == premiumID) ? premiumUserAccess:
      (this == standardID) ? standardUserAccess:
      freeUserAccess;
  int updatedTickets(int tickets, bool isUpgrade) =>
      (isUpgrade && this == premiumID) ? tickets + premiumTicketNumber:
      (isUpgrade && this == standardID) ? tickets + standardTicketNumber:
      tickets;
  IconData adFreeIcon() =>
      (this == premiumID) ? CupertinoIcons.check_mark_circled_solid:
      CupertinoIcons.multiply_circle_fill;
  Color adFreeIconColor() =>
      (this == premiumID) ? redColor: grayColor;

}

extension CustomerInfoExt on CustomerInfo {

  EntitlementInfo? subscriptionEntitlementInfo(String planID) =>
      entitlements.all[planID.userAccess()];
  bool isSubscriptionActive(String planID) =>
      subscriptionEntitlementInfo(planID) == null ? false:
      subscriptionEntitlementInfo(planID)!.isActive;
  bool isPremiumActive() => isSubscriptionActive(premiumID);
  bool isStandardActive() => isSubscriptionActive(standardID);
  String planID() =>
      isPremiumActive() ? premiumID:
      isStandardActive() ? standardID:
      freeID;
  int addTicket() =>
      isPremiumActive() ? premiumTicketNumber:
      isStandardActive() ? standardTicketNumber:
      0;
  int subscriptionExpirationDate() =>
      (subscriptionEntitlementInfo(planID()) == null) ? 20240101000000:
      DateTime.parse(subscriptionEntitlementInfo(planID())!.expirationDate!).intDateTime();
  String updatedPlan() =>
      isSubscriptionActive(premiumID) ? premiumID:
      isSubscriptionActive(standardID) ? standardID:
      freeID;
}

extension IntExt on int {

  DateTime toLocalDate() {
    final year = this ~/ 10000000000;
    final month = (this % 10000000000) ~/ 100000000;
    final day = (this % 100000000) ~/ 1000000;
    final hour = (this % 1000000) ~/ 10000;
    final minute = (this % 10000) ~/ 100;
    final second = (this % 100);
    final localDate = DateTime.utc(year, month, day, hour, minute, second).toLocal();
    return localDate;
  }

  int currentDay() => toLocalDate().intDate();
  bool isToday(int currentDate) => (this == currentDate.currentDay());
  int currentTickets(int tickets, int currentDate) =>  tickets + isToday(currentDate).isFalseNumber();

  ///Image
  //Asset
  String countryString() =>
      (this == 0) ? "jp":
      (this == 1) ? "uk":
      (this == 2) ? "cn":
      "us";
  String crossingAssets() => "assets/images/crossing/${countryString()}/";
  //Train
  String countryTrain() =>
      (this == 0) ? "n700s":
      (this == 1) ? "374":
      (this == 2) ? "cr400af":
      "avelia_liberty";
  List<String> trainImage() => List.generate(6, (i) =>
    "assets/images/train/${countryString()}/${countryTrain()}_${i + 1}.png"
  );
  //Free_photo
  String photoAssets() => "assets/images/photo/${countryString()}/";
  String countryFreePhoto(int currentDate) => "${photoAssets()}${countryString()}0${currentNumber(currentDate)}.jpg";

  //Vertex AI or Dall-E 3
  String inputTrain() =>
      (this == 0) ? "Shinkansen N700S":
      (this == 1) ? "Eurostar e320":
      (this == 2) ? "Fu Xing Hao CR400AF":
                    "Amtrak Acela Express Avelia Liberty";
  String trainPrimaryColor() =>
      (this == 0) ? "white":
      (this == 1) ? "blue":
      (this == 2) ? "silver":
                    "white";
  String trainAccentColor() =>
      (this == 0) ? "blue":
      (this == 1) ? "yellow and white":
      (this == 2) ? "red and black":
                    "blue and red";
  List<String> inputBackGround() =>
      (this == 0) ? jpSpot:
      (this == 1) ? ukSpot:
      (this == 2) ? cnSpot:
                    usSpot;
  String inputCountry() =>
      (this == 0) ? "Japan":
      (this == 1) ? "United Kingdom":
      (this == 2) ? "China":
                    "USA";
  int randomNumber() =>
      math.Random().nextInt(inputBackGround().length);
  int currentNumber(int currentDate) =>
      currentDate.currentDay() % 10;

  //Generate Dall E 3 images
  String dallEPrompt() => [
    "Realistic Image of a high-speed train called the ${inputTrain()} "
    "featuring primary ${trainPrimaryColor()} with accents of ${trainAccentColor()}, ",
    "with ${inputBackGround()[randomNumber()]} in ${inputCountry()} in the background."
  ].join();
  //Generate Vertex AI Imagen 3 images
  String vertexAIPrompt() => [
    "Digital art of a high-speed train called the ${inputTrain()}, "
    "featuring primary ${trainPrimaryColor()} with accents of ${trainAccentColor()}, ",
    "with ${inputBackGround()[randomNumber()]} in ${inputCountry()} in the background."
  ].join();

  //Flag
  String flagImage() => "assets/images/flag/${countryString()}.png";
  Map<String, Object> flagMap() => {'image': flagImage(), 'countryNumber': this};
  //Background Image
  String backgroundImage() => "${crossingAssets()}background.png";
  //Pole Image
  String poleFrontImage() => "${crossingAssets()}pole_front.png";
  String poleBackImage() => "${crossingAssets()}pole_back.png";
  //Bar Image
  String barFrontOff() => "${crossingAssets()}bar_front_off.png";
  String barFrontOn() => "${crossingAssets()}bar_front_on.png";
  String barBackOff() => "${crossingAssets()}bar_back_off.png";
  String barBackOn() => "${crossingAssets()}bar_back_on.png";
  String reverseBarFront(String barFront) => (barFront == barFrontOff()) ? barFrontOn(): barFrontOff();
  String reverseBarBack(String barBack) => (barBack == barBackOff()) ? barBackOn(): barBackOff();
  double barAngle(bool isWait) => (this == 2 || isWait) ? 0.0: barUpAngle;
  double barShift(bool isWait) => (this == 2 && !isWait) ? 1.0: 0.0;
  //Warning Image
  String warningFrontImageOff() => "${crossingAssets()}warning_off.png";
  String warningFrontImageLeft() => "${crossingAssets()}warning_left.png";
  String warningFrontImageRight() => "${crossingAssets()}warning_right.png";
  String warningFrontImageYellow() => "${crossingAssets()}warning_yellow.png";
  String reverseWarningFront(String frontWarningImage) =>
      (frontWarningImage == warningFrontImageLeft()) ?  warningFrontImageRight(): warningFrontImageLeft();
  String warningBackImageOff() => "${crossingAssets()}warning_back_off.png";
  String warningBackImageLeft() => "${crossingAssets()}warning_back_left.png";
  String warningBackImageRight() => "${crossingAssets()}warning_back_right.png";
  String warningBackImageYellow() => "${crossingAssets()}warning_back_yellow.png";
  String reverseWarningBack(String frontWarningImage) =>
      (frontWarningImage == warningBackImageLeft()) ?  warningBackImageRight(): warningBackImageLeft();
  //Direction Image
  String directionImageOff() => "${crossingAssets()}direction_off.png";
  String directionImageLeft() => "${crossingAssets()}direction_left.png";
  String directionImageRight() => "${crossingAssets()}direction_right.png";
  String directionImageBoth() => "${crossingAssets()}direction_both.png";
  String bothOrRightDirection(bool isLeftWait) => isLeftWait ? directionImageBoth() : directionImageRight();
  String bothOrLeftDirection(bool isRightWait) => isRightWait ? directionImageBoth() : directionImageLeft();
  String offOrLeftDirection(bool isLeftWait) => isLeftWait ? directionImageLeft() : directionImageOff();
  String offOrRightDirection(bool isRightWait) => isRightWait ? directionImageRight() : directionImageOff();
  //Emergency Image
  String emergencyImage() => "${crossingAssets()}emergency.png";
  //Traffic Sign Image
  String signImage() => "${crossingAssets()}sign.png";
  //Gate Image
  String gateFrontImage() => "${crossingAssets()}gate_front.png";
  String gateBackImage() => "${crossingAssets()}gate_back.png";
  //Fence Image
  String fenceFrontLeftImage() => "${crossingAssets()}fence_front_left.png";
  String fenceFrontRightImage() => "${crossingAssets()}fence_front_right.png";
  String fenceBackLeftImage() => "${crossingAssets()}fence_back_left.png";
  String fenceBackRightImage() => "${crossingAssets()}fence_back_right.png";

  ///Sound
  String soundAssets() => "audios/${countryString()}/";
  String warningSound() => "${soundAssets()}warning_${countryString()}.mp3";

  ///Time
  int flashTime() => (this == 1) ? 500: 1000;

  ///Bar Position
  double frontBarAlignmentX() =>
      (this == 0) ? 0.6947:
      (this == 1) ? 0.7637:
      (this == 2) ? 0.7637:
      (this == 3) ? 0.63:
      0.6947;
  double frontBarAlignmentY() =>
      (this == 0) ? -0.4122:
      (this == 1) ? -0.4122:
      (this == 2) ? -0.4122:
      (this == 3) ? -0.3:
      -0.4122;
  double backBarAlignmentX() =>
      (this == 0) ? -0.6947:
      (this == 1) ? -0.7637:
      (this == 2) ? -0.7637:
      (this == 3) ? -0.63:
      -0.6947;
  double backBarAlignmentY() =>
      (this == 0) ? -0.4122:
      (this == 1) ? -0.4122:
      (this == 2) ? -0.4122:
      (this == 3) ? -0.3:
      -0.4122;
}

extension BoolExt on bool {
  int isFalseNumber() => this ? 0 : 1;
}

extension DateTimeExt on DateTime {

  int intDateTime() {
    final DateFormat formatter = DateFormat('yyyyMMddHHmmss');
    return int.parse(formatter.format(this));
  }

  int intDate() {
    final DateFormat formatter = DateFormat('yyyyMMdd');
    return int.parse(formatter.format(this));
  }
}