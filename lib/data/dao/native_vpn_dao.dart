import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:pug_vpn/core/exceptions/backend_exception.dart';
import 'package:pug_vpn/domain/entities/device_app.dart';
import 'package:pug_vpn/domain/entities/device_key_pair.dart';

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

  Future<Map<String, dynamic>> status() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'status',
      );
      if (result == null) {
        return const <String, dynamic>{'state': 'down', 'is_connected': false};
      }

      return result.map(
        (Object? key, Object? value) => MapEntry(key?.toString() ?? '', value),
      );
    } on MissingPluginException {
      throw const BackendException(
        'Native VPN bridge не найден на этой платформе.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<DeviceKeyPair?> loadDeviceKeyPair() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'loadDeviceKeyPair',
      );
      if (result == null) {
        return null;
      }

      final mapped = result.map(
        (Object? key, Object? value) => MapEntry(key?.toString() ?? '', value),
      );
      final keyPair = DeviceKeyPair.fromJson(mapped);
      if (keyPair.privateKeyBase64.isEmpty || keyPair.publicKeyBase64.isEmpty) {
        return null;
      }
      return keyPair;
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      if (error.code == 'MissingPluginException') {
        return null;
      }
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<void> saveDeviceKeyPair(DeviceKeyPair keyPair) async {
    try {
      await _channel.invokeMethod<void>('saveDeviceKeyPair', keyPair.toJson());
    } on MissingPluginException {
      return;
    } on PlatformException catch (error) {
      if (error.code == 'MissingPluginException') {
        return;
      }
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<List<DeviceApp>> listInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'listInstalledApps',
      );
      return (result ?? <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(DeviceApp.fromMap)
          .where((DeviceApp app) => app.packageName.isNotEmpty)
          .toList();
    } on MissingPluginException {
      throw const BackendException(
        'Installed apps are not available on this platform.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<List<DeviceApp>> pickInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'pickInstalledApps',
      );
      return (result ?? <Object?>[])
          .whereType<Map<Object?, Object?>>()
          .map(DeviceApp.fromMap)
          .where((DeviceApp app) => app.packageName.isNotEmpty)
          .toList();
    } on MissingPluginException {
      throw const BackendException(
        'Native app picker не найден на этой платформе.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<Map<String, Uint8List>> loadInstalledAppIcons(List<DeviceApp> apps) async {
    try {
      final payload = apps
          .map((DeviceApp app) => app.toMap())
          .toList(growable: false);
      final result = await _channel.invokeMethod<List<Object?>>(
        'loadInstalledAppIcons',
        payload,
      );
      final icons = <String, Uint8List>{};
      for (final entry in result ?? <Object?>[]) {
        if (entry is! Map<Object?, Object?>) continue;
        final packageName = entry['packageName'] as String?;
        final iconBase64 = entry['iconBase64'] as String?;
        if (packageName == null || packageName.isEmpty) continue;
        if (iconBase64 == null || iconBase64.isEmpty) continue;
        icons[packageName] = base64Decode(iconBase64);
      }
      return icons;
    } on MissingPluginException {
      return <String, Uint8List>{};
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }

  Future<bool> shareText(String text) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'shareText',
        <String, dynamic>{'text': text},
      );
      return result ?? false;
    } on MissingPluginException {
      throw const BackendException(
        'Native share bridge не найден на этой платформе.',
      );
    } on PlatformException catch (error) {
      throw BackendException(error.message ?? error.code);
    }
  }
}
