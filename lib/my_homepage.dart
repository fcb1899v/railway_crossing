import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:fab_circular_menu_plus/fab_circular_menu_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:railroad_crossing/main.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'common_extension.dart';
import 'common_function.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'admob_banner.dart';

class MyHomePage extends HookConsumerWidget {

  final GlobalKey<FabCircularMenuPlusState> fabKey = GlobalKey();
  MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

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
    final isMenuOpen = useState(false);
    final isMyPurchase = useState(false);
    final isPurchasing = useState(false);
    final isShowAd = useState(true);
    final counter = useState(0);

    //Purchase
    final currentPlan = useState(freeID);
    final activePlan = useState([]);
    final tickets = useState(0);
    final expirationDate = useState(defaultIntDateTime);
    final lastClaimedDate = useState(defaultIntDate);
    final currentDate = useState(defaultDateTime);
    final priceList = useState(defaultPriceList);
    final isLoadedSubscriptionInfo = useState(false);
    // final isMainLandChina = useState(false);

    //Photo
    final vertexAIToken = useState("");
    final photoIndex = useState(0);
    final photoPermission = useState(PermissionStatus.denied);
    final photoImage = useState<List<Uint8List>?>(null);
    final isShowPhoto = useState(false);
    final isSavePhoto = useState(false);
    final isPossiblePhoto = useState(false);
    final isLoadingPhoto = useState(false);

    //Audio
    final audioPlayers = AudioPlayerManager();
    final effectPlayer = AudioPlayer();
    final lifecycle = useAppLifecycleState();

    //Image
    final countryCode = useState("OTH");
    final countryNumber = useState(3);
    final barFrontImage = useState("");
    final barBackImage = useState("");
    final warningFrontImage = useState("");
    final warningBackImage = useState("");
    final directionImage = useState("");

    //Animation
    final leftController = useAnimationController(duration: const Duration(seconds: trainTime));
    final rightController = useAnimationController(duration: const Duration(seconds: trainTime));
    final leftAnimation = useState(Tween(
      begin: context.trainBeginPosition(isLeftFast.value),
      end: context.trainEndPosition(isLeftFast.value),
    ).animate(leftController));
    final rightAnimation = useState(Tween(
      begin: context.trainEndPosition(isRightFast.value),
      end: context.trainBeginPosition(isRightFast.value),
    ).animate(rightController));
    final leftTrain = useState(0.trainImage());
    final rightTrain = useState(0.trainImage());
    final barAngle = useState(0.0);
    final barShift = useState(0.0);
    final changeTime = useState(0);
    final emergencyColor = useState(whiteColor);

    initState() async {
      "initState".debugPrint();
      "width: ${context.mediaWidth()}, height: ${context.mediaHeight()}".debugPrint();
      "sideMargin: ${context.sideMargin()}, upDownMargin: ${context.upDownMargin()}".debugPrint();
      final prefs = await SharedPreferences.getInstance();
      priceList.value = await loadPriceList(prefs);
      countryCode.value = await getCountryCode(prefs);
      countryNumber.value = countryCode.value.getCountryNumber();
      // isMainLandChina.value = countryCode.value.getIsMainLandChina();
      final androidSDK = await getAndroidSDK();
      photoPermission.value = await (androidSDK < 33 ? Permission.storage.status: Permission.photos.status);
    }

    showDebugPrints() {
      "currentPlan: ${currentPlan.value}, activePlan: ${activePlan.value}".debugPrint();
      "tickets: ${tickets.value}, isShowAd: ${isShowAd.value}".debugPrint();
      "expirationDate: ${expirationDate.value}, lastClaimDate: ${lastClaimedDate.value}".debugPrint();
    }

    getCurrentPlan() async {
      "getCurrentPlan".debugPrint();
      final prefs = await SharedPreferences.getInstance();
      currentDate.value = await getServerDateTime();
      currentPlan.value = prefs.getString("plan") ?? freeID;
      activePlan.value = prefs.getStringList("activePlan") ?? [];
      tickets.value = prefs.getInt("tickets") ?? 0;
      expirationDate.value = prefs.getInt('expiration') ?? defaultIntDateTime;
      lastClaimedDate.value = prefs.getInt('lastClaim') ?? defaultIntDate;
      isShowAd.value = (currentPlan.value != premiumID && defaultIsShowAd);
      showDebugPrints();
    }

    setPlan({required String planString, required List<String> activePlanListString, required int ticketsInt, required int expirationInt}) async {
      "setPlan: $planString".debugPrint();
      currentPlan.value = planString;
      activePlan.value = activePlanListString;
      tickets.value = ticketsInt;
      expirationDate.value = expirationInt;
      isShowAd.value = (currentPlan.value != premiumID);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("plan", planString);
      await prefs.setStringList("activePlan", activePlanListString);
      await prefs.setInt("tickets", ticketsInt);
      await prefs.setInt('expiration', expirationInt);
      showDebugPrints();
    }

