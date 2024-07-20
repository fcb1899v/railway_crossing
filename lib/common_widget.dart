import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'common_extension.dart';
import 'constant.dart';

///App Tracking Transparency
Future<void> initPlugin(BuildContext context) async {
  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined && context.mounted) {
      await showCupertinoDialog(context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text(context.appTitle()),
            content: Text(context.thisApp()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        }
      );
    // }
    await Future.delayed(const Duration(milliseconds: 200));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}

///LifecycleEventHandler
class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;
  final AsyncCallback suspendingCallBack;

  LifecycleEventHandler({required this.resumeCallBack, required this.suspendingCallBack});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        resumeCallBack();
        break;
      case AppLifecycleState.paused:
        suspendingCallBack();
        break;
      default:
        break;
    }
  }
}

///App Bar
// PreferredSize myHomeAppBar(BuildContext context, int counter) =>
//     PreferredSize(
//       preferredSize: const Size.fromHeight(appBarHeight),
//       child: AppBar(
//         title: titleText(context, context.appTitle()),
//         backgroundColor: grayColor,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings, color: whiteColor, size: 32),
//             onPressed: () => context.pushSettingsPage(),
//           ),
//         ],
//       ),
//     );

Widget upgradeAppBar(BuildContext context, bool isPremium, isPurchase) =>
    Container(
      height: upgradeAppBarHeight + context.topPadding(),
      padding: EdgeInsets.only(top: context.topPadding() - 10),
      color: grayColor,
      child: Stack(alignment: Alignment.center,
        children: [
          Row(children: [
            const SizedBox(width: 15),
            if (!isPurchase) IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: whiteColor,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
          ]),
          titleText(context, (isPremium) ? context.restore(): context.upgrade()),
        ],
      ),
    );

Widget titleText(BuildContext context, String title) =>
    Text(title,
      style: const TextStyle(
        fontFamily: "beon",
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: whiteColor,
        decoration: TextDecoration.none
      ),
      textScaler: const TextScaler.linear(1.0),
    );

///Operation Icon
Widget operationIcon(BuildContext context, Color color, IconData icon) => Container(
  width: context.height() * 0.1,
  height: context.height() * 0.1,
  alignment: Alignment.center,
  decoration:  BoxDecoration(
    color: transpBlackColor,
    border: Border.all(
      color: color,
      width: context.height() * 0.008,
    ),
    borderRadius: BorderRadius.circular(context.height() * 0.02),),
  child: Icon(icon,
      color: color,
      size: context.height() * 0.08
  ),
);


///Background
//common
Widget backGroundImage(BuildContext context, int countryNumber) =>
    Container(
      width: context.width(),
      height: context.height(),
      color: blackColor,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: context.sideMargin()),
        width: context.height() / 9 * 16,
        height: context.height(),
        child: Image.asset(backGroundJP),
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

Widget frontPoleImage(BuildContext context, int countryNumber) =>
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: context.sideMargin()),
        Container(
          alignment: Alignment.bottomLeft,
          margin: EdgeInsets.only(
            left: context.frontPoleLeftMargin(countryNumber),
            top: context.frontPoleTopMargin(countryNumber),
          ),
          height: context.frontPoleImageHeight(countryNumber),
          child: Image.asset(countryNumber.poleFrontImage()),
        ),
        const Spacer(),
        SizedBox(width: context.sideMargin()),
      ],
    );

Widget frontWaringImage(BuildContext context, int countryNumber, String warningImage) =>
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: context.sideMargin()),
        Container(
          margin: EdgeInsets.only(
            bottom: context.warningBottomMargin(countryNumber),
            left: context.warningLeftMargin(countryNumber)
          ),
          height: context.warningImageHeight(countryNumber),
          child: Image.asset(warningImage),
        ),
        const Spacer(),
        SizedBox(width: context.sideMargin()),
      ],
    );

Widget frontDirectionImage(BuildContext context, String directionImage) =>
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: context.sideMargin()),
        Container(
          margin: EdgeInsets.only(
            top: context.height() * 0.16,
            left: context.height() * 0.238
          ),
          height: context.height() * 0.11,
          child: Image.asset(directionImage),
        ),
        const Spacer(),
        SizedBox(width: context.sideMargin()),
      ],
    );

Widget backPoleImage(BuildContext context, int countryNumber) =>
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: context.sideMargin()),
        Container(
          alignment: Alignment.bottomLeft,
          margin: EdgeInsets.only(
            left: context.backPoleLeftMargin(countryNumber),
            top: context.backPoleTopMargin(countryNumber),
          ),
          height: context.backPoleImageHeight(countryNumber),
          child: Image.asset(countryNumber.poleBackImage()),
        ),
        const Spacer(),
        SizedBox(width: context.sideMargin()),
      ],
    );

