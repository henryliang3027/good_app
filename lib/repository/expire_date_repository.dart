import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:good_app/repository/api_exception_manager.dart';
import 'package:good_app/repository/models/ocr_response.dart';
import 'package:image/image.dart' as img;

class ExpireDateRepository {
  ExpireDateRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
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
