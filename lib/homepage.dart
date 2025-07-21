import 'dart:async';
import 'dart:typed_data';
import 'package:fab_circular_menu_plus/fab_circular_menu_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:railroad_crossing/photo.dart';
import 'package:vibration/vibration.dart';
import 'common_widget.dart';
import 'common_extension.dart';
import 'constant.dart';
import 'main.dart';
import 'menu.dart';
import 'audio_manager.dart';
import 'admob_banner.dart';
import 'photo_manager.dart';

// Home Page Widget - Main railway crossing simulation interface
class HomePage extends HookConsumerWidget {
  final GlobalKey<FabCircularMenuPlusState> fabKey = GlobalKey();
  HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    /// ===== PROVIDER STATE MANAGEMENT =====
    // Watch provider states for reactive updates
    final countryNumber = ref.watch(countryProvider);
    final currentDate = ref.watch(currentProvider);
    final expirationDate = ref.watch(expirationProvider);
    final isLoading = ref.watch(loadingProvider);
    final photoImages = ref.watch(photoProvider);

    /// ===== RAILWAY CROSSING STATE VARIABLES =====
    // Railway crossing state variables for simulation control
    final isLeftOn = useState(false);        // Left side barrier state
    final isRightOn = useState(false);       // Right side barrier state
    final isLeftFast = useState(true);       // Left train speed mode
    final isRightFast = useState(true);      // Right train speed mode
    final isLeftWait = useState(false);      // Left train waiting state
    final isRightWait = useState(false);     // Right train waiting state
    final isYellow = useState(false);        // Yellow warning light state
    final isEmergency = useState(false);     // Emergency mode state
    final isPossibleEmergency = useState(true); // Emergency button availability
    final isPossiblePhoto = useState(false); // Photo capture availability
    final changeTime = useState(0);          // Animation duration
    final photoIndex = useState(0);          // Current photo index
    final isSavePhoto = useState(false);     // Photo save state
    final lifecycle = useAppLifecycleState(); // App lifecycle state

    /// ===== ANIMATION CONTROLLERS =====
    // Train animation controllers and effects
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
    
    /// ===== LAMP ANIMATION EFFECTS =====
    // Lamp animation controllers and effects for visual feedback
    flashAnimation(int flashTime) => CurvedAnimation(
      parent: useAnimationController(
        duration: Duration(milliseconds: flashTime),
      )..repeat(reverse: false),
      curve: const Threshold(0.5),
    );
    final flashEmergencyColor = useAnimation(
      ColorTween(begin: whiteColor, end: yellowColor).animate(flashAnimation(emergencyDuration)),
    );
    final ledFlashIndex = useAnimation(
      IntTween(begin: 0, end: 1).animate(flashAnimation(ledDuration)),
    );
    final warningFlashIndex = useAnimation(
      IntTween(begin: 0, end: 1).animate(flashAnimation(warningDuration)),
    );

    /// ===== MANAGER INITIALIZATION =====
    // Initialize managers and widgets for audio and photo functionality
    final audioManager = useMemoized(() => AudioManager());
    final photoManager = useMemoized(() => PhotoManager(
      context: context,
      currentDate: currentDate,
    ));
    final common = CommonWidget(context: context);
    final home = HomeWidget(
      context: context, 
      countryNumber: countryNumber,
      isYellow: isYellow.value,
      isLeftOn: isLeftOn.value,
      isRightOn: isRightOn.value,
      isLeftFast: isLeftFast.value,
      isRightFast: isRightFast.value,
      isLeftWait: isLeftWait.value,
      isRightWait: isRightWait.value,
      photoImages: photoImages,
    );

    /// ===== STATE MANAGEMENT METHODS =====
    // Reset railway crossing to normal state
    setNormalState() async {
      "setNormal".debugPrint();
      isLeftOn.value = false;
      isLeftWait.value = false;
      isRightOn.value = false;
      isRightWait.value = false;
      isYellow.value = false;
      isPossiblePhoto.value = false;
      isPossibleEmergency.value = true;
      changeTime.value = 0;
      await audioManager.stopAll();
    }

