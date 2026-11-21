import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLocaleKey = 'app_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  bool get isUrdu => state.languageCode == 'ur';

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLocaleKey);
      if (code != null && (code == 'ur' || code == 'en')) {
        state = Locale(code);
      }
    } catch (e) {
      debugPrint('Failed to load locale from SharedPreferences: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('Failed to save locale to SharedPreferences: $e');
    }
  }

  Future<void> toggleLocale() async {
    final next = state.languageCode == 'ur' ? const Locale('en') : const Locale('ur');
    await setLocale(next);
  }
}
