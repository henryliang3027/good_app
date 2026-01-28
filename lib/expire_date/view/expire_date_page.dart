import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_app/expire_date/bloc/expire_date_bloc/expire_date_bloc.dart';
import 'package:good_app/expire_date/view/expire_date_view.dart';
import 'package:good_app/repository/expire_date_repository.dart';

class ExpireDatePage extends StatelessWidget {
  const ExpireDatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExpireDateBloc(
        expireDateRepository: RepositoryProvider.of<ExpireDateRepository>(
          context,
        ),
      ),
      child: const ExpireDateView(),
    );
  }
}
