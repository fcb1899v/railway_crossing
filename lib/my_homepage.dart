import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:fab_circular_menu_plus/fab_circular_menu_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'common_extension.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'main.dart';
import 'plan_provider.dart';
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
    final warningImage = useState(warningImageJPOff);
    final directionImage = useState(directionImageJPOff);

    //Animation
    final leftController = useAnimationController(duration: const Duration(seconds: 10));
    final rightController = useAnimationController(duration: const Duration(seconds: 10));
    final leftAnimation = useMemoized(() => Tween(begin: 10000.0, end: -10000.0).animate(leftController));
    final rightAnimation = useMemoized(() => Tween(begin: -10000.0, end: 10000.0).animate(rightController));
    final leftTrain = useState(trainList[0]);
    final rightTrain = useState(trainList[0]);
    final barAngle = useState(1.5);
    final barShift = useState(0.0);
    final changeTime = useState(5);
    final emergencyColor = useState(whiteColor);

    //Premium Plan
    final isPremiumProvider = ref.watch(planProvider).isPremium;
    // final plan = ref.read(planProvider.notifier);
    // final isPremium = useState("premium".getSettingsValueBool(false));

    setNormalState() async {
      "setNormal".debugPrint();
      leftTrain.value = trainList[countryNumber.value];
      rightTrain.value = trainList[countryNumber.value];
      isLeftOn.value = false;
      isLeftWait.value = false;
      isRightOn.value = false;
      isRightWait.value = false;
      warningImage.value = countryNumber.value.warningImageOff();
      barFrontImage.value = countryNumber.value.barFrontOff();
      barBackImage.value = countryNumber.value.barBackOff();
      directionImage.value = countryNumber.value.directionImageOff();
      barAngle.value = countryNumber.value.barAngle(false);
      barShift.value = countryNumber.value.barShift(false);
      isPossibleEmergency.value = true;
    }

    initState() async {
      final locale = await Devicelocale.currentLocale ?? "ja-JP";
      final countryCode = locale.substring(3, 5);
      countryNumber.value = countryCode.getDefaultCounter();
      "Locale: $locale, countryNumber: ${countryNumber.value}".debugPrint();
      "width: $width, height: $height".debugPrint();
      setNormalState();
      // countryNumber.value = 2; //for debug
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Platform.isIOS || Platform.isMacOS) initPlugin(context);
        initState();
        initSettings();
      });
      return null;
    }, const []);

    setYellowState() {
      "setYellow".debugPrint();
      isYellow.value = true;
      warningImage.value = countryNumber.value.warningImageYellow();
    }

    setWarningState() {
      "setWarning".debugPrint();
      isYellow.value == false;
      "isYellow: ${isYellow.value}".debugPrint();
      warningImage.value = countryNumber.value.warningImageLeft();
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
      if (!isRightWait.value) setNormalState();
    }

    goLeftTrain() async {
      if (isLeftWait.value && !isEmergency.value) {
        isPossibleEmergency.value;
        "isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
        await leftTrainPlayer.play(AssetSource(soundTrain));
        await leftTrainPlayer.setReleaseMode(ReleaseMode.release);
        await leftTrainPlayer.setVolume(trainVolume);
        "leftTrainPlayer: ${leftTrainPlayer.state}".debugPrint();
        await leftController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () => leftWaitOff());
      }
    }

    leftWaitOn() async {
      if (!isRightWait.value) setWarningState();
      directionImage.value = countryNumber.value.bothOrLeftDirection(isRightWait.value);
      isLeftWait.value = true;
      "isLeftWait: ${isLeftWait.value}".debugPrint();
      Future.delayed(const Duration(seconds: waitTime), () => goLeftTrain());
    }

    pushLeftButton() {
      if (!isLeftOn.value && !isEmergency.value) {
        setYellowState();
        isLeftOn.value = true;
        Future.delayed(const Duration(seconds: yellowTime), () => leftWaitOn());
      }
    }

    rightWaitOff() async {
      await rightTrainPlayer.stop();
      "rightTrainPlayer: ${rightTrainPlayer.state}".debugPrint();
      directionImage.value = countryNumber.value.offOrLeftDirection(isLeftWait.value);
      isRightOn.value = false;
      isRightWait.value = false;
      "isRightWait: ${isRightWait.value}".debugPrint();
      if (!isLeftWait.value) setNormalState();
    }

    goRightTrain() async {
      if (isRightWait.value && !isEmergency.value) {
        isPossibleEmergency.value = false;
        await rightTrainPlayer.play(AssetSource(soundTrain));
        await rightTrainPlayer.setReleaseMode(ReleaseMode.release);
        await rightTrainPlayer.setVolume(trainVolume);
        "rightTrainPlayer: ${rightTrainPlayer.state}".debugPrint();
        await rightController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () => rightWaitOff());
      }
    }

    rightWaitOn() async {
      if (!isLeftWait.value) setWarningState();
      directionImage.value = countryNumber.value.bothOrRightDirection(isLeftWait.value);
      isRightWait.value = true;
      "isRightWait: ${isRightWait.value}".debugPrint();
      Future.delayed(const Duration(seconds: waitTime), () => goRightTrain());
    }

    pushRightButton() {
      if (!isRightWait.value && !isEmergency.value) {
        setYellowState();
        isRightOn.value = true;
        Future.delayed(const Duration(seconds: yellowTime), () => rightWaitOn());
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
      await setNormalState();
      fabKey.currentState?.close();
      Future.delayed(const Duration(seconds: 5), () => changeTime.value = 5);
    }

    /// Left Action
    useEffect(() {

      Timer? leftWarningTimer;
      Timer? leftBarTimer;

      void leftWarningToggle() {
        if (!isLeftWait.value && !isRightWait.value) {
          warningPlayer.stop();
          "leftWarningPlayer: ${warningPlayer.state}".debugPrint();
          return;
        }
        if (warningPlayer.state == PlayerState.completed) {
          warningPlayer.play(AssetSource(countryNumber.value.warningSound()));
          "leftWarningPlayer: ${warningPlayer.state}".debugPrint();
        }
        warningImage.value = countryNumber.value.reverseWarning(warningImage.value);
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
          "leftWarningPlayer: ${warningPlayer.state}".debugPrint();
        }
        leftWarningToggle();
        leftBarToggle();
      }

      return () {
        leftWarningTimer?.cancel();
        leftBarTimer?.cancel();
        leftTrainPlayer.dispose();
      };
    }, [isLeftWait.value]);

    /// Right Action
    useEffect(() {

      Timer? rightWarningTimer;
      Timer? rightBarTimer;

      void rightWarningToggle() {
        if (!isLeftWait.value && !isRightWait.value) {
          warningPlayer.stop();
          "rightWarningPlayer: ${warningPlayer.state}".debugPrint();
          return;
        }
        if (!isLeftWait.value) {
          if (warningPlayer.state == PlayerState.completed) {
            warningPlayer.play(AssetSource(countryNumber.value.warningSound()));
            "rightWarningPlayer: ${warningPlayer.state}".debugPrint();
          }
          warningImage.value = countryNumber.value.reverseWarning(warningImage.value);
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
          "rightWarningPlayer: ${warningPlayer.state}".debugPrint();
        }
        rightWarningToggle();
        rightBarToggle();
      }

      return () {
        rightWarningTimer?.cancel();
        rightBarTimer?.cancel();
        rightTrainPlayer.dispose();
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
          if (countryNumber.value == 0) backBoardImage(context, countryNumber.value),
          if (countryNumber.value == 0) backGateImage(context, countryNumber.value),
          backBarImage(context, countryNumber.value, barBackImage.value, barAngle.value, barShift.value, changeTime.value),
          if (countryNumber.value != 0) backGateImage(context, countryNumber.value),
          backPoleImage(context, countryNumber.value),
          if (countryNumber.value == 0) backDirectionImage(context, countryNumber.value, directionImage.value),
          if (countryNumber.value == 0) backWarningImage(context, warningImage.value),
          if (isRightWait.value) rightTrainImage(context, rightTrain.value, rightAnimation),
          if (isLeftWait.value) leftTrainImage(context, leftTrain.value, leftAnimation),
          frontPoleImage(context, countryNumber.value),
          frontWaringImage(context, countryNumber.value, warningImage.value),
          if (countryNumber.value == 0) frontDirectionImage(context, directionImage.value),
          if (countryNumber.value == 1) frontGateImage(context, countryNumber.value),
          frontBarImage(context, countryNumber.value, barFrontImage.value, barAngle.value, barShift.value, changeTime.value),
          if (countryNumber.value != 1) frontGateImage(context, countryNumber.value),
          if (countryNumber.value == 0) frontBoardImage(context, countryNumber.value),
          if (countryNumber.value != 2) emergencyButton(context, countryNumber.value, emergencyOn),
          frontFenceImage(context, countryNumber.value),
          sideSpacer(context),
          if (!isPremiumProvider) const AdBannerWidget(),
          bottomButtons(context, isLeftOn.value, isRightOn.value, emergencyColor.value, emergencyOff, pushLeftButton, pushRightButton),
        ],
      ),
      floatingActionButton: ((!isRightWait.value) && (!isLeftWait.value)) ? FabCircularMenuPlus(
        key: fabKey,
        alignment: Alignment.topLeft,
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
      ): null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
    );
  }
}