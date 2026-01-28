import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/expire_date/view/expire_date_page.dart';
import 'package:good_app/repository/expire_date_repository.dart';
import 'package:good_app/repository/inventory_repository.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.expireDateRepository,
    required this.inventoryRepository,
  });

  final ExpireDateRepository expireDateRepository;
  final InventoryRepository inventoryRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => expireDateRepository),
        RepositoryProvider(create: (context) => inventoryRepository),
      ],
      child: MaterialApp(theme: ThemeData.dark(), home: ExpireDatePage()),
    );
  }
}
