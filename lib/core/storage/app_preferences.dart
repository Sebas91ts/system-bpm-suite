import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appPreferencesProvider = ChangeNotifierProvider<AppPreferences>((ref) {
  return AppPreferences(const FlutterSecureStorage());
});

class AppPreferences extends ChangeNotifier {
  AppPreferences(this._storage);

  static const _themeKey = 'preferred_theme_mode';
  static const _localeKey = 'preferred_locale_code';

  final FlutterSecureStorage _storage;

  ThemeMode _themeMode = ThemeMode.dark;
  String _localeCode = 'es';
  bool _bootstrapped = false;

  ThemeMode get themeMode => _themeMode;
  String get localeCode => _localeCode;

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }

    _bootstrapped = true;
    final savedTheme = await _storage.read(key: _themeKey);
    final savedLocale = await _storage.read(key: _localeKey);

    _themeMode = _parseThemeMode(savedTheme);
    _localeCode = _parseLocaleCode(savedLocale);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode next) async {
    _themeMode = next;
    await _storage.write(key: _themeKey, value: _themeMode.name);
    notifyListeners();
  }

  Future<void> setLocaleCode(String next) async {
    _localeCode = _parseLocaleCode(next);
    await _storage.write(key: _localeKey, value: _localeCode);
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  String _parseLocaleCode(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized == 'en') {
      return 'en';
    }
    return 'es';
  }
}
