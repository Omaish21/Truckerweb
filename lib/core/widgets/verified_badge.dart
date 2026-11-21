import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/colors.dart';

class VerifiedBadge extends StatelessWidget {
  final bool? isVerified;
  final String? status; // 'verified', 'pending', 'unverified'
  final String? customLabel;

  const VerifiedBadge({
    super.key,
    this.isVerified,
    this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final effectiveStatus = status ?? ((isVerified ?? false) ? 'verified' : 'unverified');

    if (effectiveStatus == 'verified') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified,
              size: 15,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              customLabel ?? (l10n?.verifiedBadgeText ?? (isUrdu ? 'نادرا تصدیق شدہ' : 'NADRA Verified')),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    } else if (effectiveStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top, size: 14, color: Colors.amber.shade900),
            const SizedBox(width: 4),
            Text(
              customLabel ?? (isUrdu ? 'تصدیق جاری ہے' : 'Verification Pending'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pending_outlined, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            customLabel ?? (l10n?.unverifiedBadgeText ?? (isUrdu ? 'غیر تصدیق شدہ' : 'Unverified')),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
