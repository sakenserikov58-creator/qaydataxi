import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:qayda_taxi_app/data/models/app_user.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/data/state/ride_notifier.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';

// ─── Shared Auth ──────────────────────────────────────────────────────────────
import 'package:qayda_taxi_app/shared/auth/splash_screen.dart';
import 'package:qayda_taxi_app/shared/auth/login_screen.dart';
import 'package:qayda_taxi_app/shared/auth/sms_verification_screen.dart';

// ─── Passenger ────────────────────────────────────────────────────────────────
import 'package:qayda_taxi_app/passenger/screens/home/home_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/ride/ride_selection_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/ride/searching_driver_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/ride/ride_in_progress_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/ride/rate_trip_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/chat/chat_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/history/ride_history_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/history/ride_detail_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/profile/profile_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/profile/payment_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/profile/promo_codes_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/profile/settings_screen.dart';
import 'package:qayda_taxi_app/passenger/screens/profile/become_driver_screen.dart';

// ─── Driver ───────────────────────────────────────────────────────────────────
import 'package:qayda_taxi_app/driver/screens/driver_home_screen.dart';
import 'package:qayda_taxi_app/driver/screens/driver_request_screen.dart';
import 'package:qayda_taxi_app/driver/screens/driver_navigation_screen.dart';
import 'package:qayda_taxi_app/driver/screens/driver_profile_screen.dart';

// ─── Widgets ──────────────────────────────────────────────────────────────────
import 'package:qayda_taxi_app/widgets/bottom_nav_bar.dart';

/// BottomNavBar shell for the passenger tab routes
class _PassengerShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _PassengerShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

/// Router factory. Accepts [authService] as a Listenable so GoRouter
/// automatically re-evaluates redirects when auth state changes.
/// [navigatorKey] is optional — pass it from main.dart to access the
/// Navigator's Overlay for the connectivity banner.
GoRouter buildAppRouter(
  AuthService authService,
  RideNotifier rideNotifier, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: authService,
    initialLocation: '/',

    // ── Global redirect ──────────────────────────────────────────────────────
    redirect: (context, state) {
      final location = state.uri.toString();
      final isLoggedIn = authService.isLoggedIn;
      final isDriver = authService.isDriver;
      final ride = rideNotifier;

      // Unauthorised → only /login and /verify are reachable
      final onAuthPages = location == '/login' || location.startsWith('/verify');
      if (!isLoggedIn && !onAuthPages && location != '/') {
        return '/login';
      }

      // Logged in → no need to stay on auth pages
      if (isLoggedIn && onAuthPages) {
        return isDriver ? '/driver/home' : '/home';
      }

      // Passenger trying to reach driver pages
      if (isLoggedIn && !isDriver && location.startsWith('/driver')) {
        return '/home';
      }

      // Driver trying to reach passenger pages
      if (isLoggedIn && isDriver) {
        if (location == '/home' ||
            location == '/history' ||
            location.startsWith('/profile')) {
          return '/driver/home';
        }
      }

      // Auto-navigate passenger via ride FSM
      if (!isDriver) {
        if (ride.status == RideStatus.accepted && location == '/searching') {
          return '/ride-active';
        }
        if (ride.status == RideStatus.completed && location == '/ride-active') {
          return '/rate';
        }
      }

      return null;
    },

    routes: [
      // ── Splash ──────────────────────────────────────────────────────────────
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),

      // ── Auth (shared) ────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/verify',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SmsVerificationScreen(
            phone: extra?['phone'] as String? ?? '',
            role: extra?['role'] as UserRole? ?? UserRole.passenger,
          );
        },
      ),

      // ── Passenger Shell (with BottomNav) ─────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => _PassengerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (_, __) => const RideHistoryScreen(),
              routes: [
                GoRoute(
                    path: 'detail',
                    builder: (_, __) => const RideDetailScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
              routes: [
                GoRoute(
                    path: 'payment',
                    builder: (_, __) => const PaymentScreen()),
                GoRoute(
                    path: 'promo',
                    builder: (_, __) => const PromoCodesScreen()),
                GoRoute(
                    path: 'settings',
                    builder: (_, __) => const SettingsScreen()),
                GoRoute(
                    path: 'become-driver',
                    builder: (_, __) => const BecomeDriverScreen()),
              ],
            ),
          ]),
        ],
      ),

      // ── Passenger Ride Flow (no BottomNav) ───────────────────────────────────
      GoRoute(path: '/ride-select', builder: (_, __) => const RideSelectionScreen()),
      GoRoute(path: '/searching',   builder: (_, __) => const SearchingDriverScreen()),
      GoRoute(path: '/ride-active', builder: (_, __) => const RideInProgressScreen()),
      GoRoute(path: '/chat',         builder: (_, __) => const ChatScreen()),
      GoRoute(path: '/rate',         builder: (_, __) => const RateTripScreen()),

      // Splash alias for role-switch navigation
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

      // ── Driver ───────────────────────────────────────────────────────────────
      GoRoute(path: '/driver/home',     builder: (_, __) => const DriverHomeScreen()),
      GoRoute(path: '/driver/request',  builder: (_, __) => const DriverRequestScreen()),
      GoRoute(path: '/driver/navigate', builder: (_, __) => const DriverNavigationScreen()),
      GoRoute(path: '/driver/profile',  builder: (_, __) => const DriverProfileScreen()),
    ],
  );
}
