import 'package:flutter/foundation.dart';

class AppEnv {
  const AppEnv._();

  static const String _backendBaseUrlFromEnv = String.fromEnvironment(
    'PUGVPN_BACKEND_URL',
    defaultValue: '',
  );

  static String get backendBaseUrl => _backendBaseUrlFromEnv.isNotEmpty
      ? _backendBaseUrlFromEnv
      : _defaultBackendUrl();

  static String _defaultBackendUrl() {
    if (!kDebugMode) return 'http://178.17.60.48:8080';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator reaches host machine via 10.0.2.2.
        return 'http://10.0.2.2:8080';
      default:
        return 'http://127.0.0.1:8080';
    }
  }

  static const String backendEmail = String.fromEnvironment(
    'PUGVPN_BACKEND_EMAIL',
    defaultValue: 'demo@pugvpn.app',
  );

  static const String backendPassword = String.fromEnvironment(
    'PUGVPN_BACKEND_PASSWORD',
    defaultValue: 'demo1234',
  );
}
