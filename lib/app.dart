import 'package:flutter/material.dart';
import 'core/providers/app_scope.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'l10n/app_localizations.dart';

class TruckLinkApp extends StatefulWidget {
  const TruckLinkApp({super.key});

  @override
  State<TruckLinkApp> createState() => _TruckLinkAppState();
}

class _TruckLinkAppState extends State<TruckLinkApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  String? _lastShownMessageId;

  @override
  Widget build(BuildContext context) {
    final activeLocale = context.localeProvider.locale;
    final notif = context.notifications;
    final lastMessage = notif.lastForegroundMessage;

    if (lastMessage != null && lastMessage.messageId != _lastShownMessageId) {
      _lastShownMessageId = lastMessage.messageId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final title = lastMessage.notification?.title ??
            lastMessage.data['title'] ??
            'Truck Link Alert';
        final body =
            lastMessage.notification?.body ?? lastMessage.data['body'] ?? '';

        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/truck_link_icon_square.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
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
      });
    }

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'TruckLink PK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      locale: activeLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
