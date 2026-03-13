import 'package:flutter/material.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setDarkMode(bool value) {
    final next = value ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == next) return;
    _themeMode = next;
    notifyListeners();
  }
}
