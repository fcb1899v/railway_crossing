import 'dart:io';
import 'package:devicelocale/devicelocale.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
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

/// ===== PURCHASE INITIALIZATION =====
// Initialize RevenueCat purchase system with configuration and listeners
Future<void> initPurchase() async {
  await Purchases.setLogLevel(LogLevel.debug);
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
    return localIntDateTime;
  } catch (e) {
    'Failed to fetch time: $e'.debugPrint();
    return defaultIntDateTime;
  }
}

/// ===== PRICE LIST MANAGEMENT =====
// Load and update price list from RevenueCat offerings
// Future<List<String>> loadPriceList(SharedPreferences prefs) async {
//   final priceList = prefs.getStringList("price") ?? defaultPriceList;
//   "Price List: $priceList".debugPrint();
//   if (priceList[0] == "-") {
//     final offerings = await Purchases.getOfferings();
//     final newPriceList = List<String>.from(defaultPriceList);
//     offerings.all.forEach((key, offering) {
//       for (var package in offering.availablePackages) {
//         final storeProduct = package.storeProduct;
//         final price = storeProduct.priceString;
//         newPriceList[storeProduct.identifier.planNumber()] = price;
//       }
//     });
//     prefs.setStringList("price", newPriceList);
//     "Get Price List: $newPriceList".debugPrint();
//     return newPriceList;
//   } else {
//     return priceList;
//   }
// }

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


