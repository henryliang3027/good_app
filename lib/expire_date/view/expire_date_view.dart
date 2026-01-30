// A screen that allows users to take a picture using a given camera.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/core/constants.dart';
import 'package:good_app/core/form_status.dart';
import 'package:good_app/expire_date/bloc/expire_date_bloc/expire_date_bloc.dart';
import 'package:image/image.dart' as img;

class ExpireDateView extends StatelessWidget {
  const ExpireDateView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final previewSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                // 相機預覽
                CameraView(),
                // 模式相關 widgets
                AppModeOverlay(previewSize: previewSize),
                // 共用 widgets
                const AppModeToggleButton(),

                // const Positioned.fill(
                //   child: Align(
                //     alignment: AlignmentGeometry.bottomLeft,
                //     child: ZoomButton(),
                //   ),
                // ),
              ],
            );
          },
        ),
        floatingActionButton: TakePictureFloatingActionButton(
          parentContext: context,
        ),
      ),
    );
  }
}

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      buildWhen: (previous, current) =>
          previous.formStatus != current.formStatus ||
          previous.appMode != current.appMode,
      builder: (context, state) {
        if (state.formStatus.isRequestSuccess) {
          return SizedBox.expand(child: CameraPreview(state.cameraController!));
        } else if (state.formStatus.isRequestInProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return const Scaffold(body: Center(child: Text('初始化失敗')));
        }
      },
    );
  }
}

class AppModeOverlay extends StatelessWidget {
  const AppModeOverlay({super.key, required this.previewSize});

  final Size previewSize;

  @override
  Widget build(BuildContext context) {
    /// 效期辨識模式的 widgets
    Widget buildExpireDateModeWidgets(Size previewSize) {
      return Stack(
        children: [
          // 半透明遮罩
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
          const Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text(
                  '請將效期對準掃描框',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // 辨識結果顯示
          const Positioned.fill(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 40, left: 10),
                child: OcrResultDisplay(),
              ),
            ),
          ),
        ],
      );
    }

    /// 庫存辨識模式的 widgets
    Widget buildInventoryModeWidgets() {
      return Stack(
        children: [
          // 辨識結果顯示
          const Positioned.fill(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 40, left: 10),
                child: InventoryResultDisplay(),
              ),
            ),
          ),
        ],
      );
    }

    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      buildWhen: (previous, current) =>
          previous.formStatus != current.formStatus ||
          previous.appMode != current.appMode,
      builder: (context, state) {
        if (state.formStatus.isRequestSuccess) {
          return state.appMode == AppMode.expireDate
              ? buildExpireDateModeWidgets(previewSize)
              : buildInventoryModeWidgets();
        } else {
          return SizedBox();
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
    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      builder: (context, state) {
        return FloatingActionButton(
          onPressed: () async {
            try {
              final image = await state.cameraController!.takePicture();

              if (!context.mounted) return;

              if (state.appMode == AppMode.expireDate) {
                // 取得預覽區域大小
                final RenderBox? renderBox =
                    parentContext.findRenderObject() as RenderBox?;
                final Size previewSize =
                    renderBox?.size ?? const Size(400, 600);

                context.read<ExpireDateBloc>().add(
                  ExpireDateRecognized(
                    imagePath: image.path,
                    previewSize: previewSize,
                  ),
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

// class ZoomButton extends StatelessWidget {
//   const ZoomButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ExpireDateBloc, ExpireDateState>(
//       builder: (context, state) {
//         if (state.formStatus.isRequestSuccess) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.zoom_in),
//                   color: Colors.white,
//                   onPressed: () async {
//                     await state.cameraController!.setZoomLevel(8.0);
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.zoom_out),
//                   color: Colors.white,
//                   onPressed: () async {
//                     await state.cameraController!.setZoomLevel(2.0);
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.center_focus_strong_outlined),
//                   color: Colors.white,
//                   onPressed: () async {
//                     await state.cameraController!.setFocusPoint(
//                       const Offset(0.5, 0.5),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           );
//         } else {
//           return SizedBox();
//         }
//       },
//     );
//   }
// }

/// 模式切換按鈕
class AppModeToggleButton extends StatelessWidget {
  const AppModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpireDateBloc, ExpireDateState>(
      buildWhen: (previous, current) => previous.appMode != current.appMode,
      builder: (context, state) {
        return Positioned.fill(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40, right: 10),
              child: ToggleButtons(
                isSelected: [
                  state.appMode == AppMode.expireDate,
                  state.appMode == AppMode.inventory,
                ],
                onPressed: (index) {
                  context.read<ExpireDateBloc>().add(
                    AppModeChanged(
                      appMode: index == 0
                          ? AppMode.expireDate
                          : AppMode.inventory,
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
            ),
          ),
        );
      },
    );
  }
}

/// 辨識結果顯示元件
class OcrResultDisplay extends StatefulWidget {
  const OcrResultDisplay({super.key});

  @override
  State<OcrResultDisplay> createState() => _OcrResultDisplayState();
}

class _OcrResultDisplayState extends State<OcrResultDisplay> {
  Timer? _hideTimer;
  bool _isVisible = false;

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpireDateBloc, ExpireDateState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus ||
          previous.ocrResponse != current.ocrResponse,
      listener: (context, state) {
        if (state.submissionStatus.isSubmissionSuccess ||
            state.submissionStatus.isSubmissionFailure) {
          setState(() => _isVisible = true);
          _startHideTimer();
        } else if (state.submissionStatus.isSubmissionInProgress) {
          _hideTimer?.cancel();
          setState(() => _isVisible = true);
        }
      },
      child: BlocBuilder<ExpireDateBloc, ExpireDateState>(
        buildWhen: (previous, current) =>
            previous.submissionStatus != current.submissionStatus ||
            previous.ocrResponse != current.ocrResponse,
        builder: (context, state) {
          if (!_isVisible) {
            return const SizedBox.shrink();
          }

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
                  if (response.hasValidDate && response.date != null) ...[
                    Text(
                      '${response.date!.year} 年 ${response.date!.month} 月 ${response.date!.day} 日',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      '無法辨識效期',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
      ),
    );
  }
}

/// 庫存辨識結果顯示元件
class InventoryResultDisplay extends StatefulWidget {
  const InventoryResultDisplay({super.key});

  @override
  State<InventoryResultDisplay> createState() => _InventoryResultDisplayState();
}

class _InventoryResultDisplayState extends State<InventoryResultDisplay> {
  Timer? _hideTimer;
  bool _isVisible = false;

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpireDateBloc, ExpireDateState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus ||
          previous.inventoryResponse != current.inventoryResponse,
      listener: (context, state) {
        if (state.submissionStatus.isSubmissionSuccess ||
            state.submissionStatus.isSubmissionFailure) {
          setState(() => _isVisible = true);
          _startHideTimer();
        } else if (state.submissionStatus.isSubmissionInProgress) {
          _hideTimer?.cancel();
          setState(() => _isVisible = true);
        }
      },
      child: BlocBuilder<ExpireDateBloc, ExpireDateState>(
        buildWhen: (previous, current) =>
            previous.submissionStatus != current.submissionStatus ||
            previous.inventoryResponse != current.inventoryResponse,
        builder: (context, state) {
          if (!_isVisible) {
            return const SizedBox.shrink();
          }

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
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            );
          } else if (state.submissionStatus.isSubmissionSuccess &&
              state.inventoryResponse != null) {
            final response = state.inventoryResponse!.data;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    response.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
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
