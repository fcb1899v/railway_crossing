import 'package:flutter/material.dart';

///Signal Number
const int totalCountryNumber = 7;

///App Name
const String appTitle = "LETS CROSSING";
const String appTitleImage = "assets/images/letsSignal.png";
const double appBarHeight = 56;

///Time
const int waitTime = 10;             //seconds
const int yellowTime = 5;            //seconds
const int ledDurationTime = 200;     //milliSeconds
const int emergencyWaitTime = 15;    //seconds
const int emergencyFlashTime = 500;  //milliSeconds

///Vibration
const int vibTime = 200;
const int vibAmp = 128;

///Color
const Color blackColor = Colors.black;
const Color whiteColor = Colors.white;
const Color grayColor = Colors.grey;
const Color transpColor = Colors.transparent;
const Color transpGrayColor = Color.fromRGBO(200, 200, 200, 0.7);
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.7);
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.7);
const Color edgeColor1 = Color.fromRGBO(180, 180, 180, 1);      //#b4b4b4
const Color edgeColor2 = Color.fromRGBO(230, 230, 230, 1);      //#e6e6e6
const Color darkYellowColor = Color.fromRGBO(190, 140, 60, 1);  //#be8c3c
const Color orangeColor = Color.fromRGBO(209, 130, 64, 1);      //#d18240
const Color yellowColor = Color.fromRGBO(250, 210, 90, 1);      //#fad25a
const Color greenColor = Color.fromRGBO(87, 191, 163, 1);       //#57BFA3
const Color redColor = Color.fromRGBO(200, 77, 62, 1);          //#C84D3E
const Color transpYellowColor = Color.fromRGBO(250, 210, 90, 0.7);      //#fad25a
const Color transpGreenColor = Color.fromRGBO(87, 191, 163, 0.7);       //#57BFA3
const Color transpRedColor = Color.fromRGBO(200, 77, 62, 0.7);          //#C84D3E

/// Sound
//Asset
const String soundJPAssets = "audios/jp/";
const String soundUKAssets = "audios/uk/";
const String soundUSAssets = "audios/us/";
const String soundCNAssets = "audios/cn/";
const String soundTrain = "audios/train.mp3";
const String soundEmergency = "audios/emergency.mp3";
const double warningVolume = 0.6;
const double trainVolume = 0.8;
const double emergencyVolume = 1.0;

/// Crossing Image
//Asset
const String crossingJPAssets = "assets/images/crossing/jp/";
const String crossingUKAssets = "assets/images/crossing/uk/";
const String crossingCNAssets = "assets/images/crossing/cn/";
const String crossingUSAssets = "assets/images/crossing/us/";
//Background
const String backGroundJP = "${crossingJPAssets}background.png";
//Bar Image
const String barFrontImageJPOff = "${crossingJPAssets}bar_front_off.png";
const String barBackImageJPOff = "${crossingJPAssets}bar_back_off.png";
//Warning Image
const String warningImageJPOff = "${crossingJPAssets}warning_off.png";
//Emergency Image
const String emergencyImage = "${crossingJPAssets}emergency.png";
const String boardFrontImage = "${crossingJPAssets}board_front.png";
const String boardBackImage = "${crossingJPAssets}board_back.png";
//Direction Image Board
const String directionImageJPOff = "${crossingJPAssets}direction_off.png";
const String directionImageJPLeft = "${crossingJPAssets}direction_left.png";
const String directionImageJPRight = "${crossingJPAssets}direction_right.png";
const String directionImageJPBoth = "${crossingJPAssets}direction_both.png";
//Direction Image Board
const String trainJPAssets = "assets/images/train/jp/";
const String trainUKAssets = "assets/images/train/uk/";
const String trainCNAssets = "assets/images/train/cn/";
const String trainUSAssets = "assets/images/train/us/";
// const selectTrainList = [
//   [
//     "${trainJPAssets}f-n700s.png",
//   ]
// ];
const trainList = [
  [
    "${trainJPAssets}n700s_1.png",
    "${trainJPAssets}n700s_2.png",
    "${trainJPAssets}n700s_3.png",
    "${trainJPAssets}n700s_4.png",
    "${trainJPAssets}n700s_5.png",
    "${trainJPAssets}n700s_6.png",
  ],
  [
    "${trainUKAssets}734_1.png",
    "${trainUKAssets}734_2.png",
    "${trainUKAssets}734_3.png",
    "${trainUKAssets}734_4.png",
    "${trainUKAssets}734_5.png",
    "${trainUKAssets}734_6.png",
  ],
  [
    "${trainCNAssets}cr400af_1.png",
    "${trainCNAssets}cr400af_2.png",
    "${trainCNAssets}cr400af_3.png",
    "${trainCNAssets}cr400af_4.png",
    "${trainCNAssets}cr400af_5.png",
    "${trainCNAssets}cr400af_6.png",
  ],
];
//Country Flag
const String flagImageJP = "assets/images/flag/jp.png";
const String flagImageUK = "assets/images/flag/uk.png";
const String flagImageCN = "assets/images/flag/cn.png";
const String flagImageUS = "assets/images/flag/us.png";
final flagList = {
  'jp': {'image': flagImageJP, 'countryNumber': 0},
  'uk': {'image': flagImageUK, 'countryNumber': 1},
  'cn': {'image': flagImageCN, 'countryNumber': 2}
  // 'us': {'image': flagImageUS, 'countryNumber': 3},
};

