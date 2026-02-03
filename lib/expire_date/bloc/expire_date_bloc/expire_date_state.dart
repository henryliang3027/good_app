part of 'expire_date_bloc.dart';

enum AppMode { expireDate, inventory }

class ExpireDateState extends Equatable {
  const ExpireDateState({
    this.formStatus = FormStatus.none,
    this.submissionStatus = SubmissionStatus.none,
    this.cameraController,
    this.ocrResponse,
    this.inventoryResponse,
    this.errorMessage = '',
    this.appMode = AppMode.expireDate,
    this.inventoryQuestion = '',
  });

  final FormStatus formStatus;
  final SubmissionStatus submissionStatus;
  final CameraController? cameraController;
  final OcrResponse? ocrResponse;
  final InventoryResponse? inventoryResponse;
  final String errorMessage;
  final AppMode appMode;
  final String inventoryQuestion;

  ExpireDateState copyWith({
    FormStatus? formStatus,
    SubmissionStatus? submissionStatus,
    CameraController? cameraController,
    OcrResponse? ocrResponse,
    InventoryResponse? inventoryResponse,
    String? errorMessage,
    AppMode? appMode,
    String? inventoryQuestion,
  }) {
    return ExpireDateState(
      formStatus: formStatus ?? this.formStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      cameraController: cameraController ?? this.cameraController,
      ocrResponse: ocrResponse ?? this.ocrResponse,
      inventoryResponse: inventoryResponse ?? this.inventoryResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      appMode: appMode ?? this.appMode,
      inventoryQuestion: inventoryQuestion ?? this.inventoryQuestion,
    );
  }

  @override
  List<Object?> get props => [
    formStatus,
    submissionStatus,
    cameraController,
    ocrResponse,
    inventoryResponse,
    errorMessage,
    appMode,
    inventoryQuestion,
  ];
}
