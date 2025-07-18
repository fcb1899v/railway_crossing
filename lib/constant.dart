import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:railroad_crossing/common_extension.dart';

/// ===== GENERAL PARAMETERS =====
// Core application parameters and configuration
const int countryNumber = 4;
double aspectRatio = 16.0 / 9.0;
const double barUpAngle = 1.5;
const audioPlayerNumber = 5;

/// ===== TIMING CONSTANTS =====
// Time-based constants for railway crossing simulation
const int waitTime = 10;            // seconds
const int yellowTime = 3;           // seconds
const int barUpDownTime = 10;       // seconds
const int trainTime = 16;           // seconds
const int emergencyWaitTime = 15;   // seconds
const int warningDuration = 2000;   // milliSeconds
const int ledDuration = 200;        // milliSeconds
const int emergencyDuration = 700;  // milliSeconds

/// ===== DEFAULT VALUES =====
// Default values for date, time, and pricing
DateTime defaultDateTime = DateTime(2024,1,1,0,0,0);
const int defaultIntDateTime = 20240101000000;
const int defaultIntDate = 20240101;
const List<String> defaultPriceList = ["-", "-", "-", "-"];
const String defaultPrice = "-";
const String defaultOnetimePrice = "\$3.99";

/// ===== VIBRATION SETTINGS =====
// Vibration parameters for haptic feedback
const int vibTime = 200;
const int vibAmp = 128;

/// ===== COLOR DEFINITIONS =====
// Color constants for UI styling
const Color blackColor = Colors.black;
const Color whiteColor = Colors.white;
const Color grayColor = Colors.grey;
const Color transpColor = Colors.transparent;
const Color transpGrayColor = Color.fromRGBO(200, 200, 200, 0.5);
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.8);
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.9);
const Color edgeColor1 = Color.fromRGBO(180, 180, 180, 1);         // #b4b4b4
const Color edgeColor2 = Color.fromRGBO(230, 230, 230, 1);         // #e6e6e6
const Color darkYellowColor = Color.fromRGBO(190, 140, 60, 1);     // #be8c3c
const Color orangeColor = Color.fromRGBO(209, 130, 64, 1);         // #d18240
const Color yellowColor = Color.fromRGBO(250, 210, 90, 1);         // #fad25a
const Color greenColor = Color.fromRGBO(87, 191, 163, 1);          // #57bfa3
const Color redColor = Color.fromRGBO(200, 77, 62, 1);             // #c84d3e
const Color transpYellowColor = Color.fromRGBO(250, 210, 90, 0.7); // #fad25a
const Color transpGreenColor = Color.fromRGBO(87, 191, 163, 0.7);  // #57bfa3
const Color transpRedColor = Color.fromRGBO(200, 77, 62, 0.7);     // #c84d3e
Color operationColor(bool isOn) => isOn ? redColor: whiteColor;

/// ===== AUDIO ASSETS AND SETTINGS =====
// Audio file paths and volume settings
const String soundTrain = "audios/train.mp3";
const String soundEmergency = "audios/emergency.mp3";
const double warningVolume = 0.6;
const double trainVolume = 0.8;
const double emergencyVolume = 1.0;
const double effectVolume = 1.0;
const String openSound = "audios/popi.mp3";
const String decideSound = "audios/tetete.mp3";
const String cameraSound = "audios/camera.mp3";

/// ===== IMAGE ASSETS =====
// Default image assets for railway crossing components
String backGroundDefault = "${0.crossingAssets()}background.png";
String barFrontDefault = "${0.crossingAssets()}bar_front_off.png";
String barBackDefault = "${0.crossingAssets()}bar_back_off.png";
String warningDefault = "${0.crossingAssets()}warning_off.png";
String boardFrontDefault = "${0.crossingAssets()}board_front.png";
String boardBackDefault = "${0.crossingAssets()}board_back.png";
String directionDefault = "${0.crossingAssets()}direction_off.png";
Map<String, Map<String, Object>> flagList = {
  for (var i = 0; i < countryNumber; i++) i.countryString(): i.flagMap()
};
String instagramLogo = "assets/images/instagram.png";

