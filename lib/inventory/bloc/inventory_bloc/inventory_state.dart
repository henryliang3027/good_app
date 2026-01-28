part of 'inventory_bloc.dart';

class InventoryState extends Equatable {
  const InventoryState({
    this.formStatus = FormStatus.none,
    this.submissionStatus = SubmissionStatus.none,
    this.cameraDescriptions = const [],
    this.response = '',
    this.errorMessage = '',
  });

  final FormStatus formStatus;
  final SubmissionStatus submissionStatus;
  final List<CameraDescription> cameraDescriptions;
  final String response;
  final String errorMessage;

  InventoryState copyWith({
    FormStatus? formStatus,
    SubmissionStatus? submissionStatus,
    List<CameraDescription>? cameraDescriptions,
    String? response,
    String? errorMessage,
  }) {
    return InventoryState(
      formStatus: formStatus ?? this.formStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      cameraDescriptions: cameraDescriptions ?? this.cameraDescriptions,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    formStatus,
    submissionStatus,
    cameraDescriptions,
    response,
    errorMessage,
  ];
}
