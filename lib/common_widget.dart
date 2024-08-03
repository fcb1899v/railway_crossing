import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'common_extension.dart';
import 'constant.dart';

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

///Background
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
      child: Image.asset(warningFrontImage),
    );

Widget backWarningImage(BuildContext context, int countryNumber, String warningBackImage) =>
    Container(
      margin: EdgeInsets.only(
        bottom: context.backWarningBottomMargin(countryNumber),
        left: context.backWarningLeftMargin(countryNumber)
      ),
      height: context.backWarningImageHeight(countryNumber),
      child: (countryNumber == 0 || countryNumber == 3)  ? Image.asset(warningBackImage): null,
    );

///Direction
Widget frontDirectionImage(BuildContext context, int countryNumber, String directionImage) =>
    Container(
      margin: EdgeInsets.only(
        top: context.frontDirectionTopMargin(),
        left: context.frontDirectionLeftMargin(),
      ),
      height: context.frontDirectionHeight(),
      child: (countryNumber == 0) ? Image.asset(directionImage): null,
    );

Widget backDirectionImage(BuildContext context, int countryNumber, String directionImage) =>
    Container(
      margin: EdgeInsets.only(
        top: context.backDirectionTopMargin(),
        left: context.backDirectionLeftMargin(),
      ),
      height: context.backDirectionHeight(),
      child: (countryNumber == 0) ? Image.asset(directionImage): null
    );

///Gate
Widget frontGateImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.frontGateTopMargin(countryNumber),
        left: context.frontGateLeftMargin(countryNumber),
      ),
      height: context.frontGateImageHeight(countryNumber),
      child: (countryNumber != 3) ? Image.asset(countryNumber.gateFrontImage()): null,
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
        transform: (countryNumber == 2) ?
          Matrix4.translationValues(context.backBarShift(shift), 0, 0):
          Matrix4.rotationZ(-angle),
        transformAlignment: (countryNumber != 2) ? Alignment(
          countryNumber.backBarAlignmentX(),
          countryNumber.backBarAlignmentY(),
        ): null,
        child: Image.asset(barBackImage),
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
      child: (countryNumber == 0) ? Image.asset(boardFrontImage): null,
    );

Widget backEmergencyImage(BuildContext context, int countryNumber) =>
    Container(
      margin: EdgeInsets.only(
        top: context.backEmergencyTopMargin(),
        left: context.backEmergencyLeftMargin(),
      ),
      height: context.backEmergencyHeight(),
      child: Image.asset(boardBackImage),
    );

Widget emergencyButton(BuildContext context, int countryNumber, void emergencyOn()) =>
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
      margin: EdgeInsets.symmetric(horizontal: context.sideMargin()),
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

///Bottom Buttons
///Operation Icon
Widget operationIcon(BuildContext context, Color color, IconData icon) => Container(
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

Widget emergencyOffButton(BuildContext context, Color emergencyColor, void emergencyOff()) =>
    GestureDetector(
      onTap: () async => emergencyOff(),
      child: operationIcon(context, emergencyColor, Icons.emergency),
    );

Widget leftButton(BuildContext context, bool isLeftOn, void pushLeftButton()) =>
    GestureDetector(
      onTap: () async => pushLeftButton(),
      child: operationIcon(context, isLeftOn.operationColor(), Icons.arrow_back)
    );

Widget rightButton(BuildContext context, bool isRightOn, void pushRightButton()) =>
    GestureDetector(
      onTap: () async => pushRightButton(),
      child: operationIcon(context, isRightOn.operationColor(), Icons.arrow_forward),
    );

Widget leftSpeedButton(BuildContext context, bool isLeftOn, bool isLeftFast, void pushLeftSpeedButton()) =>
    GestureDetector(
        onTap: () async => pushLeftSpeedButton(),
        child: operationIcon(context, isLeftOn.operationColor(), isLeftFast ? CupertinoIcons.chevron_left_2:  CupertinoIcons.chevron_left)
    );

Widget rightSpeedButton(BuildContext context, bool isRightOn, bool isRightFast, void pushRightSpeedButton()) =>
    GestureDetector(
      onTap: () async => pushRightSpeedButton(),
      child: operationIcon(context, isRightOn.operationColor(), isRightFast ? CupertinoIcons.chevron_right_2: CupertinoIcons.chevron_right),
    );

