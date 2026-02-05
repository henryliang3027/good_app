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

class ExpireDateRecognized extends ExpireDateEvent {
  const ExpireDateRecognized({
    required this.imagePath,
    required this.previewSize,
  });

  final String imagePath;
  final Size previewSize;

  @override
  List<Object> get props => [imagePath, previewSize];
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
