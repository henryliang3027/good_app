part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object> get props => [];
}

class InventoryInitialized extends InventoryEvent {
  const InventoryInitialized();

  @override
  List<Object> get props => [];
}

class InventoryRecognized extends InventoryEvent {
  const InventoryRecognized({required this.imagePath});

  final String imagePath;

  @override
  List<Object> get props => [imagePath];
}
