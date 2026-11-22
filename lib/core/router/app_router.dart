import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/screens/admin_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_selection_screen.dart';
import '../../features/driver_profile/presentation/screens/driver_home_screen.dart';
import '../../features/loads/presentation/screens/loads_feed_screen.dart';
import '../../features/loads/presentation/screens/post_load_screen.dart';
import '../../features/route_intelligence/presentation/screens/city_timing_screen.dart';
import '../../features/route_intelligence/presentation/screens/report_condition_screen.dart';
import '../../features/route_intelligence/presentation/screens/route_planner_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/driver-home',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/driver-home',
    ),
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
      path: '/home',
      redirect: (context, state) => '/driver-home',
    ),
    GoRoute(
      path: '/loads-feed',
      builder: (context, state) {
        final city = state.uri.queryParameters['city'];
        final vehicle = state.uri.queryParameters['vehicle'];
        return LoadsFeedScreen(
          initialCity: city,
          initialVehicle: vehicle,
        );
      },
    ),
    GoRoute(
      path: '/loads',
      redirect: (context, state) => '/loads-feed',
    ),
    GoRoute(
      path: '/post-load',
      builder: (context, state) => const PostLoadScreen(),
    ),
    GoRoute(
      path: '/route-planner',
      builder: (context, state) {
        final origin = state.uri.queryParameters['origin'];
        final destination = state.uri.queryParameters['destination'];
        final vehicle = state.uri.queryParameters['vehicle'];
        final motorway = state.uri.queryParameters['motorway'];
        return RoutePlannerScreen(
          initialOrigin: origin,
          initialDestination: destination,
          initialVehicle: vehicle,
          initialMotorway: motorway == null ? null : (motorway == 'true' || motorway == '1'),
        );
      },
    ),
    GoRoute(
      path: '/routes',
      redirect: (context, state) => '/route-planner',
    ),
    GoRoute(
      path: '/city-timing',
      builder: (context, state) {
        final city = state.uri.queryParameters['city'];
        return CityTimingScreen(initialCity: city);
      },
    ),
    GoRoute(
      path: '/city-timings',
      redirect: (context, state) => '/city-timing',
    ),
    GoRoute(
      path: '/report-condition',
      builder: (context, state) => const ReportConditionScreen(),
    ),
    GoRoute(
      path: '/report-hazard',
      redirect: (context, state) => '/report-condition',
    ),
    GoRoute(
      path: '/admin/verification',
      builder: (context, state) => const AdminVerificationScreen(),
    ),
    GoRoute(
      path: '/admin',
      redirect: (context, state) => '/admin/verification',
    ),
  ],
);
