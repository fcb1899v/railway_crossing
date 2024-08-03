import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'my_homepage.dart';
import 'constant.dart';

extension ContextExt on BuildContext {

  void pushHomePage() =>
      Navigator.pushReplacement(this, MaterialPageRoute(builder: (BuildContext context) =>  MyHomePage()));

  ///Locale
  Locale locale() => Localizations.localeOf(this);
  String lang() => locale().languageCode;

  ///Localization
  String selectLeftTrain() => AppLocalizations.of(this)!.selectLeftTrain;
  String selectRightTrain() => AppLocalizations.of(this)!.selectRightTrain;

  ///Size
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double topPadding() => MediaQuery.of(this).padding.top;
  double sideMargin() => (width() / 16 > height() / 9) ? (width() - height() * 16 / 9) / 2: 0;

  ///Admob
  double admobHeight() => (height() < 320) ? 50: (820 < height()) ? 100: 0.1 * height() + 18;
  double admobWidth() => 320;

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
  double backFenceBottomMargin(int countryNumber) => height() * 0.235;

  ///Train
  double leftTrainOffset()  => - height() * 0.050;
  double rightTrainOffset() => - height() * 0.025;
  double leftTrainHeight()  => height() * 0.9;
  double rightTrainHeight() => height() * 0.7;

  ///Buttons
  double buttonSpace() => height() * 0.035;
  double buttonSideMargin() => sideMargin() + buttonSpace();
  double operationButtonSize() => height() * 0.1;
  double operationButtonBorderWidth() => height() * 0.008;
  double operationButtonBorderRadius() => height() * 0.02;
  double operationButtonIconSize() => height() * 0.06;
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
  String soundAssets() =>
      (this == 1) ?  soundUKAssets:
      (this == 2) ?  soundCNAssets:
      (this == 3) ?  soundUSAssets:
      soundJPAssets;
  String warningSound() => "${soundAssets()}warning.mp3";

  ///Time
  int flashTime() => (this == 0) ? 1000: 500;

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

  Alignment adAlignment() =>
      (this == 0)  ? Alignment.topRight:
      (this == 1)  ? Alignment.topRight:
      (this == 2)  ? Alignment.topLeft:
      (this == 3)  ? Alignment.topLeft:
      Alignment.topRight;

  Alignment floatingActionAlignment() =>
      (this == 0)  ? Alignment.topLeft:
      (this == 1)  ? Alignment.topLeft:
      (this == 2)  ? Alignment.topRight:
      (this == 3)  ? Alignment.topRight:
      Alignment.topLeft;

  FloatingActionButtonLocation floatingActionLocation() =>
      (this == 0)  ? FloatingActionButtonLocation.startDocked:
      (this == 1)  ? FloatingActionButtonLocation.startDocked:
      (this == 2)  ? FloatingActionButtonLocation.endDocked:
      (this == 3)  ? FloatingActionButtonLocation.endDocked:
      FloatingActionButtonLocation.startDocked;

}

extension BoolExt on bool {

  Color operationColor() => this ? redColor: whiteColor;

  double boolToDouble() => this ? 1.0: 0.0;
}