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
  const ExpireDateRecognized({required this.imagePath});

  final String imagePath;

  @override
  List<Object> get props => [imagePath];
}
