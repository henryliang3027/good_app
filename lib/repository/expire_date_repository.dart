import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:good_app/repository/api_exception_manager.dart';
import 'package:good_app/repository/date_validator.dart';
import 'package:good_app/repository/models/ocr_response.dart';
import 'package:flutter_ppocrv5/flutter_ppocrv5.dart';
import 'package:image/image.dart' as img;

class ExpireDateRepository {
  ExpireDateRepository({Dio? dio})
    : _dio = dio ?? Dio(),
      _ppocrv5 = FlutterPpocrv5();

  final Dio _dio;
  final FlutterPpocrv5 _ppocrv5;
  bool _modelLoaded = false;
  static const String _endpoint =
      'https://gillian-unhesitative-jestine.ngrok-free.dev';

  /// 發送圖片到 OCR API 進行效期辨識
  /// [imagePath] 圖片檔案路徑
  /// 返回 OCR 辨識結果
  ///
  /// 可能拋出的異常:
  /// - [ServerUnavailableException] 伺服器無法連線
  /// - [RequestTimeoutException] 請求超時
  /// - [ServerErrorException] 伺服器錯誤
  /// - [ImageFileException] 圖片檔案讀取失敗
  Future<OcrResponse> recognizeExpireDate({
    required Uint8List imageBytes,
  }) async {
    // Debug: check image size
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage != null) {
      developer.log(
        'Image size: ${decodedImage.width} x ${decodedImage.height}, '
        'bytes: ${imageBytes.length}',
        name: 'ExpireDateRepository',
      );
    }

    final String base64Image = base64Encode(imageBytes);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_endpoint/glm_ocr_inference_base64',
        data: {'image_base64': base64Image},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data == null) {
        throw const ServerErrorException('伺服器回傳資料為空');
      }

      return OcrResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// 預載 PPOCRv5 模型（可在 camera 初始化時提前呼叫）
  Future<void> ensureModelLoaded() async {
    if (!_modelLoaded) {
      _modelLoaded = await _ppocrv5.loadModel();
      if (!_modelLoaded) {
        throw const ServerErrorException('PPOCRv5 模型載入失敗');
      }
    }
  }

  /// 使用 camera stream 的 NV21 bytes 直接進行 OCR 辨識
  Future<OcrResponse> recognizeExpireDateFromStream({
    required Uint8List nv21Bytes,
    required int width,
    required int height,
    int rotation = 0,
  }) async {
    await ensureModelLoaded();

    final results = await _ppocrv5.detectFromImage(
      nv21Bytes,
      width,
      height,
      rotation: rotation,
    );

    developer.log(
      'PPOCRv5 stream detected ${results.length} text regions',
      name: 'ExpireDateRepository',
    );
    for (final result in results) {
      developer.log(
        'Text: ${result.text}, Confidence: ${result.confidence}',
        name: 'ExpireDateRepository',
      );
    }

    final combinedText = results.map((r) => '.${r.text}').join(' ');
    developer.log(
      'Combined OCR text: $combinedText',
      name: 'ExpireDateRepository',
    );

    return DateValidator.extractMultipleDates(combinedText);
  }

  /// 使用 flutter_ppocrv5 進行本地端 OCR 辨識，並透過 DateValidator 解析日期
  /// [imageBytes] 圖片位元組資料
  /// 返回 OCR 辨識結果（與 recognizeExpireDate 相同的 OcrResponse 格式）
  Future<OcrResponse> recognizeExpireDate2({
    required Uint8List imageBytes,
  }) async {
    await ensureModelLoaded();

    final tempDir = await Directory.systemTemp.createTemp('ocr_');
    final tempFile = File('${tempDir.path}/image.jpg');
    try {
      await tempFile.writeAsBytes(imageBytes);
      final results = await _ppocrv5.detectFromFile(tempFile.path);

      developer.log(
        'PPOCRv5 detected ${results.length} text regions',
        name: 'ExpireDateRepository',
      );
      for (final result in results) {
        developer.log(
          'Text: ${result.text}, Confidence: ${result.confidence}',
          name: 'ExpireDateRepository',
        );
      }

      // 合併所有辨識文字，用空格分隔
      final combinedText = results.map((r) => '.${r.text}').join(' ');
      developer.log(
        'Combined OCR text: $combinedText',
        name: 'ExpireDateRepository',
      );

      return DateValidator.extractMultipleDates(combinedText);
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  ApiClientException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RequestTimeoutException();

      case DioExceptionType.connectionError:
        return const ServerUnavailableException();

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null && statusCode >= 500) {
          return ServerErrorException('伺服器錯誤 ($statusCode)');
        }
        return ServerErrorException('請求失敗 ($statusCode)');

      case DioExceptionType.cancel:
        return const ServerUnavailableException('請求已取消');

      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
        if (e.error is SocketException) {
          return const ServerUnavailableException();
        }
        return ServerUnavailableException('網路錯誤: ${e.message}');
    }
  }
}