    loadSubscriptionInfo() async {
      if (currentPlan.value != freeID && activePlan.value.isNotEmpty && currentDate.value.intDateTime() > expirationDate.value) {
        try {
          "loadSubscriptionInfo: Update".debugPrint();
          final customerInfo = await Purchases.getCustomerInfo();
          await setPlan(
            planString: customerInfo.updatedPlan(),
            activePlanListString: customerInfo.activeSubscriptions,
            ticketsInt: (expirationDate.value == defaultDateTime.intDateTime()) ? tickets.value: customerInfo.addTicket(),
            expirationInt: customerInfo.subscriptionExpirationDate(),
          );
          "Grant tickets: ${customerInfo.planID()}".debugPrint();
          isLoadedSubscriptionInfo.value = true;
          "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
        } on PlatformException catch (e) {
          "Failed to load subscription information: $e".debugPrint();
          isLoadedSubscriptionInfo.value = false;
          "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
          counter.value += 1;
          if (!isLoadedSubscriptionInfo.value && counter.value < 10) {
            Future.delayed(const Duration(seconds: 10), () {
              loadSubscriptionInfo();
              if (context.mounted && counter.value == 9) showSnackBar(context, context.checkNetwork(), true);
            });
          }
        }
      } else if (currentPlan.value != freeID && activePlan.value.isEmpty && currentDate.value.intDateTime() > expirationDate.value) {
        "loadSubscriptionInfo: Cancel".debugPrint();
        await setPlan(
          planString: freeID,
          activePlanListString: [],
          ticketsInt: 0,
          expirationInt: defaultIntDateTime,
        );
        isLoadedSubscriptionInfo.value = true;
        "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
      } else {
        isLoadedSubscriptionInfo.value = true;
        "isLoadedSubscriptionInfo: ${isLoadedSubscriptionInfo.value}".debugPrint();
      }
    }

    setNormalState() async {
      "setNormal".debugPrint();
      leftTrain.value = countryNumber.value.trainImage();
      rightTrain.value = countryNumber.value.trainImage();
      isLeftOn.value = false;
      isLeftWait.value = false;
      isRightOn.value = false;
      isRightWait.value = false;
      isYellow.value = false;
      emergencyColor.value = whiteColor;
      warningFrontImage.value = countryNumber.value.warningFrontImageOff();
      warningBackImage.value = countryNumber.value.warningBackImageOff();
      barFrontImage.value = countryNumber.value.barFrontOff();
      barBackImage.value = countryNumber.value.barBackOff();
      directionImage.value = countryNumber.value.directionImageOff();
      barAngle.value = countryNumber.value.barAngle(false);
      barShift.value = countryNumber.value.barShift(false);
      isPossibleEmergency.value = true;
      isPossiblePhoto.value = false;
      isLoadingPhoto.value = false;
      await audioPlayers.audioPlayers[0].stop();
    }

    useEffect(() {
      Future<void> handleLifecycleChange() async {
        // ウィジェットが破棄されていたら何もしない
        if (!context.mounted) return;
        // アプリがバックグラウンドに移行する直前
        if (lifecycle == AppLifecycleState.paused) {
          for (int i = 0; i < audioPlayers.audioPlayers.length; i++) {
            final player = audioPlayers.audioPlayers[i];
            try {
              if (player.state == PlayerState.playing) await player.stop();
              setNormalState();
            } catch (e) {
              'Error handling stop for player $i: $e'.debugPrint();
            }
          }
        }
      }
      handleLifecycleChange();
      return null;
    }, [lifecycle, context.mounted, audioPlayers.audioPlayers.length]);

