import 'dart:async';
import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:railroad_crossing/common_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'firebase_options.dart';
import 'common_function.dart';
import 'constant.dart';
import 'homepage.dart';

/// ===== DEBUG CONFIGURATION =====
// Debug mode configuration for development and testing
const isDebugMode = false;
const defaultIsShowAd = !isDebugMode;
String defaultPlan = isDebugMode ? premiumID: freeID;
const defaultTickets = isDebugMode ? premiumTicketNumber: 0;

/// ===== STATE PROVIDERS =====
// State providers for app-wide state management using Riverpod
final countryProvider = StateProvider<int>((ref) => 3);           // Selected country (0-3)
final ticketsProvider = StateProvider<int>((ref) => 0);           // Available tickets count
final currentProvider = StateProvider<int>((ref) => defaultIntDateTime); // Current server time
final expirationProvider = StateProvider<int>((ref) => defaultIntDateTime); // Premium expiration date
final lastClaimedProvider = StateProvider<int>((ref) => defaultIntDateTime); // Last claimed date
final loadingProvider = StateProvider<bool>((ref) => false);      // Loading state indicator
final photoProvider = StateProvider<List<Uint8List>>((ref) => []); // Generated photo images

/// Main application entry point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  /// ===== UI CONFIGURATION =====
  // Configure system UI, orientation, and platform-specific styling
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  } else {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }
  /// ===== ENVIRONMENT AND DATA LOADING =====
  // Load environment variables and restore user preferences from SharedPreferences
  await dotenv.load(fileName: "assets/.env");

  // Load saved user preferences and current date
  final prefs = await SharedPreferences.getInstance();
  final countryCode = await getCountryCode(prefs);
  final savedCountryNumber = countryCode.getCountryNumber();
  final savedTickets = "tickets".getSharedPrefInt(prefs, 0);
  final currentDate = await getServerDateTime();
  final savedExpirationDate = 'expiration'.getSharedPrefInt(prefs, defaultIntDateTime);
  final savedLastClaimedDate = 'lastClaim'.getSharedPrefInt(prefs, defaultIntDateTime);

  /// ===== FIREBASE AND ADS INITIALIZATION =====
  // Initialize Firebase services and mobile ads
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  await MobileAds.instance.initialize();  // Initialize ads
  await initATTPlugin();
  await initPurchase();
  /// ===== APP LAUNCH =====
  // Launch app with provider overrides for saved state
  runApp(ProviderScope(
    overrides: [
      countryProvider.overrideWith((ref) => savedCountryNumber),
      ticketsProvider.overrideWith((ref) => savedTickets),
      currentProvider.overrideWith((ref) => currentDate),
      expirationProvider.overrideWith((ref) => savedExpirationDate),
      lastClaimedProvider.overrideWith((ref) => savedLastClaimedDate),
    ],
    child: MyApp()
  ));
}

/// Main application widget - Configures MaterialApp with localization and analytics
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// ===== APP CONFIGURATION =====
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'LETS CROSSING',
      theme: ThemeData(colorScheme: const ColorScheme.light(primary: redColor)),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      routes: {'/h' : (_) => HomePage()},
      navigatorObservers: <NavigatorObserver>[
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        RouteObserver<ModalRoute>()
      ],
    );
  }
}

