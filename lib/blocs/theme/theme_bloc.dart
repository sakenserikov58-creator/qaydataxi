import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeBloc extends Cubit<ThemeMode> {
  ThemeBloc() : super(ThemeMode.light); // Default to light

  void changeTheme(ThemeMode mode) {
    if (state != mode) {
      emit(mode);
    }
  }
}
