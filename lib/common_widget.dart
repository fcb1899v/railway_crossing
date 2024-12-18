import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common_extension.dart';
import 'constant.dart';

///Background
Widget backGroundImage(BuildContext context, int countryNumber) =>
    Container(
      width: context.mediaWidth(),
      height: context.mediaHeight(),
      color: blackColor,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: context.sideMargin()),
        width: context.height() / aspectRatio,
        height: context.height(),
        child: Image.asset(countryNumber.backgroundImage()),
      )
    );

Widget sideSpacer(BuildContext context) =>
    Row(children: [
      Container(
        color: blackColor,
        width: context.sideMargin(),
      ),
      const Spacer(),
      Container(
        color: blackColor,
        width: context.sideMargin(),
      ),
    ]);

Widget upDownSpacer(BuildContext context) =>
    Column(children: [
      Container(
        color: blackColor,
        height: context.upDownMargin(),
      ),
      const Spacer(),
      Container(
        color: blackColor,
        height: context.upDownMargin(),
      ),
    ]);

///Pole
Widget frontPoleImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.frontPoleTopMargin(countryNumber),
        left: context.frontPoleLeftMargin(countryNumber),
      ),
      height: context.frontPoleImageHeight(countryNumber),
      child: Image.asset(countryNumber.poleFrontImage()),
    );

Widget backPoleImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.backPoleTopMargin(countryNumber),
        left: context.backPoleLeftMargin(countryNumber),
      ),
      height: context.backPoleImageHeight(countryNumber),
      child: Image.asset(countryNumber.poleBackImage()),
    );

///Warning Lamp
Widget frontWaringImage(BuildContext context, int countryNumber, String warningFrontImage) =>
    Container(
      margin: EdgeInsets.only(
        left: context.frontWarningLeftMargin(countryNumber),
        bottom: context.frontWarningBottomMargin(countryNumber),
      ),
      height: context.frontWarningImageHeight(countryNumber),
      child: (warningFrontImage != "") ? Image.asset(warningFrontImage): null,
    );

Widget backWarningImage(BuildContext context, int countryNumber, String warningBackImage) =>
    Container(
      margin: EdgeInsets.only(
        bottom: context.backWarningBottomMargin(countryNumber),
        left: context.backWarningLeftMargin(countryNumber)
      ),
      height: context.backWarningImageHeight(countryNumber),
      child: ((countryNumber == 0 || countryNumber == 3) && warningBackImage != "") ? Image.asset(warningBackImage): null,
    );

///Direction
Widget frontDirectionImage(BuildContext context, int countryNumber, String directionImage) =>
    Container(
      margin: EdgeInsets.only(
        top: context.frontDirectionTopMargin(),
        left: context.frontDirectionLeftMargin(),
      ),
      height: context.frontDirectionHeight(),
      child: (countryNumber == 0 && directionImage != "")  ? Image.asset(directionImage): null,
    );

Widget backDirectionImage(BuildContext context, int countryNumber, String directionImage) =>
    Container(
      margin: EdgeInsets.only(
        top: context.backDirectionTopMargin(),
        left: context.backDirectionLeftMargin(),
      ),
      height: context.backDirectionHeight(),
      child: (countryNumber == 0 && directionImage != "") ? Image.asset(directionImage): const SizedBox(width: 0),
    );

///Gate
Widget frontGateImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.frontGateTopMargin(countryNumber),
        left: context.frontGateLeftMargin(countryNumber),
      ),
      height: context.frontGateImageHeight(countryNumber),
      child: (countryNumber != 3) ? Image.asset(countryNumber.gateFrontImage()): const SizedBox(width: 0),
    );

Widget backGateImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.backGateTopMargin(countryNumber),
        left: context.backGateLeftMargin(countryNumber),
      ),
      height: context.backGateImageHeight(countryNumber),
      child: (countryNumber != 3) ? Image.asset(countryNumber.gateBackImage()): null,
    );

///Bar
Widget frontBarImage(BuildContext context, int countryNumber, String barFrontImage, double angle, double shift, int changeTime) =>
    Container(
      margin: EdgeInsets.only(
        left: context.frontBarLeftMargin(countryNumber),
        top: context.frontBarTopMargin(countryNumber)
      ),
      height: context.frontBarImageHeight(countryNumber),
      child: TweenAnimationBuilder<double>(
        duration: Duration(seconds: changeTime),
        curve: Curves.easeInOut,
        tween:  Tween(
          begin: (countryNumber != 2) ? barUpAngle - angle: (shift - 1) * context.height(),
          end: (countryNumber != 2) ? angle: -shift * context.height(),
        ),
        builder: (context, value, child) => Transform(
          transform: (countryNumber != 2) ? Matrix4.rotationZ(value):
            Matrix4.translationValues(value, 0, 0),
          alignment: (countryNumber != 2) ? Alignment(
            countryNumber.frontBarAlignmentX(),
            countryNumber.frontBarAlignmentY(),
          ): null,
          child: child,
        ),
        child: (barFrontImage != "") ? Image.asset(barFrontImage): null,
      ),
    );

