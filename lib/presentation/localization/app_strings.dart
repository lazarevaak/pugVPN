import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:pug_vpn/presentation/viewmodels/language_viewmodel.dart';

class AppStrings {
  const AppStrings._(this._language);

  final AppLanguage _language;

  static AppStrings of(BuildContext context) {
    return AppStrings._(context.watch<LanguageViewModel>().language);
  }


  static AppStrings fromLanguage(AppLanguage language) {
    return AppStrings._(language);
  }

  String _t({
    required String en,
    String? ru,
    String? es,
    String? tr,
    String? pt,
  }) {
    return switch (_language) {
      AppLanguage.english => en,
      AppLanguage.russian => ru ?? en,
      AppLanguage.spanish => es ?? en,
      AppLanguage.turkish => tr ?? en,
      AppLanguage.portuguese => pt ?? en,
    };
  }

  String get homeTab => _t(
    en: 'Home',
    ru: 'Главная',
    es: 'Inicio',
    tr: 'Ana Sayfa',
    pt: 'Início',
  );
  String get locationsTab => _t(
    en: 'Locations',
    ru: 'Локации',
    es: 'Ubicaciones',
    tr: 'Konumlar',
    pt: 'Localizações',
  );
  String get settingsTab => _t(
    en: 'Settings',
    ru: 'Настройки',
    es: 'Ajustes',
    tr: 'Ayarlar',
    pt: 'Ajustes',
  );
  String get premiumTab => 'Premium';

  String get appName => 'pugVPN';
  String get locationsTitle => locationsTab;
  String get settingsTitle => settingsTab;
  String get selectAppsTitle => _t(
    en: 'Select Apps',
    ru: 'Выбор приложений',
    es: 'Seleccionar apps',
    tr: 'Uygulamaları Seç',
    pt: 'Selecionar apps',
  );
  String get premiumTitle => 'Premium';
  String get premiumComingSoon => _t(
    en: 'Coming soon. Premium features and extras will appear here soon.',
    ru: 'Coming soon. Скоро здесь появятся премиум-функции и дополнительные возможности.',
    es: 'Próximamente. Las funciones premium y extras aparecerán aquí pronto.',
    tr: 'Yakında. Premium özellikler ve ekstralar yakında burada olacak.',
    pt: 'Em breve. Recursos premium e extras aparecerão aqui em breve.',
  );

  String get connect => _t(
    en: 'CONNECT',
    ru: 'ПОДКЛЮЧИТЬ',
    es: 'CONECTAR',
    tr: 'BAĞLAN',
    pt: 'CONECTAR',
  );
  String get connecting => _t(
    en: 'CONNECTING...',
    ru: 'ПОДКЛЮЧЕНИЕ...',
    es: 'CONECTANDO...',
    tr: 'BAĞLANIYOR...',
    pt: 'CONECTANDO...',
  );
  String get disconnect => _t(
    en: 'DISCONNECT',
    ru: 'ОТКЛЮЧИТЬ',
    es: 'DESCONECTAR',
    tr: 'BAĞLANTIYI KES',
    pt: 'DESCONECTAR',
  );
  String get tapToSecure => _t(
    en: 'Tap to secure your connection',
    ru: 'Нажмите для защищенного соединения',
    es: 'Toca para proteger tu conexión',
    tr: 'Bağlantınızı korumak için dokunun',
    pt: 'Toque para proteger sua conexão',
  );
  String get connected => _t(
    en: 'Connected',
    ru: 'Подключено',
    es: 'Conectado',
    tr: 'Bağlandı',
    pt: 'Conectado',
  );
  String get disconnected => _t(
    en: 'Disconnected',
    ru: 'Отключено',
    es: 'Desconectado',
    tr: 'Bağlantı kesildi',
    pt: 'Desconectado',
  );
  String connectedTo(String location) => _t(
    en: 'Connected to $location',
    ru: 'Подключено к $location',
    es: 'Conectado a $location',
    tr: '$location konumuna bağlandı',
    pt: 'Conectado a $location',
  );
  String get notConnected => _t(
    en: 'Currently not connected',
    ru: 'Сейчас не подключено',
    es: 'Actualmente no conectado',
    tr: 'Şu anda bağlı değil',
    pt: 'Atualmente não conectado',
  );

