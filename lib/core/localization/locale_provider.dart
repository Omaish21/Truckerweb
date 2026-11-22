import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLocaleKey = 'app_locale';

/// Pure Flutter ChangeNotifier for app localization.
/// Zero third-party state management dependency.
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;
  bool get isUrdu => _locale.languageCode == 'ur';
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLocaleKey);
      if (code != null && (code == 'ur' || code == 'en')) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load locale from SharedPreferences: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('Failed to save locale to SharedPreferences: $e');
    }
  }

  Future<void> toggleLocale() async {
    final next = _locale.languageCode == 'ur' ? const Locale('en') : const Locale('ur');
    await setLocale(next);
  }
}