Widget backBarImage(BuildContext context, int countryNumber, String barBackImage, double angle, double shift, int changeTime) =>
    Container(
      margin: EdgeInsets.only(
        top: context.backBarTopMargin(countryNumber),
        left: context.backBarLeftMargin(countryNumber),
      ),
      height: context.backBarImageHeight(countryNumber),
      child: AnimatedContainer(
        duration: Duration(seconds: changeTime),
        curve: Curves.easeInOut,
        transform: (countryNumber == 2) ?
          Matrix4.translationValues(context.backBarShift(shift), 0, 0):
          Matrix4.rotationZ(-angle),
        transformAlignment: (countryNumber != 2) ? Alignment(
          countryNumber.backBarAlignmentX(),
          countryNumber.backBarAlignmentY(),
        ): null,
        child: (barBackImage != "") ? Image.asset(barBackImage): null,
      ),
    );

/// Emergency
Widget frontEmergencyImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.frontEmergencyTopMargin(),
        left: context.frontEmergencyLeftMargin(),
      ),
      height: context.frontEmergencyHeight(),
      child: (countryNumber == 0) ? Image.asset(boardFrontDefault): null,
    );

Widget backEmergencyImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.backEmergencyTopMargin(),
        left: context.backEmergencyLeftMargin(),
      ),
      height: context.backEmergencyHeight(),
      child: Image.asset(boardBackDefault),
    );

Widget emergencyButton(BuildContext context, int countryNumber, void Function() emergencyOn) =>
    Container(
      margin: EdgeInsets.only(
        top: context.emergencyButtonTopMargin(countryNumber),
        left: context.emergencyButtonLeftMargin(countryNumber),
      ),
      height: context.emergencyButtonHeight(countryNumber),
      child: GestureDetector(
        onTap: () => emergencyOn(),
        child: (countryNumber == 0 || countryNumber == 1) ? Image.asset(countryNumber.emergencyImage()): null,
      )
    );

///Traffic Sign
Widget trafficSignImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.trafficSignTopMargin(countryNumber),
        left: context.trafficSignLeftMargin(countryNumber),
      ),
      height: context.trafficSignHeight(countryNumber),
      child:Image.asset(countryNumber.signImage()),
    );

/// Fence Image
Widget frontFenceImage(BuildContext context, int countryNumber) =>
    Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(
        bottom: context.upDownMargin(),
        left: context.sideMargin(),
        right: context.sideMargin(),
      ),
      child: Row(children: List.generate(3, (i) =>
        (i == 1) ? const Spacer(): SizedBox(
          height: context.frontFenceImageHeight(countryNumber),
          child: Image.asset(
            (i == 0) ? countryNumber.fenceFrontLeftImage(): countryNumber.fenceFrontRightImage()
          ),
        )
      )),
    );

Widget backFenceImage(BuildContext context, int countryNumber) =>
    Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(
        bottom: context.backFenceBottomMargin(countryNumber),
        left: context.sideMargin(),
        right: context.sideMargin(),
      ),
      child: Row(children: List.generate(3, (i) =>
        (i == 1) ? const Spacer(): SizedBox(
          height: context.backFenceImageHeight(countryNumber),
          child: Image.asset(
            (i == 0) ? countryNumber.fenceBackLeftImage(): countryNumber.fenceBackRightImage()
          )
        )
      )),
    );


/// Train Image
Widget leftTrainImage(BuildContext context, List<String> leftTrainImage, Animation<double> leftAnimation) =>
    AnimatedBuilder(
      animation: leftAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(leftAnimation.value, context.leftTrainOffset()),
        child: OverflowBox(
          maxWidth: double.infinity,
          child: Row(children: List.generate(leftTrainImage.length, (i) =>
            SizedBox(
              height: context.leftTrainHeight(),
              child: Image.asset(
                leftTrainImage[i],
                fit: BoxFit.fitHeight
              )
            ),
          )),
        ),
      ),
    );

Widget rightTrainImage(BuildContext context, List<String> rightTrainImage, Animation<double> rightAnimation) =>
    AnimatedBuilder(
      animation: rightAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(rightAnimation.value, context.rightTrainOffset()),
        child: OverflowBox(
          maxWidth: double.infinity,
          child: Row(children: List.generate(rightTrainImage.length, (i) =>
            SizedBox(
              height: context.rightTrainHeight(),
              child: Image.asset(
                rightTrainImage[i],
                fit: BoxFit.fitHeight,
              ),
            ),
          )),
        ),
      ),
    );

///Camera Button
Widget cameraButtonImage(BuildContext context, int tickets, int currentDate, int lastClaimedDate, bool isPurchase) =>
    Stack(alignment: Alignment.center,
      children: [
        Container(
          width: context.fabSize(),
          height: context.fabSize(),
          decoration: BoxDecoration(
            color: isPurchase ? transpColor: transpBlackColor,
            shape: BoxShape.circle
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: context.cameraIconBottomMargin()),
            child: Icon(Icons.camera_alt_outlined,
              color: (lastClaimedDate.isToday(currentDate) && tickets == 0 && !isPurchase) ? grayColor: whiteColor,
              size: context.cameraIconSize(),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: context.cameraTextTopMargin()),
          child: Text(context.photoShots(currentDate, lastClaimedDate, tickets),
            style: TextStyle(
              fontSize: context.cameraTextFontSize(),
              fontWeight: FontWeight.bold,
              color: (lastClaimedDate.isToday(currentDate) && tickets == 0 && !isPurchase) ? grayColor: whiteColor
            ),
          ),
        ),
      ]
    );

