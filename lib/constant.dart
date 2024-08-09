import 'package:flutter/material.dart';
import 'package:railroad_crossing/common_extension.dart';

///Signal Number
const int totalCountryNumber = 4;


///App Name
const String appTitle = "LETS CROSSING";

///Position
double trainBeginPosition(bool isFast) => 16000.0 / (2.0 - isFast.boolToDouble());
double trainEndPosition(bool isFast) => -16000.0 / (2.0 - isFast.boolToDouble());

///Time
const int waitTime = 10;             //seconds
const int yellowTime = 5;            //seconds
const int barUpDownTime = 5;         //seconds
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
  [
    "${trainUSAssets}avelia_liberty_1.png",
    "${trainUSAssets}avelia_liberty_2.png",
    "${trainUSAssets}avelia_liberty_3.png",
    "${trainUSAssets}avelia_liberty_4.png",
    "${trainUSAssets}avelia_liberty_5.png",
    "${trainUSAssets}avelia_liberty_6.png",
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
  'cn': {'image': flagImageCN, 'countryNumber': 2},
  'us': {'image': flagImageUS, 'countryNumber': 3},
};