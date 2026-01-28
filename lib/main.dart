import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_app/app.dart';
import 'package:good_app/repository/expire_date_repository.dart';
import 'package:good_app/repository/inventory_repository.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    App(
      expireDateRepository: ExpireDateRepository(),
      inventoryRepository: InventoryRepository(),
    ),
  );
}
