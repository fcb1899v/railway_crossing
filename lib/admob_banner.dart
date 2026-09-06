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
    // The size Google served, not the one asked for. Inline adaptive reports
    // height 0 until the ad lands, so only getPlatformAdSize knows the box
    final adSize = useRef<AdSize?>(null);
    final sizeReady = useState(0);
    // Ref, not state: the consent callbacks resolve after this widget can be
    // gone, and writing to a disposed ValueNotifier asserts in debug
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    /// ===== AD UNIT ID CONFIGURATION =====
    // Get appropriate banner ad unit ID based on platform and debug mode
    String bannerUnitId() =>
        (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_BANNER_UNIT_ID"):
        (Platform.isIOS || Platform.isMacOS) ? iosBannerTestId:
        (!kDebugMode) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
        androidBannerTestId;

    /// ===== AD LOADING METHODS =====
    // Load banner ad with error handling. The 30 second re-request below never
    // fires: adFailedLoading is set right before it and the guard requires it
    // to be false. Left as it was rather than switched on here, because making
    // it live changes how often this app asks Google for an ad
    // slotWidth comes from LayoutBuilder, so it is the width this slot really
    // gets, capped below. MediaQuery would be the whole screen, which is not
    // what the banner occupies
    Future<void> loadAdBanner(int slotWidth) async {
      // Anchored derives the height from the slot width and cannot be capped;
      // inline takes maxBannerHeight as the ceiling and Google picks under it
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
            // The box follows what was served, so a short creative leaves no
            // gap. Nothing is laid out against this overlay, so it can move
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

    /// ===== CONSENT GATE =====
    // The single gate for the ad request. canRequestAds is the SDK's own
    // verdict: it already weighs the region, the TCF consent string and
    // Additional Consent, so the app must not read ConsentStatus and decide for
    // itself. A false answer also covers "the SDK could not tell", and letting
    // that through is exactly what serving without consent looks like in the EEA
    Future<void> requestAdIfAllowed(int slotWidth) async {
      if (isAdRequested.value) return;
      // Say so. Stopping here is silent otherwise, and it looks identical to an
      // ad that was requested and never filled
      if (!await ConsentInformation.instance.canRequestAds()) {
        'Ad: consent gate closed, no request made'.debugPrint();
        return;
      }
      // The two callers cannot both run: requestConsentInfoUpdate calls either
      // its success or its failure listener, never both
      // (user_messaging_channel.dart), and the form callback fires once
      // (consent_form.dart). So this is one request per launch and the double
      // check never decides anything today. It is kept as the guard a third
      // caller would need, since claiming happens with no await in between
      if (isAdRequested.value) return;
      isAdRequested.value = true;
      await loadAdBanner(slotWidth);
    }

    /// ===== CONSENT AND AD INITIALIZATION =====
    // The slot width is only known inside LayoutBuilder, which runs during
    // build. The consent flow must start once, not on every layout pass, so the
    // width lands in a ref and the effect waits for the first non zero value
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
        // The SDK decides whether a form is required, loads it and presents it.
        // The old flow called loadAdBanner from the consent form callback, which
        // fires when the form closes no matter what the user chose, so a user
        // who declined still got an ad request
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed(slotWidth);
        });
      }, (FormError error) async {
        // The update failed, but consent given in an earlier session still
        // stands and canRequestAds can still say yes. Stopping here would throw
        // away impressions the SDK would have allowed
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        await requestAdIfAllowed(slotWidth);
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // Dispose ad on unmount
    }, [hasWidth.value]);

    /// ===== AD DISPLAY WIDGET =====
    // sizeReady exists only to rebuild once the size resolves. useState
    // subscribes on its own (flutter_hooks primitives.dart), so bumping it is
    // enough and there is nothing to read here
    return LayoutBuilder(builder: (context, constraints) {
      // This widget sits straight in the home Stack (homepage.dart:571), so the
      // constraint is the whole screen and the cap has to come from the art.
      // Three limits apply, and the tightest one wins:
      //
      //   bannerWidthRatio       screen width * 0.40   stops short of the
      //                                                centre, where the road
      //                                                crosses the tracks
      //   clear of the controls  see below              the row must not be
      //                                                covered
      //   maxBannerWidth         728                   past the leaderboard no
      //                                                further standard size
      //                                                becomes eligible
      //
      // The control row and the banner are measured in screen coordinates, not
      // in width(), or the two numbers would not be comparable:
      //
      //   controls end at   sideMargin() + 5 * 0.15h    five buttons at 0.12h
      //                                                 each plus a 0.03h
      //                                                 margin, emergency
      //                                                 showing
      //   banner starts at  mediaWidth() * 0.60
      //
      // On an iPhone 16 Pro in landscape (874x402) that is 79.7 + 301.5 = 381
      // against 525, so 144 apart.
      //
      // The ratio is of the screen, not of width(): width() takes off the side
      // margins, and 40% of that gives 285 on an iPhone 16 Pro where the screen
      // gives 349. minBannerWidth then holds the floor at 320, which the ratio
      // alone misses on the smallest supported device - an iPhone SE in
      // landscape (667x375) works out at 266.
      //
      // 320x50 is the narrowest standard creative, so a slot under it has none
      // to fill it and the fill rate is likely to suffer. That is the whole
      // claim: Google documents INVALID as returned "if the context is null or
      // the device height cannot be determined from the context" and states no
      // minimum width, so a narrow slot returning null is not a documented
      // behaviour. The log line above will say if it ever happens.
      //
      // The ratio binds on nearly every device, so in practice the slot lands
      // under 728 and the leaderboard cannot fill it. That is the price of
      // keeping the banner off the centre of the crossing.
      //
      // Google only optimizes the height: whatever width goes in comes back out
      // unchanged (ad_containers.dart:522-526), so this is the box width too.
      final free = context.bannerSlotWidth();
      final available =
          constraints.maxWidth > free ? free : constraints.maxWidth;
      if (available.isFinite && available > 0 && slotWidthRef.value == 0) {
        slotWidthRef.value = available.truncate();
        // Set after this frame: hasWidth drives an effect, and flipping it
        // during build would rebuild while the tree is still being built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) hasWidth.value = true;
        });
      }
      // The served size. Until it lands the box holds the old admob size, which
      // is not load bearing: this is a non-positioned child of the home Stack
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
