import 'package:flutter_bloc/flutter_bloc.dart';

enum AppMode { expireDate, inventory }

class AppModeCubit extends Cubit<AppMode> {
  AppModeCubit() : super(AppMode.expireDate);

  void toggleMode() {
    emit(state == AppMode.expireDate ? AppMode.inventory : AppMode.expireDate);
  }

  void setMode(AppMode mode) {
    emit(mode);
  }
}
