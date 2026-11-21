class AppValidators {
  AppValidators._();

  /// Validates Pakistani CNIC with or without dashes (13 digits total)
  /// Format: 12345-1234567-1 or 1234512345671
  static String? validateCnic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CNIC number is required / شناختی کارڈ نمبر درج کریں';
    }
    final clean = value.replaceAll('-', '').trim();
    if (clean.length != 13 || int.tryParse(clean) == null) {
      return 'Valid 13-digit CNIC required (e.g. 42101-1234567-1)';
    }
    return null;
  }

  /// Formats raw 13 digits to standard Pakistani CNIC format XXXXX-XXXXXXX-X
  static String formatCnic(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length <= 5) return clean;
    if (clean.length <= 12) {
      return '${clean.substring(0, 5)}-${clean.substring(5)}';
    }
    return '${clean.substring(0, 5)}-${clean.substring(5, 12)}-${clean.substring(12, clean.length > 13 ? 13 : clean.length)}';
  }

  /// Validates Pakistani phone number: 03001234567 or +923001234567
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required / فون نمبر درج کریں';
    }
    final clean = value.replaceAll(' ', '').replaceAll('-', '').trim();
    final pkPhoneRegex = RegExp(r'^((\+92)|(0092)|(92)|0)?(3[0-9]{9})$');
    if (!pkPhoneRegex.hasMatch(clean)) {
      return 'Enter a valid Pakistani mobile number (e.g. 0300 1234567)';
    }
    return null;
  }

  /// Normalizes to standard +923XXXXXXXXX
  static String normalizePhone(String raw) {
    var clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('03')) {
      return '+92${clean.substring(1)}';
    } else if (clean.startsWith('923')) {
      return '+$clean';
    } else if (clean.startsWith('00923')) {
      return '+92${clean.substring(4)}';
    }
    return clean;
  }
}
