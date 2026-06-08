import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (kDebugMode) {
      log('BLoC Error in ${bloc.runtimeType}: $error',
          name: 'AppBlocObserver', error: error, stackTrace: stackTrace);
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      log('Transition in ${bloc.runtimeType}: ${transition.currentState} -> ${transition.nextState}',
          name: 'AppBlocObserver');
    }
  }
}
