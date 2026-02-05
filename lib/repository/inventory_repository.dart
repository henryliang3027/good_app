import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:good_app/repository/models/inventory_response.dart';
import 'dart:developer' as developer;
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class InventoryRepository {
  InventoryRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _endpoint =
      'https://gillian-unhesitative-jestine.ngrok-free.dev';

  /// 發送圖片到 OCR API 進行效期辨識
  /// [imagePath] 圖片檔案路徑
  /// [question] 用戶輸入的問題
  /// 返回 OCR 辨識結果
  Future<InventoryResponse> recognizeInventory({
    required Uint8List imageBytes,
    required String question,
  }) async {
    final String base64Image = base64Encode(imageBytes);

    // Debug: check image size
    // final decodedImage = img.decodeImage(imageBytes);
    // if (decodedImage != null) {
    //   print('Image size: ${decodedImage.width} x ${decodedImage.height}, ');
    // }

    final response = await _dio.post(
      '$_endpoint/inventory_base64',
      data: {
        'image_base64': base64Image,
        'question': question,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    return InventoryResponse.fromJson(response.data);
  }
}