    // Initialize app
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await setNormalState();
        // await loadSubscriptionInfo();
      });
      return null;
    }, const []);


    /// ===== APP LIFECYCLE MANAGEMENT =====
    // Handle app lifecycle changes (pause, resume) to stop audio
    useEffect(() {
      Future<void> handleLifecycleChange() async {
        if (!context.mounted) return;
        if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
          try {
            await audioManager.stopAll();
            setNormalState();
          } catch (e) {
            'Error handling stop for player: $e'.debugPrint();
            setNormalState();
          }
        }
      }
      handleLifecycleChange();
      return null;
    }, [lifecycle, context.mounted]);

    /// ===== COUNTRY SELECTION =====
    // Change country selection - Updates railway crossing style
    changeCountry(MapEntry entry) async {
      "ChangeCountry".debugPrint();
      if (!isLoading) {
        final newCountryNumber = entry.value['countryNumber'] as int;
        if (countryNumber != newCountryNumber) {
          await audioManager.playEffectSound(decideSound);
          ref.read(countryProvider.notifier).state = newCountryNumber;
          'select_${entry.key}: $countryNumber'.debugPrint();
        } else {
          await audioManager.playEffectSound(openSound);
        }
        fabKey.currentState?.close();
        if (context.mounted) context.pushHomePage();
      }
    }

    // Country selection floating action button
    Widget selectCountryButton() => FabCircularMenuPlus(
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
        "onDisplayChange called: $isOpen".debugPrint();
        if (isOpen){
          await audioManager.playEffectSound(openSound);
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

    /// ===== PHOTO MANAGEMENT =====
    // Share photo image to external apps
    Future sharePhotoImage() async {
      "Share photo image".debugPrint();
      ref.read(loadingProvider.notifier).state = true;
      await photoManager.sharePhoto(
        imageList: photoImages,
        index: photoIndex.value
      );
      ref.read(loadingProvider.notifier).state = false;
    }

    // Save photo image to device gallery
    Future savePhotoImage() async {
      "Save photo image".debugPrint();
      ref.read(loadingProvider.notifier).state = true;
      isSavePhoto.value = await photoManager.savePhoto(
        imageList: photoImages,
        index: photoIndex.value
      );
      ref.read(loadingProvider.notifier).state = false;
    }

    // Return to home page from photo display
    Future returnHome() async {
      "returnHome".debugPrint();
      ref.read(photoProvider.notifier).state = [];
      context.pushHomePage();
    }

    // Navigate between photo images (next/previous)
    void changeImageIndex(bool isNext) {
      photoIndex.value = (photoIndex.value + (isNext ? 1: -1)) % generatePhotoNumber;
      "${isNext ? 'Next': 'Back'} photo image: ${photoIndex.value}".debugPrint();
    }

    /// ===== WARNING STATE MANAGEMENT =====
    // Set yellow warning state for railway crossing
    void setYellowState() {
      "setYellowState".debugPrint();
      isYellow.value = true;
      "isYellow: ${isYellow.value}".debugPrint();
    }

    // Set warning state with sound for railway crossing
    setWarningState() async {
      "setWarningState".debugPrint();
      isYellow.value = false;
      "isYellow: ${isYellow.value}".debugPrint();
      await audioManager.playWarningSound(countryNumber.warningSound());
    }

    /// ===== LEFT SIDE TRAIN CONTROL =====
    // Stop left train and reset left side state
    leftWaitOff() async {
      "leftWaitOff".debugPrint();
      await audioManager.stopLeftTrainSound();
      isLeftOn.value = false;
      isLeftWait.value = false;
      "isLeftOn: ${isLeftOn.value}, isRightOn: ${isRightOn.value}".debugPrint();
      "isLeftWait: ${isLeftWait.value}, isRightWait: ${isRightWait.value}".debugPrint();
      if (!isRightOn.value) {
        isPossiblePhoto.value = false;
        await audioManager.stopWarningSound();
        Future.delayed(const Duration(seconds: barUpDownTime), () async {
          if (!isRightOn.value) await setNormalState();
        });
      }
    }

    // Start left train animation and sound
    goLeftTrain() async {
      "goLeftTrain".debugPrint();
      if (isLeftWait.value && !isEmergency.value) {
        isPossiblePhoto.value = true;
        isPossibleEmergency.value = false;
        "isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
        await audioManager.playLeftTrainSound();
        if (context.mounted) leftAnimation.value = context.leftAnimation(leftController, isLeftFast.value);
        await leftController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () => leftWaitOff());
      }
    }

    // Activate left side warning and wait for train
    leftWaitOn() async {
      "leftWaitOn".debugPrint();
      isLeftWait.value = true;
      "isLeftWait: ${isLeftWait.value}, isRightWait: ${isRightWait.value}".debugPrint();
      if (!isRightWait.value) setWarningState();
      Future.delayed(const Duration(seconds: waitTime), () => goLeftTrain());
    }

    // Handle left button press - Start left side railway crossing sequence
    pushLeftButton() {
      "pushLeftButton".debugPrint();
      if (!isLeftOn.value && !isEmergency.value) {
        isLeftOn.value = true;
        changeTime.value = barUpDownTime;
        if (!isRightWait.value && !isRightOn.value) {
          setYellowState();
          Future.delayed(const Duration(seconds: yellowTime), () => leftWaitOn());
        } else {
          leftWaitOn();
        }
      }
    }

    /// ===== RIGHT SIDE TRAIN CONTROL =====
    // Stop right train and reset right side state
    rightWaitOff() async {
      "rightWaitOff".debugPrint();
      await audioManager.stopRightTrainSound();
      isRightOn.value = false;
      isRightWait.value = false;
      "isLeftOn: ${isLeftOn.value}, isRightOn: ${isRightOn.value}".debugPrint();
      "isLeftWait: ${isLeftWait.value}, isRightWait: ${isRightWait.value}".debugPrint();
      if (!isLeftOn.value) {
        isPossiblePhoto.value = false;
        await audioManager.stopWarningSound();
        Future.delayed(const Duration(seconds: barUpDownTime), () async {
          if (!isLeftOn.value) await setNormalState();
        });
      }
    }

    // Start right train animation and sound
    goRightTrain() async {
      "goRightTrain".debugPrint();
      if (isRightWait.value && !isEmergency.value) {
        isPossiblePhoto.value = true;
        isPossibleEmergency.value = false;
        "isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
        await audioManager.playRightTrainSound();
        if (context.mounted) rightAnimation.value = context.rightAnimation(rightController, isRightFast.value);
        await rightController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () => rightWaitOff());
      }
    }

    // Activate right side warning and wait for train
    rightWaitOn() async {
      "rightWaitOn".debugPrint();
      if (!isLeftWait.value) setWarningState();
      isRightWait.value = true;
      "isLeftWait: ${isLeftWait.value}, isRightWait: ${isRightWait.value}".debugPrint();
      Future.delayed(const Duration(seconds: waitTime), () => goRightTrain());
    }

    // Handle right button press - Start right side railway crossing sequence
    pushRightButton() {
      "pushRightButton".debugPrint();
      if (!isRightWait.value && !isEmergency.value) {
        isRightOn.value = true;
        changeTime.value = barUpDownTime;
        if (!isLeftWait.value && !isLeftOn.value) {
          setYellowState();
          Future.delayed(const Duration(seconds: yellowTime), () => rightWaitOn());
        } else {
          rightWaitOn();
        }
      }
    }

    /// ===== TRAIN SPEED CONTROL =====
    // Toggle left train speed (fast/normal)
    pushLeftSpeedButton() {
      "pushLeftSpeedButton".debugPrint();
      if (!isLeftOn.value) {
        isLeftFast.value = !isLeftFast.value;
        "isLeftFast: ${isLeftFast.value}".debugPrint();
      }
    }

    // Toggle right train speed (fast/normal)
    pushRightSpeedButton() {
      "pushRightSpeedButton".debugPrint();
      if (!isRightOn.value) {
        isRightFast.value = !isRightFast.value;
        "isRightFast: ${isRightFast.value}".debugPrint();
      }
    }

    /// ===== EMERGENCY CONTROL =====
    // Activate emergency mode with vibration and sound
    emergencyOn() async {
      "pushEmergencyButton".debugPrint();
      if (!isEmergency.value && isPossibleEmergency.value && countryNumber < 2) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        audioManager.playEmergencySound();
        isEmergency.value = true;
        "isEmergency: ${isEmergency.value}".debugPrint();
        isPossibleEmergency.value = false;
        "isPossibleEmergency: ${isPossibleEmergency.value}".debugPrint();
      }
    }

    // Deactivate emergency mode and resume normal operation
    emergencyOff() async {
      "pushEmergencyOffButton".debugPrint();
      if (isEmergency.value) {
        isEmergency.value = false;
        "isEmergency: ${isEmergency.value}".debugPrint();
        audioManager.stopEmergencySound();
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

    /// ===== MAIN UI LAYOUT =====
    // Main UI layout with railway crossing components
    // Components are layered from background to foreground using Stack widget
    return Scaffold(
      body: Stack(alignment: Alignment.centerLeft,
        children: [
          // ===== BACKGROUND AND BACK LAYER =====
          // Base background and back components (fence, gates, barriers, poles)
          home.backGroundImage(),
          home.backFenceImage(),
          home.backEmergencyImage(),
          if (countryNumber == 0) home.backGateImage(),
          if (countryNumber != 3) home.backBarImage(ledFlashIndex, changeTime.value),
          if (countryNumber != 0) home.backGateImage(),
          home.backPoleImage(),
          if (countryNumber == 3) home.backBarImage(ledFlashIndex, changeTime.value),
          home.backDirectionImage(),
          home.backWarningImage(warningFlashIndex),
          // ===== TRAIN LAYER =====
          // Animated train images (only when trains are active)
          if (isRightWait.value) home.rightTrainImage(rightAnimation.value),
          if (isLeftWait.value) home.leftTrainImage(leftAnimation.value),
          // ===== FRONT LAYER =====
          // Front components (poles, gates, barriers, emergency signs)
          home.frontPoleImage(),
          if (countryNumber == 1) home.frontGateImage(),
          home.frontBarImage(ledFlashIndex, changeTime.value),
          if (countryNumber != 1) home.frontGateImage(),
          home.frontEmergencyImage(),
          home.emergencyButton(onTap: () => emergencyOn()),
          home.frontDirectionImage(),
          home.frontWaringImage(warningFlashIndex),
          home.frontFenceImage(),
          home.trafficSignImage(),
          // ===== LAYOUT SPACERS =====
          home.upDownSpacer(),
          home.sideSpacer(),
          // ===== INTERACTIVE CONTROLS =====
          // Bottom control buttons for train operations and emergency functions
          home.bottomButtons(
            isEmergency: isEmergency.value,
            emergencyColor: flashEmergencyColor!,
            onTap: [
              pushLeftButton,
              pushLeftSpeedButton,
              pushRightSpeedButton,
              pushRightButton,
              emergencyOff,
            ]
          ),
          // ===== MENU AND UTILITY COMPONENTS =====
          // Menu button with conditional visibility
          IgnorePointer(
            ignoring: (isYellow.value || isRightWait.value || isLeftWait.value || isLoading),
            child: Opacity(
              opacity: (!isYellow.value && !isRightWait.value && !isLeftWait.value && !isLoading) ? 1.0 : 0.0,
              child: MenuButton(),
            ),
          ),
          // Country selection and advertisement components
          if (!isYellow.value && !isRightWait.value && !isLeftWait.value && !isLoading) selectCountryButton(),
          if (currentDate > expirationDate) AdBannerWidget(),
          // Photo capture button with conditional visibility
          IgnorePointer(
            ignoring: !(isPossiblePhoto.value && !isLoading),
            child: Opacity(
              opacity: (isPossiblePhoto.value && !isLoading) ? 1.0 : 0.0,
              child: PhotoButton(),
            ),
          ),
          // ===== PHOTO DISPLAY =====
          // Photo image display with navigation and sharing functionality
          if (photoImages.isNotEmpty) home.showPhotoImage(
            index: photoIndex.value,
            isSavePhoto: isSavePhoto.value,
            onTapToHome: () => returnHome(),
            onTapShare: () async => (isSavePhoto.value) ? await sharePhotoImage(): await savePhotoImage(),
            onTapBack: () => changeImageIndex(false),
            onTapNext: () => changeImageIndex(true),
          ),
          // ===== LOADING INDICATOR =====
          if (isLoading) common.circularProgressIndicator(),
        ],
      ),
    );
  }
}

