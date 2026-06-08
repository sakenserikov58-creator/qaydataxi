import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qayda_taxi_app/core/theme.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/data/state/ride_notifier.dart';
import 'package:qayda_taxi_app/passenger/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PassengerApp());
}

class PassengerApp extends StatelessWidget {
  const PassengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => RideNotifier()),
      ],
      child: const _RouterWrapper(),
    );
  }
}

class _RouterWrapper extends StatefulWidget {
  const _RouterWrapper();

  @override
  State<_RouterWrapper> createState() => _RouterWrapperState();
}

class _RouterWrapperState extends State<_RouterWrapper> {
  late final _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final ride = context.read<RideNotifier>();
    _router = buildPassengerRouter(authService: auth, rideNotifier: ride);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MIDNIGHT — Пассажир',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
