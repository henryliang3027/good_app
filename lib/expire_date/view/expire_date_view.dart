// A screen that allows users to take a picture using a given camera.
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/core/constants.dart';
import 'package:good_app/core/form_status.dart';
import 'package:good_app/expire_date/bloc/expire_date_bloc/expire_date_bloc.dart';
import 'package:image/image.dart' as img;

class ExpireDateView extends StatelessWidget {
  const ExpireDateView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      builder: (context, state) {
        if (state.formStatus.isRequestInProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state.formStatus.isRequestSuccess) {
          return SafeArea(
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final previewSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Stack(
                    children: [
                      // 相機預覽
                      SizedBox.expand(
                        child: CameraPreview(state.cameraController!),
                      ),
                      // 半透明遮罩 (使用 CustomPaint)
                      state.appMode == AppMode.expireDate
                          ? CustomPaint(
                              size: previewSize,
                              painter: ScanOverlayPainter(
                                scanWidth: scanWidth,
                                scanHeight: scanHeight,
                              ),
                            )
                          : SizedBox(),
                      // 掃描框邊框
                      state.appMode == AppMode.expireDate
                          ? Center(
                              child: Container(
                                width: scanWidth,
                                height: scanHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            )
                          : SizedBox(),
                      // 提示文字
                      state.appMode == AppMode.expireDate
                          ? Positioned(
                              bottom: 120,
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
                            )
                          : SizedBox(),
                      const Positioned(
                        top: 40,
                        right: 0,
                        child: AppModeToggleButton(),
                      ),
                      const Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ZoomButton(),
                        ),
                      ),
                      // 辨識結果顯示
                      state.appMode == AppMode.expireDate
                          ? const Positioned(
                              top: 90,
                              left: 160,
                              right: 160,
                              child: OcrResultDisplay(),
                            )
                          : SizedBox(),
                    ],
                  );
                },
              ),

              floatingActionButton: TakePictureFloatingActionButton(
                parentContext: context,
              ),
            ),
          );
        } else {
          return const Scaffold(body: Center(child: Text('初始化失敗')));
        }
      },
    );
  }
}

class TakePictureFloatingActionButton extends StatelessWidget {
  const TakePictureFloatingActionButton({
    super.key,
    required this.parentContext,
  });

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    Future<String> cropImage(String imagePath, Size previewSize) async {
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
      final int cropY = ((previewSize.height - scanHeight) / 2 * scaleY)
          .round();
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

    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      builder: (context, state) {
        return FloatingActionButton(
          onPressed: () async {
            try {
              final image = await state.cameraController!.takePicture();

              if (!context.mounted) return;

              if (!context.mounted) return;

              if (state.appMode == AppMode.expireDate) {
                // 取得預覽區域大小
                final RenderBox? renderBox =
                    parentContext.findRenderObject() as RenderBox?;
                final Size previewSize =
                    renderBox?.size ?? const Size(400, 600);

                // 裁剪圖片
                final String croppedPath = await cropImage(
                  image.path,
                  previewSize,
                );

                context.read<ExpireDateBloc>().add(
                  ExpireDateRecognized(imagePath: croppedPath),
                );
              } else if (state.appMode == AppMode.inventory) {
                context.read<ExpireDateBloc>().add(
                  InventoryRecognized(imagePath: image.path),
                );
              }

              // await Navigator.of(context).push(
              //   MaterialPageRoute<void>(
              //     builder: (context) =>
              //         DisplayPictureScreen(imagePath: croppedPath),
              //   ),
              // );
            } catch (e) {
              debugPrint('Error: $e');
            }
          },
          child: state.submissionStatus.isSubmissionInProgress
              ? const CircularProgressIndicator()
              : const Icon(Icons.camera_alt),
        );
      },
    );
  }
}

class ZoomButton extends StatelessWidget {
  const ZoomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      builder: (context, state) {
        if (state.formStatus.isRequestSuccess) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  color: Colors.white,
                  onPressed: () async {
                    await state.cameraController!.setZoomLevel(8.0);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  color: Colors.white,
                  onPressed: () async {
                    await state.cameraController!.setZoomLevel(2.0);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.center_focus_strong_outlined),
                  color: Colors.white,
                  onPressed: () async {
                    await state.cameraController!.setFocusPoint(
                      const Offset(0.5, 0.5),
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return SizedBox();
        }
      },
    );
  }
}

/// 模式切換按鈕
class AppModeToggleButton extends StatelessWidget {
  const AppModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      buildWhen: (previous, current) => previous.appMode != current.appMode,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ToggleButtons(
            isSelected: [
              state.appMode == AppMode.expireDate,
              state.appMode == AppMode.inventory,
            ],
            onPressed: (index) {
              context.read<ExpireDateBloc>().add(
                AppModeChanged(
                  appMode: index == 0 ? AppMode.expireDate : AppMode.inventory,
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: Colors.blue,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('效期'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('庫存'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 辨識結果顯示元件
class OcrResultDisplay extends StatelessWidget {
  const OcrResultDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      buildWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus ||
          previous.ocrResponse != current.ocrResponse,
      builder: (context, state) {
        if (state.submissionStatus.isSubmissionInProgress) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '辨識中...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        } else if (state.submissionStatus.isSubmissionSuccess &&
            state.ocrResponse != null) {
          final response = state.ocrResponse!;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: response.hasValidDate
                  ? Colors.green.withValues(alpha: 0.9)
                  : Colors.orange.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  response.hasValidDate ? '辨識成功' : '無法辨識效期',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (response.hasValidDate && response.date != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${response.date!.year} 年 ${response.date!.month} 月 ${response.date!.day} 日',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          );
        } else if (state.submissionStatus.isSubmissionFailure &&
            state.errorMessage.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '辨識失敗: ${state.errorMessage}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
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
  final String endpoint = 'https://gillian-unhesitative-jestine.ngrok-free.dev';

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
        '$endpoint/ocr_inference_base64',
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