// Home Widget - UI components for railway crossing simulation
class HomeWidget {

  /// ===== WIDGET PROPERTIES =====
  final BuildContext context;
  final int countryNumber;
  final bool isYellow;
  final bool isLeftOn;
  final bool isRightOn;
  final bool isLeftFast;
  final bool isRightFast;
  final bool isLeftWait;
  final bool isRightWait;
  final List<Uint8List> photoImages;

  HomeWidget({
    required this.context, 
    required this.countryNumber,
    required this.isYellow,
    required this.isLeftOn,
    required this.isRightOn,
    required this.isLeftFast,
    required this.isRightFast,
    required this.isLeftWait,
    required this.isRightWait,
    required this.photoImages,
  });

  /// ===== BACKGROUND COMPONENTS =====
  // Background image for railway crossing scene
  Widget backGroundImage() => Container(
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

  CommonWidget common() => CommonWidget(context: context);

  // Back fence image for railway crossing scene
  Widget backFenceImage() => Container(
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

  // Back emergency sign image
  Widget backEmergencyImage() => Container(
    margin: EdgeInsets.only(
      top: context.backEmergencyTopMargin(),
      left: context.backEmergencyLeftMargin(),
    ),
    height: context.backEmergencyHeight(),
    child: (countryNumber == 0) ? Image.asset(boardBackDefault): null,
  );

  // Back gate image for railway crossing
  Widget backGateImage() => Container(
    margin: EdgeInsets.only(
      top: context.backGateTopMargin(countryNumber),
      left: context.backGateLeftMargin(countryNumber),
    ),
    height: context.backGateImageHeight(countryNumber),
    child: (countryNumber != 3) ? Image.asset(countryNumber.gateBackImage()): null,
  );

  // Back barrier image with animation for railway crossing
  Widget backBarImage(int flashIndex, int changeTime) {
    final bool isWait = isLeftWait || isRightWait;
    final double angle = countryNumber.barAngle(isWait);
    final double shift = countryNumber.barShift(isWait);
    final String barBackImage = countryNumber.barBackImage(isWait, flashIndex);
    return Container(
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
  }

  // Back pole image for railway crossing
  Widget backPoleImage() => Container(
    margin: EdgeInsets.only(
      top: context.backPoleTopMargin(countryNumber),
      left: context.backPoleLeftMargin(countryNumber),
    ),
    height: context.backPoleImageHeight(countryNumber),
    child: Image.asset(countryNumber.poleBackImage()),
  );

  // Back direction sign image
  Widget backDirectionImage() => Container(
    margin: EdgeInsets.only(
      top: context.backDirectionTopMargin(),
      left: context.backDirectionLeftMargin(),
    ),
    height: context.backDirectionHeight(),
    child: (countryNumber == 0) ? Image.asset(countryNumber.directionImage(isLeftWait, isRightWait)): null,
  );

  // Back warning light image with flashing effect
  Widget backWarningImage(int index) {
    final isWait = isLeftWait || isRightWait;
    final String warningBackImage = countryNumber.warningBackImage(isYellow, isWait, index);
    return Container(
      margin: EdgeInsets.only(
        bottom: context.backWarningBottomMargin(countryNumber),
        left: context.backWarningLeftMargin(countryNumber)
      ),
      height: context.backWarningImageHeight(countryNumber),
      child: ((countryNumber == 0 || countryNumber == 3) && warningBackImage != "") ? Image.asset(warningBackImage): null,
    );
  }

  /// ===== TRAIN COMPONENTS =====
  // Right train image with animation
  Widget rightTrainImage(Animation<double> rightAnimation) => AnimatedBuilder(
    animation: rightAnimation,
    builder: (_, child) => Transform.translate(
      offset: Offset(rightAnimation.value, context.rightTrainOffset()),
      child: OverflowBox(
        maxWidth: double.infinity,
        child: Row(children: List.generate(countryNumber.trainImage().length, (i) =>
          SizedBox(
            height: context.rightTrainHeight(),
            child: Image.asset(countryNumber.trainImage()[i],
              fit: BoxFit.fitHeight,
            ),
          ),
        )),
      ),
    ),
  );

  /// Left train image with animation
  Widget leftTrainImage(Animation<double> leftAnimation) => AnimatedBuilder(
    animation: leftAnimation,
    builder: (_, child) => Transform.translate(
      offset: Offset(leftAnimation.value, context.leftTrainOffset()),
      child: OverflowBox(
        maxWidth: double.infinity,
        child: Row(children: List.generate(countryNumber.trainImage().length, (i) =>
          SizedBox(
            height: context.leftTrainHeight(),
            child: Image.asset(countryNumber.trainImage()[i],
              fit: BoxFit.fitHeight
            )
          ),
        )),
      ),
    ),
  );

  /// ===== FRONT COMPONENTS =====
  // Front pole image for railway crossing
  Widget frontPoleImage() => Container(
    margin: EdgeInsets.only(
      top: context.frontPoleTopMargin(countryNumber),
      left: context.frontPoleLeftMargin(countryNumber),
    ),
    height: context.frontPoleImageHeight(countryNumber),
    child: Image.asset(countryNumber.poleFrontImage()),
  );

  // Front gate image for railway crossing
  Widget frontGateImage() => Container(
    margin: EdgeInsets.only(
      top: context.frontGateTopMargin(countryNumber),
      left: context.frontGateLeftMargin(countryNumber),
    ),
    height: context.frontGateImageHeight(countryNumber),
    child: (countryNumber != 3) ? Image.asset(countryNumber.gateFrontImage()): const SizedBox(width: 0),
  );

  // Front barrier image with animation for railway crossing
  Widget frontBarImage(int flashIndex , int changeTime) {
    final bool isWait = isLeftWait || isRightWait;
    final double angle = countryNumber.barAngle(isWait);
    final double shift = countryNumber.barShift(isWait);
    final String barFrontImage = countryNumber.barFrontImage(isWait, flashIndex);
    return Container(
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
  }

  // Front emergency sign image
  Widget frontEmergencyImage() => Container(
    margin: EdgeInsets.only(
      top: context.frontEmergencyTopMargin(),
      left: context.frontEmergencyLeftMargin(),
    ),
    height: context.frontEmergencyHeight(),
    child: (countryNumber == 0) ? Image.asset(boardFrontDefault): null,
  );

  /// ===== CONTROL COMPONENTS =====
  // Emergency button for railway crossing
  Widget emergencyButton({required void Function() onTap}) => Container(
    margin: EdgeInsets.only(
      top: context.emergencyButtonTopMargin(countryNumber),
      left: context.emergencyButtonLeftMargin(countryNumber),
    ),
    height: context.emergencyButtonHeight(countryNumber),
    child: GestureDetector(
      onTap: onTap,
      child: (countryNumber < 2) ? Image.asset(countryNumber.emergencyImage()): null,
    )
  );

  /// Front direction sign image for railway crossing
  Widget frontDirectionImage() => Container( //String directionImage) => Container(
    margin: EdgeInsets.only(
      top: context.frontDirectionTopMargin(),
      left: context.frontDirectionLeftMargin(),
    ),
    height: context.frontDirectionHeight(),
    child: (countryNumber == 0) ? Image.asset(
      (isLeftWait && isRightWait) ? countryNumber.directionImageBoth():
      (isLeftWait) ? countryNumber.directionImageLeft():
      (isRightWait) ? countryNumber.directionImageRight():
      countryNumber.directionImageOff()
    ): null,
  );

  // Front warning light image with flashing effect
  Widget frontWaringImage(int index) {
    final isWait = isLeftWait || isRightWait;
    final String warningFrontImage = countryNumber.warningFrontImage(isYellow, isWait, index);
    return Container(
      margin: EdgeInsets.only(
        left: context.frontWarningLeftMargin(countryNumber),
        bottom: context.frontWarningBottomMargin(countryNumber),
      ),
      height: context.frontWarningImageHeight(countryNumber),
      child: (warningFrontImage != "") ? Image.asset(warningFrontImage): null,
    );
  }

  // Front fence image for railway crossing scene
  Widget frontFenceImage() => Container(
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

  // Traffic sign image for railway crossing
  Widget trafficSignImage() => Container(
    margin: EdgeInsets.only(
      top: context.trafficSignTopMargin(countryNumber),
      left: context.trafficSignLeftMargin(countryNumber),
    ),
    height: context.trafficSignHeight(countryNumber),
    child:Image.asset(countryNumber.signImage()),
  );

  /// ===== LAYOUT COMPONENTS =====
  // Vertical spacer for layout adjustment
  Widget upDownSpacer() => Column(children: [
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

  // Horizontal spacer for layout adjustment
  Widget sideSpacer() => Row(children: [
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

  /// ===== INTERACTIVE COMPONENTS =====
  // Operation button with icon for railway crossing controls
  Widget operationButton({
    required Color color, 
    required IconData icon,
    required void Function() onTap
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
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
    )
  );

  // Bottom control buttons for railway crossing operations
  Widget bottomButtons({
    required bool isEmergency,
    required Color emergencyColor,
    required List<void Function()> onTap,
  }) => Container(
    alignment: Alignment.bottomLeft,
    margin: EdgeInsets.only(
      left: context.buttonSideMargin(),
      right: context.buttonSideMargin() + context.buttonSpace(),
      bottom: context.buttonUpDownMargin()
    ),
    child: Row(children: List.generate((countryNumber < 2 && isEmergency) ? 5: 4, (i) =>
      operationButton(
        color: [
          operationColor(isLeftOn),
          operationColor(isLeftOn),
          operationColor(isRightOn),
          operationColor(isRightOn),
          isEmergency ? emergencyColor: whiteColor,
        ][i],
        icon: [
          Icons.arrow_back,
          isLeftFast ? CupertinoIcons.chevron_left_2:  CupertinoIcons.chevron_left,
          isRightFast ? CupertinoIcons.chevron_right_2: CupertinoIcons.chevron_right,
          Icons.arrow_forward,
          Icons.emergency,
        ][i],
        onTap: () => onTap[i](),
      )
    ))
  );

  // Photo display widget with navigation controls
  Widget showPhotoImage({
    required int index,
    required bool isSavePhoto,
    required void Function() onTapToHome,
    required void Function() onTapShare,
    required void Function() onTapBack,
    required void Function() onTapNext,
  }) => Container(
    width: context.width(),
    height: context.height(),
    margin: EdgeInsets.symmetric(horizontal: context.sideMargin()),
    color: transpBlackColor,
    child: (photoImages.isEmpty) ? SizedBox(): Stack(alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            common().circleIconButton(icon: Icons.arrow_back_rounded, onTap: onTapToHome),
            Image.memory(photoImages[index.clamp(0, photoImages.length - 1)], fit: BoxFit.cover),
            common().circleIconButton(icon: isSavePhoto ? Icons.share: Icons.save_alt_rounded, onTap: onTapShare)
          ]
        ),
        if (!isSavePhoto && photoImages.length > 1) Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            common().circleIconButton(icon: Icons.arrow_back_ios_rounded, onTap: onTapBack),
            common().circleIconButton(icon: Icons.arrow_forward_ios_rounded, onTap: onTapNext),
          ]
        ),
      ]
    )
  );
}