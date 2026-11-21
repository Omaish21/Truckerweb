import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utilities for handling Urdu typography and numerals in TruckLink PK
class UrduTextUtils {
  UrduTextUtils._();

  /// Returns standard Urdu Nastaliq typography style
  static TextStyle nastaliqStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double height = 1.6,
  }) {
    return GoogleFonts.notoNastaliqUrdu(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Converts English ASCII digits (0-9) to Urdu digits (۰-۹)
  static String toUrduNumerals(String input) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const urduDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (int i = 0; i < englishDigits.length; i++) {
      result = result.replaceAll(englishDigits[i], urduDigits[i]);
    }
    return result;
  }

  /// Checks if current locale or text direction is RTL
  static bool isRtl(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }
}
