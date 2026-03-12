import 'package:flutter/services.dart';

import 'package:pug_vpn/core/exceptions/backend_exception.dart';

class NativeVpnDao {
  const NativeVpnDao();

  static const MethodChannel _channel = MethodChannel('pug_vpn/awg');

  Future<bool> prepare() async {
    try {
      final result = await _channel.invokeMethod<bool>('prepare');
      return result ?? false;
    } on MissingPluginException {
      throw const BackendException(
        'Native VPN bridge не найден на этой платформе.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<bool> connect({
    required String config,
    required String tunnelName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'connect',
        <String, dynamic>{'config': config, 'tunnelName': tunnelName},
      );
      return result ?? false;
    } on MissingPluginException {
      throw const BackendException(
        'Native VPN bridge не найден на этой платформе.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<bool> importConfig({
    required String config,
    required String tunnelName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'importConfig',
        <String, dynamic>{'config': config, 'tunnelName': tunnelName},
      );
      return result ?? false;
    } on MissingPluginException {
      throw const BackendException(
        'iOS import bridge не найден. Проверь сборку iOS.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod<bool>('disconnect');
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }
}
