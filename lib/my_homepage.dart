import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:fab_circular_menu_plus/fab_circular_menu_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'main.dart';
import 'admob_banner.dart';

class MyHomePage extends HookConsumerWidget {

  final GlobalKey<FabCircularMenuPlusState> fabKey = GlobalKey();
  MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final width = context.width();
    final height = context.height();

    final countryNumber = useState(0);

    //State
    final isLeftOn = useState(false);
    final isRightOn = useState(false);
    final isLeftFast = useState(true);
    final isRightFast = useState(true);
    final isLeftWait = useState(false);
    final isRightWait = useState(false);
    final isYellow = useState(false);
    final isEmergency = useState(false);
    final isPossibleEmergency = useState(true);

    //Audio
    final warningPlayer = AudioPlayer();
    final leftTrainPlayer = AudioPlayer();
    final rightTrainPlayer = AudioPlayer();
    final emergencyPlayer = AudioPlayer();

    //Image
    final barFrontImage = useState(barFrontImageJPOff);
    final barBackImage = useState(barBackImageJPOff);
    final warningFrontImage = useState(warningImageJPOff);
    final warningBackImage = useState(warningImageJPOff);
    final directionImage = useState(directionImageJPOff);

    //Animation
    final leftController = useAnimationController(duration: const Duration(seconds: 16));
    final rightController = useAnimationController(duration: const Duration(seconds: 16));
    final leftAnimation = useState(Tween(
      begin: trainBeginPosition(isLeftFast.value),
      end: trainEndPosition(isLeftFast.value),
    ).animate(leftController));
    final rightAnimation = useState(Tween(
      begin: trainEndPosition(isRightFast.value),
      end: trainBeginPosition(isRightFast.value),
    ).animate(rightController));
    final leftTrain = useState(trainList[0]);
    final rightTrain = useState(trainList[0]);
    final barAngle = useState(0.0);
    final barShift = useState(0.0);
    final changeTime = useState(0);
    final emergencyColor = useState(whiteColor);

    setNormalState() async {
      "setNormal".debugPrint();
      leftTrain.value = trainList[countryNumber.value];
      rightTrain.value = trainList[countryNumber.value];
      isLeftOn.value = false;
      isLeftWait.value = false;
      isRightOn.value = false;
      isRightWait.value = false;
      isYellow.value = false;
      warningFrontImage.value = countryNumber.value.warningFrontImageOff();
      warningBackImage.value = countryNumber.value.warningBackImageOff();
      barFrontImage.value = countryNumber.value.barFrontOff();
      barBackImage.value = countryNumber.value.barBackOff();
      directionImage.value = countryNumber.value.directionImageOff();
      barAngle.value = countryNumber.value.barAngle(false);
      barShift.value = countryNumber.value.barShift(false);
      isPossibleEmergency.value = true;
      await warningPlayer.stop();
    }

