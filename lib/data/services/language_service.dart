import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LanguageService — управление языком приложения.
///
/// Использование в SettingsScreen:
/// ```dart
/// await LanguageService.setLocale(context, Locale('kk'));
/// ```
class LanguageService {
  static const _kLocaleKey = 'qayda_locale';

  static const locales = [
    Locale('ru'),
    Locale('kk'),
  ];

  static const localeNames = {
    'ru': 'Русский',
    'kk': 'Қазақша',
  };

  /// Получить текущую локаль
  static Locale currentLocale(BuildContext context) => context.locale;

  /// Сменить язык приложения
  static Future<void> setLocale(BuildContext context, Locale locale) async {
    await context.setLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  /// Получить сохранённую локаль (для восстановления без контекста)
  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code == null) return null;
    return Locale(code);
  }
}
