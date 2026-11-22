import 'package:flutter/widgets.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../localization/locale_provider.dart';
import '../services/firebase_service.dart';
import '../services/geocoding_service.dart';
import '../services/notification_service.dart';
import 'app_provider.dart';

/// Root Multi-Provider Widget for TruckLink PK.
/// Replaces third-party state managers (Riverpod, Provider) with native Flutter InheritedNotifiers.
class AppScope extends StatefulWidget {
  final Widget child;

  const AppScope({super.key, required this.child});

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> {
  late final AuthProvider _authProvider;
  late final LocaleProvider _localeProvider;
  late final NotificationProvider _notificationProvider;
  final FirebaseService _firebaseService = FirebaseService.instance;
  final GeocodingService _geocodingService = GeocodingService.instance;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _localeProvider = LocaleProvider();
    _notificationProvider = NotificationProvider(firebaseService: _firebaseService);

    // Initialize notification listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationProvider.init();
    });
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _localeProvider.dispose();
    _notificationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ServiceProvider<FirebaseService>(
      service: _firebaseService,
      child: ServiceProvider<GeocodingService>(
        service: _geocodingService,
        child: AppProvider<AuthProvider>(
          notifier: _authProvider,
          child: AppProvider<LocaleProvider>(
            notifier: _localeProvider,
            child: AppProvider<NotificationProvider>(
              notifier: _notificationProvider,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helpful Typed Shortcuts on BuildContext
extension TruckLinkContextExtension on BuildContext {
  AuthProvider get auth => watch<AuthProvider>();
  AuthProvider get authActions => read<AuthProvider>();

  LocaleProvider get localeProvider => watch<LocaleProvider>();
  LocaleProvider get localeActions => read<LocaleProvider>();

  NotificationProvider get notifications => watch<NotificationProvider>();
  NotificationProvider get notificationActions => read<NotificationProvider>();

  FirebaseService get firebase => service<FirebaseService>();
  GeocodingService get geocoding => service<GeocodingService>();
}
