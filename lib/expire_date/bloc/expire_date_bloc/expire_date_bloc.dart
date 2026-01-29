import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/core/form_status.dart';
import 'package:good_app/repository/api_exception_manager.dart';
import 'package:good_app/repository/expire_date_repository.dart';
import 'package:good_app/repository/inventory_repository.dart';
import 'package:good_app/repository/models/inventory_response.dart';
import 'package:good_app/repository/models/ocr_response.dart';
import 'package:good_app/core/constants.dart';
import 'package:image/image.dart' as img;

part 'expire_date_event.dart';
part 'expire_date_state.dart';

class ExpireDateBloc extends Bloc<ExpireDateEvent, ExpireDateState> {
  ExpireDateBloc({
    required ExpireDateRepository expireDateRepository,
    required InventoryRepository inventoryRepository,
  }) : _expireDateRepository = expireDateRepository,
       _inventoryRepository = inventoryRepository,
       super(ExpireDateState()) {
    on<ExpireDateInitialize>(_onExpireDateInitialized);
    on<ExpireDateRecognized>(_onExpireDateRecognized);
    on<InventoryRecognized>(_onInventoryRecognized);
    on<AppModeChanged>(_onAppModeChanged);

    add(ExpireDateInitialize());
  }

  final ExpireDateRepository _expireDateRepository;
  final InventoryRepository _inventoryRepository;

  Future<void> _onExpireDateInitialized(
    ExpireDateInitialize event,
    Emitter<ExpireDateState> emit,
  ) async {
    emit(state.copyWith(formStatus: FormStatus.requestInProgress));

    List<CameraDescription> cameraDescriptions = await availableCameras();
    CameraDescription cameraDescription = cameraDescriptions[2];
    CameraController controller = CameraController(
      cameraDescription,
      ResolutionPreset.ultraHigh,
    );
    await controller.initialize();

    double getMaxZoomLevel = await controller.getMaxZoomLevel();
    double getMinZoomLevel = await controller.getMinZoomLevel();
    controller.setFocusMode(FocusMode.auto);
    controller.setZoomLevel(2.0);
    emit(
      state.copyWith(
        formStatus: FormStatus.requestSuccess,
        cameraController: controller,
      ),
    );
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

  Future<void> _onExpireDateRecognized(
    ExpireDateRecognized event,
    Emitter<ExpireDateState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: SubmissionStatus.submissionInProgress,
        errorMessage: '',
      ),
    );

    String croppedImagePath = await _cropImage(
      event.imagePath,
      event.previewSize,
    );

    try {
      final result = await _expireDateRepository.recognizeExpireDate(
        imagePath: croppedImagePath,
      );

      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.submissionSuccess,
          ocrResponse: result,
          errorMessage: '',
        ),
      );
    } on ServerUnavailableException catch (e) {
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.submissionFailure,
          errorMessage: e.message,
        ),
      );
    } on RequestTimeoutException catch (e) {
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.submissionFailure,
          errorMessage: e.message,
        ),
      );
    } on ApiClientException catch (e) {
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.submissionFailure,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onInventoryRecognized(
    InventoryRecognized event,
    Emitter<ExpireDateState> emit,
  ) async {
    emit(
      state.copyWith(
        submissionStatus: SubmissionStatus.submissionInProgress,
        errorMessage: '',
      ),
    );

    try {
      final result = await _inventoryRepository.recognizeInventory(
        imagePath: event.imagePath,
      );

      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.submissionSuccess,
          inventoryResponse: result,
          errorMessage: '',
        ),
      );
    } on ServerUnavailableException catch (e) {
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.submissionFailure,
          errorMessage: e.message,
        ),
      );
    } on RequestTimeoutException catch (e) {
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.submissionFailure,
          errorMessage: e.message,
        ),
      );
    } on ApiClientException catch (e) {
      emit(
        state.copyWith(
          submissionStatus: SubmissionStatus.submissionFailure,
          errorMessage: e.message,
        ),
      );
    }
  }

  void _onAppModeChanged(AppModeChanged event, Emitter<ExpireDateState> emit) {
    emit(state.copyWith(appMode: event.appMode));
  }
}
