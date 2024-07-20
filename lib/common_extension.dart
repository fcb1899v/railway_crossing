import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:purchases_flutter/errors.dart';
import 'my_homepage.dart';
import 'settings.dart';
import 'upgrade.dart';
import 'constant.dart';

extension ContextExt on BuildContext {

  ///Locale
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  ///Size
  //Common
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double topPadding() => MediaQuery.of(this).padding.top;
  double sideMargin() => (width() / 16 > height() / 9) ? (width() - height() * 16 / 9) / 2: 0;

  //Pole
  double frontPoleImageHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.95:
      (countryNumber == 1) ? 0.80:
      0.80
  );
  double frontPoleLeftMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.165:
      (countryNumber == 1) ? 0.165:
      1.28
  );
  double frontPoleTopMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.00:
      (countryNumber == 1) ? 0.16:
      0.10
  );
  double backPoleImageHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.57:
      (countryNumber == 1) ? 0.48:
      0.48
  );
  double backPoleLeftMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 1.15:
      (countryNumber == 1) ? 1.165:
      0.48
  );
  double backPoleTopMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.00:
      (countryNumber == 1) ? 0.09:
      0.08
  );
  //Warning
  double warningImageHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.12:
      (countryNumber == 1) ? 0.23:
      0.27
  );
  double warningLeftMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.131:
      (countryNumber == 1) ? 0.131:
      1.267
  );
  double warningBottomMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.30:
      (countryNumber == 1) ? 0.48:
      0.072
  );
  //Emergency Button
  double emergencyButtonHeight(int countryNumber) => height() * ((countryNumber == 0) ? 0.13: 0.10);
  double emergencyButtonLeftMargin(int countryNumber) => height() * ((countryNumber == 0) ? 0.085: 0.27);
  double emergencyButtonBottomMargin(int countryNumber) => height() * ((countryNumber == 0) ? 0.20: 0.225);
  //Gate
  double gateWidth(int countryNumber) => width() * (
      (countryNumber == 0) ? 1:
      (countryNumber == 1) ? 1:
      2
  );
  double frontGateImageHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.288:
      (countryNumber == 1) ? 0.288:
      0.31
  );
  double frontGateRightMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.220:
      (countryNumber == 1) ? 0.145:
      0.456
  );
  double frontGateBottomMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.02:
      (countryNumber == 1) ? 0.02:
      0.005
  );
  double backGateImageHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.173:
      (countryNumber == 1) ? 0.173:
      0.182
  );
  double backGateLeftMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.500:
      (countryNumber == 1) ? 0.455:
      0
  );
  double backGateBottomMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.215:
      (countryNumber == 1) ? 0.215:
      0.23
  );
  //Bar
  double frontBarImageHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.145:
      (countryNumber == 1) ? 0.145:
      0.22
  );
  double frontBarRightMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.085:
      (countryNumber == 1) ? 0.092:
      0.379
  );
  double frontBarBottomMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.15:
      (countryNumber == 1) ? 0.15:
      0.033
  );
  double backBarImageHeight(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.084:
      (countryNumber == 1) ? 0.084:
      0.13
  );
  double backBarLeftMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.424:
      (countryNumber == 1) ? 0.428:
      0.585
  );
  double backBarBottomMargin(int countryNumber) => height() * (
      (countryNumber == 0) ? 0.298:
      (countryNumber == 1) ? 0.298:
      0.2455
  );
  //Fence
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
  double backFenceBottomMargin(int countryNumber) => height() * 0.235;
  //Train
  double leftTrainOffset()  => - height() * 0.050;
  double rightTrainOffset() => - height() * 0.025;
  double leftTrainHeight()  => height() * 0.9;
  double rightTrainHeight() => height() * 0.7;
  //Button
  double buttonSpace() => height() * 0.05;
  double buttonSideMargin() => sideMargin() + buttonSpace();

  //Settings
  double settingsSidePadding() => width() < 600 ? 10: width() / 2 - 290;
  //Admob
  double admobHeight() => (height() < 320) ? 50: (820 < height()) ? 100: 0.1 * height() + 18;
  double admobWidth() => 320;

  ///Localization
  String appTitle() => AppLocalizations.of(this)!.appTitle;
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String settingsTitle() => AppLocalizations.of(this)!.settingsTitle;
  String premiumPlan() => AppLocalizations.of(this)!.premiumPlan;
  String plan() => AppLocalizations.of(this)!.plan;
  String free() => AppLocalizations.of(this)!.free;
  String premium() => AppLocalizations.of(this)!.premium;
  String upgrade() => AppLocalizations.of(this)!.upgrade;
  String toUpgrade() => AppLocalizations.of(this)!.toUpgrade;
  String restore() => AppLocalizations.of(this)!.restore;
  String toRestore() => AppLocalizations.of(this)!.toRestore;
  String successPurchase() => AppLocalizations.of(this)!.successPurchase;
  String successRestore() => AppLocalizations.of(this)!.successRestore;
  String successPurchaseMessage(bool isRestore) => isRestore ? successRestore(): successPurchase();
  String errorPurchase() => AppLocalizations.of(this)!.errorPurchase;
  String errorRestore() => AppLocalizations.of(this)!.errorRestore;
  String errorPurchaseTitle(bool isRestore) => isRestore ? errorRestore(): errorPurchase();
  String readError() => AppLocalizations.of(this)!.readError;
  String failPurchase() => AppLocalizations.of(this)!.failPurchase;
  String failRestore() => AppLocalizations.of(this)!.failRestore;
  String failPurchaseMessage(bool isRestore) => isRestore ? failRestore(): failPurchase();
  String purchaseCancelledMessage() => AppLocalizations.of(this)!.purchaseCancelledMessage;
  String paymentPendingMessage() => AppLocalizations.of(this)!.paymentPendingMessage;
  String purchaseInvalidMessage() => AppLocalizations.of(this)!.purchaseInvalidMessage;
  String purchaseNotAllowedMessage() => AppLocalizations.of(this)!.purchaseNotAllowedMessage;
  String networkErrorMessage() => AppLocalizations.of(this)!.networkErrorMessage;
  String purchaseErrorMessage(PurchasesErrorCode errorCode, bool isRestore) =>
    (errorCode == PurchasesErrorCode.purchaseCancelledError) ? purchaseCancelledMessage():
    (errorCode == PurchasesErrorCode.paymentPendingError) ? paymentPendingMessage():
    (errorCode == PurchasesErrorCode.purchaseInvalidError) ? purchaseInvalidMessage():
    (errorCode == PurchasesErrorCode.purchaseNotAllowedError) ? purchaseNotAllowedMessage():
    (errorCode == PurchasesErrorCode.networkError) ? networkErrorMessage():
    failPurchaseMessage(isRestore);
  String loading() => AppLocalizations.of(this)!.loading;
  String loadingError() => AppLocalizations.of(this)!.loadingError;
  String selectLeftTrain() => AppLocalizations.of(this)!.selectLeftTrain;
  String selectRightTrain() => AppLocalizations.of(this)!.selectRightTrain;

  String pushButton() => AppLocalizations.of(this)!.pushButton;
  String pedestrianSignal() => AppLocalizations.of(this)!.pedestrianSignal;
  String carSignal() => AppLocalizations.of(this)!.carSignal;
  String noAds() => AppLocalizations.of(this)!.noAds;
  String timeSettings() => AppLocalizations.of(this)!.timeSettings;
  String timeUnit() => AppLocalizations.of(this)!.timeUnit;
  String waitTime() => AppLocalizations.of(this)!.waitTime;
  String goTime() => AppLocalizations.of(this)!.goTime;
  String flashTime() => AppLocalizations.of(this)!.flashTime;
  String soundSettings() => AppLocalizations.of(this)!.soundSettings;
  String crosswalkSound() => AppLocalizations.of(this)!.crosswalkSound;
  String toSettings() => AppLocalizations.of(this)!.toSettings;
  String toOn() => AppLocalizations.of(this)!.toOn;
  String toOff() => AppLocalizations.of(this)!.toOff;
  String toNew() => AppLocalizations.of(this)!.toNew;
  String toOld() => AppLocalizations.of(this)!.toOld;
  String confirmed() => AppLocalizations.of(this)!.confirmed;
  String oldOrNew(bool isNew) => (isNew) ? toOld(): toNew();
  String settingsPremiumTitle(String premiumPrice, bool isReadError) =>
      (premiumPrice != "") ? premiumPlan():
      (isReadError) ? readError(): loading();

  void pushHomePage() =>
      Navigator.pushReplacement(this, MaterialPageRoute(builder: (BuildContext context) =>  MyHomePage()));
  void pushSettingsPage() =>
      Navigator.push(this, MaterialPageRoute(builder: (context) => const MySettingsPage()));
  void pushUpgradePage() =>
      Navigator.push(this, MaterialPageRoute(builder: (context) => const MyUpgradePage()));
}