Widget cameraButton(BuildContext context, int tickets, int currentDate, int lastClaimedDate, void Function() cameraAction) =>
    Container(
      alignment: Alignment.topRight,
      margin: EdgeInsets.symmetric(
        horizontal: context.fabSideMargin(),
        vertical: context.fabTopMargin(),
      ),
      child: GestureDetector(
        onTap: cameraAction,
        child: cameraButtonImage(context, tickets, currentDate, lastClaimedDate, false),
      ),
    );

///Operation Icon
Widget operationIcon(BuildContext context, Color color, IconData icon) =>
    Container(
      width: context.operationButtonSize(),
      height: context.operationButtonSize(),
      margin: EdgeInsets.only(left: context.buttonSpace()),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: transpBlackColor,
          border: Border.all(
            color: color,
            width: context.operationButtonBorderWidth(),
          ),
          borderRadius: BorderRadius.circular(context.operationButtonBorderRadius())
      ),
      child: Icon(icon,
        color: color,
        size: context.operationButtonIconSize(),
      ),
    );

Widget emergencyOffButton(BuildContext context, Color emergencyColor, void Function() emergencyOff) =>
    GestureDetector(
      onTap: () async => emergencyOff(),
      child: operationIcon(context, emergencyColor, Icons.emergency),
    );

Widget leftButton(BuildContext context, bool isLeftOn, void Function() pushLeftButton) =>
    GestureDetector(
        onTap: () async => pushLeftButton(),
        child: operationIcon(context, operationColor(isLeftOn), Icons.arrow_back)
    );

Widget rightButton(BuildContext context, bool isRightOn, void Function() pushRightButton) =>
    GestureDetector(
      onTap: () async => pushRightButton(),
      child: operationIcon(context, operationColor(isRightOn), Icons.arrow_forward),
    );

Widget leftSpeedButton(BuildContext context, bool isLeftOn, bool isLeftFast, void Function() pushLeftSpeedButton) =>
    GestureDetector(
        onTap: () async => pushLeftSpeedButton(),
        child: operationIcon(context, operationColor(isLeftOn), isLeftFast ? CupertinoIcons.chevron_left_2:  CupertinoIcons.chevron_left)
    );

Widget rightSpeedButton(BuildContext context, bool isRightOn, bool isRightFast, void Function() pushRightSpeedButton) =>
    GestureDetector(
      onTap: () async => pushRightSpeedButton(),
      child: operationIcon(context, operationColor(isRightOn), isRightFast ? CupertinoIcons.chevron_right_2: CupertinoIcons.chevron_right),
    );

Widget circleIconImage(BuildContext context, IconData icon) => Container(
  width: context.fabSize(),
  height: context.fabSize(),
  margin: EdgeInsets.all(context.buttonSpace()),
  decoration: const BoxDecoration(shape: BoxShape.circle),
  child: Icon(icon,
    color: whiteColor,
    size: context.circleIconSize(),
  ),
);

Widget imageButtonImage(BuildContext context, String image) => Container(
  width: context.operationButtonSize(),
  height: context.operationButtonSize(),
  margin: EdgeInsets.all(context.buttonSpace()),
  child: Image.asset(image),
);

showSnackBar(BuildContext context, String text, bool isAlert) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: blackColor,
        fontSize: context.snackBarFontSize(),
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();

  final snackBar = SnackBar(
    content: Text(text,
      style: TextStyle(
        color: isAlert ? whiteColor: blackColor,
        fontWeight: FontWeight.bold,
        fontSize: context.snackBarFontSize(),
      ),
      textAlign: TextAlign.center,
    ),
    backgroundColor: isAlert ? redColor: whiteColor,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.snackBarBorderRadius()),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: 0,
      vertical: context.snackBarPadding(),
    ), // コンテンツ周囲のパディング
    margin: EdgeInsets.symmetric(
      horizontal: context.snackBarSideMargin(textPainter),
      vertical: context.snackBarBottomMargin(),
    ), // 画面中央に配置
  );
  "showSnackBar: $text".debugPrint();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Widget menuButton(BuildContext context, bool isMenuOpen, bool isMyPurchase, void Function() menuAction) =>
    Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.symmetric(
        horizontal: context.fabSideMargin(),
        vertical: context.fabTopMargin(),
      ),
      child: GestureDetector(
        onTap: isMyPurchase ? (){context.pushHomePage();}: menuAction,
        child: Container(
          width: context.fabSize(),
          height: context.fabSize(),
          decoration: BoxDecoration(
            color: (isMenuOpen || isMyPurchase) ? transpColor: transpBlackColor,
            shape: BoxShape.circle
          ),
          child: Icon(isMyPurchase ? CupertinoIcons.back: isMenuOpen ? Icons.close: Icons.menu,
            color: (isMenuOpen || isMyPurchase) ? transpBlackColor: whiteColor,
            size: context.menuButtonIconSize(),
          ),
        ),
      ),
    );

