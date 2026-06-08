import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_bloc.dart';
import 'package:qayda_taxi_app/blocs/auth/auth_state.dart';
import 'package:qayda_taxi_app/blocs/driver/driver_bloc.dart';
import 'package:qayda_taxi_app/blocs/ride/ride_bloc.dart';
import 'package:qayda_taxi_app/blocs/ride/ride_event_state.dart';
import 'package:qayda_taxi_app/blocs/theme/theme_bloc.dart';
import 'package:qayda_taxi_app/core/app_bloc_observer.dart';
import 'package:qayda_taxi_app/core/router/app_router.dart';
import 'package:qayda_taxi_app/data/repositories/ride_repository.dart';
import 'package:qayda_taxi_app/data/repositories/user_repository.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/data/services/connectivity_service.dart';
import 'package:qayda_taxi_app/data/services/sound_service.dart';
import 'package:qayda_taxi_app/data/services/notification_service.dart';
import 'package:qayda_taxi_app/data/state/ride_notifier.dart';
import 'package:qayda_taxi_app/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ── Firebase ──────────────────────────────────────────────────────────────
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  Bloc.observer = AppBlocObserver();

  // ── Локализация ────────────────────────────────────────────────────────────
  await EasyLocalization.ensureInitialized();

  // ── Уведомления ───────────────────────────────────────────────────────────
  await NotificationService.initialize();

  // ── Ориентация ────────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar ─────────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF8F9FA),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // ── Auth session ──────────────────────────────────────────────────────────
  final authService = AuthService();
  await authService.initFromPrefs();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ru'), Locale('kk')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      startLocale: const Locale('ru'),
      child: QaydaApp(authService: authService),
    ),
  );
}

class QaydaApp extends StatelessWidget {
  final AuthService authService;
  const QaydaApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final rideNotifier = RideNotifier();
    return MultiProvider(
      providers: [
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<RideRepository>(create: (_) => RideRepository()),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<RideNotifier>.value(value: rideNotifier),
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authService: authService),
        ),
        BlocProvider<RideBloc>(
          create: (context) => RideBloc(
            rideNotifier: rideNotifier,
            rideRepository: context.read<RideRepository>(),
            userRepository: context.read<UserRepository>(),
            auth: context.read<AuthService>(),
          ),
          lazy: true,
        ),
        BlocProvider<DriverBloc>(
          create: (context) => DriverBloc(
            rideRepository: context.read<RideRepository>(),
            auth: context.read<AuthService>(),
          ),
          lazy: true,
        ),
      ],
      child: _RouterWrapper(authService: authService, rideNotifier: rideNotifier),
    );
  }
}

class _RouterWrapper extends StatefulWidget {
  final AuthService authService;
  final RideNotifier rideNotifier;
  const _RouterWrapper({required this.authService, required this.rideNotifier});

  @override
  State<_RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<_RouterWrapper> {
  /// Shared NavigatorKey — lets us reach the GoRouter's Overlay
  /// AFTER MaterialApp.router has been mounted.
  final _navKey = GlobalKey<NavigatorState>();

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter(
      widget.authService,
      widget.rideNotifier,
      navigatorKey: _navKey,
    );

    // ── Connect connectivity banner AFTER first frame ──────────────────────
    // At initState time MaterialApp hasn't painted yet → no Overlay exists.
    // addPostFrameCallback fires after the very first build, so the
    // MaterialApp.router (and its Overlay) are guaranteed to be live.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final overlayState = _navKey.currentState?.overlay;
      if (overlayState != null) {
        ConnectivityService.instance.attach(
          overlayState: overlayState,
          onReconnect: _onReconnect,
        );
      }
    });
  }

  /// При восстановлении сети — сбрасываем зависший поиск
  void _onReconnect() {
    if (!mounted) return;
    final rideState = context.read<RideBloc>().state;
    if (rideState is RideSearchingState || rideState is RideErrorBlocState) {
      context.read<RideBloc>().add(const RideReset());
    }
  }

  @override
  void dispose() {
    ConnectivityService.instance.detach();
    SoundService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (_, __) {},
      child: BlocBuilder<ThemeBloc, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Qayda Taxi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: _router,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
          );
        },
      ),
    );
  }
}
