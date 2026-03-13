import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/viewmodels/language_viewmodel.dart';

class AppStrings {
  const AppStrings._(this._isRussian);

  final bool _isRussian;

  static AppStrings of(BuildContext context) {
    return AppStrings._(context.watch<LanguageViewModel>().isRussian);
  }

  static AppStrings fromLanguage(bool isRussian) {
    return AppStrings._(isRussian);
  }

  String get homeTab => _isRussian ? 'Главная' : 'Home';
  String get locationsTab => _isRussian ? 'Локации' : 'Locations';
  String get settingsTab => _isRussian ? 'Настройки' : 'Settings';
  String get premiumTab => 'Premium';

  String get appName => 'PugVPN';
  String get locationsTitle => _isRussian ? 'Локации' : 'Locations';
  String get settingsTitle => _isRussian ? 'Настройки' : 'Settings';
  String get selectAppsTitle => _isRussian ? 'Выбор приложений' : 'Select Apps';
  String get premiumTitle => 'Premium';
  String get premiumComingSoon => _isRussian
      ? 'Coming soon. Скоро здесь появятся премиум-функции и дополнительные возможности.'
      : 'Coming soon. Premium features and extras will appear here soon.';

  String get connect => _isRussian ? 'ПОДКЛЮЧИТЬ' : 'CONNECT';
  String get connecting => _isRussian ? 'ПОДКЛЮЧЕНИЕ...' : 'CONNECTING...';
  String get disconnect => _isRussian ? 'ОТКЛЮЧИТЬ' : 'DISCONNECT';
  String get tapToSecure =>
      _isRussian ? 'Нажмите для защищенного соединения' : 'Tap to secure your connection';
  String get connected => _isRussian ? 'Подключено' : 'Connected';
  String get disconnected => _isRussian ? 'Отключено' : 'Disconnected';
  String connectedTo(String location) =>
      _isRussian ? 'Подключено к $location' : 'Connected to $location';
  String get notConnected =>
      _isRussian ? 'Сейчас не подключено' : 'Currently not connected';

  String get killSwitch => 'Kill Switch';
  String get autoConnect => _isRussian ? 'Автоподключение' : 'Auto Connect';
  String get darkMode => _isRussian ? 'Темная тема' : 'Dark Mode';
  String get account => _isRussian ? 'Аккаунт' : 'Account';
  String get language => _isRussian ? 'Язык' : 'Language';
  String get selectApps => _isRussian ? 'Выбор приложений' : 'Select Apps';
  String get subscription => _isRussian ? 'Подписка' : 'Subscription';
  String get about => _isRussian ? 'О приложении' : 'About';
  String get shareApp => _isRussian ? 'Поделиться' : 'Share';
  String get shareCopied =>
      _isRussian ? 'Текст для отправки скопирован' : 'Share text copied';
  String get languageChoice =>
      _isRussian ? 'Выберите язык' : 'Choose language';
  String get aboutTitle => _isRussian ? 'О PugVPN' : 'About PugVPN';
  String get aboutBody => _isRussian
      ? 'PugVPN это быстрый и простой VPN-клиент с выбором локаций, темной и светлой темой, а также управлением приложениями, которые используют VPN.'
      : 'PugVPN is a simple VPN client with location selection, light and dark themes, and per-app VPN controls.';
  String get close => _isRussian ? 'Закрыть' : 'Close';

  String get english => 'English';
  String get russian => 'Русский';

  String get onlySelectedApps =>
      _isRussian
          ? 'Только выбранные приложения будут использовать VPN. По умолчанию выбраны все установленные приложения.'
          : 'Only the selected apps will use the VPN. By default, all installed apps are selected.';
  String get selected => _isRussian ? 'Выбрано' : 'Selected';
  String get selectAll => _isRussian ? 'Выбрать все' : 'Select all';
  String get reset => _isRussian ? 'Сбросить' : 'Reset';
  String get save => _isRussian ? 'Сохранить' : 'Save';
  String get noAppsFound =>
      _isRussian ? 'На устройстве не найдено приложений.' : 'No launchable apps found on this device.';
}
