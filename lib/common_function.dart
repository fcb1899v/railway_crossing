import 'dart:convert';
import 'dart:io';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:ntp/ntp.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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

/// Photo Access
Future<void> permitPhotoAccess() async {
  final isAndroidUnder33 = await isAndroidSDKUnder33();
  final photoPermission = await (isAndroidUnder33 ? Permission.storage.status: Permission.photos.status);
  "Photo permission: $photoPermission".debugPrint();
  if (photoPermission != PermissionStatus.granted) {
    try {
      await (isAndroidUnder33 ? Permission.storage.request(): Permission.photos.request());
      "Photo permission request: $photoPermission".debugPrint();
    } on PlatformException catch (e) {
      "Photo permission error: $e".debugPrint();
    }
  }
}


/// Get current DateTime from server
Future<int> getServerDateTime(int currentDate) async {
  if (currentDate == 20240101000000) {
    try {
      final serverDateTime = await NTP.now();
      final utcDateTime = serverDateTime.toUtc().intDateTime();
      'Fetch server utc time successfully: $utcDateTime'.debugPrint();
      return utcDateTime;
    } catch (e) {
      'Failed to fetch time: $e'.debugPrint();
      return 20240101000000;
    }
  } else {
    return currentDate;
  }
}

/// Get Android SDK version
Future<bool> isAndroidSDKUnder33() async {
  if (Platform.isIOS || Platform.isMacOS) return false;
  try {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final sdkVersion = androidInfo.version.sdkInt;
    "Android SDK version: $sdkVersion".debugPrint();
    return (sdkVersion < 33);
  } on PlatformException {
    return false;
  }
}

Future<bool> isAppleMainLandChinaByStorefront() async {
  if (!Platform.isIOS && !Platform.isMacOS) return false;
  try {
    final channel = MethodChannel('nakajimamasao.appstudio.railwaycrossing/storefront');
    final countryCode = await channel.invokeMethod<String>("getStorefrontCountryCode");
    "countryCodeByStoreFront: $countryCode".debugPrint();
    return (countryCode == "CHN");
  } catch (e) {
    'Error getting storefront country code: $e'.debugPrint();
    return true;
  }
}

///CountryNumber
Future<int> getDefaultCountryNumber(BuildContext context) async {
  final locale = await Devicelocale.currentLocale ?? "en-US";
  final countryCode = locale.substring(3, 5);
  final countryNumber = (countryCode == "JP") ? 0:
                        (countryCode == "GB") ? 1:
                        (countryCode == "CN") ? 2:
                        3;
  "countryCode: $countryCode, countryNumber: $countryNumber".debugPrint();
  return countryNumber;
}

///LifecycleEventHandler
class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;
  final AsyncCallback suspendingCallBack;
  LifecycleEventHandler({required this.resumeCallBack, required this.suspendingCallBack});
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        resumeCallBack();
        break;
      case AppLifecycleState.paused:
        suspendingCallBack();
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

