import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pug_vpn/domain/usecases/connect_vpn_use_case.dart';
import 'package:pug_vpn/domain/usecases/disconnect_vpn_use_case.dart';
import 'package:pug_vpn/domain/usecases/get_vpn_status_use_case.dart';
import 'package:pug_vpn/domain/usecases/share_app_use_case.dart';
import 'package:pug_vpn/presentation/viewmodels/app_selection_viewmodel.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required AppSelectionViewModel appSelectionViewModel,
    required ConnectVpnUseCase connectVpnUseCase,
    required DisconnectVpnUseCase disconnectVpnUseCase,
    required GetVpnStatusUseCase getVpnStatusUseCase,
    required ShareAppUseCase shareAppUseCase,
  }) : _appSelectionViewModel = appSelectionViewModel,
       _connectVpnUseCase = connectVpnUseCase,
       _disconnectVpnUseCase = disconnectVpnUseCase,
       _getVpnStatusUseCase = getVpnStatusUseCase,
       _shareAppUseCase = shareAppUseCase;

  final AppSelectionViewModel _appSelectionViewModel;
  final ConnectVpnUseCase _connectVpnUseCase;
  final DisconnectVpnUseCase _disconnectVpnUseCase;
  final GetVpnStatusUseCase _getVpnStatusUseCase;
  final ShareAppUseCase _shareAppUseCase;

  Timer? _vpnStatusTimer;
  bool _initialized = false;

  bool _isConnecting = false;
  bool _isConnected = false;
  String _location = 'Auto';
  String _locationDetails = 'Fastest location';
  String _statusLabel = 'Disconnected';
  String? _errorMessage;

  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String get location => _location;
  String get locationDetails => _locationDetails;
  String get statusLabel => _statusLabel;
  String? get errorMessage => _errorMessage;
  String get displayLocation => _isConnected ? _location : 'RU';
  String get displayLocationDetails => _isConnected ? _locationDetails : 'Russia';

  bool get _useNativeTunnel =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _startVpnStatusPolling();
    unawaited(_syncVpnStatusOnce());
  }

  @override
  void dispose() {
    _vpnStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> toggleConnection() async {
    if (_isConnecting) return;
    if (_isConnected) {
      await disconnect();
      return;
    }
    await connect();
  }

  Future<void> connect() async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _appSelectionViewModel.ensureLoaded();
      final session = await _connectVpnUseCase.execute(
        deviceName: _buildDeviceName(),
        useNativeTunnel: _useNativeTunnel,
        allPackages: _appSelectionViewModel.allPackages,
        selectedPackages: _appSelectionViewModel.selectedPackages.toList(
          growable: false,
        ),
        onProgress: (String status) {
          _statusLabel = status;
          notifyListeners();
        },
      );

      _startVpnStatusPolling();
      _location = session.location;
      _locationDetails = session.details;
      _isConnected = true;
      _errorMessage = null;
    } catch (error) {
      _isConnected = false;
      _errorMessage = error.toString();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      _vpnStatusTimer?.cancel();
      _vpnStatusTimer = null;
      await _disconnectVpnUseCase.execute(useNativeTunnel: _useNativeTunnel);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      resetConnectionState();
      notifyListeners();
    }
  }

  Future<void> handleAppSelectionChanged() async {
    if (_isConnected) {
      await disconnect();
      return;
    }
    resetConnectionState();
    notifyListeners();
  }

  Future<void> shareApp() => _shareAppUseCase.execute();

  void resetConnectionState() {
    _isConnected = false;
    _isConnecting = false;
    _location = 'Auto';
    _locationDetails = 'Fastest location';
    _statusLabel = 'Disconnected';
  }

  Future<void> _syncVpnStatusOnce() async {
    try {
      final status = await _getVpnStatusUseCase.execute(
        useNativeTunnel: _useNativeTunnel,
      );
      _applyNativeVpnStatus(status);
    } catch (_) {
      // Ignore initial sync failures.
    }
  }

  void _startVpnStatusPolling() {
    _vpnStatusTimer?.cancel();
    if (!_useNativeTunnel) {
      return;
    }

    _vpnStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final status = await _getVpnStatusUseCase.execute(
          useNativeTunnel: _useNativeTunnel,
        );
        _applyNativeVpnStatus(status);
      } catch (_) {
        // Ignore transient native status errors.
      }
    });
  }

  void _applyNativeVpnStatus(Map<String, dynamic> status) {
    final state = (status['state'] as String? ?? 'down').toLowerCase();
    final isConnected = status['is_connected'] as bool? ?? false;

    if (isConnected || state == 'up') {
      if (!_isConnected || _isConnecting || _statusLabel != 'Connected') {
        _isConnected = true;
        _isConnecting = false;
        _statusLabel = 'Connected';
        _errorMessage = null;
        notifyListeners();
      }
      return;
    }

    if (state == 'connecting' || state == 'reasserting') {
      if (!_isConnecting || _statusLabel != 'Connecting...') {
        _isConnecting = true;
        _statusLabel = 'Connecting...';
        notifyListeners();
      }
      return;
    }

    if (_isConnected || _isConnecting || _statusLabel != 'Disconnected') {
      _isConnected = false;
      _isConnecting = false;
      _statusLabel = 'Disconnected';
      notifyListeners();
    }
  }

  String _buildDeviceName() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
    return 'pug-$platform-$ts';
  }
}
