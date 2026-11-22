import 'package:flutter/material.dart';

/// Utilities and widgets for handling authentic iOS-style Nastaliq Urdu typography in TruckLink PK
class UrduTextUtils {
  UrduTextUtils._();

  /// Primary iOS-style Urdu Nastaliq typography style
  /// Nastaliq font requires generous line height (height: 1.9-2.2) to prevent clipping of diacritic dots (nuqtas)
  static TextStyle nastaliqStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double height = 2.0,
  }) {
    return TextStyle(
      fontFamily: 'Noto Nastaliq Urdu',
      fontFamilyFallback: const ['Urdu Typesetting', 'Tahoma', 'Arial', 'sans-serif'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Converts English ASCII digits (0-9) to standard Urdu digits (۰-۹)
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

/// Convenience widget to render Urdu text with authentic Nastaliq styling,
/// RTL text direction, and proper vertical padding to prevent glyph clipping.
class UrduText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const UrduText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    final urduStyle = UrduTextUtils.nastaliqStyle(
      fontSize: baseStyle.fontSize ?? 16,
      fontWeight: baseStyle.fontWeight ?? FontWeight.normal,
      color: baseStyle.color,
      height: baseStyle.height ?? 2.0,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        text,
        style: urduStyle,
        textAlign: textAlign ?? TextAlign.right,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }
}
