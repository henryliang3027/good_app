import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras[2];

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  // 掃描區域大小
  static const double scanWidth = 240;
  static const double scanHeight = 70;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _cropImage(String imagePath, Size previewSize) async {
    final File imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // 計算裁剪區域在實際圖片中的位置
    final double scaleX = originalImage.width / previewSize.width;
    final double scaleY = originalImage.height / previewSize.height;

    final int cropX = ((previewSize.width - scanWidth) / 2 * scaleX).round();
    final int cropY = ((previewSize.height - scanHeight) / 2 * scaleY).round();
    final int cropW = (scanWidth * scaleX).round();
    final int cropH = (scanHeight * scaleY).round();

    // 裁剪圖片
    final croppedImage = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    // 儲存裁剪後的圖片
    final croppedPath = imagePath.replaceAll('.jpg', '_cropped.jpg');
    final croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

    return croppedPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('效期辨識')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final previewSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return Stack(
                  children: [
                    // 相機預覽
                    SizedBox.expand(child: CameraPreview(_controller)),
                    // 半透明遮罩 (使用 CustomPaint)
                    CustomPaint(
                      size: previewSize,
                      painter: ScanOverlayPainter(
                        scanWidth: scanWidth,
                        scanHeight: scanHeight,
                      ),
                    ),
                    // 掃描框邊框
                    Center(
                      child: Container(
                        width: scanWidth,
                        height: scanHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // 提示文字
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: const Text(
                        '請將效期對準掃描框',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            final image = await _controller.takePicture();

            if (!context.mounted) return;

            // 取得預覽區域大小
            final RenderBox? renderBox =
                context.findRenderObject() as RenderBox?;
            final previewSize = renderBox?.size ?? const Size(400, 600);

            // 裁剪圖片
            final croppedPath = await _cropImage(image.path, previewSize);

            if (!context.mounted) return;

            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    DisplayPictureScreen(imagePath: croppedPath),
              ),
            );
          } catch (e) {
            debugPrint('Error: $e');
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// 自訂繪製掃描遮罩
class ScanOverlayPainter extends CustomPainter {
  final double scanWidth;
  final double scanHeight;

  ScanOverlayPainter({required this.scanWidth, required this.scanHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // 計算掃描框位置
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanWidth,
      height: scanHeight,
    );

    // 繪製遮罩 (整個畫面減去掃描框區域)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  final Dio _dio = Dio();
  bool _isLoading = false;
  String? _ocrResult;

  Future<void> _sendToOcrApi() async {
    setState(() {
      _isLoading = true;
      _ocrResult = null;
    });

    try {
      // 讀取圖片檔案並轉換為 base64
      final File imageFile = File(widget.imagePath);
      // check image height and width
      final image = await decodeImageFromList(imageFile.readAsBytesSync());
      print('Image width: ${image.width}, height: ${image.height}');

      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // 發送 POST 請求到 OCR API
      final response = await _dio.post(
        'http://192.168.50.46:8888/ocr_inference_base64',
        data: {'image_base64': base64Image},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      setState(() {
        _ocrResult = response.data.toString();
      });
    } on DioException catch (e) {
      setState(() {
        _ocrResult = '錯誤: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _ocrResult = '錯誤: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(File(widget.imagePath)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendToOcrApi,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('辨識效期'),
            ),
            if (_ocrResult != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '辨識結果:\n$_ocrResult',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
