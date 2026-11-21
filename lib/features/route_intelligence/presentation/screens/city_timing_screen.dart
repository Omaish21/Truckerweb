import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('City Entry Timing / شہروں کے اوقات'),
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
                    children: const [
                      Text(
                        'Heavy Vehicle Curfew Windows',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Timings are actively verified via traffic police bulletins and driver reports to avoid costly fines or impounds.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._rules.map((rule) {
            final isAllowed = rule.isEntryAllowedNow();
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_city, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              rule.cityName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAllowed ? AppColors.success : AppColors.danger,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAllowed ? '🟢 ENTRY OPEN' : '🔴 CLOSED NOW',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Allowed Entry Window: ${rule.entryFrom} - ${rule.entryUntil}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rule.notes,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_parking, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Suggested Parking: Near ${rule.cityName} Toll Plaza / Ring Road Layover',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
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
