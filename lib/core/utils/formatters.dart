import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##,###', 'en_US');

  /// Formats amount in PKR (e.g., Rs. 85,000)
  static String formatPkr(num amount) {
    return 'Rs. ${_currencyFormat.format(amount)}';
  }

  /// Formats weight in tons (e.g., 25.5 Tons)
  static String formatWeight(double tons) {
    if (tons == tons.roundToDouble()) {
      return '${tons.toInt()} Tons / ٹن';
    }
    return '${tons.toStringAsFixed(1)} Tons / ٹن';
  }

  /// Formats distance in km
  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).toInt()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Formats any Pakistani mobile number to standard formatted view: +92 308 750 2250
  static String formatPakistaniPhoneNumber(String raw) {
    if (raw.trim().isEmpty) return '';
    // Strip everything except digits
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // Normalize leading national/international dialing prefixes
    if (digits.startsWith('0092')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('92')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.isEmpty) return '+92 ';

    // Limit to 10 national digits (3XX XXXXXXX)
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    final buffer = StringBuffer('+92 ');
    if (digits.length <= 3) {
      buffer.write(digits);
    } else if (digits.length <= 6) {
      buffer.write('${digits.substring(0, 3)} ${digits.substring(3)}');
    } else {
      buffer.write('${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}');
    }
    return buffer.toString();
  }
}

/// Real-time automatic formatter for Pakistani mobile numbers in TextFormFields.
/// Produces: +92 308 750 2250 as the user types.
class PakistaniPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // If user is clearing and only '+92' or '+92 ' remains, allow clearing completely
    final trimmed = newValue.text.trim();
    if (trimmed == '+92' || trimmed == '+' || trimmed == '+9') {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final formatted = AppFormatters.formatPakistaniPhoneNumber(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
