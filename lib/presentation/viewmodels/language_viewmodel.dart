import 'package:flutter/material.dart';

enum AppLanguage { english, russian, spanish, turkish, portuguese }

class LanguageViewModel extends ChangeNotifier {
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  bool get isRussian => _language == AppLanguage.russian;
  Locale get locale => switch (_language) {
    AppLanguage.english => const Locale('en'),
    AppLanguage.russian => const Locale('ru'),
    AppLanguage.spanish => const Locale('es'),
    AppLanguage.turkish => const Locale('tr'),
    AppLanguage.portuguese => const Locale('pt'),
  };
  String get displayName => switch (_language) {
    AppLanguage.english => 'English',
    AppLanguage.russian => 'Русский',
    AppLanguage.spanish => 'Español',
    AppLanguage.turkish => 'Türkçe',
    AppLanguage.portuguese => 'Português',
  };

  void setLanguage(AppLanguage value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }
}
