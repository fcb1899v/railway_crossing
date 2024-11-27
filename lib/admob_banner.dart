import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'common_extension.dart';
import 'dart:io';

class AdBannerWidget extends HookWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {

    final adLoaded = useState(false);
    final adFailedLoading = useState(false);
    final bannerAd = useState<BannerAd?>(null);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // バナー広告ID
    String bannerUnitId() =>
        (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_BANNER_UNIT_ID"):
        (Platform.isIOS || Platform.isMacOS) ? dotenv.get("IOS_BANNER_TEST_ID"):
        (!kDebugMode) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
        dotenv.get("ANDROID_BANNER_TEST_ID");

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
      return () => bannerAd.value?.dispose();      // unmount時に広告を破棄する
    }, []);

    return Container(
      margin: EdgeInsets.only(top: context.admobTopMargin()),
      width: context.admobWidth(),
      height: context.admobHeight(),
      child: Transform.rotate(
        angle: context.admobRotationAngle(),
        child: (adLoaded.value) ? AdWidget(ad: bannerAd.value!): null,
      ),
    );
  }
}

adLeftBanner(BuildContext context) => Transform.translate(
  offset: Offset(-context.admobOffset(), 0),
  child: Container(
    alignment: Alignment.topLeft,
    child: const AdBannerWidget()
  ),
);

adCenterBanner(BuildContext context) => Container(
  margin: EdgeInsets.symmetric(horizontal: (context.mediaWidth() - context.admobWidth())/2),
  alignment: Alignment.topCenter,
  child: const AdBannerWidget()
);

adRightBanner(BuildContext context) => Transform.translate(
  offset: Offset(context.admobOffset(), 0),
  child: Container(
    alignment: Alignment.topRight,
    child: const AdBannerWidget()
  ),
);

adMobBanner(BuildContext context) =>
  (context.isAdmobEnoughSideSpace()) ? Row(children: [
    adLeftBanner(context),
    const Spacer(),
    adRightBanner(context),
  ]): adCenterBanner(context);
