import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/core/form_status.dart';
import 'package:good_app/repository/api_exception_manager.dart';
import 'package:good_app/repository/inventory_repository.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({required InventoryRepository inventoryRepository})
    : _inventoryRepository = inventoryRepository,
      super(InventoryState()) {
    on<InventoryInitialized>(_onInventoryInitialized);
    on<InventoryRecognized>(_onInventoryRecognized);
  }

  final InventoryRepository _inventoryRepository;

  Future<void> _onInventoryInitialized(
    InventoryInitialized event,
    Emitter<InventoryState> emit,
  ) async {
    // List<CameraDescription> cameraDescriptions = await availableCameras();
    // CameraDescription cameraDescription = cameraDescriptions[2];

    emit(state.copyWith());
  }

  Future<void> _onInventoryRecognized(
    InventoryRecognized event,
    Emitter<InventoryState> emit,
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
          response: result,
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
}
