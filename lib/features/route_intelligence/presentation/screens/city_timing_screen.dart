import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/route_models.dart';

class CityTimingScreen extends StatelessWidget {
  const CityTimingScreen({super.key});

  final List<CityTimingRule> _rules = const [
    CityTimingRule(
      id: 'karachi-heavy',
      cityName: 'Karachi',
      vehicleCategory: 'heavy',
      entryFrom: '23:00',
      entryUntil: '05:00',
      notes: 'Entry prohibited during day. Heavy container and trailer entry strictly allowed between 11 PM and 5 AM via Northern Bypass & Super Highway.',
      confidence: 0.95,
    ),
    CityTimingRule(
      id: 'lahore-heavy',
      cityName: 'Lahore',
      vehicleCategory: 'heavy',
      entryFrom: '22:00',
      entryUntil: '06:00',
      notes: 'Lahore Ring Road and interior freight corridors open 10 PM to 6 AM. Day entry requires special traffic police permit.',
      confidence: 0.90,
    ),
    CityTimingRule(
      id: 'islamabad-heavy',
      cityName: 'Islamabad / Rawalpindi',
      vehicleCategory: 'heavy',
      entryFrom: '23:00',
      entryUntil: '06:00',
      notes: 'Islamabad Expressway, I-9 Industrial Sector, and Faizabad intersection curfew 6 AM to 11 PM.',
      confidence: 0.88,
    ),
    CityTimingRule(
      id: 'multan-heavy',
      cityName: 'Multan',
      vehicleCategory: 'heavy',
      entryFrom: '21:00',
      entryUntil: '06:00',
      notes: 'Bosan Road & inner Bypass open for heavy trucks from 9 PM.',
      confidence: 0.85,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          ..._rules.map((rule) {
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
                        Text(
                          rule.cityName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.allowedEntryWindow(rule.entryFrom, rule.entryUntil),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rule.notes,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const Divider(height: 20),
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
              ),
            );
          }),
        ],
      ),
    );
  }
}
