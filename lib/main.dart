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
import 'package:flutter_native_splash/flutter_native_splash.dart';
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

/// ===== STATE PROVIDERS (Riverpod 3 Notifier API, no legacy) =====
// Notifier classes for app-wide state management (state updated via public methods)
class CountryNotifier extends Notifier<int> {
  @override
  int build() => 3;
  void update(int value) => state = value;
}
class _OverrideCountryNotifier extends CountryNotifier {
  _OverrideCountryNotifier(this.initial);
  final int initial;
  @override
  int build() => initial;
}

class TicketsNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void update(int value) => state = value;
}
class _OverrideTicketsNotifier extends TicketsNotifier {
  _OverrideTicketsNotifier(this.initial);
  final int initial;
  @override
  int build() => initial;
}

class CurrentNotifier extends Notifier<int> {
  @override
  int build() => defaultIntDateTime;
  void update(int value) => state = value;
}
class _OverrideCurrentNotifier extends CurrentNotifier {
  _OverrideCurrentNotifier(this.initial);
  final int initial;
  @override
  int build() => initial;
}

class ExpirationNotifier extends Notifier<int> {
  @override
  int build() => defaultIntDateTime;
  void update(int value) => state = value;
}
class _OverrideExpirationNotifier extends ExpirationNotifier {
  _OverrideExpirationNotifier(this.initial);
  final int initial;
  @override
  int build() => initial;
}

class LastClaimedNotifier extends Notifier<int> {
  @override
  int build() => defaultIntDateTime;
  void update(int value) => state = value;
}
class _OverrideLastClaimedNotifier extends LastClaimedNotifier {
  _OverrideLastClaimedNotifier(this.initial);
  final int initial;
  @override
  int build() => initial;
}

class LoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool value) => state = value;
}

class PhotoNotifier extends Notifier<List<Uint8List>> {
  @override
  List<Uint8List> build() => [];
  void update(List<Uint8List> value) => state = value;
}

final countryProvider = NotifierProvider<CountryNotifier, int>(CountryNotifier.new);
final ticketsProvider = NotifierProvider<TicketsNotifier, int>(TicketsNotifier.new);
final currentProvider = NotifierProvider<CurrentNotifier, int>(CurrentNotifier.new);
final expirationProvider = NotifierProvider<ExpirationNotifier, int>(ExpirationNotifier.new);
final lastClaimedProvider = NotifierProvider<LastClaimedNotifier, int>(LastClaimedNotifier.new);
final loadingProvider = NotifierProvider<LoadingNotifier, bool>(LoadingNotifier.new);
final photoProvider = NotifierProvider<PhotoNotifier, List<Uint8List>>(PhotoNotifier.new);

/// Main application entry point
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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
  /// ===== REVENUE CAT INITIALIZATION =====
  await initPurchase();
  /// ===== APP LAUNCH =====
  // Launch app with provider overrides for saved state
  runApp(ProviderScope(
    overrides: [
      countryProvider.overrideWith(() => _OverrideCountryNotifier(savedCountryNumber)),
      ticketsProvider.overrideWith(() => _OverrideTicketsNotifier(savedTickets)),
      currentProvider.overrideWith(() => _OverrideCurrentNotifier(currentDate)),
      expirationProvider.overrideWith(() => _OverrideExpirationNotifier(savedExpirationDate)),
      lastClaimedProvider.overrideWith(() => _OverrideLastClaimedNotifier(savedLastClaimedDate)),
    ],
    child: const MyApp()
  ));
  /// ===== Post-Launch Services =====
  // Initialize additional services after app launch (Firebase App Check, ads, tracking)
  await FirebaseAppCheck.instance.activate(
    providerAndroid: androidAppCheckProvider,
    providerApple: appleAppCheckProvider,
  );
  await MobileAds.instance.initialize();  // Initialize ads
  await initATTPlugin();
}

/// ===== Main application widget =====
// - Configures MaterialApp with localization and analytics
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    /// ===== Localization =====
    // Multi-language support configuration
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    /// ===== App Configuration =====
    // Basic app settings and theme
    title: 'LETS CROSSING',
    theme: ThemeData(colorScheme: const ColorScheme.light(primary: redColor)),
    debugShowCheckedModeBanner: false,
    /// ===== Routing =====
    // Navigation routes to different app screens
    initialRoute: "/h",
    routes: {'/h' : (_) => HomePage()},
    /// ===== Navigation Observers =====
    // Track navigation for analytics and debugging
    navigatorObservers: <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      RouteObserver<ModalRoute>()
    ],
  );
}

