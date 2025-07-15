import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'common_extension.dart';
import 'dart:io';

/// ===== AD BANNER WIDGET CLASS =====
// Ad Banner Widget - Handles Google AdMob banner advertisement display
class AdBannerWidget extends HookWidget {
  const AdBannerWidget({super.key});
  @override
  Widget build(BuildContext context) {

    /// ===== AD STATE MANAGEMENT =====
    // State variables for ad loading and display
    final adLoaded = useState(false);
    final adFailedLoading = useState(false);
    final bannerAd = useState<BannerAd?>(null);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    /// ===== AD UNIT ID CONFIGURATION =====
    // Get appropriate banner ad unit ID based on platform and debug mode
    String bannerUnitId() =>
        (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_BANNER_UNIT_ID"):
        (Platform.isIOS || Platform.isMacOS) ? dotenv.get("IOS_BANNER_TEST_ID"):
        (!kDebugMode) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
        dotenv.get("ANDROID_BANNER_TEST_ID");

    /// ===== AD LOADING METHODS =====
    // Load banner ad with error handling and retry logic
    Future<void> loadAdBanner() async {
      final adBanner = BannerAd(
        adUnitId: bannerUnitId(),
        size: AdSize.largeBanner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            'Ad: $ad loaded.'.debugPrint();
            adLoaded.value = true;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            'Ad: $ad failed to load: $error'.debugPrint();
            adFailedLoading.value = true;
            Future.delayed(const Duration(seconds: 30), () {
              if (!adLoaded.value && !adFailedLoading.value) loadAdBanner();
            });
          },
        ),
      );
      adBanner.load();
      bannerAd.value = adBanner;
    }

    /// ===== CONSENT AND AD INITIALIZATION =====
    // Initialize ad consent and load banner ad with proper lifecycle management
    useEffect(() {
      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadConsentForm((ConsentForm consentForm) async {
            var status = await ConsentInformation.instance.getConsentStatus();
            "status: $status".debugPrint();
            if (status == ConsentStatus.required) {
              consentForm.show((formError) async => await loadAdBanner());
            } else {
              await loadAdBanner();
            }
          }, (formError) {
            "formError: $formError".debugPrint();
          });
        } else {
          await loadAdBanner();
        }
      }, (FormError error) {
        "error: ${error.message}: $error".debugPrint();
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // Dispose ad on unmount
    }, []);

    /// ===== AD DISPLAY WIDGET =====
    // Render banner ad widget with proper positioning and sizing
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: context.admobWidth(),
        height: context.admobHeight(),
        child: (adLoaded.value) ? AdWidget(ad: bannerAd.value!): null,
      ),
    );
  }
}
