import 'package:go_router/go_router.dart';
import 'package:qayda_taxi_app/data/services/auth_service.dart';
import 'package:qayda_taxi_app/data/state/ride_notifier.dart';
import 'package:qayda_taxi_app/data/models/ride_order.dart';
import 'package:qayda_taxi_app/shared/auth/splash_screen.dart';
import 'package:qayda_taxi_app/shared/auth/login_screen.dart';
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

GoRouter buildPassengerRouter({
  required AuthService authService,
  required RideNotifier rideNotifier,
}) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authService,
    redirect: (context, state) {
      final loggedIn = authService.isLoggedIn;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/verify' ||
          state.matchedLocation == '/splash';

      if (!loggedIn && !onAuth) return '/login';

      // FSM redirects
      switch (rideNotifier.status) {
        case RideStatus.searching:
          if (state.matchedLocation != '/searching') return '/searching';
          break;
        case RideStatus.accepted:
        case RideStatus.inProgress:
          if (state.matchedLocation != '/in-progress') return '/in-progress';
          break;
        case RideStatus.completed:
          if (state.matchedLocation != '/rate') return '/rate';
          break;
        default:
          break;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/ride-select', builder: (_, __) => const RideSelectionScreen()),
      GoRoute(path: '/searching', builder: (_, __) => const SearchingDriverScreen()),
      GoRoute(path: '/in-progress', builder: (_, __) => const RideInProgressScreen()),
      GoRoute(path: '/rate', builder: (_, __) => const RateTripScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),

      GoRoute(path: '/history', builder: (_, __) => const RideHistoryScreen()),
      GoRoute(
        path: '/history/:id',
        builder: (_, state) => const RideDetailScreen(),
      ),

      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/payment', builder: (_, __) => const PaymentScreen()),
      GoRoute(path: '/promo', builder: (_, __) => const PromoCodesScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
}
