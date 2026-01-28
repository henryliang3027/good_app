part of 'expire_date_bloc.dart';

class ExpireDateState extends Equatable {
  const ExpireDateState({
    this.formStatus = FormStatus.none,
    this.submissionStatus = SubmissionStatus.none,
    this.cameraDescriptions = const [],
    this.ocrResponse,
    this.errorMessage = '',
  });

  final FormStatus formStatus;
  final SubmissionStatus submissionStatus;
  final List<CameraDescription> cameraDescriptions;
  final OcrResponse? ocrResponse;
  final String errorMessage;

  ExpireDateState copyWith({
    FormStatus? formStatus,
    SubmissionStatus? submissionStatus,
    List<CameraDescription>? cameraDescriptions,
    OcrResponse? ocrResponse,
    String? errorMessage,
  }) {
    return ExpireDateState(
      formStatus: formStatus ?? this.formStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      cameraDescriptions: cameraDescriptions ?? this.cameraDescriptions,
      ocrResponse: ocrResponse ?? this.ocrResponse,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    formStatus,
    submissionStatus,
    cameraDescriptions,
    ocrResponse,
    errorMessage,
  ];
}