Widget menuTitleText(BuildContext context, String plan) =>
    Container(
      margin: EdgeInsets.symmetric(
        vertical: context.menuTitleMargin()
      ),
      child: Text(context.currentPlanTitle(plan),
        style: TextStyle(
          fontSize: context.menuTitleTextFontSize(),
          fontWeight: FontWeight.bold,
          fontFamily: "beon",
          color: transpBlackColor
        ),
      ),
    );

Widget menuDivider(BuildContext context) =>
    Divider(
      color: transpBlackColor,
      thickness: context.menuPurchaseButtonBorderWidth(),
      height: context.menuPurchaseButtonBorderWidth(),
      indent: context.menuDividerSideMargin(),
      endIndent: context.menuDividerSideMargin(),
    );

Widget menuTicketsLeftStatus(BuildContext context, String plan, int tickets, int currentDate, int lastClaimedDate) =>
    Container(
        margin: EdgeInsets.symmetric(
          horizontal: context.menuTextSideMargin(),
        ),
        alignment: Alignment.topLeft,
        child: Row(children: [
          Text(context.ticketsLeft(tickets, currentDate, lastClaimedDate),
            style: TextStyle(
              fontSize: context.menuTextFontSize(),
              color: transpBlackColor,
            ),
          ),
          const Spacer(),
          if (tickets == 0 && lastClaimedDate.isToday(currentDate)) Icon(CupertinoIcons.multiply_circle_fill,
            color: grayColor,
            size: context.menuIconSize(),
          ),
          SizedBox(width: context.menuIconMargin()),
          Text(context.menuTicketsNumber(tickets, currentDate, lastClaimedDate),
            style: TextStyle(
              fontSize: (tickets == 0) ? context.menuTextFontSize(): context.menuTitleTextFontSize(),
              fontWeight: FontWeight.bold,
              fontFamily: "beon",
              color: transpBlackColor,
            ),
          )
        ])
    );

Widget menuAdFreeStatus(BuildContext context, String plan) =>
    Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.menuTextSideMargin(),
      ),
      alignment: Alignment.topLeft,
      child: Row(children: [
        Text(context.adFree(),
          style: TextStyle(
            fontSize: context.menuTextFontSize(),
            color: transpBlackColor,
          ),
        ),
        const Spacer(),
        Icon(plan.adFreeIcon(),
          color: plan.adFreeIconColor(),
          size: context.menuIconSize(),
        ),
        SizedBox(width: context.menuIconMargin()),
        Text(context.adFreeText(plan),
          style: TextStyle(
            fontSize: context.menuTextFontSize(),
            fontWeight: FontWeight.bold,
            fontFamily: "beon",
            color: transpBlackColor,
          ),
        )
      ])
    );