Widget backWarningImage(BuildContext context, String warningImage) =>
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: context.sideMargin()),
        Container(
          margin: EdgeInsets.only(
            bottom: context.height() * 0.18,
            left: context.height() * 1.132
          ),
          height: context.height() * 0.07,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi),
            child: Image.asset(warningImage),
          ),
        ),
        const Spacer(),
        SizedBox(width: context.sideMargin()),
      ]
    );

Widget backDirectionImage(BuildContext context, int countryNumber, String directionImage) =>
    Row(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: context.sideMargin()),
        Container(
          margin: EdgeInsets.only(
            top: context.height() * 0.096,
            left: context.height() * 1.193
          ),
          height: context.height() * 0.066,
          child: Image.asset(directionImage)
        ),
        const Spacer(),
        SizedBox(width: context.sideMargin()),
      ]
    );

Widget frontGateImage(BuildContext context, int countryNumber) =>
    Column(children: [
      const Spacer(),
      Row(children: [
        SizedBox(width: context.sideMargin()),
        if (countryNumber == 0 || countryNumber == 1) const Spacer(),
        Container(
          margin: EdgeInsets.only(
            right: context.frontGateRightMargin(countryNumber),
            bottom: context.frontGateBottomMargin(countryNumber)
          ),
          height: context.frontGateImageHeight(countryNumber),
          child: Image.asset(countryNumber.gateFrontImage()),
        ),
        if (countryNumber == 2) const Spacer(),
        SizedBox(width: context.sideMargin()),
      ]),
    ]);

Widget backGateImage(BuildContext context, int countryNumber) =>
    Column(children: [
      const Spacer(),
      Row(children: [
        SizedBox(width: context.sideMargin()),
        if (countryNumber == 2) const Spacer(),
        Container(
          margin: EdgeInsets.only(
            left: context.backGateLeftMargin(countryNumber),
            bottom: context.backGateBottomMargin(countryNumber)
          ),
          height: context.backGateImageHeight(countryNumber),
          child: Image.asset(countryNumber.gateBackImage()),
        ),
        if (countryNumber == 0 || countryNumber == 1) const Spacer(),
        SizedBox(width: context.sideMargin()),
      ]),
    ]);

Widget frontBarImage(BuildContext context, int countryNumber, String barFrontImage, double angle, double shift, int changeTime) =>
    Column(children: [
      const Spacer(),
      Row(children: [
        SizedBox(width: context.sideMargin()),
        const Spacer(),
        Container(
          margin: EdgeInsets.only(
            right: context.frontBarRightMargin(countryNumber),
            bottom: context.frontBarBottomMargin(countryNumber)
          ),
          height: context.frontBarImageHeight(countryNumber),
          child: AnimatedContainer(
            duration: Duration(seconds: changeTime),
            transform: (countryNumber == 2) ?
              Matrix4.translationValues(-shift * context.height(), 0, 0):
              Matrix4.rotationZ(angle),
            transformAlignment: (countryNumber != 2) ? Alignment(
              countryNumber.frontBarAlignmentX(),
              countryNumber.frontBarAlignmentY(),
            ): null,
            child: Image.asset(barFrontImage),
          ),
        ),
        SizedBox(width: context.sideMargin()),
      ]),
    ]);

Widget backBarImage(BuildContext context, int countryNumber, String barBackImage, double angle, double shift, int changeTime) =>
    Column(children: [
      const Spacer(),
      Row(children: [
        SizedBox(width: context.sideMargin()),
        Container(
          margin: EdgeInsets.only(
            left: context.backBarLeftMargin(countryNumber),
            bottom: context.backBarBottomMargin(countryNumber)
          ),
          height: context.backBarImageHeight(countryNumber),
          child: AnimatedContainer(
            duration: Duration(seconds: changeTime),
            transform: (countryNumber == 2) ?
              Matrix4.translationValues(shift * 0.575 * context.height(), 0, 0):
              Matrix4.rotationZ(-angle),
            transformAlignment: (countryNumber != 2) ? Alignment(
              countryNumber.backBarAlignmentX(),
              countryNumber.backBarAlignmentY(),
            ): null,
            child: Image.asset(barBackImage),
          ),
        ),
        const Spacer(),
        SizedBox(width: context.sideMargin()),
      ]),
    ]);

