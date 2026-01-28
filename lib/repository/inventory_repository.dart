import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class InventoryRepository {
  InventoryRepository({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _endpoint =
      'https://gillian-unhesitative-jestine.ngrok-free.dev';

  /// 發送圖片到 OCR API 進行效期辨識
  /// [imagePath] 圖片檔案路徑
  /// 返回 OCR 辨識結果
  Future<String> recognizeInventory(String imagePath) async {
    final File imageFile = File(imagePath);
    final List<int> imageBytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    final response = await _dio.post(
      '$_endpoint/inventory_base64',
      data: {'image_base64': base64Image},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    return response.data.toString();
  }
}
