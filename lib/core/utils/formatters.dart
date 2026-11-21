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
}