/// ===== PURCHASE CONFIGURATION =====
// RevenueCat API keys and purchase-related constants
final revenueCatApiKey = dotenv.get((Platform.isIOS || Platform.isMacOS) ?
  "REVENUE_CAT_IOS_API_KEY":
  "REVENUE_CAT_ANDROID_API_KEY"
);
// Platform-specific provider settings
final androidProvider = AndroidProvider.playIntegrity;
final appleProvider = kDebugMode ? AppleProvider.debug: AppleProvider.deviceCheck;
// Purchase plan configurations
const List<bool?> isUpgradeAdFreeList = [true, false];
const List<String> countryCodeList = ["JP", "GB", "CN", "US"];
String premiumID = (Platform.isIOS || Platform.isMacOS) ? 'monthly_premium': 'premium_plan:monthly-premium';
String standardID = (Platform.isIOS || Platform.isMacOS) ? 'monthly_standard': 'standard_plan:monthly-standard';
const String addID = 'add_onetime';
const String trialID = 'trial_onetime';
const String freeID = 'free';
// Offering identifiers
const String defaultOffering = 'default_offering';
const String premiumOffering = 'premium_offering';
const String addPassesOffering = 'premium_offering';
const String normalOffering = 'normal_offering';
// User access levels
const String premiumUserAccess = 'premium_user_access';
const String standardUserAccess = 'standard_user_access';
const String freeUserAccess = 'free_user_access';
// Ticket allocation numbers
const int premiumTicketNumber  = 36;
const int standardTicketNumber = 24;
const int addOnTicketNumber    = 24;
const int trialTicketNumber    = 10;
const int onetimeTicketLimitNumber = 72;
// Month list for date formatting
const List<String> monthList = [
  'Jan.', 'Feb.', 'Mar.', 'Apr.', 'May.', 'Jun.',
  'Jul.', 'Aug.', 'Sep.', 'Oct.', 'Nov.', 'Dec.'
];
// Subscription management URLs
final Uri subscriptionUri = Uri.parse((Platform.isIOS || Platform.isMacOS) ?
  'https://apps.apple.com/account/subscriptions':
  'https://play.google.com/store/account/subscriptions'
);
// Photo generation settings
const generatePhotoNumber = 2;
const eulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";

/// ===== AI GENERATION SETTINGS =====
// Vertex AI configuration for image generation
const projectName = "letscrossing-app";
const vertexAILocation = "asia-northeast1";
const vertexAIModel = "imagen-3.0-generate-002"; // "imagen-3.0-fast-generate-001";
const vertexAIPostUrl = 'https://$vertexAILocation-aiplatform.googleapis.com/v1/projects/$projectName/locations/$vertexAILocation/publishers/google/models/$vertexAIModel:predict';
const vertexAINegativePrompt = "Wiring, Frame";
const vertexAIAspectRatio = "1:1";
const vertexAIPersonGeneration = "dont_allow";

/// ===== LANDMARK LISTS BY COUNTRY =====
// Japanese landmarks for AI photo generation
const jpSpot = [
  "Mount Fuji and Cherry Blossoms", "Mount Fuji and Five-storied pagoda", "Tokyo Tower", "Himeji Castle",
  "Kinkaku-ji Temple", "Gassho style house of Shirakawa-go", "Fushimi Inari Shrine", "Atomic Bomb Dome",
  "Todai-ji Temple", "Asakusa Senso-ji Temple", "Kamakura Great Buddha", "Tsutenkaku", "Horyu-ji Temple",
  "Itsukushima Shrine", "Tenryu-ji Temple Japanese Garden", "Furano Lavender Fields", "Sapporo Snow Festival"
];
// UK landmarks for AI photo generation
const ukSpot = [
  "Big Ben", "Tower Bridge", "Stonehenge", "White Cliffs", "Forth Railway Bridge",
  "British Museum", "Buckingham Palace", "Trafalgar Square", "London Eye", "Tower of London",
  "Westminster Abbey", "Kew Garden with flowers", "St Paul's Cathedral", "Piccadilly Circus", "Kings Cross Station",
  "Greenwich Observatory", "Oxford University", "Windsor Castle", "Bourton on the Water", "Jurassic Coast",
  "Edinburgh Castle", "Hadrian's Wall", "Livepool Cathedral", "Old Trafford Stadium", "Giant's Causeway",
];
// Chinese landmarks for AI photo generation
const cnSpot = [
  "Great wall", "Tiananmen Square", "Shanghai", "Guilin", "Stone Forest"
  "Zhangjiajie", "Potala Palace", "Jiuzhaigou Valley", "Yu Garden", "Forbidden City",
  "Broken Bridge of West Lake", "Terracotta Army", "Lijiang old town", "Mogao Caves", "Jiulong Waterfalls",
  "Sanya Beaches", "Kashga old Town", "Shaolin Temple", "Dazu Rock Carvings", "Longmen Grottoes",
  "Temple of Heaven", "Summer Palace", "Xi'an City Wall", "Canton Tower", "Ping An Finance Centre"
];
// US landmarks for AI photo generation
const usSpot = [
  "Grand Canyon", "Statue of Liberty", "Niagara Falls", "Times Square", "Golden Gate Bridge",
  "Las Vegas Strip", "Mount Rushmore", "Hollywood", "Yellowstone", "White House",
  "Brooklyn Bridge", "Central Park", "Death Valley", "Big Sur", "Capitol Building",
  "Washington Monument", "Kennedy Space Center", "Zion", "Kenai Fjords", "Hoover Dam",
  "Waikiki Beach", "Hawai'i Volcanoes"
];

/// ===== STORE FRONT URL =====
// Method channel URL for store front integration
const storeFrontUrl = 'nakajimamasao.appstudio.railwaycrossing/storefront';
