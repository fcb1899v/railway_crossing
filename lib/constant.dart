import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:railroad_crossing/common_extension.dart';

/// ===== GENERAL PARAMETERS =====
// Core application parameters and configuration
const int countryNumber = 4;
const double aspectRatio = 16.0 / 9.0;
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
const String soundTrain = "assets/audios/train.mp3";
const String soundEmergency = "assets/audios/emergency.mp3";
const double warningVolume = 0.6;
const double trainVolume = 0.8;
const double emergencyVolume = 1.0;
const double effectVolume = 1.0;
const String openSound = "assets/audios/popi.mp3";
const String decideSound = "assets/audios/tetete.mp3";
const String cameraSound = "assets/audios/camera.mp3";

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

/// ===== CREDITS INFORMATION =====
// Sound credits for audio assets
const List<String> credits = [
  "railroad-crossing-signal-shanghai-china.wav © 2012 freesound.org / RTB45",
];

/// ===== PURCHASE CONFIGURATION =====
// RevenueCat API keys and purchase-related constants
final revenueCatApiKey = dotenv.get((Platform.isIOS || Platform.isMacOS) ?
  "REVENUE_CAT_IOS_API_KEY":
  "REVENUE_CAT_ANDROID_API_KEY"
);
// Platform-specific App Check providers (non-legacy API)
//
// The debug tokens come from .env, not from source. This repository is public,
// and a registered debug token lets anyone mint a valid App Check token for this
// app, which is exactly what App Check exists to prevent. kDebugMode keeps the
// value out of the shipped binary, but it does not keep it out of the published
// source.
//
// Android and iOS are separate App Check apps and each has its own token, so one
// shared constant would have left the iOS debug build failing App Check.
// Register both under Firebase Console -> App Check -> Manage debug tokens, or:
//   firebase appcheck:debugtokens:create <token> --app <appId> --display-name <name>
// The values are recorded in the private company repo, not here.
final androidAppCheckProvider = kDebugMode
    ? AndroidDebugProvider(debugToken: dotenv.env['APPCHECK_DEBUG_TOKEN_ANDROID'])
    : const AndroidPlayIntegrityProvider();
final appleAppCheckProvider = kDebugMode
    ? AppleDebugProvider(debugToken: dotenv.env['APPCHECK_DEBUG_TOKEN_IOS'])
    : const AppleDeviceCheckProvider();
const appCheckTokenTimeout = Duration(seconds: 12);
// Game Center / Play Games sign-in must not block launch forever when offline.
const gamesSignInTimeout = Duration(seconds: 10);

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
const generatePhotoNumber = 3;
const eulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";

/// ===== AI GENERATION SETTINGS =====
// Image generation runs on Cloud Functions (secrets stay server-side)
const generateTrainPhotoFunction = "generateTrainPhoto";
const generateTrainPhotoRegion = "asia-northeast1";

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
  "Great wall", "Tiananmen Square", "Shanghai", "Guilin", "Stone Forest",
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

// --- AdMob demo ad units ---
//
// Google publishes these and they are the same for every developer, so they are
// constants here rather than .env entries: they are not secret, and keeping them
// in source means a missing .env key can no longer break a debug build.
// Production unit IDs stay in .env, because those are ours.
// Gap above a snackbar, as a share of the drawn height. The bar is pushed up
// from the bottom, so this is what decides how far down from the top it lands
const double snackBarTopGap = 0.08;

// The banner sits bottom right and must stop short of the centre, where the
// road crosses the tracks. 42% of the SCREEN width leaves that gap and clears
// the control row on the left, which needs 0.75h of the 1.778h drawn width when
// the emergency button is showing.
//
// Landscape locked, so MediaQuery's size.width is the device's long side: this
// is 42% of that, and it is the banner width.
//
// Of the screen, not of width(): width() drops the side margins, and 40% of it
// lands under 320 on a phone, below the narrowest standard creative.
const double bannerWidthRatio = 0.42;

// The narrowest standard creative is 320x50. A slot under it cannot be filled
// by one, so the auction falls back on whatever else fits and the fill is
// likely to drop. On an iPhone SE in landscape (667x375) the ratio alone gives
// 266, so a floor is needed to hold this.
//
// This is about fill, not about the SDK refusing. Google documents INVALID as
// returned "if the context is null or the device height cannot be determined
// from the context" and says nothing about a minimum width, so a narrow slot
// returning null is NOT a documented behaviour and must not be claimed as one.
//
// 320 still keeps its distance on the smallest supported device: 320/667 is 48%
// of the screen, the banner starts at 347 and the control row ends at 281.
const double minBannerWidth = 320;

// The widest standard creative is the leaderboard, 728x90 (AdSize.leaderboard,
// ad_containers.dart). Past that width no further standard size becomes
// eligible, so a wider slot costs screen and returns nothing. That makes 728
// the point where widening stops paying, not a number picked for looks.
//
// NOT from Google's documentation. Google says only that adaptive banners
// "select creatives for maximum performance" and publishes no breakdown, so
// treat this as the reasoning behind the value, not a measured fact.
const double maxBannerWidth = 728;

// Ceiling handed to the inline adaptive request, and the cap on the box. Only
// inline takes one; anchored derives its height from the slot width instead
const double maxBannerHeight = 60;

// https://developers.google.com/admob/android/test-ads
// https://developers.google.com/admob/ios/test-ads  (checked 2026-09-02)
// Adaptive banners have their own demo unit. The fixed size ones (6300978111,
// 2934735716) only serve 320x50, making every adaptive size look like 320x50
const String androidBannerTestId = "ca-app-pub-3940256099942544/9214589741";
const String iosBannerTestId = "ca-app-pub-3940256099942544/2435281174";
const String androidRewardedTestId = "ca-app-pub-3940256099942544/5224354917";
const String iosRewardedTestId = "ca-app-pub-3940256099942544/1712485313";
const String androidInterstitialTestId = "ca-app-pub-3940256099942544/1033173712";
const String iosInterstitialTestId = "ca-app-pub-3940256099942544/4411468910";
