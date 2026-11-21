import 'package:flutter/material.dart';
import '../../../../core/services/audio_alert_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_models.dart';

class BridgeAlertBanner extends StatelessWidget {
  final BridgeClearanceAlert alert;
  final VoidCallback? onRerouteTap;

  const BridgeAlertBanner({
    super.key,
    required this.alert,
    this.onRerouteTap,
  });

  void _speakAlert(BuildContext context) {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final alertSpeech = isUrdu
        ? 'خبردار! آگے کم اونچائی والا پل ہے: ${alert.bridgeName}، اونچائی ${alert.clearanceHeightFt} فٹ، آپ کے ٹرک کی اونچائی ${alert.truckHeightFt} فٹ ہے۔ براہ کرم متبادل راستہ اختیار کریں۔'
        : 'Warning! Critical low bridge clearance ahead: ${alert.bridgeName}, clearance ${alert.clearanceHeightFt} feet, your truck is ${alert.truckHeightFt} feet. Please reroute immediately.';
    
    AudioAlertService().speakWarning(
      text: alertSpeech,
      languageCode: isUrdu ? 'ur' : 'en',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.criticalLowBridgeAhead,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${alert.bridgeName} (${alert.roadSegment})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: AppColors.accent, size: 28),
                tooltip: 'Listen Alert (سنیں)',
                onPressed: () => _speakAlert(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      l10n.bridgeClearance(alert.clearanceHeightFt.toString()),
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Container(height: 20, width: 1, color: Colors.white24),
                Column(
                  children: [
                    Text(
                      l10n.truckHeight(alert.truckHeightFt.toString()),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Container(height: 20, width: 1, color: Colors.white24),
                Column(
                  children: [
                    Text(
                      l10n.distanceAhead(alert.distanceAheadKm.toString()),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onRerouteTap != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.danger,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: onRerouteTap,
                icon: const Icon(Icons.alt_route, size: 16),
                label: Text(
                  l10n.tapToRecalculate,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