///Button Frame
const double frameHeightRate = 0.40;
const List<double> frameTopPaddingRate = [0, 0, 0, 0, 0.01, 0.02, 0];
const List<double> frameBottomPaddingRate = [0, 0.08, 0, 0, 0.01, 0.02, 0];
const List<double> labelTopMarginRate = [0, 0, 0, 0, 0.085, 0.10, 0];
const List<double> labelMiddleMarginRate = [0, 0, 0, 0, 0.14, 0.135, 0];
const List<double> labelHeightRate = [0, 0, 0, 0, 0.045, 0.045, 0];
const List<double> labelWidthRate = [0, 0, 0, 0, 0.2, 0.2, 0];
const List<double> labelFontSizeRate = [0, 0, 0, 0, 0.025, 0.025, 0];

///Push Button
const List<double> buttonHeightRate = [0.13, 0.11, 0.05, 0.04, 0.115, 0.08, 0.15];
const List<double> buttonTopMarginRate = [0.225, 0.29, 0.328, 0.325, 0.143, 0.17, 0.22];

///Pedestrian Signal
const double signalHeightRate = 0.35;
const List<double> pedestrianSignalPaddingRate = [0.03, 0.06, 0.03, 0.015, 0.015, 0.015, 0.015];
const List<double> trafficSignalPaddingRate = [0.01, 0, 0.01, 0.01, 0.04, 0.04, 0.01];

//Countdown Number
const List<double> cdNumTopSpaceRate = [0.07, 0, 0.189, 0, 0, 0, 0];
const List<double> cdNumLeftSpaceRate = [0.14, 0, 0.157, 0, 0, 0, 0];
const List<double> cdNumPaddingRate = [0.03, 0, 0.018, 0, 0, 0, 0];
const List<double> cdNumFontSizeRate = [0.115, 0, 0.055, 0, 0, 0, 0];
const List<Color> cdNumColor = [orangeColor, transpColor, yellowColor, transpColor, transpColor, transpColor, transpColor];
const List<String> cdNumFont = ["dotFont", "", "freeTfb", "", "", "", ""];

//Countdown Meter
const double countMeterTopSpaceRate =  0.035;
const double countMeterCenterSpaceRate =  0.08;
const double countDownRightPaddingRate = 0.003;
const double countMeterWidthRate =  0.012;
const double countMeterHeightRate =  0.01;
const double countMeterSpaceRate =  0.0024;

//stop/go flag
const double stopGoFlagHeightRate = 0.18;
const int flagRotationTime = 1;

/// Floating Action Button
const double floatingButtonSizeRate = 0.07;
const double floatingImageSizeRate = 0.02;
const double floatingIconSizeRate = 0.03;

///Upgrade
const String premiumProduct = "signal_upgrade_premium";
const double upgradeAppBarHeight = 45;
const double premiumTitleFontSizeRate = 0.035;
const double premiumPriceFontSizeRate = 0.08;
const double premiumPricePaddingRate = 0.025;
const double upgradeButtonFontSizeRate = 0.025;
const double upgradeTableFontSizeRate = 0.018;
const double upgradeTableIconSizeRate = 0.03;
const double upgradeTableHeadingHeightRate = 0.03;
const double upgradeTableHeightRate = 0.06;
const double upgradeTableDividerWidth = 0;
const double upgradeButtonPaddingRate = 0.006;
const double upgradeButtonBottomMarginRate = 0.035;
const double upgradeButtonElevation = 10;
const double upgradeButtonBorderWidth = 1.5;
const double upgradeButtonBorderRadius = 5;
const double upgradeMarginWidthRate = 0.05;
const double upgradeCircularProgressMarginBottomRate = 0.4;

///Settings
const double settingsTilePaddingSize = 20;
const double settingsTileRadiusSize = 15;
