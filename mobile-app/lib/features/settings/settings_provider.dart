import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String language = 'English';
  bool pushAlerts = true;

  void setThemeMode(ThemeMode value) {
    themeMode = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void setPushAlerts(bool value) {
    pushAlerts = value;
    notifyListeners();
  }
}
