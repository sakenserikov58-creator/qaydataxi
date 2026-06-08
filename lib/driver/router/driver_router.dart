import 'package:go_router/go_router.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/shared/auth/login_screen.dart';
import 'package:qayda_taxi_app/shared/auth/splash_screen.dart';
import 'package:qayda_taxi_app/driver/screens/driver_home_screen.dart';
import 'package:qayda_taxi_app/driver/screens/driver_request_screen.dart';
import 'package:qayda_taxi_app/driver/screens/driver_navigation_screen.dart';

GoRouter buildDriverRouter({required AuthService authService}) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authService,
    redirect: (context, state) {
      final loggedIn = authService.isLoggedIn;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash';
      if (!loggedIn && !onAuth) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/driver/home', builder: (_, __) => const DriverHomeScreen()),
      GoRoute(path: '/driver/request', builder: (_, __) => const DriverRequestScreen()),
      GoRoute(path: '/driver/navigate', builder: (_, __) => const DriverNavigationScreen()),
    ],
  );
}
