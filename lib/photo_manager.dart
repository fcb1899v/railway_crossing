import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common_function.dart';
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
      // iOS needs add-only access; Android save uses MediaStore without read permission.
      if (!Platform.isAndroid) {
        final permission = await permitPhotoAccess();
        if (!permission.isGranted && !permission.isLimited) {
          return false;
        }
      }
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
  // Daily free photo: prefer 1 cached Storage image; generate 1 if none exist.
  Future<List<Uint8List>> getFreePhoto(int countryNumber) async {
    "getFreePhoto (daily cache)".debugPrint();
    return _callGenerateTrainPhoto(
      countryNumber,
      mode: 'daily',
      count: 1,
    );
  }

  /// ===== AI PHOTO GENERATION (Cloud Functions) =====
  // Secrets stay on the server; client sends prompt + App Check + Auth only.
  Future<List<Uint8List>> getGenerativeAIPhoto(int countryNumber) async {
    "getGenerateTrainPhotoViaFunctions".debugPrint();
    return _callGenerateTrainPhoto(
      countryNumber,
      mode: 'standard',
      count: generatePhotoNumber,
    );
  }

  Future<List<Uint8List>> _callGenerateTrainPhoto(
    int countryNumber, {
    required String mode,
    required int count,
  }) async {
    final common = CommonWidget(context: context);
    try {
      return await _invokeGenerateTrainPhoto(
        countryNumber,
        mode: mode,
        count: count,
      );
    } on FirebaseFunctionsException catch (e) {
      // Stale/empty App Check JWT: refresh once and retry.
      if (_isAppCheckRejection(e)) {
        'App Check rejected; refreshing token and retrying once'.debugPrint();
        try {
          await refreshAppCheckToken();
          return await _invokeGenerateTrainPhoto(
            countryNumber,
            mode: mode,
            count: count,
          );
        } on FirebaseFunctionsException catch (retryError) {
          return _handleGenerateFailure(common, retryError);
        } catch (retryError) {
          return _handleGenerateFailure(common, retryError);
        }
      }
      return _handleGenerateFailure(common, e);
    } catch (e) {
      return _handleGenerateFailure(common, e);
    }
  }

  Future<List<Uint8List>> _invokeGenerateTrainPhoto(
    int countryNumber, {
    required String mode,
    required int count,
  }) async {
    // Obtain a fresh valid App Check JWT before callable (enforceAppCheck).
    final appCheckToken = await refreshAppCheckToken();
    'Calling generateTrainPhoto with App Check JWT length=${appCheckToken.length}'.debugPrint();
    final request = countryNumber.aiImageGenerationRequest();
    final prompt = request['prompt'] as String;
    final cacheIdentity = Map<String, String>.from(
      request['cacheIdentity'] as Map,
    );
    "mode: $mode".debugPrint();
    "prompt: $prompt".debugPrint();
    "cacheIdentity: $cacheIdentity".debugPrint();
    final callable = FirebaseFunctions.instanceFor(region: generateTrainPhotoRegion)
        .httpsCallable(
      generateTrainPhotoFunction,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final result = await callable.call(<String, dynamic>{
      'prompt': prompt,
      'count': count,
      'mode': mode,
      'cacheIdentity': cacheIdentity,
    });
    final data = result.data;
    if (data is Map) {
      'cacheKey: ${data['cacheKey']}'.debugPrint();
      'storagePath: ${data['storagePath']}'.debugPrint();
      'cachedCount: ${data['cachedCount']}'.debugPrint();
      'usedCache: ${data['usedCache']}'.debugPrint();
      'mode: ${data['mode']}'.debugPrint();
    }
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
  }

  bool _isAppCheckRejection(FirebaseFunctionsException e) {
    final message = (e.message ?? '').toLowerCase();
    return e.code == 'failed-precondition' ||
        e.code == 'unauthenticated' ||
        message.contains('app check') ||
        message.contains('appcheck');
  }

  List<Uint8List> _handleGenerateFailure(CommonWidget common, Object e) {
    if (context.mounted) context.photoCaptureFailed().debugPrint();
    if (context.mounted) {
      common.showSnackBar(context.photoCaptureFailed(), true);
    }
    if (e is FirebaseFunctionsException) {
      'Cloud Function error: ${e.code} ${e.message}'.debugPrint();
      'App Check root-cause hint: code=${e.code} usually means '
          'enforceAppCheck rejected the client JWT'.debugPrint();
    } else {
      'Failed to generate AI image via Functions: $e'.debugPrint();
    }
    return [];
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
  // iOS: request add-only photo access for saving.
  // Android: no gallery-read permission; MediaStore save does not need it.
  Future<PermissionStatus> permitPhotoAccess() async {
    if (Platform.isAndroid) {
      final androidSDK = await getAndroidSDK();
      // Legacy write permission only on Android 9 and below.
      if (androidSDK > 0 && androidSDK < 29) {
        final status = await Permission.storage.status;
        if (status.isGranted) {
          return status;
        }
        return Permission.storage.request();
      }
      return PermissionStatus.granted;
    }

    final common = CommonWidget(context: context);
    final permission = Permission.photosAddOnly;
    final current = await permission.status;
    "photoPermission: $current".debugPrint();
    if (current.isGranted || current.isLimited) {
      return current;
    }
    try {
      final updated = await permission.request();
      "updatedPermission: $updated".debugPrint();
      if (!updated.isGranted && !updated.isLimited && context.mounted) {
        common.showSnackBar(context.photoAccessPermission(), true);
        Future.delayed(const Duration(seconds: 3), () async => await openAppSettings());
      }
      return updated;
    } on PlatformException catch (e) {
      "photoPermissionError: $e".debugPrint();
      if (context.mounted) common.showSnackBar(context.photoAccessPermission(), true);
      Future.delayed(const Duration(seconds: 3), () async => await openAppSettings());
      return current;
    }
  }
}
