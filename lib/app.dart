import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'l10n/app_localizations.dart';

class TruckLinkApp extends ConsumerStatefulWidget {
  const TruckLinkApp({super.key});

  @override
  ConsumerState<TruckLinkApp> createState() => _TruckLinkAppState();
}

class _TruckLinkAppState extends ConsumerState<TruckLinkApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Initialize FCM notification listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for foreground push notifications and surface an in-app banner
    ref.listen<NotificationState>(notificationStateProvider, (previous, next) {
      if (next.lastForegroundMessage != null &&
          next.lastForegroundMessage != previous?.lastForegroundMessage) {
        final message = next.lastForegroundMessage!;
        final title =
            message.notification?.title ?? message.data['title'] ?? 'TruckLink Alert';
        final body = message.notification?.body ?? message.data['body'] ?? '';

        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (body.isNotEmpty)
                        Text(
                          body,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    final router = ref.watch(appRouterProvider);
    final activeLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'TruckLink PK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: activeLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