Widget menuPurchaseButton(BuildContext context, String plan, void Function() toBuyOnetime, toUpgradePlan, toPurchase) =>
    GestureDetector(
      onTap: (plan == premiumID) ? toBuyOnetime: (plan == standardID) ? toUpgradePlan: toPurchase,
      child: Container(
        width: context.menuPurchaseButtonWidth(),
        height: context.menuPurchaseButtonHeight(),
        margin: EdgeInsets.only(top: context.menuPurchaseButtonMargin()),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: transpYellowColor,
          border: Border.all(
            color: redColor,
            width: context.menuPurchaseButtonBorderWidth(),
          ),
          borderRadius: BorderRadius.circular(context.menuPurchaseButtonCornerRadius())
        ),
        child: Text(context.purchasePlan(plan),
          style: TextStyle(
            fontSize: context.menuPurchaseButtonFontSize(),
            fontWeight: FontWeight.bold,
            fontFamily: "beon",
            color: redColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

Widget menuUpdatedDate(BuildContext context, int countryNumber, int expirationDate) => Container(
  alignment: Alignment.centerRight,
  margin: EdgeInsets.only(
    right: context.menuUpdatedDateMarginRight(),
    bottom: context.menuUpdatedDateMarginBottom()
  ),
  child: Text(context.nextRenewal(context.toCountryDate(countryNumber, expirationDate.toLocalDate())),
    style: TextStyle(
      fontSize: context.menuUpdatedDateFontSize(),
      color: transpBlackColor,
    ),
  ),
);

Widget menuWidget(BuildContext context, String plan, int tickets, int countryNumber, int currentDate, int lastClaimedDate, int expirationDate, void Function() toBuyOnetime, toUpgradePlan, toPurchase, toCancel, toRestore) =>
    Container(
      margin: EdgeInsets.only(
        left: context.menuSideMargin(),
        bottom: context.menuMarginBottom(plan),
      ),
      padding: EdgeInsets.symmetric(vertical: context.menuPaddingTop()),
      width: context.menuWidth(),
      height: context.menuHeight(plan),
      decoration: BoxDecoration(
        color: transpWhiteColor,
        borderRadius: BorderRadius.circular(context.menuCornerRadius())
      ),
      child: Column(children: [
        menuTitleText(context, plan),
        menuTicketsLeftStatus(context, plan, tickets, currentDate, lastClaimedDate),
        menuDivider(context),
        SizedBox(height: context.menuTextUpDownMargin()),
        menuAdFreeStatus(context, plan),
        menuDivider(context),
        menuPurchaseButton(context, plan, toBuyOnetime, toUpgradePlan, toPurchase),
        SizedBox(height: context.menuPurchaseButtonMarginBottom()),
        if (plan != freeID) menuUpdatedDate(context, countryNumber, expirationDate),
        Row(children: [
          if (plan != freeID) externalLink(context, context.contactUs(), context.contactUrl()),
          Spacer(),
          menuCancelOrRestore(context, plan, true, toCancel, toRestore),
        ]),
      ]),
    );

DataColumn dataColumnLabel(BuildContext context, String plan, String label) =>
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(label,
            style: TextStyle(
              fontSize: context.purchaseTableTitleFontSize(),
              fontWeight: FontWeight.bold,
              fontFamily: "beon",
              color: whiteColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

DataCell textDataCell(BuildContext context, String text) =>
    DataCell(
      Center(child:
      Text(text,
        style: TextStyle(
          fontSize: context.purchaseTableFontSize(),
          fontFamily: "beon",
          fontWeight: FontWeight.bold,
          color: transpBlackColor,
        ),
        textAlign: TextAlign.center,
      ),
      ),
    );

DataCell numberDataCell(BuildContext context, String numberText) =>
    DataCell(
      Center(child:
      Text(numberText,
        style: TextStyle(
          fontSize: context.purchaseTableNumberFontSize(),
          fontFamily: "beon",
          fontWeight: FontWeight.bold,
          color: transpBlackColor,
        ),
        textAlign: TextAlign.center,
      ),
      ),
    );

DataCell priceDataCell(BuildContext context, List<String> priceList, int i) =>
    DataCell(
      Center(child:
        RichText(
          textAlign: TextAlign.end,
          text: TextSpan(
            style: const TextStyle(
              fontFamily: "beon",
              fontWeight: FontWeight.bold,
              color: transpBlackColor,
            ),
            children: [
              TextSpan(
                text: priceList[i],
                style: TextStyle(
                  fontSize: context.purchaseTableNumberFontSize(),
                ),
              ),
              if (i < 2) TextSpan(
                text: "\n${context.monthly()}",
                style: TextStyle(
                  fontSize: context.purchaseTableFontSize(),
                ),
              ),
            ],
          ),
        ),
      ),
    );


DataCell iconDataCell(BuildContext context, String plan, int i) =>
    DataCell(
      Center(child:
      ((plan == premiumID && i == 0) || (plan == standardID && i == 1)) ?
        Icon(CupertinoIcons.check_mark_circled_solid,
          color: redColor,
          size: context.purchaseTableIconSize(),
        ): Text("",
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.bold,
            fontFamily: "beon",
            fontSize: context.purchaseTableSubFontSize()
          ),
        ),
      ),
    );

DataCell iconTextDataCell(BuildContext context, bool? isYes, String text) =>
    DataCell(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: (isYes == null) ? null:
            Icon(isYes ? CupertinoIcons.check_mark_circled_solid: CupertinoIcons.multiply_circle_fill,
              color: isYes ? redColor: transpBlackColor,
              size: context.purchaseTableIconSize(),
            ),
          ),
          Text((isYes == null) ? "-": text,
            style: TextStyle(
              color: (isYes != null && isYes) ? redColor: transpBlackColor,
              fontWeight: FontWeight.bold,
              fontFamily: "beon",
              fontSize: context.purchaseTableSubFontSize()
            ),
          )
        ]
      ),
    );

purchaseButtonImage(BuildContext context, String plan, bool isOnetime, bool isCancel) =>
    Container(
      alignment: Alignment.center,
      width: context.purchaseButtonWidth(plan),
      height: context.purchaseButtonHeight(),
      padding: EdgeInsets.all(context.purchaseButtonPadding()),
      decoration: BoxDecoration(
        color: isCancel ? grayColor: transpYellowColor,
        border: Border.all(
          color: isCancel ? transpBlackColor: redColor,
          width: context.purchaseButtonBorderWidth()
        ),
        borderRadius: BorderRadius.circular(context.purchaseButtonBorderRadius()),
      ),
      child: Text(context.purchaseButtonText(plan, isOnetime, isCancel) ,
        style: TextStyle(
          fontSize: context.purchaseButtonFontSize(),
          fontWeight: FontWeight.bold,
          fontFamily: "beon",
          color: isCancel ? transpBlackColor: redColor,
          decoration: TextDecoration.none
        ),
        textAlign: TextAlign.center,
      ),
    );

DataCell purchaseButton(BuildContext context, int i, void Function() buyPremium, buyStandard, buyOnetime) =>
    DataCell(
      GestureDetector(
        onTap: (i == 3) ? null: [buyPremium, buyStandard, buyOnetime][i],
        child: (i == 3) ? null: purchaseButtonImage(context, freeID, false, false),
      ),
    );

DataRow purchaseTableDataRow(BuildContext context, int i, String plan, List<String> priceList, void Function() buyPremium, buyStandard, buyOnetime) =>
    DataRow(
      color: WidgetStateColor.resolveWith((states) => (i % 2 == 0) ? whiteColor: transpGrayColor),
      cells: [
        textDataCell(context, context.purchasePlanList(plan)[i]),
        numberDataCell(context, context.photos(plan.photosList()[i])),
        textDataCell(context, context.timingList()[i]),
        iconTextDataCell(context, plan.isPurchaseRolloverList()[i], context.purchaseRolloverList(plan)[i]),
        iconTextDataCell(context, plan.isPurchaseAdFreeList()[i], context.purchaseAdFreeList(plan)[i]),
        priceDataCell(context, priceList, i),
        purchaseButton(context, i, buyPremium, buyStandard, buyOnetime),
      ]
    );

Widget purchaseTitle(BuildContext context) =>
    Container(
      margin: EdgeInsets.only(bottom: context.purchaseTitleMarginBottom()),
      child: Text(context.worldsFirstApp(),
        style: TextStyle(
          fontSize: context.purchaseTitleFontSize(),
          fontWeight: FontWeight.bold,
          color: redColor,
        ),
        textAlign: TextAlign.center,
      ),
    );

Widget purchaseTable(BuildContext context, String plan, int tickets, List<String> priceList, void Function() buyPremium, buyStandard, buyOnetime) =>
    Container(
      width: context.width(),
      height: context.height(),
      color: whiteColor,
      margin: EdgeInsets.symmetric(
        horizontal: context.sideMargin(),
        vertical: context.upDownMargin(),
      ),
      alignment: Alignment.center,
      child: Column(children: [
        const Spacer(),
        if (plan == freeID) purchaseTitle(context),
        if (plan == freeID) DataTable(
          headingRowHeight: context.purchaseTableHeight(),
          headingRowColor: WidgetStateColor.resolveWith((states) => transpBlackColor),
          headingTextStyle: const TextStyle(color: whiteColor),
          dividerThickness: context.purchaseTableDividerWidth(),
          dataRowMaxHeight: context.purchaseTableHeight(),
          dataRowMinHeight: context.purchaseTableHeight(),
          columnSpacing: context.purchaseTableSpacing(),
          horizontalMargin: context.purchaseTableMargin(),
          border: TableBorder.all(
            color: transpBlackColor,
            width: context.purchaseTableBorderWidth(),
          ),
          columns: List.generate(context.purchaseDataTitleList(plan).length, (j) =>
            dataColumnLabel(context, plan, context.purchaseDataTitleList(plan)[j])
          ),
          rows: List.generate(plan.photosList().length, (i) =>
            (tickets > 0 && i == 2) ? null: purchaseTableDataRow(context, i, plan, priceList, buyPremium, buyStandard, buyOnetime)
          ).where((element) => element != null).cast<DataRow>().toList(),
        ),
        externalLink(context, context.terms(), context.termsUrl()),
        const Spacer(),
      ])
    );

upgradePlanDialog(BuildContext context, String plan, List<String> priceList, int countryNumber, int expirationDate, void Function() toUpgrade) =>
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: transpBlackColor,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, _) =>
        upgradePlanDialogButton(context, plan, priceList, countryNumber, expirationDate, toUpgrade),
      transitionBuilder: (context, animation, _, child) =>
        customFadeTransition(animation, child),
    );