/// Emergency Image
Widget frontBoardImage(BuildContext context, int countryNumber) =>
    Column(children: [
      const Spacer(),
      Row(children: [
        SizedBox(width: context.sideMargin()),
        Container(
          margin: EdgeInsets.only(
            left: context.height() * 0.085,
            bottom: context.height() * 0.01
          ),
          height: context.height() * 0.42,
          child: Image.asset(boardFrontImage),
        ),
        const Spacer(),
      ]),
    ]);

Widget backBoardImage(BuildContext context, int countryNumber) =>
    Column(children: [
      const Spacer(),
      Row(children: [
        SizedBox(width: context.sideMargin()),
        Container(
          margin: EdgeInsets.only(
            left: context.height() * 1.29,
            bottom: context.height() * 0.225
          ),
          height: context.height() * 0.252,
          child: Image.asset(boardBackImage),
        ),
        const Spacer(),
      ]),
    ]);

Widget emergencyButton(BuildContext context, int countryNumber, void emergencyOn()) =>
    Column(children: [
      const Spacer(),
      Row(children: [
        SizedBox(width: context.sideMargin()),
        Container(
          margin: EdgeInsets.only(
            left: context.emergencyButtonLeftMargin(countryNumber),
            bottom: context.emergencyButtonBottomMargin(countryNumber),
          ),
          height: context.emergencyButtonHeight(countryNumber),
          child: GestureDetector(
            onTap: () => emergencyOn(),
            child:Image.asset(countryNumber.emergencyImage()),
          )
        ),
        const Spacer(),
      ]),
    ]);


/// Fence Image
Widget frontFenceImage(BuildContext context, int countryNumber) =>
    Container(
      alignment: Alignment.bottomCenter,
      child: Row(children: List.generate(5, (i) =>
        (i == 2) ? const Spacer():
        (i == 0 || i == 4) ? SizedBox(width: context.sideMargin()):
        SizedBox(
          height: context.frontFenceImageHeight(countryNumber),
          child: Image.asset(
            (i == 1) ? countryNumber.fenceFrontLeftImage(): countryNumber.fenceFrontRightImage()
          ),
        )
      )),
    );

Widget backFenceImage(BuildContext context, int countryNumber) =>
    Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(bottom: context.backFenceBottomMargin(countryNumber)),
      child: Row(children: List.generate(5, (i) =>
        (i == 2) ? const Spacer():
        (i == 0 || i == 4) ? SizedBox(width: context.sideMargin()):
        SizedBox(
          height: context.backFenceImageHeight(countryNumber),
          child: Image.asset(
            (i == 1) ? countryNumber.fenceBackLeftImage(): countryNumber.fenceBackRightImage()
          ),
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
              child: Image.asset(leftTrainImage[i])),
            ),
          ),
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
              child: Image.asset(rightTrainImage[i])),
            ),
          ),
        ),
      ),
    );

//Bottom Buttons
Widget bottomButtons(BuildContext context, bool isLeftOn, bool isRightOn, Color emergencyColor, void emergencyOff(), void pushLeftButton(), void pushRightButton()) =>
    Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(bottom: context.buttonSpace()),
      child: Row(mainAxisAlignment: MainAxisAlignment.end,
        children: List.generate(7, (i) =>
          (i == 2) ? const Spacer():
          (i == 4) ? SizedBox(width: context.buttonSpace()):
          (i == 0 || i == 6) ? SizedBox(width: context.buttonSideMargin()):
          GestureDetector(
            onTap: () async => (i == 1) ? emergencyOff(): (i == 3) ? pushLeftButton(): pushRightButton(),
            child: operationIcon(context,
              (i == 1) ? emergencyColor: (i == 3) ? isLeftOn.operationColor(): isRightOn.operationColor(),
              (i == 1) ? Icons.emergency: (i == 3) ? Icons.arrow_back: Icons.arrow_forward
            )
          ),
        ),
      ),
    );



///Settings
AppBar settingsAppBar(BuildContext context, String title, bool isPurchase) =>
    AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: transpColor,
      foregroundColor: blackColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () async => context.pushHomePage(),
      ),
    );

Widget settingsTitle(BuildContext context, String title, int time) =>
    Row(children: [
      const Icon(Icons.watch_later_outlined, color: grayColor),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(color: blackColor)),
      const Spacer(),
      Text("$time${context.timeUnit()} ", style: const TextStyle(color: blackColor)),
    ]);

sliderTheme(BuildContext context, Color activeColor) =>
    SliderTheme.of(context).copyWith(
      trackHeight: 6,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      thumbColor: activeColor,
      valueIndicatorColor: activeColor,
      overlayColor: activeColor.withAlpha(80),
      activeTrackColor: activeColor,
      inactiveTrackColor: transpGrayColor,
      activeTickMarkColor: activeColor,
      inactiveTickMarkColor: grayColor,
    );

