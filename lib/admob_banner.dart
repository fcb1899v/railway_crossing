import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'common_extension.dart';
import 'dart:io';
import 'constant.dart';

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
    // The size Google served, not the one asked for.
    // Inline adaptive reports height 0 until the ad lands, so only getPlatformAdSize knows the box.
    final adSize = useRef<AdSize?>(null);
    final sizeReady = useState(0);
    // Ref, not state: consent callbacks can resolve after dispose, and a disposed ValueNotifier asserts in debug.
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    /// ===== AD UNIT ID CONFIGURATION =====
    // Get appropriate banner ad unit ID based on platform and debug mode
    String bannerUnitId() =>
        (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_BANNER_UNIT_ID"):
        (Platform.isIOS || Platform.isMacOS) ? iosBannerTestId:
        (!kDebugMode) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
        androidBannerTestId;

    /// ===== AD LOADING METHODS ===== (the 30 s re-request below never fires: the guard
    /// requires adFailedLoading false; slotWidth is the LayoutBuilder width, not the screen)
    Future<void> loadAdBanner(int slotWidth) async {
      // Anchored derives the height from the slot width and cannot be capped.
      // Inline takes maxBannerHeight as the ceiling and Google picks under it.
      final size = AdSize.getInlineAdaptiveBannerAdSize(
          slotWidth, maxBannerHeight.toInt());
      final adBanner = BannerAd(
        adUnitId: bannerUnitId(),
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) async {
            'Ad: $ad loaded.'.debugPrint();
            // Mount first; behind the await the ad never shows if it throws
            if (context.mounted) adLoaded.value = true;
            final served = await (ad as BannerAd).getPlatformAdSize();
            'AdSize: ${size.width} x cap ${maxBannerHeight.toInt()} / served: ${served?.width} x ${served?.height} (slot: $slotWidth)'.debugPrint();
            // The box follows what was served, so a short creative leaves no gap.
            // Nothing is laid out against this overlay, so it can move.
            if (!context.mounted) return;
            adSize.value = served;
            sizeReady.value++;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            'Ad: $ad failed to load: $error'.debugPrint();
            if (!context.mounted) return;
            adFailedLoading.value = true;
            Future.delayed(const Duration(seconds: 30), () {
              if (!adLoaded.value && !adFailedLoading.value) loadAdBanner(slotWidth);
            });
          },
        ),
      );
      adBanner.load();
      bannerAd.value = adBanner;
    }

    /// ===== CONSENT GATE ===== canRequestAds is the SDK's own verdict (region, TCF,
    /// Additional Consent); the app must not read ConsentStatus and decide for itself
    Future<void> requestAdIfAllowed(int slotWidth) async {
      if (isAdRequested.value) return;
      // Log it: a silent stop looks identical to an ad that was requested and never filled.
      if (!await ConsentInformation.instance.canRequestAds()) {
        'Ad: consent gate closed, no request made'.debugPrint();
        return;
      }
      // Today only one caller runs per launch; this guard is kept for a third caller.
      // The claim follows this check with no await in between.
      if (isAdRequested.value) return;
      isAdRequested.value = true;
      await loadAdBanner(slotWidth);
    }

    /// ===== CONSENT AND AD INITIALIZATION ===== The slot width is only known in
    /// LayoutBuilder, so it lands in a ref and the effect waits for the first non zero value
    final slotWidthRef = useRef<int>(0);
    final hasWidth = useState(false);

    // Initialize ad consent and load banner ad with proper lifecycle management
    useEffect(() {
      if (!hasWidth.value) return null;
      final slotWidth = slotWidthRef.value;
      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        // The SDK decides whether a form is required.
        // Do not load the ad from the form callback: it fires on close no matter what the user chose.
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed(slotWidth);
        });
      }, (FormError error) async {
        // The update failed, but earlier consent can still make canRequestAds true, so do not stop here.
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        await requestAdIfAllowed(slotWidth);
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // Dispose ad on unmount
    }, [hasWidth.value]);

    /// ===== AD DISPLAY WIDGET ===== sizeReady exists only to rebuild once the size
    /// resolves; useState subscribes on its own, so there is nothing to read here
    return LayoutBuilder(builder: (context, constraints) {
      // The constraint is the whole screen, so the cap comes from the art: a screen ratio clamped to [320, 728].
      // Google keeps the width, so this is the box width too.
      final free = context.bannerSlotWidth();
      final available =
          constraints.maxWidth > free ? free : constraints.maxWidth;
      if (available.isFinite && available > 0 && slotWidthRef.value == 0) {
        slotWidthRef.value = available.truncate();
        // Set after this frame: hasWidth drives an effect, and flipping it during build rebuilds mid-build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) hasWidth.value = true;
        });
      }
      // The served size; until it lands the box holds the old admob size.
      // That is not load bearing: this is a non-positioned child of the home Stack.
      final size = adSize.value;
      final boxHeight = (size?.height.toDouble() ?? context.admobHeight())
          .clamp(0.0, maxBannerHeight);
      return Align(
        alignment: Alignment.bottomRight,
        child: SizedBox(
          width: size?.width.toDouble() ?? context.admobWidth(),
          height: boxHeight,
          child: (adLoaded.value && bannerAd.value != null)
              ? AdWidget(ad: bannerAd.value!)
              : null,
        ),
      );
    });
  }
}