Widget upgradePlanDialogButton(BuildContext context, String plan, List<String> priceList, int countryNumber, int expirationDate, void Function() toUpgrade) =>
    Center(
      child: IntrinsicHeight(
        child: AlertDialog(
          backgroundColor: transpWhiteColor,
          content: Column(children: [
            purchaseUpdatedDate(context, plan, countryNumber, expirationDate),
            upgradePlanTable(context, plan, priceList),
            GestureDetector(
              onTap: toUpgrade,
              child: Container(
                margin: EdgeInsets.only(top: context.purchaseUpgradeButtonMarginTop()),
                child: purchaseButtonImage(context, plan, false, false),
              ),
            ),
          ]),
        ),
      ),
    );

DataRow upgradePlanTableDataRow(BuildContext context, int i, String plan, List<String> priceList) =>
    DataRow(
      color: WidgetStateColor.resolveWith((states) => (i % 2 == 0) ? whiteColor: transpGrayColor),
      cells: [
        iconDataCell(context, plan, i),
        textDataCell(context, context.upgradePlanList()[i]),
        numberDataCell(context, context.photos(plan.photosList()[i])),
        iconTextDataCell(context, isUpgradeAdFreeList[i], context.upgradeAdFreeList()[i]),
        priceDataCell(context, priceList, i),
      ]
    );

Widget upgradePlanTable(BuildContext context, String plan, List<String> priceList) =>
    Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(vertical: context.purchaseTableMarginTop()),
      color: transpColor,
      child: DataTable(
        headingRowHeight: context.purchaseTableHeight(),
        headingRowColor: WidgetStateColor.resolveWith((states) => transpBlackColor),
        headingTextStyle: const TextStyle(color: whiteColor),
        dividerThickness: context.purchaseTableDividerWidth(),
        dataRowMaxHeight: context.purchaseTableHeight(),
        dataRowMinHeight: context.purchaseTableHeight(),
        columnSpacing: context.purchaseTableSpacing(),
        horizontalMargin: context.purchaseTableMargin(),
        border: TableBorder.all(
          color: transpBlackColor,
          width: context.purchaseTableBorderWidth(),
        ),
        columns: List.generate(context.upgradeDataTitleList().length, (j) =>
          dataColumnLabel(context, plan, context.upgradeDataTitleList()[j])
        ),
        rows: List.generate(context.upgradePlanList().length, (i) =>
          upgradePlanTableDataRow(context, i, plan, priceList)
        ),
      )
    );