  String get killSwitch => 'Kill Switch';
  String get autoConnect => _t(
    en: 'Auto Connect',
    ru: 'Автоподключение',
    es: 'Conexión automática',
    tr: 'Otomatik Bağlan',
    pt: 'Conexão automática',
  );
  String get darkMode => _t(
    en: 'Dark Mode',
    ru: 'Темная тема',
    es: 'Modo oscuro',
    tr: 'Koyu mod',
    pt: 'Modo escuro',
  );
  String get account => _t(
    en: 'Account',
    ru: 'Аккаунт',
    es: 'Cuenta',
    tr: 'Hesap',
    pt: 'Conta',
  );
  String get language => _t(
    en: 'Language',
    ru: 'Язык',
    es: 'Idioma',
    tr: 'Dil',
    pt: 'Idioma',
  );
  String get selectApps => selectAppsTitle;
  String get subscription => _t(
    en: 'Subscription',
    ru: 'Подписка',
    es: 'Suscripción',
    tr: 'Abonelik',
    pt: 'Assinatura',
  );
  String get about => _t(
    en: 'About',
    ru: 'О приложении',
    es: 'Acerca de',
    tr: 'Hakkında',
    pt: 'Sobre',
  );
  String get shareApp => _t(
    en: 'Share',
    ru: 'Поделиться',
    es: 'Compartir',
    tr: 'Paylaş',
    pt: 'Compartilhar',
  );
  String get shareCopied => _t(
    en: 'Share text copied',
    ru: 'Текст для отправки скопирован',
    es: 'Texto para compartir copiado',
    tr: 'Paylaşım metni kopyalandı',
    pt: 'Texto de compartilhamento copiado',
  );
  String get languageChoice => _t(
    en: 'Choose language',
    ru: 'Выберите язык',
    es: 'Elige un idioma',
    tr: 'Dil seçin',
    pt: 'Escolha um idioma',
  );
  String get aboutTitle => _t(
    en: 'About pugVPN',
    ru: 'О pugVPN',
    es: 'Acerca de pugVPN',
    tr: 'pugVPN Hakkında',
    pt: 'Sobre o pugVPN',
  );
  String get aboutBody => _t(
    en: 'pugVPN is a simple VPN client with location selection, light and dark themes, and per-app VPN controls.',
    ru: 'pugVPN это быстрый и простой VPN-клиент с выбором локаций, темной и светлой темой, а также управлением приложениями, которые используют VPN.',
    es: 'pugVPN es un cliente VPN simple con selección de ubicaciones, temas claro y oscuro, y control de VPN por aplicación.',
    tr: 'pugVPN; konum seçimi, açık ve koyu tema ile uygulama bazlı VPN kontrolü sunan basit bir VPN istemcisidir.',
    pt: 'pugVPN é um cliente VPN simples com seleção de localizações, temas claro e escuro e controle de VPN por aplicativo.',
  );
  String get close => _t(
    en: 'Close',
    ru: 'Закрыть',
    es: 'Cerrar',
    tr: 'Kapat',
    pt: 'Fechar',
  );

  String get english => 'English';
  String get russian => 'Русский';
  String get spanish => 'Español';
  String get turkish => 'Türkçe';
  String get portuguese => 'Português';

  String get onlySelectedApps => _t(
    en: 'Only the selected apps will use the VPN. By default, all installed apps are selected.',
    ru: 'Только выбранные приложения будут использовать VPN. По умолчанию выбраны все установленные приложения.',
    es: 'Solo las aplicaciones seleccionadas usarán la VPN. Por defecto, todas las aplicaciones instaladas están seleccionadas.',
    tr: 'Yalnızca seçilen uygulamalar VPN kullanacaktır. Varsayılan olarak yüklü tüm uygulamalar seçilidir.',
    pt: 'Apenas os aplicativos selecionados usarão a VPN. Por padrão, todos os aplicativos instalados estão selecionados.',
  );
  String get selected => _t(
    en: 'Selected',
    ru: 'Выбрано',
    es: 'Seleccionado',
    tr: 'Seçili',
    pt: 'Selecionado',
  );
  String get selectAll => _t(
    en: 'Select all',
    ru: 'Выбрать все',
    es: 'Seleccionar todo',
    tr: 'Tümünü seç',
    pt: 'Selecionar tudo',
  );
  String get chooseApps => _t(
    en: 'Choose apps',
    ru: 'Выбрать приложения',
    es: 'Elegir apps',
    tr: 'Uygulama seç',
    pt: 'Escolher apps',
  );
  String get reset => _t(
    en: 'Reset',
    ru: 'Сбросить',
    es: 'Restablecer',
    tr: 'Sıfırla',
    pt: 'Redefinir',
  );
  String get save => _t(
    en: 'Save',
    ru: 'Сохранить',
    es: 'Guardar',
    tr: 'Kaydet',
    pt: 'Salvar',
  );
  String get noAppsFound => _t(
    en: 'No launchable apps found on this device.',
    ru: 'На устройстве не найдено приложений.',
    es: 'No se encontraron aplicaciones ejecutables en este dispositivo.',
    tr: 'Bu cihazda çalıştırılabilir uygulama bulunamadı.',
    pt: 'Nenhum aplicativo executável foi encontrado neste dispositivo.',
  );
  String get noAppsSelectedMacos => _t(
    en: 'No apps selected yet. Open the native AppKit picker and choose the .app bundles you want.',
    ru: 'Приложения ещё не выбраны. Откройте системное окно AppKit и выберите нужные .app.',
    es: 'Aún no se han seleccionado aplicaciones. Abre el selector nativo de AppKit y elige los paquetes .app que quieras.',
    tr: 'Henüz uygulama seçilmedi. Yerel AppKit seçicisini açın ve istediğiniz .app paketlerini seçin.',
    pt: 'Ainda não há aplicativos selecionados. Abra o seletor nativo do AppKit e escolha os pacotes .app desejados.',
  );
}
