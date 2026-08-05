import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _alertsKey = 'push_alerts';

  ThemeMode themeMode = ThemeMode.system;
  String language = 'English';
  bool pushAlerts = true;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = switch (prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    language = prefs.getString(_languageKey) ?? 'English';
    pushAlerts = prefs.getBool(_alertsKey) ?? true;
    notifyListeners();
  }

  bool get isSwahili => language == 'Swahili';

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
    notifyListeners();
  }

  Future<void> setPushAlerts(bool value) async {
    pushAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alertsKey, value);
    notifyListeners();
  }

  String text(String en, String sw) => isSwahili ? sw : en;
}
