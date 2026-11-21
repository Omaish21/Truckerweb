import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum RoadHazardSeverity { medium, high, critical }

class RoadReportCategory {
  final String id;
  final String nameEn;
  final String nameUr;
  final String icon;
  final Color color;
  final RoadHazardSeverity severity;
  final Duration autoExpiry;

  const RoadReportCategory({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.icon,
    required this.color,
    required this.severity,
    required this.autoExpiry,
  });

  static const List<RoadReportCategory> all = [
    RoadReportCategory(
      id: 'kacha',
      nameEn: 'Kacha Road (Unpaved)',
      nameUr: 'کچا راستہ',
      icon: '🟤',
      color: AppColors.hazardKacha,
      severity: RoadHazardSeverity.medium,
      autoExpiry: Duration(days: 30),
    ),
    RoadReportCategory(
      id: 'broken',
      nameEn: 'Broken / Terrible Road',
      nameUr: 'ٹوٹی ہوئی سڑک / کھڈے',
      icon: '🔴',
      color: AppColors.hazardBroken,
      severity: RoadHazardSeverity.high,
      autoExpiry: Duration(days: 7),
    ),
    RoadReportCategory(
      id: 'flooded',
      nameEn: 'Flooded / Waterlogged',
      nameUr: 'سیلابی پانی / تالاب',
      icon: '🔵',
      color: AppColors.hazardFlooded,
      severity: RoadHazardSeverity.high,
      autoExpiry: Duration(hours: 24),
    ),
    RoadReportCategory(
      id: 'landslide',
      nameEn: 'Landslide Risk / Blocked',
      nameUr: 'لینڈ سلائیڈنگ / پہاڑی ملبہ',
      icon: '🟠',
      color: AppColors.hazardLandslide,
      severity: RoadHazardSeverity.critical,
      autoExpiry: Duration(hours: 48),
    ),
    RoadReportCategory(
      id: 'protest',
      nameEn: 'Protest / Sit-in / Dharna',
      nameUr: 'احتجاج / دھرنا / سڑک بند',
      icon: '🟣',
      color: AppColors.hazardProtest,
      severity: RoadHazardSeverity.high,
      autoExpiry: Duration(hours: 12),
    ),
    RoadReportCategory(
      id: 'accident',
      nameEn: 'Accident / Congestion',
      nameUr: 'حادثہ / ٹریفک جام',
      icon: '🚗',
      color: AppColors.hazardAccident,
      severity: RoadHazardSeverity.high,
      autoExpiry: Duration(hours: 6),
    ),
  ];

  static RoadReportCategory? findById(String id) {
    try {
      return all.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }
}
