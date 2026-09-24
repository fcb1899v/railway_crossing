// ===== SizeExt: responsive layout sizes (part of extension.dart) =====
part of 'extension.dart';

extension SizeExt on BuildContext {
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
  // Banner slot width (adaptive keeps the width and only picks the height).
  // Lives here so the test exercises the same expression the widget uses.
  double bannerSlotWidth() => (mediaWidth() * bannerWidthRatio)
      .clamp(minBannerWidth, maxBannerWidth);

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
  /// Vertical space the purchase button takes in the one-time menu, margins included
  double onetimeMenuPurchaseButtonExtent() =>
      menuPurchaseButtonMargin() + menuPurchaseButtonHeight() + menuPurchaseButtonMarginBottom();
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
  // A floating snackbar anchors to the bottom, so the top margin is screen height less the bar and its gap.
  double snackBarHeight() => snackBarFontSize() * 1.4 + snackBarPadding() * 2;
  double snackBarTopMargin() =>
      (mediaHeight() - snackBarHeight() - height() * snackBarTopGap)
          .clamp(0.0, mediaHeight());
}
