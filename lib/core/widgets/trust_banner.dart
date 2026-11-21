import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TrustBanner extends StatelessWidget {
  final VoidCallback? onWatchVideo;

  const TrustBanner({super.key, this.onWatchVideo});

  @override
  Widget build(BuildContext context) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user, color: AppColors.success, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUrdu ? 'پاکستان کا مصدقہ لاجسٹکس نیٹ ورک' : 'Verified Pakistan Logistics Network',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (onWatchVideo != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const Icon(Icons.play_circle_fill, size: 18),
                  label: Text(
                    isUrdu ? 'ویڈیو دیکھیں' : 'Watch Showcase',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: onWatchVideo,
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceAround,
            children: [
              _TrustBadgeItem(
                icon: Icons.shield,
                label: isUrdu ? 'نادرا ویریفائیڈ' : 'NADRA Verified',
                sub: isUrdu ? '100% تصدیق شدہ' : 'Govt API Match',
              ),
              _TrustBadgeItem(
                icon: Icons.alt_route,
                label: isUrdu ? 'ہائی وے پولیس' : 'NHMP Guidelines',
                sub: isUrdu ? 'محفوظ کوریڈورز' : 'M-5 / N-5 Safe',
              ),
              _TrustBadgeItem(
                icon: Icons.local_shipping,
                label: isUrdu ? '۱۰،۰۰۰+ ٹرکس' : '10,000+ Fleets',
                sub: isUrdu ? 'پورے پاکستان میں' : 'Active Nationwide',
              ),
              _TrustBadgeItem(
                icon: Icons.lock_clock,
                label: isUrdu ? 'محفوظ ادائیگیاں' : 'Instant Escrow',
                sub: isUrdu ? 'کیش لیس / جاز کیش' : 'Guaranteed Rates',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _TrustBadgeItem({
    required this.icon,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accent, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
