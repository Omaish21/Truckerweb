import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand palette (Deep logistics slate & vibrant highway amber/emerald)
  static const Color primary = Color(0xFF0F2B48); // Deep Navy
  static const Color primaryLight = Color(0xFF1E3A5F);
  static const Color accent = Color(0xFFF59E0B); // Amber / Highway Yellow
  static const Color accentOrange = Color(0xFFF97316);
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color danger = Color(0xFFEF4444); // Alert Red (bridge/hazard)
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Road hazard severity colors
  static const Color hazardKacha = Color(0xFF8D6E63);
  static const Color hazardBroken = Color(0xFFEF4444);
  static const Color hazardFlooded = Color(0xFF2563EB);
  static const Color hazardLandslide = Color(0xFFEA580C);
  static const Color hazardProtest = Color(0xFF7C3AED);
  static const Color hazardAccident = Color(0xFFDC2626);

  // Backgrounds & Neutrals
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0B132B);
  static const Color surfaceDark = Color(0xFF1C2541);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF2B3A67);
}
