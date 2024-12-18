import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'common_function.dart';
import 'constant.dart';
import 'firebase_options.dart';
import 'my_homepage.dart';

const isDebugMode = false;
const defaultIsShowAd = !isDebugMode;
String defaultPlan = isDebugMode ? premiumID: freeID;
const defaultTickets = isDebugMode ? premiumTicketNumber: 0;

final currentDateProvider = StateProvider<int>((ref) => 20240101000000);
final countryNumberProvider = StateProvider<int>((ref) => 3);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Purchases.setLogLevel(LogLevel.debug);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]); //横向き指定
  MobileAds.instance.initialize();
  await dotenv.load(fileName: "assets/.env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
  await permitPhotoAccess();
  await initATTPlugin();
  await initPurchase();
  runApp(const ProviderScope(child: MyApp())
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'LETS CROSSING',
      theme: ThemeData(colorScheme: const ColorScheme.light(primary: redColor)),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
      routes: {'/h' : (_) => MyHomePage()},
      navigatorObservers: <NavigatorObserver>[
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        RouteObserver<ModalRoute>()
      ],
    );
  }
}