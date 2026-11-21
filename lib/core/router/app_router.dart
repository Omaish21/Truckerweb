import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/driver_profile/presentation/screens/driver_home_screen.dart';
import '../../features/loads/presentation/screens/loads_feed_screen.dart';
import '../../features/loads/presentation/screens/post_load_screen.dart';
import '../../features/route_intelligence/presentation/screens/city_timing_screen.dart';
import '../../features/route_intelligence/presentation/screens/report_condition_screen.dart';
import '../../features/route_intelligence/presentation/screens/route_planner_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/driver-home' : '/driver-home',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/driver-home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/loads-feed',
        builder: (context, state) => const LoadsFeedScreen(),
      ),
      GoRoute(
        path: '/post-load',
        builder: (context, state) => const PostLoadScreen(),
      ),
      GoRoute(
        path: '/route-planner',
        builder: (context, state) => const RoutePlannerScreen(),
      ),
      GoRoute(
        path: '/city-timing',
        builder: (context, state) => const CityTimingScreen(),
      ),
      GoRoute(
        path: '/report-condition',
        builder: (context, state) => const ReportConditionScreen(),
      ),
    ],
  );
});
