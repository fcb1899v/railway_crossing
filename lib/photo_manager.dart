import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:railroad_crossing/common_extension.dart';
import 'package:share_plus/share_plus.dart';
import 'common_function.dart';
import 'common_widget.dart';

/// Class For Photos
class PhotoManager {

  final BuildContext context;
  PhotoManager({required this.context});

  Future<List<Uint8List>> getFreePhoto(int countryNumber, int currentDate) async {
    "Get Free Photo".debugPrint();
    final byteData = await rootBundle.load(countryNumber.countryFreePhoto(currentDate));
    return [byteData.buffer.asUint8List()];
  }

  ///Generate VertexAI photo
  Future<List<Uint8List>> getGenerateVertexAIPhoto(int countryNumber) async {
    "Generate VertexAI Photo".debugPrint();
    try {
      final vertexAIToken = await loadVertexAIToken(context);
      final prompt = countryNumber.vertexAIPrompt();
      "prompt: $prompt".debugPrint();
      final response = await prompt.vertexAIResponse(vertexAIToken.value);
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
      return await getGenerateDallEPhoto(countryNumber);
    }
  }

  ///Generate Dall-E-3 photo
  Future<List<Uint8List>> getGenerateDallEPhoto(int countryNumber) async {
    "Generate Dall-E-3 Photo".debugPrint();
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
        return Future.wait(responseImageList);
      } else {
        final errorResponse = jsonDecode(response.body);
        'code: ${errorResponse['error']['code']}'.debugPrint();
        'message: ${errorResponse['error']['message']}'.debugPrint();
        throw Exception('StatusCode is not 200.');
      }
    } catch (e) {
      if (context.mounted) context.photoCaptureFailed().debugPrint();
      if (context.mounted) showSnackBar(context, context.photoCaptureFailed(), true);
      'Failed to generate Dall-E 3 image: $e'.debugPrint();
      return [];
    }
  }

  Future<PermissionStatus> permitPhotoAccess() async {
    final androidSDK = await getAndroidSDK();
    final photoPermission = await (androidSDK < 33 ? Permission.storage.status: Permission.photos.status);
    "photoPermission: $photoPermission".debugPrint();
    if (photoPermission != PermissionStatus.granted) {
      try {
        await (androidSDK < 33 ? Permission.storage.request(): Permission.photos.request());
        "photoPermission: $photoPermission".debugPrint();
        if (photoPermission != PermissionStatus.granted) {
          if (context.mounted) showSnackBar(context, context.photoAccessPermission(), true);
          Future.delayed(const Duration(seconds: 3), () async => await openAppSettings());
        }
        return photoPermission;
      } on PlatformException catch (e) {
        "photoPermissionError: $e".debugPrint();
        return photoPermission;
      }
    } else {
      return photoPermission;
    }
  }

  Future<void> sharePhoto(Uint8List imageData) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/shared_image.png';
      final file = File(filePath);
      await file.writeAsBytes(imageData);
      final result = await Share.shareXFiles([XFile(filePath)], text: '');
      "Share photo: $result".debugPrint();
    } catch (e) {
      'Error sharing image: $e'.debugPrint();
    }
  }

  Future<bool> savePhoto(Uint8List imageData) async {
    try {
      final result = await ImageGallerySaver.saveImage(imageData);
      "result: $result".debugPrint();
      if (context.mounted) {
        (result['isSuccess'] ? context.photoSaved() : context.photoSavingFailed()).debugPrint();
        showSnackBar(context, result['isSuccess'] ? context.photoSaved() : context.photoSavingFailed(), !result['isSuccess']);
      }
      "Save photo: $result".debugPrint();
      return result['isSuccess'] ?? false;
    } catch (e) {
      if (context.mounted) '${context.photoCaptureFailed()}: $e'.debugPrint();
      if (context.mounted) showSnackBar(context, context.photoCaptureFailed(), true);
      return false;
    }
  }
}