EdgeInsets settingsTitlePadding(bool isBottom) =>
    EdgeInsets.only(
      top: settingsTilePaddingSize,
      bottom: isBottom ? settingsTilePaddingSize / 2: 0,
      left: settingsTilePaddingSize,
      right: settingsTilePaddingSize,
    );

BoxDecoration settingsTileDecoration(bool isTop, isBottom) =>
    BoxDecoration(
      color: (Platform.isIOS || Platform.isMacOS) ? whiteColor: transpColor,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isTop ? settingsTileRadiusSize: 0),
        topRight: Radius.circular(isTop ? settingsTileRadiusSize: 0),
        bottomLeft: Radius.circular(isBottom ? settingsTileRadiusSize: 0),
        bottomRight: Radius.circular(isBottom ? settingsTileRadiusSize: 0),
      ),
    );

///Upgrade
Text premiumTitle(BuildContext context) =>
    Text(context.premiumPlan(),
      style: upgradeTextStyle(context, premiumTitleFontSizeRate, grayColor),
    );

Widget upgradePrice(BuildContext context, String price, bool isPremium) =>
    Container(
      padding: EdgeInsets.all(context.height() * premiumPricePaddingRate),
      child: (!isPremium) ? Text(price,
        style: upgradeTextStyle(context, premiumPriceFontSizeRate, yellowColor),
      ): null,
    );

Widget upgradeButtonImage(BuildContext context, bool isRestore) =>
    Material(
      elevation: upgradeButtonElevation,
      child: Container(
        padding: EdgeInsets.all(context.height() * upgradeButtonPaddingRate),
        decoration: BoxDecoration(
          color: isRestore ? greenColor: yellowColor,
          border: Border.all(color: grayColor, width: upgradeButtonBorderWidth),
          borderRadius: BorderRadius.circular(upgradeButtonBorderRadius),
        ),
        child: Text(isRestore ? context.toRestore(): context.toUpgrade(),
          style: upgradeTextStyle(context, upgradeButtonFontSizeRate, isRestore ? whiteColor: grayColor),
        )
      )
    );

DataTable upgradeDataTable(BuildContext context) =>
    DataTable(
      headingRowHeight: context.height() * upgradeTableHeadingHeightRate,
      headingRowColor: WidgetStateColor.resolveWith((states) => grayColor),
      headingTextStyle: const TextStyle(color: whiteColor),
      dividerThickness: upgradeTableDividerWidth,
      dataRowMaxHeight: context.height() * upgradeTableHeightRate,
      dataRowMinHeight: context.height() * upgradeTableHeightRate,
      columns: [
        dataColumnLabel(context, context.plan()),
        dataColumnLabel(context, context.free()),
        dataColumnLabel(context, context.premium()),
      ],
      rows: [
        tableDataRow(context, context.pushButton(), whiteColor, false),
        tableDataRow(context, context.pedestrianSignal(), transpGrayColor, false),
        tableDataRow(context, context.carSignal(), whiteColor, true),
        tableDataRow(context, context.noAds(), transpGrayColor, true),
      ],
    );

DataColumn dataColumnLabel(BuildContext context, String text) =>
    DataColumn(
      label: Expanded(
        child: Text(text,
          style: upgradeTextStyle(context, upgradeTableFontSizeRate, whiteColor),
          textAlign: TextAlign.center,
        ),
      ),
    );

DataRow tableDataRow(BuildContext context, String title, Color color, bool isPremium) =>
    DataRow(
      color: WidgetStateColor.resolveWith((states) => color),
      cells: [
        DataCell(Text(title,
          style: upgradeTextStyle(context, upgradeTableFontSizeRate, grayColor),
          textAlign: TextAlign.left,
        )),
        isPremium ?
          iconDataCell(context, Icons.not_interested, redColor):
          iconDataCell(context, Icons.check_circle, greenColor),
        iconDataCell(context, Icons.check_circle, greenColor),
      ]
    );

TextStyle upgradeTextStyle(BuildContext context, double fontSizeRate, Color color) =>
    TextStyle(
        fontSize: context.height() * fontSizeRate,
        fontWeight: FontWeight.bold,
        fontFamily: "beon",
        color: color,
        decoration: TextDecoration.none
    );

DataCell iconDataCell(BuildContext context, IconData icon, Color color) =>
    DataCell(Center(child:
      Icon(icon, color: color, size: context.height() * upgradeTableIconSizeRate))
    );

Widget circularProgressIndicator(BuildContext context) =>
    Column(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: greenColor),
        SizedBox(height: context.height() * upgradeCircularProgressMarginBottomRate),
      ]
    );