    // Initialize app
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
        await getCurrentPlan();
        await loadSubscriptionInfo();
        await setNormalState();
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
      await audioPlayers.audioPlayers[1].stop();
      "leftTrainPlayer: ${audioPlayers.audioPlayers[1].state}".debugPrint();
      directionImage.value = countryNumber.value.offOrRightDirection(isRightWait.value);
      isLeftOn.value = false;
      isLeftWait.value = false;
      "isLeftOn: ${isLeftOn.value}, isRightOn: ${isRightOn.value}".debugPrint();
      "isLeftWait: ${isLeftWait.value}, isRightWait: ${isRightWait.value}".debugPrint();
      if (!isRightWait.value) await setNormalState();
    }

    goLeftTrain() async {
      if (isLeftWait.value && !isEmergency.value) {
        isPossibleEmergency.value = false;
        isPossiblePhoto.value = true;
        "isPossiblePhoto: ${isPossiblePhoto.value}, isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
        await audioPlayers.audioPlayers[1].play(AssetSource(soundTrain));
        await audioPlayers.audioPlayers[1].setReleaseMode(ReleaseMode.release);
        await audioPlayers.audioPlayers[1].setVolume(trainVolume);
        "leftTrainPlayer: ${audioPlayers.audioPlayers[1].state}".debugPrint();
        if (context.mounted) leftAnimation.value = context.leftAnimation(leftController, isLeftFast.value);
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
      isMenuOpen.value = false;
      if (!isLeftOn.value && !isEmergency.value && !isLoadingPhoto.value) {
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
      await audioPlayers.audioPlayers[2].stop();
      "rightTrainPlayer: ${audioPlayers.audioPlayers[2].state}".debugPrint();
      directionImage.value = countryNumber.value.offOrLeftDirection(isLeftWait.value);
      isRightOn.value = false;
      isRightWait.value = false;
      "isLeftOn: ${isLeftOn.value}, isRightOn: ${isRightOn.value}".debugPrint();
      "isLeftWait: ${isLeftWait.value}, isRightWait: ${isRightWait.value}".debugPrint();
      if (!isLeftWait.value) await setNormalState();
    }

    goRightTrain() async {
      if (isRightWait.value && !isEmergency.value) {
        isPossibleEmergency.value = false;
        isPossiblePhoto.value = true;
        "isPossiblePhoto: ${isPossiblePhoto.value}, isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
        await audioPlayers.audioPlayers[2].play(AssetSource(soundTrain));
        await audioPlayers.audioPlayers[2].setReleaseMode(ReleaseMode.release);
        await audioPlayers.audioPlayers[2].setVolume(trainVolume);
        "rightTrainPlayer: ${audioPlayers.audioPlayers[2].state}".debugPrint();
        if (context.mounted) rightAnimation.value = context.rightAnimation(rightController, isRightFast.value);
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
      isMenuOpen.value = false;
      if (!isRightWait.value && !isEmergency.value && !isLoadingPhoto.value) {
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
      isMenuOpen.value = false;
      if (!isLeftOn.value) {
        isLeftFast.value = !isLeftFast.value;
        "isLeftFast: ${isLeftFast.value}".debugPrint();
      }
    }

    pushRightSpeedButton() {
      isMenuOpen.value = false;
      if (!isRightOn.value) {
        isRightFast.value = !isRightFast.value;
        "isRightFast: ${isRightFast.value}".debugPrint();
      }
    }

    emergencyOn() async {
      isMenuOpen.value = false;
      if (!isEmergency.value && isPossibleEmergency.value && countryNumber.value < 2) {
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
      if (!isLoadingPhoto.value) {
        changeTime.value = 0;
        final newCountryNumber = entry.value['countryNumber'] as int;
        if (countryNumber.value != newCountryNumber) {
          await effectPlayer.setVolume(decideVolume);
          await effectPlayer.play(AssetSource(decideSound));
          "play: $decideSound".debugPrint();
          countryNumber.value = newCountryNumber;
          'select_${entry.key}: ${countryNumber.value}'.debugPrint();
          await setNormalState();
        } else {
          await effectPlayer.setVolume(openVolume);
          await effectPlayer.play(AssetSource(openSound));
        }
        fabKey.currentState?.close();
      }
    }

    /// Left Action
    useEffect(() {

      Timer? leftWarningTimer;
      Timer? leftBarTimer;

      leftWarningToggle() {
        if (!isLeftWait.value && !isRightWait.value) {
          audioPlayers.audioPlayers[0].stop();
          "warningPlayer: ${audioPlayers.audioPlayers[0].state}".debugPrint();
          return;
        }
        if (audioPlayers.audioPlayers[0].state == PlayerState.completed) {
          audioPlayers.audioPlayers[0].play(AssetSource(countryNumber.value.warningSound()));
          "warningPlayer: ${audioPlayers.audioPlayers[0].state}".debugPrint();
        }
        warningFrontImage.value = countryNumber.value.reverseWarningFront(warningFrontImage.value);
        warningBackImage.value = countryNumber.value.reverseWarningBack(warningBackImage.value);
        leftWarningTimer = Timer(Duration(milliseconds: countryNumber.value.flashTime()), leftWarningToggle);
      }

      leftBarToggle() {
        if (!isLeftWait.value) return;
        barFrontImage.value = countryNumber.value.reverseBarFront(barFrontImage.value);
        barBackImage.value = countryNumber.value.reverseBarBack(barBackImage.value);
        leftBarTimer = Timer(const Duration(milliseconds: ledDurationTime), leftBarToggle);
      }

      if (isLeftWait.value) {
        if (audioPlayers.audioPlayers[0].state != PlayerState.playing) {
          audioPlayers.audioPlayers[0].play(AssetSource(countryNumber.value.warningSound()));
          audioPlayers.audioPlayers[0].setReleaseMode(ReleaseMode.release);
          audioPlayers.audioPlayers[0].setVolume(warningVolume);
          "warningPlayer: ${audioPlayers.audioPlayers[0].state}".debugPrint();
        }
        leftWarningToggle();
        leftBarToggle();
      }

      return () {
        leftWarningTimer?.cancel();
        leftBarTimer?.cancel();
        audioPlayers.audioPlayers[1].stop();
      };
    }, [isLeftWait.value]);

    /// Right Action
    useEffect(() {

      Timer? rightWarningTimer;
      Timer? rightBarTimer;

      rightWarningToggle() {
        if (!isLeftWait.value && !isRightWait.value) {
          audioPlayers.audioPlayers[0].stop();
          "warningPlayer: ${audioPlayers.audioPlayers[0].state}".debugPrint();
          return;
        }
        if (!isLeftWait.value) {
          if (audioPlayers.audioPlayers[0].state == PlayerState.completed) {
            audioPlayers.audioPlayers[0].play(AssetSource(countryNumber.value.warningSound()));
            "warningPlayer: ${audioPlayers.audioPlayers[0].state}".debugPrint();
          }
          warningFrontImage.value = countryNumber.value.reverseWarningFront(warningFrontImage.value);
          warningBackImage.value = countryNumber.value.reverseWarningBack(warningBackImage.value);
        }
        rightWarningTimer = Timer(Duration(milliseconds: countryNumber.value.flashTime()), rightWarningToggle);
      }

      rightBarToggle() {
        if (!isRightWait.value) return;
        if (!isLeftWait.value) {
          barFrontImage.value = countryNumber.value.reverseBarFront(barFrontImage.value);
          barBackImage.value = countryNumber.value.reverseBarBack(barBackImage.value);
        }
        rightBarTimer = Timer(const Duration(milliseconds: ledDurationTime), rightBarToggle);
      }

      if (isRightWait.value) {
        if (!isLeftWait.value && (audioPlayers.audioPlayers[0].state != PlayerState.playing)) {
          audioPlayers.audioPlayers[0].play(AssetSource(countryNumber.value.warningSound()));
          audioPlayers.audioPlayers[0].setReleaseMode(ReleaseMode.release);
          audioPlayers.audioPlayers[0].setVolume(warningVolume);
          "warningPlayer: ${audioPlayers.audioPlayers[0].state}".debugPrint();
        }
        rightWarningToggle();
        rightBarToggle();
      }

      return () {
        rightWarningTimer?.cancel();
        rightBarTimer?.cancel();
        audioPlayers.audioPlayers[2].stop();
      };
    }, [isRightWait.value]);

    /// Emergency Action
    useEffect(() {

      Timer? emergencyTimer;

      emergencyToggle() {
        if (!isEmergency.value) {
          audioPlayers.audioPlayers[3].stop();
          "Stop emergencyPlayer: ${audioPlayers.audioPlayers[3].state}".debugPrint();
          return;
        } else if (audioPlayers.audioPlayers[3].state == PlayerState.stopped) {
          audioPlayers.audioPlayers[3].play(AssetSource(soundEmergency));
          audioPlayers.audioPlayers[3].setVolume(emergencyVolume);
          "Play emergencyPlayer: ${audioPlayers.audioPlayers[3].state}".debugPrint();
        } else if (audioPlayers.audioPlayers[3].state == PlayerState.completed) {
          "Continue emergencyPlayer: ${audioPlayers.audioPlayers[3].state}".debugPrint();
          audioPlayers.audioPlayers[3].play(AssetSource(soundEmergency));
        }
        emergencyColor.value = (emergencyColor.value == whiteColor) ? yellowColor: whiteColor;
        emergencyTimer = Timer(const Duration(milliseconds: emergencyFlashTime), emergencyToggle);
      }

      if (isEmergency.value) emergencyToggle();

      return () {
        emergencyTimer?.cancel();
        audioPlayers.audioPlayers[3].stop();
      };
    }, [isEmergency.value]);

    Widget bottomButtons() => Container(
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.only(
        left: context.buttonSideMargin(),
        right: context.buttonSideMargin() + context.buttonSpace(),
        bottom: context.buttonUpDownMargin()
      ),
      child: Row(children: List.generate(6, (i) =>
        (i == 1) ? const Spacer():
        (i == 2) ? leftButton(context, isLeftOn.value, pushLeftButton):
        (i == 3) ? leftSpeedButton(context, isLeftOn.value, isLeftFast.value, pushLeftSpeedButton):
        (i == 4) ? rightSpeedButton(context, isRightOn.value, isRightFast.value, pushRightSpeedButton):
        (i == 5) ? rightButton(context, isRightOn.value, pushRightButton):
        (countryNumber.value == 0 || countryNumber.value == 1) ? emergencyOffButton(context, emergencyColor.value, emergencyOff):
        SizedBox(width: context.buttonSpace())
      ))
    );

    FabCircularMenuPlus selectCountryButton() => FabCircularMenuPlus(
      key: fabKey,
      alignment: Alignment.topRight,
      fabSize: context.fabSize(),
      ringWidth: context.ringWidth(),
      ringDiameter: context.ringDiameter(),
      ringColor: transpBlackColor,
      fabCloseColor: transpBlackColor,
      fabOpenColor: transpBlackColor,
      fabMargin: EdgeInsets.symmetric(
        horizontal: context.fabSideMargin(),
        vertical: context.fabTopMargin(),
      ),
      fabOpenIcon: Icon(Icons.public,
        color: whiteColor,
        size: context.fabIconSize(),
      ),
      fabCloseIcon: Icon(Icons.close,
        color: whiteColor,
        size: context.fabIconSize(),
      ),
      onDisplayChange: (isOpen) async {
        if (isOpen){
          isMenuOpen.value = false;
          await effectPlayer.setVolume(openVolume);
          await effectPlayer.play(AssetSource(openSound));
          "play: $openSound".debugPrint();
        }
      },
      children: flagList.entries.map((entry) => GestureDetector(
        child: SizedBox(
          width: context.fabChildIconSize(),
          child: Image.asset(entry.value['image'] as String),
        ),
        onTap: () async {
          await changeCountry(entry);
        },
      )).toList(),
    );

    openMenu() async {
      if (isLoadedSubscriptionInfo.value) {
        effectPlayer.play(AssetSource(openSound));
        fabKey.currentState?.close();
        isMenuOpen.value = !isMenuOpen.value;
      }
    }

    sharePhoto() async {
      try {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/shared_image.png';
        final file = File(filePath);
        await file.writeAsBytes(photoImage.value![photoIndex.value]);
        await Share.shareXFiles([XFile(filePath)], text: '');
        isSavePhoto.value = false;
      } catch (e) {
        'Error sharing image: $e'.debugPrint();
      }
    }

    savePhoto() async {
      try {
        final result = await ImageGallerySaver.saveImage(photoImage.value![photoIndex.value]);
        "result: $result".debugPrint();
        if (context.mounted) {
          (result['isSuccess'] ? context.photoSaved(): context.photoSavingFailed()).debugPrint();
          showSnackBar(context, result['isSuccess'] ? context.photoSaved(): context.photoSavingFailed(), !result['isSuccess']);
        }
        if (!result['isSuccess']) throw Exception('Fail to save image');
        isSavePhoto.value = true;
      } catch (e) {
        if (context.mounted) '${context.photoCaptureFailed()}: $e'.debugPrint();
        if (context.mounted) showSnackBar(context, context.photoCaptureFailed(), true);
        isLoadingPhoto.value = false;
      }
    }

    showPhotoImage() =>
      Container(
        width: context.width(),
        height: context.height(),
        margin: EdgeInsets.symmetric(horizontal: context.sideMargin()),
        color: transpBlackColor,
        child: Stack(alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    isShowPhoto.value = false;
                    isSavePhoto.value = false;
                  },
                  child: circleIconImage(context, Icons.arrow_back_rounded)
                ),
                Image.memory(photoImage.value![photoIndex.value], fit: BoxFit.cover),
                GestureDetector(
                  onTap: () => isSavePhoto.value ? sharePhoto(): savePhoto(),
                  child: circleIconImage(context, isSavePhoto.value ? Icons.share: Icons.save_alt_rounded)
                ),
              ]
            ),
            Row(children: [
              if (!isSavePhoto.value && photoImage.value!.length > 1) GestureDetector(
                onTap: () {
                  photoIndex.value = (photoIndex.value - 1) % generatePhotoNumber;
                  "${photoIndex.value}".debugPrint();
                },
                child: circleIconImage(context, Icons.arrow_back_ios_rounded)
              ),
              Spacer(),
              if (!isSavePhoto.value && photoImage.value!.length > 1) GestureDetector(
                onTap: () {
                  photoIndex.value = (photoIndex.value + 1) % generatePhotoNumber;
                  "${photoIndex.value}".debugPrint();
                },
                child: circleIconImage(context, Icons.arrow_forward_ios_rounded)
              ),
            ]),
          ]
        )
      );

    getFreePhoto() async {
      "getFreePhoto".debugPrint();
      final byteData = await rootBundle.load(countryNumber.value.countryFreePhoto(currentDate.value.intDateTime()));
      photoImage.value = [byteData.buffer.asUint8List()];
      final prefs = await SharedPreferences.getInstance();
      lastClaimedDate.value = currentDate.value.toLocal().intDate();
      prefs.setInt('lastClaim', lastClaimedDate.value);
      "lastClaimedDate: ${lastClaimedDate.value}".debugPrint();
      isLoadingPhoto.value = false;
      isShowPhoto.value = true;
    }

    ///Generate Dall-E-3 photo
    getGenerateDallEPhoto() async {
      try {
        final prompt = countryNumber.value.dallEPrompt();
        "prompt: $prompt".debugPrint();
        final response = await prompt.dallEResponse();
        "responseStatusCode: ${response.statusCode}".debugPrint();
        if (response.statusCode == 200) {
          final responseJsonData = jsonDecode(utf8.decode(response.bodyBytes).toString());
          final responseImageList = List.generate(responseJsonData['data'].length, (i) async {
            final url = await http.get(Uri.parse(responseJsonData['data'][i]['url']));
            return url.bodyBytes;
          });
          photoImage.value = await Future.wait(responseImageList);
          tickets.value -= 1;
          final prefs = await SharedPreferences.getInstance();
          prefs.setInt('tickets', tickets.value);
          "tickets: $tickets".debugPrint();
          isLoadingPhoto.value = false;
          isShowPhoto.value = true;
        } else {
          final errorResponse = jsonDecode(response.body);
          'code: ${errorResponse['error']['code']}'.debugPrint();
          'message: ${errorResponse['error']['message']}'.debugPrint();
          throw Exception('StatusCode is not 200.');
        }
      } catch (e) {
        if (context.mounted) context.photoCaptureFailed().debugPrint();
        if (context.mounted) showSnackBar(context, context.photoCaptureFailed(), true);
        'Failed to generate Dall-E 3 image: $e'.debugPrint();
        isLoadingPhoto.value = false;
      }
    }

    ///Generate Dall-E-3 photo
    getGenerateVertexAIPhoto() async {
      "getGenerateVertexAIPhoto".debugPrint();
      try {
        vertexAIToken.value = await loadVertexAIToken(context);
        final prompt = countryNumber.value.vertexAIPrompt();
        "prompt: $prompt".debugPrint();
        final response = await prompt.vertexAIResponse(vertexAIToken.value);
        "responseStatusCode: ${response.statusCode}".debugPrint();
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          photoImage.value = List.generate(jsonResponse["predictions"].length, (i) =>
            base64Decode(jsonResponse["predictions"][i]["bytesBase64Encoded"])
          );
          tickets.value -= 1;
          final prefs = await SharedPreferences.getInstance();
          prefs.setInt('tickets', tickets.value);
          "tickets: ${tickets.value}".debugPrint();
          isLoadingPhoto.value = false;
          "isLoadingPhoto: ${isLoadingPhoto.value}".debugPrint();
          isShowPhoto.value = true;
          "isShowPhoto: ${isShowPhoto.value}".debugPrint();
        } else {
          final errorResponse = jsonDecode(response.body);
          'code: ${errorResponse['error']['code']}'.debugPrint();
          'message: ${errorResponse['error']['message']}'.debugPrint();
          throw Exception('StatusCode is not 200.');
        }
      } catch (e) {
        if (context.mounted) context.photoCaptureFailed().debugPrint();
        'Failed to generate Vertex AI image: $e'.debugPrint();
        "getGenerateDallEPhoto".debugPrint();
        getGenerateDallEPhoto();
      }
    }

    cameraAction() async {
      isMenuOpen.value = false;
      "isMenuOpen: ${isMenuOpen.value}".debugPrint();
      "photoPermission: ${photoPermission.value}".debugPrint();
      if (photoPermission.value != PermissionStatus.granted) {
        await permitPhotoAccess();
        if (photoPermission.value != PermissionStatus.granted) {
          if (context.mounted) showSnackBar(context, context.photoAccessPermission(), true);
          Future.delayed(const Duration(seconds: 3), () async => await openAppSettings());
        }
      } else {
        if (tickets.value > 0 || !lastClaimedDate.value.isToday(currentDate.value.intDateTime())) {
          await effectPlayer.setVolume(cameraVolume);
          await effectPlayer.play(AssetSource(cameraSound));
          isLoadingPhoto.value = true;
          "isLoadingPhoto: ${isLoadingPhoto.value}".debugPrint();
          if (!lastClaimedDate.value.isToday(currentDate.value.intDateTime())) {
            await getFreePhoto();
          } else if (tickets.value > 0) {
            await getGenerateVertexAIPhoto();
          }
        }
      }
    }

    ///Revenue cat Subscription
    //Buy subscription plan
    buySubscriptionPlan(String planID) async {
      if (!isPurchasing.value) {
        isPurchasing.value = true;
        "isPurchasing: ${isPurchasing.value}".debugPrint();
        if (currentPlan.value != planID && tickets.value <= premiumTicketNumber) {
          try {
            "Buy: $planID: ${activePlan.value.contains(planID)}".debugPrint();
            if (!activePlan.value.contains(planID)) {
              final offerings = await Purchases.getOfferings();
              final offering = offerings.getOffering(planID.offeringID());
              final purchaseResult = await Purchases.purchasePackage(offering!.monthly!);
              currentDate.value = await getServerDateTime();
              if (purchaseResult.isSubscriptionActive(planID)) {
                if (Platform.isIOS || Platform.isMacOS) {
                  final originalPurchaseDate = DateTime.parse(purchaseResult.originalPurchaseDate!);
                  "originalPurchaseDate: $originalPurchaseDate".debugPrint();
                  await setPlan(
                    planString: planID,
                    activePlanListString: purchaseResult.activeSubscriptions,
                    ticketsInt: tickets.value + planID.appleUpdatedTickets(currentDate.value, originalPurchaseDate),
                    expirationInt: purchaseResult.subscriptionExpirationDate()
                  );
                } else {
                  await setPlan(
                    planString: planID,
                    activePlanListString: purchaseResult.activeSubscriptions,
                    ticketsInt: tickets.value + planID.updatedTickets(currentDate.value),
                    expirationInt: purchaseResult.subscriptionExpirationDate()
                  );
                }
                if (context.mounted) context.pushHomePage();
              } else {
                if (context.mounted) await purchaseErrorDialog(context, isRestore: false, isCancel: false);
              }
            } else{
              if (context.mounted) await purchaseFinishedDialog(context, isRestore: false, isCancel: false);
            }
          } on PlatformException catch (e) {
            if (context.mounted) await purchaseExceptionDialog(context, e, isRestore: false, isCancel: false);
          }
        } else {
          if (context.mounted) context.pushHomePage();
          await showSnackBar(context, context.useTickets(premiumTicketNumber), true);
        }
      }
    }

    upgradePlan() async {
      if (context.mounted) context.popPage();
      if (!isPurchasing.value) {
        isPurchasing.value = true;
        "isPurchasing: ${isPurchasing.value}".debugPrint();
        if (currentPlan.value != premiumID && tickets.value <= premiumTicketNumber) {
          try {
            "Upgrade: $premiumID: ${activePlan.value.contains(premiumID)}".debugPrint();
            if (!activePlan.value.contains(premiumID)) {
              final offerings = await Purchases.getOfferings();
              final offering = offerings.getOffering(premiumID.offeringID());
              final purchaseResult = await Purchases.purchasePackage(
                offering!.monthly!,
                googleProductChangeInfo: GoogleProductChangeInfo(standardID)
              );
              "activePlan: ${purchaseResult.activeSubscriptions}".debugPrint();
              if (purchaseResult.isSubscriptionActive(premiumID)) {
                await setPlan(
                  planString: premiumID,
                  activePlanListString: purchaseResult.activeSubscriptions,
                  ticketsInt: tickets.value + premiumTicketNumber,
                  expirationInt: purchaseResult.subscriptionExpirationDate()
                );
                if (context.mounted) context.pushHomePage();
              } else {
                if (context.mounted) await purchaseErrorDialog(context, isRestore: false, isCancel: false);
              }
            } else{
              if (context.mounted) await purchaseFinishedDialog(context, isRestore: false, isCancel: false);
            }
          } on PlatformException catch (e) {
            if (context.mounted) await purchaseExceptionDialog(context, e, isRestore: false, isCancel: false);
          }
        } else {
          if (context.mounted) context.pushHomePage();
          await showSnackBar(context, context.useTickets(premiumTicketNumber), true);
        }
      }
    }

    //Buy onetime passes
    buyOnetime() async {
      if (context.mounted) context.popPage();
      if (!isPurchasing.value) {
        isPurchasing.value = true;
        "isPurchasing: ${isPurchasing.value}".debugPrint();
        if (tickets.value <= 1) {
          try {
            "buyOnetime".debugPrint();
            final offerings = await Purchases.getOfferings();
            final offering = offerings.getOffering(addPassesOffering);
            final purchaseResult = await Purchases.purchasePackage(offering!.lifetime!);
            "${purchaseResult.allPurchasedProductIdentifiers}".debugPrint();
            if (purchaseResult.allPurchasedProductIdentifiers.isNotEmpty) {
              await setPlan(
                planString: currentPlan.value,
                activePlanListString: [premiumID],
                ticketsInt: addOnTicketNumber,
                expirationInt: expirationDate.value
              );
              if (context.mounted) context.pushHomePage();
            } else {
              if (context.mounted) await purchaseErrorDialog(context, isRestore: false, isCancel: false);
            }
          } on PlatformException catch (e) {
            if (context.mounted) await purchaseExceptionDialog(context, e, isRestore: false, isCancel: false);
          }
        } else {
          if (context.mounted) context.pushHomePage();
          await showSnackBar(context, context.useTickets(1), true);
        }
      }
    }

    //Buy trial passes
    buyTrial() async {
      if (!isPurchasing.value) {
        isPurchasing.value = true;
        "isPurchasing: ${isPurchasing.value}".debugPrint();
        if (tickets.value <= 1) {
          try {
            "buyOnetime".debugPrint();
            final offerings = await Purchases.getOfferings();
            final offering = offerings.getOffering(defaultOffering);
            final purchaseResult = await Purchases.purchasePackage(offering!.lifetime!);
            "${purchaseResult.allPurchasedProductIdentifiers}".debugPrint();
            if (purchaseResult.allPurchasedProductIdentifiers.isNotEmpty) {
              await setPlan(
                planString: currentPlan.value,
                activePlanListString: [],
                ticketsInt: trialTicketNumber,
                expirationInt: expirationDate.value
              );
              if (context.mounted) context.pushHomePage();
            } else {
              if (context.mounted) await purchaseErrorDialog(context, isRestore: false, isCancel: false);
            }
          } on PlatformException catch (e) {
            if (context.mounted) await purchaseExceptionDialog(context, e, isRestore: false, isCancel: false);
          }
        } else {
          if (context.mounted) context.pushHomePage();
          await showSnackBar(context, context.useTickets(1), true);
        }
      }
    }

    //Cancellation page for subscription
    cancelPlan() async {
      if (!isPurchasing.value) {
        isPurchasing.value = true;
        "isPurchasing: ${isPurchasing.value}".debugPrint();
        "activePlan: ${activePlan.value}".debugPrint();
        if (activePlan.value.isNotEmpty) {
          try {
            final canLaunch = await canLaunchUrl(subscriptionUri);
            "canLaunchUrl: $canLaunch".debugPrint();
            if (context.mounted) context.pushHomePage();
            await launchUrl(subscriptionUri, mode: LaunchMode.externalApplication);
          } on PlatformException catch (e) {
            if (context.mounted) await purchaseExceptionDialog(context, e, isRestore: false, isCancel: true);
          }
        } else {
          if (context.mounted) await purchaseFinishedDialog(context, isRestore: false, isCancel: true);
        }
      }
    }

    Future<void> buyPremium() async {
      await buySubscriptionPlan(premiumID);
    }

    Future<void> buyStandard() async {
      await buySubscriptionPlan(standardID);
    }

    //Buy subscription
    toPurchase() async {
      isMenuOpen.value = false;
      "isMenuOpen: ${isMenuOpen.value}".debugPrint();
      isMyPurchase.value = true;
    }

    //Cancel Subscription,
    toCancel() {
      isMenuOpen.value = false;
      "isMenuOpen: ${isMenuOpen.value}".debugPrint();
      cancelDialog(context, currentPlan.value, cancelPlan);
    }

    //Upgrade & Downgrade Subscription,
    toUpgradePlan() {
      isMenuOpen.value = false;
      "isMenuOpen: ${isMenuOpen.value}".debugPrint();
      upgradePlanDialog(context, currentPlan.value, priceList.value, countryNumber.value, expirationDate.value, upgradePlan);
    }

    //Buy add on passes
    toBuyOnetime() {
      isMenuOpen.value = false;
      "isMenuOpen: ${isMenuOpen.value}".debugPrint();
      buyOnetimeDialog(context,
        currentPlan.value,
        priceList.value,
        countryNumber.value,
        expirationDate.value,
        buyOnetime
      );
    }

    //Restore Button
    toRestore() async {
      if (!isPurchasing.value) {
        isPurchasing.value = true;
        try {
          final restoredInfo = await Purchases.restorePurchases();
          "activePlan: ${restoredInfo.activeSubscriptions}".debugPrint();
          if (restoredInfo.activeSubscriptions.isNotEmpty && currentPlan.value == freeID) {
            await setPlan(
              planString: restoredInfo.updatedPlan(),
              activePlanListString: restoredInfo.activeSubscriptions,
              ticketsInt: tickets.value,
              expirationInt: restoredInfo.subscriptionExpirationDate()
            );
            if (context.mounted) purchaseSubscriptionSuccessDialog(context, restoredInfo.planID(), null, isRestore: true, isCancel: false);
          } else {
            if (context.mounted) purchaseErrorDialog(context, isRestore: true, isCancel: false);
          }
        } on PlatformException catch (e) {
          if (context.mounted) purchaseExceptionDialog(context, e, isRestore: true, isCancel: false);
        }
      }
    }

    return Scaffold(
      body: Stack(alignment: Alignment.centerLeft,
        children: [
          backGroundImage(context, countryNumber.value),
          if (isShowAd.value && !context.isAdmobEnoughSideSpace()) adMobBanner(context),
          backFenceImage(context, countryNumber.value),
          if (countryNumber.value == 0) backEmergencyImage(context, countryNumber.value),
          if (countryNumber.value == 0) backGateImage(context, countryNumber.value),
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
          upDownSpacer(context),
          sideSpacer(context),
          bottomButtons(),
          if (!isYellow.value && !isRightWait.value && !isLeftWait.value && !isLoadingPhoto.value) selectCountryButton(),
          if (isPossiblePhoto.value && !isLoadingPhoto.value) cameraButton(context, tickets.value, currentDate.value.intDateTime(), lastClaimedDate.value, cameraAction),
          if (isMenuOpen.value) menuWidget(context, currentPlan.value, tickets.value, countryNumber.value, currentDate.value.intDateTime(), lastClaimedDate.value, expirationDate.value, toBuyOnetime, toUpgradePlan, toPurchase, toCancel, toRestore),
          if (isMyPurchase.value) purchaseTable(context, currentPlan.value, tickets.value, priceList.value, buyPremium, buyStandard, buyTrial),
          if (!isYellow.value && !isRightWait.value && !isLeftWait.value) menuButton(context, isMenuOpen.value, isMyPurchase.value, openMenu),
          if (isShowPhoto.value) showPhotoImage(),
          if (isPurchasing.value || isLoadingPhoto.value) circularProgressIndicator(context),
          if (isShowAd.value && context.isAdmobEnoughSideSpace()) adMobBanner(context),
        ],
      ),
    );
  }
}