    initState() async {
      final locale = await Devicelocale.currentLocale ?? "ja-JP";
      final countryCode = locale.substring(3, 5);
      countryNumber.value = countryCode.getDefaultCounter();
      "Locale: $locale, countryNumber: ${countryNumber.value}".debugPrint();
      "width: $width, height: $height".debugPrint();
      // countryNumber.value = 1; //for debug
      setNormalState();
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        ///App Tracking Transparency
        if (Platform.isIOS || Platform.isMacOS) {
          final status = await AppTrackingTransparency.trackingAuthorizationStatus;
          if (status == TrackingStatus.notDetermined && context.mounted) {
            await AppTrackingTransparency.requestTrackingAuthorization();
          }
        }
        initState();
        initSettings();
      });
      return null;
    }, const []);

    setYellowState() {
      "setYellow".debugPrint();
      isYellow.value = true;
      "isYellow: ${isYellow.value}".debugPrint();
      warningFrontImage.value = countryNumber.value.warningFrontImageYellow();
      warningBackImage.value = countryNumber.value.warningBackImageYellow();
      changeTime.value = barUpDownTime;
    }

    setWarningState() {
      "setWarning".debugPrint();
      isYellow.value = false;
      "isYellow: ${isYellow.value}".debugPrint();
      warningFrontImage.value = countryNumber.value.warningFrontImageLeft();
      warningBackImage.value = countryNumber.value.warningBackImageLeft();
      barFrontImage.value = countryNumber.value.barFrontOff();
      barBackImage.value = countryNumber.value.barBackOff();
      barAngle.value = countryNumber.value.barAngle(true);
      barShift.value = countryNumber.value.barShift(true);
    }

    leftWaitOff() async {
      await leftTrainPlayer.stop();
      "leftTrainPlayer: ${leftTrainPlayer.state}".debugPrint();
      directionImage.value = countryNumber.value.offOrRightDirection(isRightWait.value);
      isLeftOn.value = false;
      isLeftWait.value = false;
      "isLeftWait: ${isLeftWait.value}".debugPrint();
      "isRightWait: ${isRightWait.value}".debugPrint();
      if (!isRightWait.value) await setNormalState();
    }

    goLeftTrain() async {
      if (isLeftWait.value && !isEmergency.value) {
        isPossibleEmergency.value = false;
        "isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
        await leftTrainPlayer.play(AssetSource(soundTrain));
        await leftTrainPlayer.setReleaseMode(ReleaseMode.release);
        await leftTrainPlayer.setVolume(trainVolume);
        "leftTrainPlayer: ${leftTrainPlayer.state}".debugPrint();
        leftAnimation.value = Tween(
          begin: trainBeginPosition(isLeftFast.value),
          end: trainEndPosition(isLeftFast.value),
        ).animate(leftController);
        await leftController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          "leftWaitOff".debugPrint();
          leftWaitOff();
        });
      }
    }

    leftWaitOn() async {
      if (!isRightWait.value) setWarningState();
      directionImage.value = countryNumber.value.bothOrLeftDirection(isRightWait.value);
      isLeftWait.value = true;
      "isLeftWait: ${isLeftWait.value}".debugPrint();
      Future.delayed(const Duration(seconds: waitTime), () {
        "goLeftTrain".debugPrint();
        goLeftTrain();
      });
    }

    pushLeftButton() {
      if (!isLeftOn.value && !isEmergency.value) {
        isLeftOn.value = true;
        if (!isRightOn.value) {
          setYellowState();
          Future.delayed(const Duration(seconds: yellowTime), () {
            "leftWaitOn".debugPrint();
            leftWaitOn();
          });
        } else {
          "leftWaitOn".debugPrint();
          leftWaitOn();
        }
      }
    }

    rightWaitOff() async {
      await rightTrainPlayer.stop();
      "rightTrainPlayer: ${rightTrainPlayer.state}".debugPrint();
      directionImage.value = countryNumber.value.offOrLeftDirection(isLeftWait.value);
      isRightOn.value = false;
      isRightWait.value = false;
      "isLeftWait: ${isLeftWait.value}".debugPrint();
      "isRightWait: ${isRightWait.value}".debugPrint();
      if (!isLeftWait.value) await setNormalState();
    }

    goRightTrain() async {
      if (isRightWait.value && !isEmergency.value) {
        isPossibleEmergency.value = false;
        await rightTrainPlayer.play(AssetSource(soundTrain));
        await rightTrainPlayer.setReleaseMode(ReleaseMode.release);
        await rightTrainPlayer.setVolume(trainVolume);
        "rightTrainPlayer: ${rightTrainPlayer.state}".debugPrint();
        rightAnimation.value = Tween(
          begin: trainEndPosition(isRightFast.value),
          end: trainBeginPosition(isRightFast.value),
        ).animate(rightController);
        await rightController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          "rightWaitOff".debugPrint();
          rightWaitOff();
        });
      }
    }

    rightWaitOn() async {
      if (!isLeftWait.value) setWarningState();
      directionImage.value = countryNumber.value.bothOrRightDirection(isLeftWait.value);
      isRightWait.value = true;
      "isRightWait: ${isRightWait.value}".debugPrint();
      Future.delayed(const Duration(seconds: waitTime), () {
        "goRightTrain".debugPrint();
        goRightTrain();
      });
    }

    pushRightButton() {
      if (!isRightWait.value && !isEmergency.value) {
        isRightOn.value = true;
        if (!isLeftWait.value) {
          setYellowState();
          Future.delayed(const Duration(seconds: yellowTime), () {
            "rightWaitOn".debugPrint();
            rightWaitOn();
          });
        } else {
          "rightWaitOn".debugPrint();
          rightWaitOn();
        }
      }
    }

    pushLeftSpeedButton() {
      if (!isLeftOn.value) {
        isLeftFast.value = !isLeftFast.value;
        "isLeftFast: ${isLeftFast.value}".debugPrint();
      }
    }

    pushRightSpeedButton() {
      if (!isRightOn.value) {
        isRightFast.value = !isRightFast.value;
        "isRightFast: ${isRightFast.value}".debugPrint();
      }
    }

    emergencyOn() async {
      if (!isEmergency.value && isPossibleEmergency.value) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        isEmergency.value = true;
        "isEmergency: ${isEmergency.value}".debugPrint();
        isPossibleEmergency.value = false;
        "isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
      }
    }

    emergencyOff() async {
      if (isEmergency.value) {
        isEmergency.value = false;
        "isEmergency: ${isEmergency.value}".debugPrint();
        if (isLeftWait.value || isRightWait.value) {
          await Future.delayed(const Duration(seconds: emergencyWaitTime), () async {
            if (isLeftWait.value) await goLeftTrain();
            if (isRightWait.value) await goRightTrain();
          });
        } else {
          if (!isLeftWait.value && !isRightWait.value) {
            isPossibleEmergency.value = true;
            "isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
          }
        }
      }
    }

    ///Change Country
    changeCountry(MapEntry entry) async {
      changeTime.value = 0;
      countryNumber.value = entry.value['countryNumber'] as int;
      'select_${entry.key}: ${countryNumber.value}'.debugPrint();
      fabKey.currentState?.close();
      await setNormalState();
      await Future.delayed(const Duration(seconds: barUpDownTime), () => changeTime.value = barUpDownTime);
    }

    /// Left Action
    useEffect(() {

      Timer? leftWarningTimer;
      Timer? leftBarTimer;

      void leftWarningToggle() {
        if (!isLeftWait.value && !isRightWait.value) {
          warningPlayer.stop();
          "warningPlayer: ${warningPlayer.state}".debugPrint();
          return;
        }
        if (warningPlayer.state == PlayerState.completed) {
          warningPlayer.play(AssetSource(countryNumber.value.warningSound()));
          "warningPlayer: ${warningPlayer.state}".debugPrint();
        }
        warningFrontImage.value = countryNumber.value.reverseWarningFront(warningFrontImage.value);
        warningBackImage.value = countryNumber.value.reverseWarningBack(warningBackImage.value);
        leftWarningTimer = Timer(Duration(milliseconds: countryNumber.value.flashTime()), leftWarningToggle);
      }

      void leftBarToggle() {
        if (!isLeftWait.value) return;
        barFrontImage.value = countryNumber.value.reverseBarFront(barFrontImage.value);
        barBackImage.value = countryNumber.value.reverseBarBack(barBackImage.value);
        leftBarTimer = Timer(const Duration(milliseconds: ledDurationTime), leftBarToggle);
      }

      if (isLeftWait.value) {
        if (warningPlayer.state != PlayerState.playing) {
          warningPlayer.play(AssetSource(countryNumber.value.warningSound()));
          warningPlayer.setReleaseMode(ReleaseMode.release);
          warningPlayer.setVolume(warningVolume);
          "warningPlayer: ${warningPlayer.state}".debugPrint();
        }
        leftWarningToggle();
        leftBarToggle();
      }

      return () {
        leftWarningTimer?.cancel();
        leftBarTimer?.cancel();
      };
    }, [isLeftWait.value]);

    /// Right Action
    useEffect(() {

      Timer? rightWarningTimer;
      Timer? rightBarTimer;

      void rightWarningToggle() {
        if (!isLeftWait.value && !isRightWait.value) {
          warningPlayer.stop();
          "warningPlayer: ${warningPlayer.state}".debugPrint();
          return;
        }
        if (!isLeftWait.value) {
          if (warningPlayer.state == PlayerState.completed) {
            warningPlayer.play(AssetSource(countryNumber.value.warningSound()));
            "warningPlayer: ${warningPlayer.state}".debugPrint();
          }
          warningFrontImage.value = countryNumber.value.reverseWarningFront(warningFrontImage.value);
          warningBackImage.value = countryNumber.value.reverseWarningBack(warningBackImage.value);
        }
        rightWarningTimer = Timer(Duration(milliseconds: countryNumber.value.flashTime()), rightWarningToggle);
      }

      void rightBarToggle() {
        if (!isRightWait.value) return;
        if (!isLeftWait.value) {
          barFrontImage.value = countryNumber.value.reverseBarFront(barFrontImage.value);
          barBackImage.value = countryNumber.value.reverseBarBack(barBackImage.value);
        }
        rightBarTimer = Timer(const Duration(milliseconds: ledDurationTime), rightBarToggle);
      }

      if (isRightWait.value) {
        if (!isLeftWait.value && (warningPlayer.state != PlayerState.playing)) {
          warningPlayer.play(AssetSource(countryNumber.value.warningSound()));
          warningPlayer.setReleaseMode(ReleaseMode.release);
          warningPlayer.setVolume(warningVolume);
          "warningPlayer: ${warningPlayer.state}".debugPrint();
        }
        rightWarningToggle();
        rightBarToggle();
      }

      return () {
        rightWarningTimer?.cancel();
        rightBarTimer?.cancel();
      };
    }, [isRightWait.value]);

    /// Emergency Action
    useEffect(() {

      Timer? emergencyTimer;

      void emergencyToggle() {
        if (!isEmergency.value) {
          emergencyPlayer.stop();
          "emergencyPlayer: ${warningPlayer.state}".debugPrint();
          return;
        }
        if (emergencyPlayer.state == PlayerState.completed) {
          emergencyPlayer.play(AssetSource(soundEmergency));
          "emergencyPlayer: ${emergencyPlayer.state}".debugPrint();
        }
        emergencyColor.value = (emergencyColor.value == whiteColor) ? yellowColor: whiteColor;
        emergencyTimer = Timer(const Duration(milliseconds: emergencyFlashTime), emergencyToggle);
      }

      if (isEmergency.value) {
        emergencyPlayer.play(AssetSource(soundEmergency));
        emergencyPlayer.setReleaseMode(ReleaseMode.release);
        emergencyPlayer.setVolume(emergencyVolume);
        emergencyToggle();
      } else {
        emergencyPlayer.stop;
        emergencyColor.value = whiteColor;
      }

      return () {
        emergencyTimer?.cancel();
        emergencyPlayer.dispose();
      };
    }, [isEmergency.value]);


    Widget bottomButtons() => Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(bottom: context.buttonSpace()),
      child: (countryNumber.value == 0 || countryNumber.value == 1) ? Row(mainAxisAlignment: MainAxisAlignment.end,
        children: List.generate(8, (i) =>
          (i == 0) ? SizedBox(width: context.sideMargin()):
          (i == 1) ? emergencyOffButton(context, emergencyColor.value, emergencyOff):
          (i == 2) ? const Spacer():
          (i == 3) ? leftButton(context, isLeftOn.value, pushLeftButton):
          (i == 4) ? leftSpeedButton(context, isLeftOn.value, isLeftFast.value, pushLeftSpeedButton):
          (i == 5) ? rightSpeedButton(context, isRightOn.value, isRightFast.value, pushRightSpeedButton):
          (i == 6) ? rightButton(context, isRightOn.value, pushRightButton):
          SizedBox(width: context.buttonSideMargin())
        ),
      ): Row(mainAxisAlignment: MainAxisAlignment.end,
        children: List.generate(7, (i) =>
          (i == 0) ? SizedBox(width: context.sideMargin()):
          (i == 1) ? const Spacer():
          (i == 2) ? leftButton(context, isLeftOn.value, pushLeftButton):
          (i == 3) ? leftSpeedButton(context, isLeftOn.value, isLeftFast.value, pushLeftSpeedButton):
          (i == 4) ? rightSpeedButton(context, isRightOn.value, isRightFast.value, pushRightSpeedButton):
          (i == 5) ? rightButton(context, isRightOn.value, pushRightButton):
          SizedBox(width: context.buttonSideMargin())
        ),
      ),
    );

    Widget selectCountryButton() => Container(
      child: FabCircularMenuPlus(
        key: fabKey,
        alignment: countryNumber.value.floatingActionAlignment(),
        fabSize: context.height() * 0.12,
        ringWidth: context.height() * 0.15,
        ringDiameter: context.height() * 0.8,
        ringColor: transpBlackColor,
        fabCloseColor: transpBlackColor,
        fabOpenColor: transpBlackColor,
        fabMargin: EdgeInsets.symmetric(
          horizontal: context.height() * 0.045,
          vertical: context.height() * 0.09,
        ),
        fabOpenIcon: Icon(Icons.public,
          color: whiteColor,
          size: context.height() * 0.08,
        ),
        fabCloseIcon: Icon(Icons.close,
          color: whiteColor,
          size: context.height() * 0.08,
        ),
        children: flagList.entries.map((entry) => GestureDetector(
          child: SizedBox(
            width: context.height() * 0.15,
            child: Image.asset(entry.value['image'] as String),
          ),
          onTap: () async => changeCountry(entry),
        )).toList()
      )
    );

    // showImagePickerDialog(BuildContext context, int i, bool isLeft) => showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     backgroundColor: transpBlackColor,
    //     title: Text(isLeft ? context.selectLeftTrain(): context.selectRightTrain(),
    //       textAlign: isLeft ? TextAlign.start: TextAlign.end,
    //       style: TextStyle(
    //         color: whiteColor,
    //         fontWeight: FontWeight.bold,
    //         fontFamily: "beon",
    //         fontSize: context.height() * 0.05
    //       ),
    //     ),
    //     content: SizedBox(
    //       width: double.maxFinite,
    //       child: GridView.builder(
    //         shrinkWrap: true,
    //         itemCount: selectTrainList[i].length,
    //         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    //           crossAxisCount: 6,
    //           crossAxisSpacing: context.height() * 0.05,
    //           mainAxisSpacing: context.height() * 0.05,
    //           childAspectRatio: 1,
    //         ),
    //         itemBuilder: (context, index) {
    //           String image = selectTrainList[i][index];
    //           return GestureDetector(
    //             onTap: () {
    //               Navigator.of(context).pop();
    //               if (isLeft) {
    //                 leftTrain.value = List.generate(6, (i) => "${image.replaceAll("f-", "")}_${i + 1}");
    //                 showImagePickerDialog(context, i, false);
    //               } else {
    //                 rightTrain.value = List.generate(6, (i) => "${image.replaceAll("f-", "")}_${i + 1}");
    //               }
    //             },
    //             onTapCancel: () {
    //               Navigator.of(context).pop();
    //             },
    //             child: SizedBox(
    //               width: context.height() * 0.2,
    //               height: context.height() * 0.2,
    //               child: Image.asset(image),
    //             ),
    //           );
    //         },
    //       ),
    //     ),
    //   ),
    // );

    return Scaffold(
      body: Stack(alignment: Alignment.centerLeft,
        children: [
          backGroundImage(context, countryNumber.value),
          backFenceImage(context, countryNumber.value),
          if (countryNumber.value == 0) backEmergencyImage(context, countryNumber.value),
          backGateImage(context, countryNumber.value),
          if (countryNumber.value != 3) backBarImage(context, countryNumber.value, barBackImage.value, barAngle.value, barShift.value, changeTime.value),
          if (countryNumber.value != 0) backGateImage(context, countryNumber.value),
          backPoleImage(context, countryNumber.value),
          if (countryNumber.value == 3) backBarImage(context, countryNumber.value, barBackImage.value, barAngle.value, barShift.value, changeTime.value),
          backDirectionImage(context, countryNumber.value, directionImage.value),
          backWarningImage(context, countryNumber.value, warningBackImage.value),
          if (isRightWait.value) rightTrainImage(context, rightTrain.value, rightAnimation.value),
          if (isLeftWait.value) leftTrainImage(context, leftTrain.value, leftAnimation.value),
          frontPoleImage(context, countryNumber.value),
          if (countryNumber.value == 1) frontGateImage(context, countryNumber.value),
          frontBarImage(context, countryNumber.value, barFrontImage.value, barAngle.value, barShift.value, changeTime.value),
          if (countryNumber.value != 1) frontGateImage(context, countryNumber.value),
          frontEmergencyImage(context, countryNumber.value),
          emergencyButton(context, countryNumber.value, emergencyOn),
          frontDirectionImage(context, countryNumber.value, directionImage.value),
          frontWaringImage(context, countryNumber.value, warningFrontImage.value),
          frontFenceImage(context, countryNumber.value),
          trafficSignImage(context, countryNumber.value),
          sideSpacer(context),
          Container(alignment: countryNumber.value.adAlignment(), child: const AdBannerWidget()),
          bottomButtons(),
        ],
      ),
      floatingActionButton: ((!isYellow.value) && (!isRightWait.value) && (!isLeftWait.value)) ? selectCountryButton(): null,
      floatingActionButtonLocation: countryNumber.value.floatingActionLocation(),
    );
  }
}