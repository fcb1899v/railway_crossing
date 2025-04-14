import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:ntp/ntp.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common_extension.dart';
import 'constant.dart';

///App Tracking Transparency
Future<void> initATTPlugin() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}

///Purchase
initPurchase() async {
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

Future<String> loadPrice(SharedPreferences prefs) async {
  final price = prefs.getString("onetime_price") ?? defaultPrice;
  "Passes price: $price".debugPrint();
  if (price == "-") {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(normalOffering);
      final package = offering!.availablePackages[0];
      final storeProduct = package.storeProduct;
      final newPrice = storeProduct.priceString;
      prefs.setString("onetime_price", newPrice);
      "Get passes price: $newPrice".debugPrint();
      return newPrice;
    } catch (e) {
      "Passes price: $defaultOnetimePrice".debugPrint();
      return defaultOnetimePrice;
    }
  } else {
    return price;
  }
}

/// Photo Access
Future<void> permitPhotoAccess() async {
  final androidSDK = await getAndroidSDK();
  final photoPermission = await (androidSDK < 33 ? Permission.storage.status: Permission.photos.status);
  "Photo permission: $photoPermission".debugPrint();
  if (photoPermission != PermissionStatus.granted) {
    try {
      await (androidSDK < 33 ? Permission.storage.request(): Permission.photos.request());
      "Photo permission request: $photoPermission".debugPrint();
    } on PlatformException catch (e) {
      "Photo permission error: $e".debugPrint();
    }
  }
}

/// Get current DateTime from server
Future<int> getServerDateTime() async {
  try {
    final serverDateTime = await NTP.now();
    final utcDateTime = serverDateTime.toUtc();
    final localDateTime = utcDateTime.toLocal();
    final localIntDateTime = localDateTime.intDateTime();
    'Fetch server local time successfully: $localDateTime'.debugPrint();
    return localIntDateTime;
  } catch (e) {
    'Failed to fetch time: $e'.debugPrint();
    return defaultIntDateTime;
  }
}

/// Get Android SDK version
Future<int> getAndroidSDK() async {
  final prefs = await SharedPreferences.getInstance();
  final androidSDK = prefs.getInt("androidSDK") ?? 0;
  if (androidSDK == 0) {
    if (Platform.isIOS || Platform.isMacOS) return 100;
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;
      prefs.setInt("androidSDK", sdkVersion);
      "Android SDK version: $sdkVersion".debugPrint();
      return sdkVersion;
    } on PlatformException {
      return 0;
    }
  } else {
    return androidSDK;
  }
}

Future<String> getStoreFrontCountryCode(SharedPreferences prefs) async {
  final channel = MethodChannel(storeFrontUrl);
  final countryCode = await channel.invokeMethod<String>("getStorefrontCountryCode");
  "countryCodeByStoreFront: $countryCode".debugPrint();
  prefs.setString("countryCode", (countryCode == null) ? "OTH": countryCode);
  return (countryCode == null) ? "OTH": countryCode;
}

Future<String> getLocalCountryCode(SharedPreferences prefs) async {
  final locale = await Devicelocale.currentLocale ?? "en-US";
  final countryCode = locale.substring(3, 5);
  prefs.setString("countryCode", countryCode);
  return countryCode;
}

Future<String> getCountryCode(SharedPreferences prefs) async {
  final countryCode = prefs.getString("countryCode") ?? "OTH";
  return (countryCode != "OTH") ? countryCode:
         // (Platform.isIOS || Platform.isMacOS) ? await getStoreFrontCountryCode(prefs):
         await getLocalCountryCode(prefs);
}

///LifecycleEventHandler
class LifecycleEventHandler extends WidgetsBindingObserver {
  // final AsyncCallback resumeCallBack;
  // final AsyncCallback suspendingCallBack;
  final Future<void> Function()? detachedCallBack;
  // LifecycleEventHandler({required this.resumeCallBack, required this.suspendingCallBack, required this.detachedCallBack});
  LifecycleEventHandler({required this.detachedCallBack});
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // case AppLifecycleState.resumed:
      //   resumeCallBack();
      //   break;
      // case AppLifecycleState.paused:
      //   suspendingCallBack();
      //   break;
      case AppLifecycleState.detached:
        if (detachedCallBack != null) detachedCallBack!();
        break;
      default:
        break;
    }
  }
}

loadVertexAIToken(BuildContext context) async {
  final jsonString = await DefaultAssetBundle.of(context).loadString('assets/letscrossing-app-804542f853dd.json');
  final serviceAccountKey =  jsonDecode(jsonString);
  final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountKey);
  final authClient = await clientViaServiceAccount(
    accountCredentials,
    ['https://www.googleapis.com/auth/cloud-platform'],
  );
  authClient.credentials.accessToken.data.debugPrint();
  return authClient.credentials.accessToken.data;
}

class AudioPlayerManager {
  // シングルトンインスタンス
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  final List<AudioPlayer> audioPlayers = [];
  // AudioPlayerのインスタンスを初期化
  AudioPlayerManager._internal() {
    for (int i = 0; i < audioPlayerNumber; i++) {
      final player = AudioPlayer();
      player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: <AVAudioSessionOptions>{},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      audioPlayers.add(player);
    }
  }
  /// 全ての AudioPlayer を dispose する
  Future<void> disposeAll() async {
    for (var player in audioPlayers) {
      try {
        await player.dispose();
      } catch (e) {
        'Error disposing AudioPlayer: $e'.debugPrint();
      }
    }
  }
}

// アプリが終了する際に disposeAll を呼び出す
void handleLifecycleChange(AppLifecycleState state) {
  if (state == AppLifecycleState.detached) {
    AudioPlayerManager().disposeAll();
  }
}
