part of 'expire_date_bloc.dart';

abstract class ExpireDateEvent extends Equatable {
  const ExpireDateEvent();

  @override
  List<Object> get props => [];
}

class ExpireDateInitialize extends ExpireDateEvent {
  const ExpireDateInitialize();

  @override
  List<Object> get props => [];
}

class ExpireDateLocalRecognized extends ExpireDateEvent {
  const ExpireDateLocalRecognized({
    required this.nv21Bytes,
    required this.width,
    required this.height,
  });

  final Uint8List nv21Bytes;
  final int width;
  final int height;

  @override
  List<Object> get props => [nv21Bytes, width, height];
}

class ExpireDateServerRecognized extends ExpireDateEvent {
  const ExpireDateServerRecognized({required this.jpegBytes});

  final Uint8List jpegBytes;

  @override
  List<Object> get props => [jpegBytes];
}

class InventoryRecognized extends ExpireDateEvent {
  const InventoryRecognized({required this.imagePath});

  final String imagePath;

  @override
  List<Object> get props => [imagePath];
}

class AppModeChanged extends ExpireDateEvent {
  const AppModeChanged({required this.appMode});

  final AppMode appMode;

  @override
  List<Object> get props => [appMode];
}

class QuestionChanged extends ExpireDateEvent {
  const QuestionChanged({required this.question});

  final String question;

  @override
  List<Object> get props => [question];
}

class OcrTypeChanged extends ExpireDateEvent {
  const OcrTypeChanged({required this.ocrType});

  final OcrType ocrType;

  @override
  List<Object> get props => [ocrType];
}
