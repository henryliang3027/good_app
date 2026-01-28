import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/core/form_status.dart';
import 'package:good_app/repository/api_exception_manager.dart';
import 'package:good_app/repository/expire_date_repository.dart';
import 'package:good_app/repository/inventory_repository.dart';
import 'package:good_app/repository/models/ocr_response.dart';

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
  }

  final ExpireDateRepository _expireDateRepository;
  final InventoryRepository _inventoryRepository;

  Future<void> _onExpireDateInitialized(
    ExpireDateInitialize event,
    Emitter<ExpireDateState> emit,
  ) async {
    // List<CameraDescription> cameraDescriptions = await availableCameras();
    // CameraDescription cameraDescription = cameraDescriptions[2];

    emit(state.copyWith());
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

    try {
      final result = await _expireDateRepository.recognizeExpireDate(
        imagePath: event.imagePath,
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
