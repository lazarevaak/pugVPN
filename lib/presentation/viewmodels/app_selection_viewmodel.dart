import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pug_vpn/core/providers.dart';
import 'package:pug_vpn/domain/entities/device_app.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';

class AppSelectionViewModel extends ChangeNotifier {
  static const String _selectionKey = 'selected_app_packages';
  static const Duration _macOsListTimeout = Duration(seconds: 4);

  AppSelectionViewModel({NativeVpnRepository? repository})
    : _repository = repository ?? createNativeVpnRepository();

  final NativeVpnRepository _repository;

  List<DeviceApp> _apps = <DeviceApp>[];
  Set<String> _selectedPackages = <String>{};
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<DeviceApp> get apps => _apps;
  Set<String> get selectedPackages => _selectedPackages;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCustomSelection =>
      _apps.isNotEmpty && _selectedPackages.length != _apps.length;
  List<String> get allPackages =>
      _apps.map((DeviceApp app) => app.packageName).toList(growable: false);
  bool get usesMacOSPicker => defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> ensureLoaded() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apps =
          defaultTargetPlatform == TargetPlatform.macOS
          ? await _repository.listInstalledApps().timeout(_macOsListTimeout)
          : await _repository.listInstalledApps();
      _apps = apps;
      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getStringList(_selectionKey) ?? <String>[];
      final availablePackages = apps
          .map((DeviceApp app) => app.packageName)
          .toSet();
      final restoredSelection = persisted
          .where(
            (String packageName) => availablePackages.contains(packageName),
          )
          .toSet();
      _selectedPackages = restoredSelection.isEmpty
          ? availablePackages
          : restoredSelection;
      _isLoaded = true;
      _loadIconsIfNeeded();
    } on TimeoutException {
      _apps = <DeviceApp>[];
      _selectedPackages = <String>{};
      _isLoaded = true;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickApps() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apps = await _repository.pickInstalledApps();
      _apps = _deduplicateApps(apps);
      _selectedPackages = _apps.map((DeviceApp app) => app.packageName).toSet();
      _isLoaded = true;
      _loadIconsIfNeeded();
      await _persistSelection();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggle(String packageName, bool value) {
    if (value) {
      _selectedPackages = <String>{..._selectedPackages, packageName};
    } else {
      final next = <String>{..._selectedPackages};
      next.remove(packageName);
      _selectedPackages = next;
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedPackages = _apps.map((DeviceApp app) => app.packageName).toSet();
    notifyListeners();
  }

  void reset() {
    _selectedPackages = <String>{};
    notifyListeners();
  }

  Future<void> saveSelection(Set<String> packages) async {
    final availablePackages = allPackages.toSet();
    _selectedPackages = packages
        .where((String packageName) => availablePackages.contains(packageName))
        .toSet();
    await _persistSelection();
    notifyListeners();
  }

  Future<void> _persistSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _selectionKey,
      _selectedPackages.toList(growable: false),
    );
  }

  List<DeviceApp> _deduplicateApps(List<DeviceApp> apps) {
    final byPackage = <String, DeviceApp>{};
    for (final app in apps) {
      byPackage[app.packageName] = app;
    }
    final values = byPackage.values.toList(growable: false);
    values.sort(
      (DeviceApp left, DeviceApp right) =>
          left.label.toLowerCase().compareTo(right.label.toLowerCase()),
    );
    return values;
  }

  Future<void> _loadIconsIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.macOS || _apps.isEmpty) {
      return;
    }

    final appsWithoutIcons = _apps
        .where((DeviceApp app) => app.iconBytes == null && (app.sourcePath?.isNotEmpty ?? false))
        .toList(growable: false);
    if (appsWithoutIcons.isEmpty) {
      return;
    }

    try {
      final icons = await _repository.loadInstalledAppIcons(appsWithoutIcons);
      if (icons.isEmpty) {
        return;
      }

      _apps = _apps.map((DeviceApp app) {
        final iconBytes = icons[app.packageName];
        if (iconBytes == null) return app;
        return app.copyWith(iconBytes: iconBytes);
      }).toList(growable: false);
      notifyListeners();
    } catch (_) {
      return;
    }
  }
}
