part of 'expire_date_bloc.dart';

enum AppMode { expireDate, inventory }

enum OcrType { server, local }

class ExpireDateState extends Equatable {
  const ExpireDateState({
    this.formStatus = FormStatus.none,
    this.submissionStatus = SubmissionStatus.none,
    this.cameraController,
    this.ocrResponse,
    this.inventoryResponse,
    this.errorMessage = '',
    this.ocrType = OcrType.local,
    this.appMode = AppMode.expireDate,
    this.question = '統計圖中的商品',
  });

  final FormStatus formStatus;
  final SubmissionStatus submissionStatus;
  final CameraController? cameraController;
  final OcrResponse? ocrResponse;
  final InventoryResponse? inventoryResponse;
  final String errorMessage;
  final OcrType ocrType;
  final AppMode appMode;
  final String question;

  ExpireDateState copyWith({
    FormStatus? formStatus,
    SubmissionStatus? submissionStatus,
    CameraController? cameraController,
    OcrResponse? ocrResponse,
    InventoryResponse? inventoryResponse,
    String? errorMessage,
    OcrType? ocrType,
    AppMode? appMode,
    String? question,
  }) {
    return ExpireDateState(
      formStatus: formStatus ?? this.formStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      cameraController: cameraController ?? this.cameraController,
      ocrResponse: ocrResponse ?? this.ocrResponse,
      inventoryResponse: inventoryResponse ?? this.inventoryResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      ocrType: ocrType ?? this.ocrType,
      appMode: appMode ?? this.appMode,
      question: question ?? this.question,
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
    ocrType,
    appMode,
    question,
  ];
}
