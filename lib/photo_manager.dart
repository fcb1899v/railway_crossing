import 'dart:async';
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
import 'analytics_manager.dart';
import 'common_function.dart';
import 'common_widget.dart';
import 'extension.dart';
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
          if (context.mounted) await _showPhotoPermissionDialog();
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

  // Ask the user to open Settings only after they try to save without photo access.
  Future<void> _showPhotoPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Text(context.photoAccessPermission()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.cancel()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: Text(context.progressSyncOpenSettings()),
            ),
          ],
        );
      },
    );
  }

  /// ===== FREE PHOTO GENERATION =====
  // Daily free photo: generate until Storage has 9+ for the key; then use cache.
  Future<PhotoResult> getFreePhoto(int countryNumber) async {
    "getFreePhoto (daily cache)".debugPrint();
    return _callGenerateTrainPhoto(
      countryNumber,
      mode: 'daily',
      count: 1,
    );
  }

  /// ===== AI PHOTO GENERATION (Cloud Functions) =====
  // Secrets stay on the server; client sends prompt + App Check + Auth only.
  Future<PhotoResult> getGenerativeAIPhoto(int countryNumber) async {
    "getGenerateTrainPhotoViaFunctions".debugPrint();
    // Quiet: the caller shows the one failure message once the top-up has settled
    return topUpTicketPhoto((count) => _callGenerateTrainPhoto(
      countryNumber,
      mode: 'standard',
      count: count,
      quiet: true,
    ));
  }

  Future<PhotoResult> _callGenerateTrainPhoto(
    int countryNumber, {
    required String mode,
    required int count,
    bool quiet = false,
  }) async {
    final common = CommonWidget(context: context);
    try {
      return PhotoResult.images(await _invokeGenerateTrainPhoto(
        countryNumber,
        mode: mode,
        count: count,
      ));
    } on FirebaseFunctionsException catch (e) {
      // Stale/empty App Check JWT: refresh once and retry.
      if (_isAppCheckRejection(e)) {
        'App Check rejected; refreshing token and retrying once'.debugPrint();
        try {
          await refreshAppCheckToken();
          return PhotoResult.images(await _invokeGenerateTrainPhoto(
            countryNumber,
            mode: mode,
            count: count,
          ));
        } on FirebaseFunctionsException catch (retryError) {
          return _handleGenerateFailure(common, retryError, quiet: quiet);
        } catch (retryError) {
          return _handleGenerateFailure(common, retryError, quiet: quiet);
        }
      }
      return _handleGenerateFailure(common, e, quiet: quiet);
    } catch (e) {
      return _handleGenerateFailure(common, e, quiet: quiet);
    }
  }

  Future<List<Uint8List>> _invokeGenerateTrainPhoto(
    int countryNumber, {
    required String mode,
    required int count,
  }) async {
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
      throw const EmptyPhotoException();
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

  /// A quiet failure shows no message: the caller may still recover with another request
  PhotoResult _handleGenerateFailure(CommonWidget common, Object e, {bool quiet = false}) {
    if (context.mounted) context.photoGenerateFailed().debugPrint();
    if (context.mounted && !quiet) {
      common.showSnackBar(context.photoGenerateFailed(), true);
    }
    if (e is FirebaseFunctionsException) {
      'Cloud Function error: ${e.code} ${e.message}'.debugPrint();
      'App Check root-cause hint: code=${e.code} usually means '
          'enforceAppCheck rejected the client JWT'.debugPrint();
    } else {
      'Failed to generate AI image via Functions: $e'.debugPrint();
    }
    return photoFailureOf(e);
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
  /// iOS: add-only photo access; Android: none (MediaStore save needs no permission).
  /// Never opens Settings; the save flow shows a dialog.
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

    final permission = Permission.photosAddOnly;
    final current = await permission.status;
    "photoPermission: $current".debugPrint();
    if (current.isGranted || current.isLimited) {
      return current;
    }
    try {
      final updated = await permission.request();
      "updatedPermission: $updated".debugPrint();
      return updated;
    } on PlatformException catch (e) {
      "photoPermissionError: $e".debugPrint();
      return current;
    }
  }
}

/// The Cloud Function answered without any image
class EmptyPhotoException implements Exception {
  const EmptyPhotoException();
  @override
  String toString() => 'No images returned from Cloud Function.';
}

/// The result of one photo generation: images, or the reason none came back
class PhotoResult {
  final List<Uint8List> images;
  /// Set when no image came back: `empty` (nothing returned) or `error` (any exception)
  final String? failureReason;

  const PhotoResult.images(this.images) : failureReason = null;
  const PhotoResult.failed(String reason) : images = const [], failureReason = reason;
}

/// Empty when the Cloud Function returned no image, error for any other exception
PhotoResult photoFailureOf(Object e) =>
  PhotoResult.failed(e is EmptyPhotoException ? 'empty' : 'error');

/// A free photo: one image asked for
Future<PhotoResult> trackFreePhoto(Future<PhotoResult> Function() generate) =>
  trackPhotoGeneration(kind: 'free', requested: 1, generate: generate);

/// The fewest images that count as a ticket photo
const minTicketPhotos = 2;

/// Whether a ticket photo returned enough images to be shown and to cost a ticket; fewer is a failed capture
bool ticketPhotoCounts(int returned) => returned >= minTicketPhotos;

/// Asks for a ticket photo, and when fewer than `minTicketPhotos` return, once more for the missing images.
/// The images of both requests are kept; the caller reports a failure from the final count
Future<PhotoResult> topUpTicketPhoto(Future<PhotoResult> Function(int count) request) async {
  final first = await request(generatePhotoNumber);
  if (ticketPhotoCounts(first.images.length)) return first;
  final second = await request(generatePhotoNumber - first.images.length);
  final images = [...first.images, ...second.images];
  if (images.isEmpty) return second;
  return PhotoResult.images(images.take(generatePhotoNumber).toList());
}

/// A ticket photo: `generatePhotoNumber` images asked for
Future<PhotoResult> trackTicketPhoto(Future<PhotoResult> Function() generate) =>
  trackPhotoGeneration(kind: 'ticket', requested: generatePhotoNumber, generate: generate);

/// Runs one generation and logs it: requested before, then generated or failed
/// An exception from the call itself is logged as an error and rethrown, so the caller's handling is unchanged
Future<PhotoResult> trackPhotoGeneration({
  required String kind,
  required int requested,
  required Future<PhotoResult> Function() generate,
}) async {
  unawaited(AnalyticsManager.photoRequested(kind: kind, requested: requested));
  final PhotoResult result;
  try {
    result = await generate();
  } catch (e) {
    unawaited(AnalyticsManager.photoFailed(kind: kind, reason: 'error'));
    rethrow;
  }
  if (result.images.isNotEmpty) {
    unawaited(AnalyticsManager.photoGenerated(kind: kind, requested: requested, returned: result.images.length));
  } else {
    unawaited(AnalyticsManager.photoFailed(kind: kind, reason: result.failureReason ?? 'error'));
  }
  return result;
}
