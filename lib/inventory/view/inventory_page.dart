import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/inventory/bloc/inventory_bloc/inventory_bloc.dart';
import 'package:good_app/inventory/view/inventory_view.dart';
import 'package:good_app/repository/inventory_repository.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({
    super.key,
    required this.controller,
    required this.initializeControllerFuture,
  });

  final CameraController? controller;
  final Future<void> initializeControllerFuture;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryBloc(
        inventoryRepository: RepositoryProvider.of<InventoryRepository>(
          context,
        ),
      ),
      child: InventoryView(
        controller: controller,
        initializeControllerFuture: initializeControllerFuture,
      ),
    );
  }
}
