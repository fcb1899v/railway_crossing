import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common_widget.dart';
import 'common_extension.dart';
import 'constant.dart';

/// ===== PHOTO MANAGER CLASS =====
// Photo Manager Class - Handles photo generation, sharing, saving, and permissions
class PhotoManager {
  final BuildContext context;
  final int currentDate;

  PhotoManager({
    required this.context,
    required this.currentDate,
  });

  /// ===== PHOTO SHARING METHODS =====
  // Share photo image to external apps with temporary file creation
  Future<void> sharePhoto({
    required List<Uint8List> imageList,
    required int index,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/shared_image.png';
      final file = File(filePath);
      await file.writeAsBytes(imageList[index]);
      final params = ShareParams(
        text: 'Share train photo',
        files: [XFile(filePath)],
      );
      final result = await SharePlus.instance.share(params);
      "Sharing ${(result.status == ShareResultStatus.success) ? 'successfully': 'failed'}".debugPrint();
    } catch (e) {
      'Sharing error: $e'.debugPrint();
    }
  }

  /// ===== PHOTO SAVING METHODS =====
  // Save photo to device gallery with success/failure feedback
  Future<bool> savePhoto({
    required List<Uint8List> imageList,
    required int index,
  }) async {
    final common = CommonWidget(context: context);
    try {
      final result = await ImageGallerySaverPlus.saveImage(imageList[index]);
      "result: $result".debugPrint();
      if (context.mounted) {
        (result['isSuccess'] ? context.photoSaved() : context.photoSavingFailed()).debugPrint();
        common.showSnackBar(result['isSuccess'] ? context.photoSaved() : context.photoSavingFailed(), !result['isSuccess']);
      }
      "Save photo: $result".debugPrint();
      return result['isSuccess'] ?? false;
    } catch (e) {
      if (context.mounted) '${context.photoCaptureFailed()}: $e'.debugPrint();
      if (context.mounted) common.showSnackBar(context.photoCaptureFailed(), true);
      return false;
    }
  }

  /// ===== FREE PHOTO GENERATION =====
  // Get free photo from bundled assets based on country and date
  Future<List<Uint8List>> getFreePhoto(int countryNumber) async {
    "getFreePhoto".debugPrint();
    final byteData = await rootBundle.load(countryNumber.countryFreePhoto(currentDate));
    return [byteData.buffer.asUint8List()];
  }

  /// ===== AI PHOTO GENERATION (Cloud Functions) =====
  // Secrets stay on the server; client sends prompt + App Check + Auth only.
  Future<List<Uint8List>> getGenerativeAIPhoto(int countryNumber) async {
    "getGenerateTrainPhotoViaFunctions".debugPrint();
    final common = CommonWidget(context: context);
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final prompt = countryNumber.aiImagePrompt();
      "prompt: $prompt".debugPrint();
      final callable = FirebaseFunctions.instanceFor(region: generateTrainPhotoRegion)
          .httpsCallable(
        generateTrainPhotoFunction,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final result = await callable.call(<String, dynamic>{
        'prompt': prompt,
        'count': generatePhotoNumber,
      });
      final data = result.data;
      final images = data is Map ? data['images'] : null;
      if (images is! List || images.isEmpty) {
        throw Exception('No images returned from Cloud Function.');
      }
      return images.map((item) {
        if (item is! String || item.isEmpty) {
          throw Exception('Invalid image payload from Cloud Function.');
        }
        return base64Decode(item);
      }).toList();
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) context.photoCaptureFailed().debugPrint();
      if (context.mounted) common.showSnackBar(context.photoCaptureFailed(), true);
      'Cloud Function error: ${e.code} ${e.message}'.debugPrint();
      return [];
    } catch (e) {
      if (context.mounted) context.photoCaptureFailed().debugPrint();
      if (context.mounted) common.showSnackBar(context.photoCaptureFailed(), true);
      'Failed to generate AI image via Functions: $e'.debugPrint();
      return [];
    }
  }

  /// ===== DEVICE INFORMATION METHODS =====
  // Get Android SDK version for permission handling compatibility
  Future<int> getAndroidSDK() async {
    final prefs = await SharedPreferences.getInstance();
    final androidSDK = "androidSDK".getSharedPrefInt(prefs, 0);
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

  /// ===== PERMISSION MANAGEMENT =====
  // Request and handle photo access permissions with platform-specific logic
  Future<PermissionStatus> permitPhotoAccess() async {
    final common = CommonWidget(context: context);
    final androidSDK = await getAndroidSDK();
    final photoPermission = await (androidSDK < 33 ? Permission.storage.status: Permission.photos.status);
    "photoPermission: $photoPermission".debugPrint();
    if (photoPermission != PermissionStatus.granted) {
      try {
        await (androidSDK < 33 ? Permission.storage.request(): Permission.photos.request());
        "photoPermission: $photoPermission".debugPrint();
        final updatedPermission = await (androidSDK < 33 ? Permission.storage.status: Permission.photos.status);
        "updatedPermission: $updatedPermission".debugPrint();
        if (updatedPermission == PermissionStatus.granted && context.mounted) {
          context.pushHomePage();
        }
        if (updatedPermission != PermissionStatus.granted && context.mounted) {
          common.showSnackBar(context.photoAccessPermission(), true);
          Future.delayed(const Duration(seconds: 3), () async => await openAppSettings());
        }
        return updatedPermission;
      } on PlatformException catch (e) {
        "photoPermissionError: $e".debugPrint();
        if (context.mounted) common.showSnackBar(context.photoAccessPermission(), true);
        Future.delayed(const Duration(seconds: 3), () async => await openAppSettings());
        return photoPermission;
      }
    } else {
      "photoPermission: $photoPermission".debugPrint();
      return photoPermission;
    }
  }
}
