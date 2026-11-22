import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../providers/app_scope.dart';
import '../services/firebase_service.dart';
import '../theme/colors.dart';

class NotificationBellButton extends StatelessWidget {
  final bool compact;

  const NotificationBellButton({super.key, this.compact = false});

  void _showNotificationPanel(BuildContext context) {
    final notifState = context.notifications.state;
    final user = context.auth.userProfile;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.pushNotificationsTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Status Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: notifState.isPermissionGranted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: notifState.isPermissionGranted ? AppColors.success : AppColors.accentOrange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    notifState.isPermissionGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: notifState.isPermissionGranted ? AppColors.success : AppColors.accentOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notifState.isPermissionGranted
                              ? l10n.alertsActive
                              : (isUrdu ? 'الرٹس بند ہیں' : 'Alerts Disabled'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          notifState.isPermissionGranted
                              ? (isUrdu ? 'آپ کو اہم روٹ اور بولی الرٹس ملیں گے' : 'You will receive route and bid alerts')
                              : (isUrdu ? 'براؤزر میں الرٹس آن کرنے کے لیے نیچے بٹن دبائیں' : 'Enable browser alerts to receive instant updates'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Enable Push Notification Button
            if (!notifState.isPermissionGranted) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: notifState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.notifications_active),
                label: Text(
                  l10n.allowNotificationsButton,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: notifState.isLoading
                    ? null
                    : () async {
                        final success = await context
                            .notificationActions
                            .enableAlerts(user?.id);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: success ? AppColors.success : AppColors.danger,
                              content: Text(
                                success ? l10n.notificationsEnabledSuccess : l10n.notificationsDenied,
                              ),
                            ),
                          );
                        }
                      },
              ),
              const SizedBox(height: 12),
            ],

            // Recent in-app notifications list
            Text(
              isUrdu ? 'حالیہ الرٹس اور پیغامات' : 'Recent Notifications',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirebaseService.instance.watchUserNotifications(user?.id ?? ''),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          isUrdu ? 'کوئی نیا نوٹیفکیشن موجود نہیں ہے' : l10n.noNewNotifications,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final title = item['title'] as String? ?? '';
                      final body = item['body'] as String? ?? '';
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(body, style: const TextStyle(fontSize: 12)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifState = context.notifications.state;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            notifState.isPermissionGranted
                ? Icons.notifications_active_outlined
                : Icons.notifications_outlined,
            color: notifState.isPermissionGranted ? AppColors.accent : Colors.white,
          ),
          tooltip: notifState.isPermissionGranted ? l10n.alertsActive : l10n.enableAlerts,
          onPressed: () => _showNotificationPanel(context),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: notifState.isPermissionGranted ? AppColors.success : AppColors.accentOrange,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
