import 'package:flutter/material.dart';

enum AppLanguage { english, russian }

class LanguageViewModel extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  bool get isRussian => _language == AppLanguage.russian;
  Locale get locale => isRussian ? const Locale('ru') : const Locale('en');
  String get displayName => isRussian ? 'Русский' : 'English';

  void setLanguage(AppLanguage value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }
}
