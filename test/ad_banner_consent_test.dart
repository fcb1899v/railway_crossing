// The Mobile Ads SDK starts only after the consent check allows ads, right before the banner loads.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railroad_crossing/admob_banner.dart';
import 'package:railroad_crossing/splash_hold.dart';

const _ump = 'plugins.flutter.io/google_mobile_ads/ump';
const _ads = 'plugins.flutter.io/google_mobile_ads';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> adCalls;
  late bool canRequestAds;
  late SplashHold hold;
  late List<String> umpCalls;

  String methodOf(ByteData? message) => const StandardMessageCodec().readValue(ReadBuffer(message!)) as String;

  setUp(() {
    adCalls = [];
    canRequestAds = true;
    umpCalls = [];
    hold = SplashHold(elapsed: () => splashMinDuration, delay: (_) async {}, remove: () {});
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Consent is already given unless a test sets canRequestAds to false
    messenger.setMockMessageHandler(_ump, (message) async {
      umpCalls.add(methodOf(message));
      return const StandardMethodCodec().encodeSuccessEnvelope(
          methodOf(message) == 'ConsentInformation#canRequestAds' ? canRequestAds : null);
    });
    // The plugin rejects a null initialize answer, so every SDK start here fails
    messenger.setMockMessageHandler(_ads, (message) async {
      adCalls.add(methodOf(message));
      return const StandardMethodCodec().encodeSuccessEnvelope(null);
    });
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(_ump, null);
    messenger.setMockMessageHandler(_ads, null);
  });

  /// Shows the banner as the home page does, then lets the consent flow and the load settle.
  Future<void> pumpBanner(WidgetTester tester, {bool splashGone = true}) async {
    if (splashGone) await hold.removeWhenReady();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AdBannerWidget(hold: hold))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the Mobile Ads SDK starts after the consent check allows ads, before the banner loads', (tester) async {
    await pumpBanner(tester);
    expect(adCalls, containsAllInOrder(['MobileAds#initialize', 'loadBannerAd']));
  });

  testWidgets('without consent the Mobile Ads SDK never starts and no banner is requested', (tester) async {
    canRequestAds = false;
    await pumpBanner(tester);
    expect(adCalls, isNot(contains('MobileAds#initialize')));
    expect(adCalls, isNot(contains('loadBannerAd')));
  });

  testWidgets('a failed SDK start still loads the banner, and the next banner starts the SDK again', (tester) async {
    await pumpBanner(tester);
    expect(adCalls, contains('loadBannerAd'));
    await tester.pumpWidget(const SizedBox());
    await pumpBanner(tester);
    expect(adCalls.where((m) => m == 'MobileAds#initialize').length, 2);
  });

  testWidgets('while the splash is up no consent request or ad request is made, and both follow once it goes', (tester) async {
    await pumpBanner(tester, splashGone: false);
    expect(umpCalls, isEmpty);
    expect(adCalls, isEmpty);
    await hold.removeWhenReady();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(umpCalls, contains('ConsentInformation#requestConsentInfoUpdate'));
    expect(adCalls, contains('loadBannerAd'));
  });
}
