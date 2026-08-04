import 'dart:async';
import 'dart:io';
import 'package:devicelocale/devicelocale.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ntp/ntp.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common_extension.dart';
import 'constant.dart';

/// ===== APP TRACKING TRANSPARENCY =====
// Initialize App Tracking Transparency for iOS privacy compliance
Future<void> initATTPlugin() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}

/// ===== FIREBASE APP CHECK / AUTH =====
Future<void>? _firebaseReadyFuture;

/// App Check + anonymous Auth. Shared Future; cleared on failure so callers can retry.
Future<void> ensureFirebaseReady() =>
    _firebaseReadyFuture ??= _activateFirebaseServices().catchError((Object e) {
      _firebaseReadyFuture = null;
      throw e;
    });

/// Forces a fresh App Check JWT right before protected API calls.
Future<String> refreshAppCheckToken() async {
  await ensureFirebaseReady();
  final token = await _getAppCheckToken(forceRefresh: true);
  if (!_isValidAppCheckJwt(token)) {
    throw StateError('App Check token refresh returned invalid JWT');
  }
  'App Check token refreshed (length=${token!.length})'.debugPrint();
  return token;
}

Future<void> _activateFirebaseServices() async {
  await FirebaseAppCheck.instance.activate(
    providerAndroid: androidAppCheckProvider,
    providerApple: appleAppCheckProvider,
  );
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  final token = await _obtainValidAppCheckToken();
  'App Check token ready (length=${token.length})'.debugPrint();

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  'Firebase anonymous auth: ${FirebaseAuth.instance.currentUser?.uid}'.debugPrint();
}