cancelDialog(BuildContext context, String plan, void Function() cancelPlan) =>
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: transpBlackColor,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, _) =>
        cancelDialogButton(context, plan, cancelPlan),
      transitionBuilder: (context, animation, _, child) =>
        customFadeTransition(animation, child),
    );

Widget cancelDialogButton(BuildContext context, String plan, void Function() cancelPlan) =>
    Center(
      child: IntrinsicHeight(
        child: AlertDialog(
          backgroundColor: transpWhiteColor,
          content: Column(children: [
            cancelTable(context, plan),
            GestureDetector(
              onTap: cancelPlan,
              child: Container(
                margin: EdgeInsets.only(
                  top: context.purchaseCancelButtonMarginTop(),
                  bottom: context.purchaseCancelButtonMarginBottom(),
                ),
                child: purchaseButtonImage(context, plan, false, true),
              ),
            )
          ]),
        ),
      ),
    );

DataRow cancelTableDataRow(BuildContext context, int i, String plan) =>
    DataRow(
      color: WidgetStateColor.resolveWith((states) => (i % 2 == 0) ? whiteColor: transpGrayColor),
      cells: [
        iconDataCell(context, plan, i),
        textDataCell(context, context.purchasePlanList(plan)[i]),
        textDataCell(context, context.photos(plan.photosList()[i])),
        iconTextDataCell(context, plan.isPurchaseAdFreeList()[i], context.purchaseAdFreeList(plan)[i]),
      ]
    );

Widget cancelTable(BuildContext context, String plan) =>
    Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: context.purchaseTableMarginTop()),
      color: transpColor,
      child: DataTable(
        headingRowHeight: context.purchaseTableHeight(),
        headingRowColor: WidgetStateColor.resolveWith((states) => transpBlackColor),
        headingTextStyle: const TextStyle(color: whiteColor),
        dividerThickness: context.purchaseTableDividerWidth(),
        dataRowMaxHeight: context.purchaseTableHeight(),
        dataRowMinHeight: context.purchaseTableHeight(),
        columnSpacing: context.purchaseTableSpacing(),
        horizontalMargin: context.purchaseTableMargin(),
        border: TableBorder.all(
          color: transpBlackColor,
          width: context.purchaseTableBorderWidth(),
        ),
        columns: List.generate(context.purchaseDataTitleList(plan).length, (j) =>
          dataColumnLabel(context, plan, context.purchaseDataTitleList(plan)[j])
        ),
        rows: List.generate(plan.photosList().length, (i) =>
          cancelTableDataRow(context, i, plan)
        ),
      )
    );


buyOnetimeDialog(BuildContext context, String plan, List<String> priceList, int countryNumber, int expirationDate, void Function() buyOnetime) =>
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: transpBlackColor,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, _) =>
        buyOnetimeDialogButton(context, plan, priceList, countryNumber, expirationDate, buyOnetime),
      transitionBuilder: (context, animation, _, child) =>
        customFadeTransition(animation, child),
    );

Widget buyOnetimeDialogButton(BuildContext context, String plan, List<String> priceList, int countryNumber, int expirationDate, void Function() buyOnetime) =>
    Center(
      child: IntrinsicHeight(
        child: AlertDialog(
          backgroundColor: transpWhiteColor,
          content: Column(children: [
            purchaseUpdatedDate(context, plan, countryNumber, expirationDate),
            buyOnetimeTable(context, priceList),
            GestureDetector(
              onTap: buyOnetime,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: context.purchaseButtonMargin()),
                child: purchaseButtonImage(context, premiumID, true, false),
              ),
            ),
          ]),
        ),
      ),
    );

DataRow buyOnetimeTableDataRow(BuildContext context, List<String> priceList) =>
    DataRow(
      color: WidgetStateColor.resolveWith((states) => whiteColor),
      cells: [
        numberDataCell(context, context.photos(addOnTicketNumber)),
        iconTextDataCell(context, false, context.expire()),
        priceDataCell(context, priceList, 2),
      ]
    );

Widget buyOnetimeTable(BuildContext context, List<String> priceList) =>
    Container(
      alignment: Alignment.center,
      color: transpColor,
      margin: EdgeInsets.only(top: context.purchaseTableMarginTop()),
      child: DataTable(
        headingRowHeight: context.purchaseTableHeight(),
        headingRowColor: WidgetStateColor.resolveWith((states) => transpBlackColor),
        headingTextStyle: const TextStyle(color: whiteColor),
        dividerThickness: context.purchaseTableDividerWidth(),
        dataRowMaxHeight: context.purchaseTableHeight(),
        dataRowMinHeight: context.purchaseTableHeight(),
        columnSpacing: context.purchaseTableSpacing(),
        horizontalMargin: context.purchaseTableMargin(),
        border: TableBorder.all(
          color: transpBlackColor,
          width: context.purchaseTableBorderWidth(),
        ),
        columns: List.generate(context.onetimeDataTitleList().length, (j) =>
          dataColumnLabel(context, premiumID, context.onetimeDataTitleList()[j])
        ),
        rows: List.generate(1, (i) =>
          buyOnetimeTableDataRow(context, priceList)
        ),
      )
    );

