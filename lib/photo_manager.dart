import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common_widget.dart';
import 'common_extension.dart';

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
      final result = await ImageGallerySaver.saveImage(imageList[index]);
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

  /// ===== VERTEX AI AUTHENTICATION =====
  // Load and authenticate Vertex AI service account credentials
  Future<String> loadVertexAIToken() async {
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

  /// ===== AI PHOTO GENERATION METHODS =====
  // Generate AI photo using Vertex AI (Google's AI service)
  Future<List<Uint8List>> getGenerativeAIPhoto(int countryNumber) async {
    "getGenerateVertexAIPhoto".debugPrint();
    try {
      final vertexAIToken = await loadVertexAIToken();
      final prompt = countryNumber.vertexAIPrompt();
      "prompt: $prompt".debugPrint();
      final response = await prompt.vertexAIResponse(vertexAIToken);
      "responseStatusCode: ${response.statusCode}".debugPrint();
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final responseImageList = List.generate(jsonResponse["predictions"].length, (i) =>
          base64Decode(jsonResponse["predictions"][i]["bytesBase64Encoded"])
        );
        return responseImageList;
      } else {
        final errorResponse = jsonDecode(response.body);
        'code: ${errorResponse['error']['code']}'.debugPrint();
        'message: ${errorResponse['error']['message']}'.debugPrint();
        throw Exception('StatusCode is not 200.');
      }
    } catch (e) {
      if (context.mounted) context.photoCaptureFailed().debugPrint();
      'Failed to generate Vertex AI image: $e'.debugPrint();
      "getGenerateDallEPhoto".debugPrint();
      return getGenerateDallEPhoto(countryNumber);
    }
  }

  // Generate photo using OpenAI's Dall-E 3 API as fallback
  Future<List<Uint8List>> getGenerateDallEPhoto(int countryNumber) async {
    final common = CommonWidget(context: context);
    try {
      final prompt = countryNumber.dallEPrompt();
      "prompt: $prompt".debugPrint();
      final response = await prompt.dallEResponse();
      "responseStatusCode: ${response.statusCode}".debugPrint();
      if (response.statusCode == 200) {
        final responseJsonData = jsonDecode(utf8.decode(response.bodyBytes).toString());
        final responseImageList = List.generate(responseJsonData['data'].length, (i) async {
          final url = await http.get(Uri.parse(responseJsonData['data'][i]['url']));
          return url.bodyBytes;
        });
        return await Future.wait(responseImageList);
      } else {
        final errorResponse = jsonDecode(response.body);
        'code: ${errorResponse['error']['code']}'.debugPrint();
        'message: ${errorResponse['error']['message']}'.debugPrint();
        throw Exception('StatusCode is not 200.');
      }
    } catch (e) {
      if (context.mounted) context.photoCaptureFailed().debugPrint();
      if (context.mounted) common.showSnackBar(context.photoCaptureFailed(), true);
      'Failed to generate Dall-E 3 image: $e'.debugPrint();
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