/// Returns a real App Check JWT, or throws.
/// Native SDKs can return a non-empty placeholder after attestation failure;
/// that placeholder is what Cloud Functions logs as "Decoding App Check token failed".
Future<String> _obtainValidAppCheckToken() async {
  var token = await _getAppCheckToken(forceRefresh: false);
  if (_isValidAppCheckJwt(token)) {
    return token!;
  }
  'App Check token missing/invalid; forcing refresh'.debugPrint();

  token = await _getAppCheckToken(forceRefresh: true);
  if (_isValidAppCheckJwt(token)) {
    return token!;
  }

  // Last resort on Apple: explicitly activate DeviceCheck and retry once.
  if (Platform.isIOS || Platform.isMacOS) {
    'App Check JWT still invalid; retrying with DeviceCheck provider'.debugPrint();
    await FirebaseAppCheck.instance.activate(
      providerAndroid: androidAppCheckProvider,
      providerApple: const AppleDeviceCheckProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    token = await _getAppCheckToken(forceRefresh: true);
    if (_isValidAppCheckJwt(token)) {
      return token!;
    }
  }

  throw StateError(
    'App Check could not obtain a valid JWT '
    '(got length=${token?.length ?? 0}, parts=${token?.split('.').length ?? 0})',
  );
}

Future<String?> _getAppCheckToken({required bool forceRefresh}) async {
  try {
    return await FirebaseAppCheck.instance
        .getToken(forceRefresh)
        .timeout(appCheckTokenTimeout);
  } on TimeoutException {
    'App Check getToken timed out (forceRefresh=$forceRefresh)'.debugPrint();
    return null;
  } catch (e) {
    'App Check getToken failed (forceRefresh=$forceRefresh): $e'.debugPrint();
    return null;
  }
}

bool _isValidAppCheckJwt(String? token) {
  if (token == null || token.isEmpty) {
    return false;
  }
  // Reject native placeholder / malformed tokens that are non-empty but not JWTs.
  final parts = token.split('.');
  return parts.length == 3 && parts.every((part) => part.isNotEmpty);
}

/// ===== PURCHASE INITIALIZATION =====
Future<void>? _purchaseInitFuture;

/// RevenueCat configure. Shared Future across concurrent callers.
Future<void> ensurePurchaseInitialized() =>
    _purchaseInitFuture ??= _configurePurchases();

Future<void> _configurePurchases() async {
  if (await Purchases.isConfigured) {
    return;
  }
  await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
  await Purchases.configure(PurchasesConfiguration(revenueCatApiKey));
  await Purchases.enableAdServicesAttributionTokenCollection();
  Purchases.addReadyForPromotedProductPurchaseListener((productID, startPurchase) async {
    'productID: $productID'.debugPrint();
    try {
      final purchaseResult = await startPurchase.call();
      'productID: ${purchaseResult.productIdentifier}'.debugPrint();
      'customerInfo: ${purchaseResult.customerInfo}'.debugPrint();
    } catch (e) {
      'Error: $e'.debugPrint();
    }
  });
}

/// Post-runApp bootstrap: await shared Firebase/IAP init, then sync NTP.
Future<void> bootstrapAfterLaunch() async {
  try {
    await ensureFirebaseReady();
  } catch (e) {
    'Firebase App Check / auth bootstrap failed: $e'.debugPrint();
  }
  try {
    await ensurePurchaseInitialized();
  } catch (e) {
    'RevenueCat bootstrap failed: $e'.debugPrint();
  }
  try {
    await getServerDateTime();
  } catch (e) {
    'NTP bootstrap failed: $e'.debugPrint();
  }
}

/// ===== SERVER TIME MANAGEMENT =====

// Get current DateTime from NTP server for accurate time synchronization
Future<int> getServerDateTime() async {
  try {
    final serverDateTime = await NTP.now();
    final utcDateTime = serverDateTime.toUtc();
    final localDateTime = utcDateTime.toLocal();
    final localIntDateTime = localDateTime.intDateTime();
    'Fetch server local time successfully: $localDateTime'.debugPrint();
    'currentDate: $localIntDateTime'.debugPrint();
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('cachedServerDate', localIntDateTime);
    prefs.setInt(
      'cachedServerDateAtMs',
      DateTime.now().millisecondsSinceEpoch,
    );
    return localIntDateTime;
  } catch (e) {
    'Failed to fetch time: $e'.debugPrint();
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt('cachedServerDate');
    if (cached != null) {
      'Using cached server date: $cached'.debugPrint();
      return cached;
    }
    return defaultIntDateTime;
  }
}

/// ===== COUNTRY CODE MANAGEMENT =====
// Get country code with fallback to local device locale
Future<String> getCountryCode(SharedPreferences prefs) async {
  final countryCode = "countryCode".getSharedPrefString(prefs, "OTH");
  return (countryCode != "OTH") ? countryCode:
         // (Platform.isIOS || Platform.isMacOS) ? await getStoreFrontCountryCode(prefs):
         await getLocalCountryCode(prefs);
}

// Get country code from device locale settings
Future<String> getLocalCountryCode(SharedPreferences prefs) async {
  try {
    final locale = await Devicelocale.currentLocale ?? "en-US";
    // Locale can be "en-US", "ja_JP", "en", "ja" - avoid substring(3,5) on short strings
    String countryCode = "US";
    if (locale.length >= 5) {
      countryCode = locale.substring(3, 5).toUpperCase();
    } else if (locale.contains("-") || locale.contains("_")) {
      final parts = locale.split(RegExp(r'[-_]'));
      if (parts.length >= 2 && parts[1].length >= 2) {
        countryCode = parts[1].substring(0, 2).toUpperCase();
      }
    }
    "countryCode".setSharedPrefString(prefs, countryCode);
    return countryCode;
  } catch (e) {
    "getLocalCountryCode error: $e".debugPrint();
    "countryCode".setSharedPrefString(prefs, "US");
    return "US";
  }
}

// Get country code from App Store/Play Store front (iOS/Android specific)
Future<String> getStoreFrontCountryCode(SharedPreferences prefs) async {
  final channel = MethodChannel(storeFrontUrl);
  final countryCode = await channel.invokeMethod<String>("getStorefrontCountryCode");
  "countryCodeByStoreFront: $countryCode".debugPrint();
  prefs.setString("countryCode", (countryCode == null) ? "OTH": countryCode);
  return (countryCode == null) ? "OTH": countryCode;
}


