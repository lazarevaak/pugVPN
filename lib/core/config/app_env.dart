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
    return 'http://84.252.140.117:8080';
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
