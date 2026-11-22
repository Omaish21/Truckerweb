import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_models.dart';

class CityTimingScreen extends ConsumerWidget {
  const CityTimingScreen({super.key});

  static const List<CityTimingRule> _defaultRules = [
    CityTimingRule(
      id: 'karachi-heavy',
      cityName: 'Karachi (کراچی)',
      vehicleCategory: 'heavy',
      entryFrom: '23:00',
      entryUntil: '05:00',
      notes: 'Entry prohibited during day. Heavy container and trailer entry strictly allowed between 11 PM and 5 AM via Northern Bypass & Super Highway.',
      confidence: 0.98,
    ),
    CityTimingRule(
      id: 'lahore-heavy',
      cityName: 'Lahore (لاہور)',
      vehicleCategory: 'heavy',
      entryFrom: '22:00',
      entryUntil: '06:00',
      notes: 'Lahore Ring Road and interior freight corridors open 10 PM to 6 AM. Day entry requires special traffic police permit.',
      confidence: 0.95,
    ),
    CityTimingRule(
      id: 'islamabad-heavy',
      cityName: 'Islamabad / Rawalpindi (اسلام آباد / راولپنڈی)',
      vehicleCategory: 'heavy',
      entryFrom: '23:00',
      entryUntil: '06:00',
      notes: 'Islamabad Expressway, I-9 Industrial Sector, and Faizabad intersection curfew 6 AM to 11 PM.',
      confidence: 0.92,
    ),
    CityTimingRule(
      id: 'multan-heavy',
      cityName: 'Multan (ملتان)',
      vehicleCategory: 'heavy',
      entryFrom: '21:00',
      entryUntil: '06:00',
      notes: 'Bosan Road & inner Bypass open for heavy trucks from 9 PM.',
      confidence: 0.90,
    ),
  ];

  _CityCountdownInfo _computeStatus(CityTimingRule rule, bool isUrdu) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final fromParts = rule.entryFrom.split(':');
    final untilParts = rule.entryUntil.split(':');
    final fromMin = int.parse(fromParts[0]) * 60 + int.parse(fromParts[1]);
    final untilMin = int.parse(untilParts[0]) * 60 + int.parse(untilParts[1]);

    bool allowed;
    int minutesUntilOpen;

    if (fromMin < untilMin) {
      allowed = currentMinutes >= fromMin && currentMinutes <= untilMin;
      if (allowed) {
        minutesUntilOpen = 0;
      } else if (currentMinutes < fromMin) {
        minutesUntilOpen = fromMin - currentMinutes;
      } else {
        minutesUntilOpen = (24 * 60 - currentMinutes) + fromMin;
      }
    } else {
      allowed = currentMinutes >= fromMin || currentMinutes <= untilMin;
      if (allowed) {
        minutesUntilOpen = 0;
      } else {
        minutesUntilOpen = fromMin - currentMinutes;
      }
    }

    final h = minutesUntilOpen ~/ 60;
    final m = minutesUntilOpen % 60;

    if (allowed) {
      return _CityCountdownInfo(
        isOpen: true,
        badgeLabel: isUrdu ? 'داخلہ کھلا ہے' : 'Entry Open',
        countdownDetails: isUrdu
            ? 'سبز نشان: داخلہ ${rule.entryUntil} بجے تک بلا روک ٹوک جاری رہے گا'
            : 'Green Flag: Open until ${rule.entryUntil}',
      );
    } else {
      final timeStr = isUrdu ? '$h گھنٹے $m منٹ' : '${h}h ${m}m';
      return _CityCountdownInfo(
        isOpen: false,
        badgeLabel: isUrdu ? 'نو اینٹری فعال' : 'No-Entry Active',
        countdownDetails: isUrdu
            ? 'سرخ نشان: داخلہ ممنوع — $timeStr میں کھلے گا (${rule.entryFrom} بجے)'
            : 'Red Alert: No-Entry Active — Opens in $timeStr (at ${rule.entryFrom})',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final timingsAsync = ref.watch(firebaseCityTimingsStreamProvider);
    final rules = (timingsAsync.value != null && timingsAsync.value!.isNotEmpty)
        ? timingsAsync.value!
        : _defaultRules;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cityTimingTitle),
        actions: const [
          Center(child: LanguageToggleButton(compact: true)),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.heavyCurfewHeader,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.curfewExplanation,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...rules.map((rule) {
            final info = _computeStatus(rule, isUrdu);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rule.cityName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: info.isOpen
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: info.isOpen ? AppColors.success : AppColors.danger,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                info.isOpen ? Icons.check_circle : Icons.timer,
                                size: 14,
                                color: info.isOpen ? AppColors.success : AppColors.danger,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                info.badgeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: info.isOpen ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Live Ticker / Countdown Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: info.isOpen ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            info.isOpen ? Icons.directions_bus : Icons.lock_clock,
                            size: 16,
                            color: info.isOpen ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              info.countdownDetails,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: info.isOpen ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      rule.notes,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.allowedEntryWindow(rule.entryFrom, rule.entryUntil),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.verifiedConfidence((rule.confidence * 100).toInt().toString()),
                              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CityCountdownInfo {
  final bool isOpen;
  final String badgeLabel;
  final String countdownDetails;

  const _CityCountdownInfo({
    required this.isOpen,
    required this.badgeLabel,
    required this.countdownDetails,
  });
}
