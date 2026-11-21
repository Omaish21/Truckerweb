import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../theme/colors.dart';

class NotificationBellButton extends ConsumerWidget {
  final bool compact;

  const NotificationBellButton({super.key, this.compact = false});

  void _showNotificationPanel(BuildContext context, WidgetRef ref) {
    final notifState = ref.read(notificationStateProvider);
    final user = ref.read(authProvider).userProfile;
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
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    notifState.isPermissionGranted ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: notifState.isPermissionGranted ? AppColors.success : AppColors.accentOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notifState.isPermissionGranted ? l10n.alertsActive : l10n.enableAlerts,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: notifState.isPermissionGranted ? AppColors.success : AppColors.accentOrange,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notifState.isPermissionGranted
                              ? (isUrdu
                                  ? 'براؤزر اور ڈیوائس پر تمام الرٹس فعال ہیں'
                                  : 'Real-time FCM push alerts active for this browser')
                              : l10n.notificationsPermissionPrompt,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!notifState.isPermissionGranted) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                        final success = await ref
                            .read(notificationStateProvider.notifier)
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
                stream: ref
                    .read(firebaseServiceProvider)
                    .watchUserNotifications(user?.id ?? 'usr-101'),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          l10n.noNewNotifications,
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
                      final isRead = item['read'] == true;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isRead ? Colors.grey.shade200 : AppColors.accent.withValues(alpha: 0.3),
                          child: Icon(
                            item['type'] == 'new_bid'
                                ? Icons.monetization_on
                                : item['type'] == 'bid_accepted'
                                    ? Icons.check_circle
                                    : Icons.warning,
                            size: 16,
                            color: isRead ? Colors.grey : AppColors.primary,
                          ),
                        ),
                        title: Text(
                          item['title'] ?? 'Alert',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          item['body'] ?? '',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        trailing: !isRead
                            ? TextButton(
                                child: Text(l10n.markAsRead, style: const TextStyle(fontSize: 11)),
                                onPressed: () {
                                  ref
                                      .read(firebaseServiceProvider)
                                      .markNotificationAsRead(item['id'] as String);
                                },
                              )
                            : null,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationStateProvider);
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
          onPressed: () => _showNotificationPanel(context, ref),
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
