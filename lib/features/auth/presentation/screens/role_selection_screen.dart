import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_scope.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    final authPhone = context.auth.state.userProfile?.phone.isNotEmpty == true
        ? context.auth.state.userProfile!.phone
        : (context.auth.state.phoneNumber ??
            FirebaseService.instance.auth?.currentUser?.phoneNumber ??
            '');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28, borderRadius: 6),
            const SizedBox(width: 10),
            Text(l10n.selectRoleTitle),
          ],
        ),
        centerTitle: true,
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: LanguageToggleButton(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: isUrdu ? 'لاگ آؤٹ' : 'Logout',
            onPressed: () {
              context.authActions.logout();
              context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                l10n.selectRoleHeader,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),

              // Active Contact Number Badge
              if (authPhone.isNotEmpty) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_android, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          isUrdu
                              ? 'رابطہ نمبر: ${AppFormatters.formatPakistaniPhoneNumber(authPhone)}'
                              : 'Contact Number: ${AppFormatters.formatPakistaniPhoneNumber(authPhone)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 15, color: AppColors.success),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 1. Driver Card
              _RoleCard(
                icon: Icons.drive_eta_rounded,
                title: l10n.driverRole,
                subtitle: l10n.driverRoleSubtitle,
                description: l10n.driverRoleDescription,
                badgeColor: AppColors.accent,
                onTap: () {
                  context.authActions.switchRole('driver');
                  context.go('/driver-home');
                },
              ),

              const SizedBox(height: 16),

              // 2. Owner / Shipper Card
              _RoleCard(
                icon: Icons.business_center_rounded,
                title: l10n.ownerRole,
                subtitle: l10n.ownerRoleSubtitle,
                description: l10n.ownerRoleDescription,
                badgeColor: AppColors.primary,
                onTap: () {
                  context.authActions.switchRole('owner');
                  context.go('/loads-feed');
                },
              ),

              const SizedBox(height: 16),

              // 3. Freight Broker & Transporter / اڈا کمیشن ایجنٹ
              _RoleCard(
                icon: Icons.hub_rounded,
                title: isUrdu ? 'ٹرانسپورٹ ایجنٹ / اڈا کمیشن بروکر' : 'Freight Broker & Fleet Transporter',
                subtitle: isUrdu ? 'ملک گیر روٹ ٹرپس اور گاڑیوں کے بیڑے' : 'Corridor routes, bulk dispatches & fleet contracts',
                description: isUrdu
                    ? 'نئے روٹ ٹرپس اور مال کے سودے پوسٹ کریں، متعدد گاڑیوں کے بیڑے بک کروائیں اور بیوپاریوں کو رجسٹرڈ ڈرائیورز سے جوڑیں۔'
                    : 'Post regular corridor trips and freight dispatches, manage multiple truck bookings, and broker cargo contracts.',
                badgeColor: const Color(0xFF00897B),
                onTap: () {
                  context.authActions.switchRole('broker');
                  context.go('/loads-feed');
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color badgeColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: badgeColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
