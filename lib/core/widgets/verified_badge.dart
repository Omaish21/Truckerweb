import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/colors.dart';

class VerifiedBadge extends StatelessWidget {
  final bool isVerified;
  final String? customLabel;

  const VerifiedBadge({
    super.key,
    this.isVerified = true,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaultVerified = l10n?.verifiedBadgeText ?? 'NADRA Verified';
    final defaultUnverified = l10n?.unverifiedBadgeText ?? 'Unverified';

    if (!isVerified) {
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
              customLabel ?? defaultUnverified,
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
            customLabel ?? defaultVerified,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
