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
  /// 返回 OCR 辨識結果
  Future<InventoryResponse> recognizeInventory({
    required String imagePath,
  }) async {
    final File imageFile = File(imagePath);
    final List<int> imageBytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    Uint8List uint8List = Uint8List.fromList(imageBytes);

    final decodedImage = img.decodeImage(uint8List);
    if (decodedImage != null) {
      developer.log(
        'Image size: ${decodedImage.width} x ${decodedImage.height}, '
        'bytes: ${imageBytes.length}',
        name: 'ExpireDateRepository',
      );
    }

    final response = await _dio.post(
      '$_endpoint/inventory_base64',
      data: {'image_base64': base64Image},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    return InventoryResponse.fromJson(response.data);
  }
}