Widget menuCancelOrRestore(BuildContext context, String plan, bool isMenu, void Function() toCancel, toRestore) =>
    GestureDetector(
      onTap: (plan == freeID) ? toRestore: toCancel,
      child: Container(
        margin: EdgeInsets.only(
          top: context.menuOtherSelectMarginTop(),
          right: (isMenu) ? context.menuOtherSelectMarginSide(): context.purchaseCancelButtonMarginRight(),
        ),
        alignment: Alignment.centerRight,
        child: Text(context.otherSelectPlan(plan),
          style: TextStyle(
            fontSize: context.menuOtherSelectFontSize(),
            color: transpBlackColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );

Widget externalLink(BuildContext context, String title, String url) =>
    GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        margin: EdgeInsets.only(
          top: context.menuOtherSelectMarginTop(),
          left: context.menuOtherSelectMarginSide(),
          right: context.menuOtherSelectMarginSide(),
        ),
        alignment: Alignment.centerRight,
        child: Text(title,
          style: TextStyle(
            fontSize: context.menuOtherSelectFontSize(),
            color: transpBlackColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );


Widget purchaseUpdatedDate(BuildContext context, String plan, int countryNumber, int expirationDate) =>
    Container(
      margin: EdgeInsets.only(
        top: context.purchaseUpdatedMarginTop(),
        right: context.purchaseUpdatedMarginRight(),
      ),
      alignment: Alignment.centerRight,
      child: Text(context.nextRenewal(context.toCountryDate(countryNumber, expirationDate.toLocalDate())),
        style: TextStyle(
          fontSize: context.purchaseUpdatedDateFontSize(),
          color: transpBlackColor,
        ),
        textAlign: TextAlign.center,
      ),
    );

Widget circularProgressIndicator(BuildContext context) =>
    Stack(children: [
      Container(
        width: context.mediaWidth(),
        height: context.mediaHeight(),
        color: transpBlackColor,
      ),
      Center(
        child: SizedBox(
          width: context.circleSize(),
          height: context.circleSize(),
          child: CircularProgressIndicator(
            color: whiteColor,
            strokeWidth: context.circleStrokeWidth(),
          )
        )
      ),
    ]);

FadeTransition customFadeTransition(Animation<double> animation, Widget child) => FadeTransition(
  opacity: CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOut,
  ),
  child: child,
);

customDialog(BuildContext context, {required String title, required String content, required bool isPositive}) =>
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child: Text(context.ok(),
              style: TextStyle(
                color: isPositive ? greenColor: redColor,
              )
            ),
            onPressed: () => context.pushHomePage()
          ),
        ],
      ),
    );

purchaseExceptionDialog(BuildContext context, PlatformException e, {required bool isRestore, required bool isCancel}) {
  final errorCode = PurchasesErrorHelper.getErrorCode(e);
  "${isRestore ? "Restore": isCancel ? "Cancel": "Purchase"} Error: $e".debugPrint();
  return customDialog(context,
    title: context.errorPurchaseTitle(isRestore, isCancel),
    content: context.purchaseErrorMessage(errorCode, isRestore, isCancel),
    isPositive: false,
  );
}

purchaseErrorDialog(BuildContext context, {required bool isRestore, required bool isCancel}) {
  "${isRestore ? "Restore": isCancel ? "Cancel": "Purchase"} Error".debugPrint();
  return customDialog(context,
    title: context.errorPurchaseTitle(isRestore, isCancel),
    content: "",
    isPositive: false,
  );
}

purchaseFinishedDialog(BuildContext context, {required bool isRestore, required bool isCancel}) {
  "Have already finished purchase".debugPrint();
  return customDialog(context,
    title: context.errorPurchaseTitle(isRestore, isCancel),
    content: context.finishPurchaseMessage(isRestore, isCancel),
    isPositive: false,
  );
}

purchaseSubscriptionSuccessDialog(BuildContext context, String planID, int? expirationDate, {required bool isRestore, required bool isCancel}) {
  "${isRestore ? "Restore": isCancel ? "Cancel": "Purchase"} Success: $planID".debugPrint();
  return customDialog(context,
    title: context.planPurchaseTitle(planID, isRestore, isCancel),
    content: context.successPurchaseMessage(planID, expirationDate, isRestore, isCancel),
    isPositive: true,
  );
}

purchaseOnetimeSuccessDialog(BuildContext context, String plan) {
  "Purchase Success: Buy onetime passes".debugPrint();
  return customDialog(context,
    title: (plan == freeID) ? context.onetime(): context.onetime(),
    content: (plan == freeID) ? context.successOnetime(): context.successAddOn(),
    isPositive: true,
  );
}