extension StringExt on String {

  void debugPrint() async {
    if (kDebugMode) {
      print(this);
    }
  }

  //this is key
  int getSettingsValueInt(int defaultValue) =>
    Settings.getValue<int>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  bool getSettingsValueBool(bool defaultValue) =>
      Settings.getValue<bool>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  String getSettingsValueString(String defaultValue) =>
      Settings.getValue<String>("key_$this", defaultValue: defaultValue) ?? defaultValue;

  //this is countryCode
  int getDefaultCounter() =>
      (this == "JP") ? 0:
      (this == "GB") ? 1:
      (this == "CN") ? 2:
      (this == "US") ? 3:
      0;

  //Settings
  Icon settingsPremiumLeadingIcon(bool isReadError) =>
      (this != "") ? const Icon(Icons.shopping_cart_outlined):
      (isReadError) ? const Icon(Icons.error):
      const Icon(Icons.downloading);
  Icon? settingsPremiumTrailingIcon() =>
      (this != "") ? const Icon(Icons.arrow_forward_ios): null;

}


extension IntExt on int {

  //this is countryNumber

  ///Image
  //Assets
  String crossingAssets() =>
      (this == 1) ?  crossingUKAssets:
      (this == 2) ?  crossingCNAssets:
      (this == 3) ?  crossingUSAssets:
      crossingJPAssets;
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
  double barAngle(bool isWait) => (this == 2 || isWait) ? 0.0: 1.5;
  double barShift(bool isWait) => (this == 2 && !isWait) ? 1.0: 0.0;
  //Warning Image
  String warningImageOff() => "${crossingAssets()}warning_off.png";
  String warningImageLeft() => "${crossingAssets()}warning_left.png";
  String warningImageRight() => "${crossingAssets()}warning_right.png";
  String warningImageYellow() => "${crossingAssets()}warning_yellow.png";
  String reverseWarning(String warningImage) => (warningImage == warningImageLeft()) ?  warningImageRight(): warningImageLeft();
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
  //Gate Image
  String gateFrontImage() => "${crossingAssets()}gate_front.png";
  String gateBackImage() => "${crossingAssets()}gate_back.png";
  //Fence Image
  String fenceFrontLeftImage() => "${crossingAssets()}fence_front_left.png";
  String fenceFrontRightImage() => "${crossingAssets()}fence_front_right.png";
  String fenceBackLeftImage() => "${crossingAssets()}fence_back_left.png";
  String fenceBackRightImage() => "${crossingAssets()}fence_back_right.png";

  ///Sound
  String soundAssets() =>
      (this == 1) ?  soundUKAssets:
      (this == 2) ?  soundCNAssets:
      (this == 3) ?  soundUSAssets:
      soundJPAssets;
  String warningSound() => "${soundAssets()}warning.mp3";

  ///Time
  int flashTime() => (this == 0) ? 1000: 500;

  ///Bar Position
  double frontBarAlignmentX() => (this == 0) ? 0.6947: 0.7637;
  double frontBarAlignmentY() => (this == 0) ? -0.4122: -0.4122;
  double backBarAlignmentX() => (this == 0) ? -0.6947: -0.7637;
  double backBarAlignmentY() => (this == 0) ? -0.4122: -0.4122;

}

extension BoolExt on bool {

  Color operationColor() => this ? redColor: whiteColor;

}