import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/expire_date/bloc/expire_date_bloc/expire_date_bloc.dart';
import 'package:good_app/expire_date/view/expire_date_view.dart';
import 'package:good_app/inventory/view/inventory_view.dart';
import 'package:good_app/repository/expire_date_repository.dart';
import 'package:good_app/repository/inventory_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExpireDateBloc(
        expireDateRepository: RepositoryProvider.of<ExpireDateRepository>(
          context,
        ),
        inventoryRepository: RepositoryProvider.of<InventoryRepository>(
          context,
        ),
      ),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.isNotEmpty ? cameras[2] : null;
    if (camera != null) {
      _controller = CameraController(camera, ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpireDateView(
      controller: _controller,
      initializeControllerFuture: _initializeControllerFuture,
    );
  }
}
