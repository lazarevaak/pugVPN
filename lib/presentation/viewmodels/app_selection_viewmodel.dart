import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pug_vpn/core/providers.dart';
import 'package:pug_vpn/domain/entities/device_app.dart';
import 'package:pug_vpn/domain/repositories/native_vpn_repository.dart';

class AppSelectionViewModel extends ChangeNotifier {
  static const String _selectionKey = 'selected_app_packages';

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

  Future<void> ensureLoaded() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apps = await _repository.listInstalledApps();
      _apps = apps;
      final prefs = await SharedPreferences.getInstance();
      final persisted = prefs.getStringList(_selectionKey) ?? <String>[];
      final availablePackages =
          apps.map((DeviceApp app) => app.packageName).toSet();
      final restoredSelection = persisted
          .where((String packageName) => availablePackages.contains(packageName))
          .toSet();
      _selectedPackages = restoredSelection.isEmpty
          ? availablePackages
          : restoredSelection;
      _isLoaded = true;
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
    _selectedPackages = _apps.map((DeviceApp app) => app.packageName).toSet();
    notifyListeners();
  }

  Future<void> saveSelection(Set<String> packages) async {
    final availablePackages = allPackages.toSet();
    _selectedPackages = packages
        .where((String packageName) => availablePackages.contains(packageName))
        .toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _selectionKey,
      _selectedPackages.toList(growable: false),
    );
    notifyListeners();
  }
}
