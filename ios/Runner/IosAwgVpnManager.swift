import Flutter
import Foundation
import NetworkExtension

final class IosAwgVpnManager {
  private static let providerConfigKey = "WgQuickConfig"
  private static let defaultTunnelName = "pugvpn"
  private static let extensionBundleSuffix = ".network-extension"

  func prepare(result: @escaping FlutterResult) {
    result(true)
  }

  func connect(config: String, tunnelName: String, result: @escaping FlutterResult) {
    let trimmedConfig = config.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedConfig.isEmpty else {
      return fail(result, code: "INVALID_ARGS", message: "config is required.")
    }

    guard let extensionBundleId = makeExtensionBundleId() else {
      return fail(
        result, code: "CONFIG_ERROR",
        message: "Unable to derive Network Extension bundle identifier.")
    }

    loadAllManagers { [weak self] loadResult in
      guard let self else { return }

      switch loadResult {
      case .failure(let error):
        self.fail(
          result, code: "LOAD_FAILED", message: "Failed to load VPN preferences.",
          details: error.localizedDescription)
      case .success(let managers):
        let manager = self.findManager(in: managers, extensionBundleId: extensionBundleId)
          ?? NETunnelProviderManager()
        let protocolConfig = (manager.protocolConfiguration as? NETunnelProviderProtocol)
          ?? NETunnelProviderProtocol()

        protocolConfig.providerBundleIdentifier = extensionBundleId
        protocolConfig.providerConfiguration = [Self.providerConfigKey: trimmedConfig]
        protocolConfig.serverAddress = self.extractServerAddress(from: trimmedConfig)
        protocolConfig.disconnectOnSleep = false

        manager.localizedDescription = self.sanitizeTunnelName(tunnelName)
        manager.protocolConfiguration = protocolConfig
        manager.isEnabled = true

        self.saveAndStart(manager: manager, result: result)
      }
    }
  }

  func disconnect(result: @escaping FlutterResult) {
    guard let extensionBundleId = makeExtensionBundleId() else {
      return fail(
        result, code: "CONFIG_ERROR",
        message: "Unable to derive Network Extension bundle identifier.")
    }

    loadAllManagers { [weak self] loadResult in
      guard let self else { return }

      switch loadResult {
      case .failure(let error):
        self.fail(
          result, code: "LOAD_FAILED", message: "Failed to load VPN preferences.",
          details: error.localizedDescription)
      case .success(let managers):
        guard
          let manager = self.findManager(in: managers, extensionBundleId: extensionBundleId)
        else {
          result(true)
          return
        }

        manager.connection.stopVPNTunnel()
        result(true)
      }
    }
  }

  func status(result: @escaping FlutterResult) {
    guard let extensionBundleId = makeExtensionBundleId() else {
      result(["state": "down", "is_connected": false])
      return
    }

    loadAllManagers { [weak self] loadResult in
      guard let self else { return }

      switch loadResult {
      case .failure:
        result(["state": "down", "is_connected": false])
      case .success(let managers):
        guard
          let manager = self.findManager(in: managers, extensionBundleId: extensionBundleId)
        else {
          result(["state": "down", "is_connected": false])
          return
        }

        let vpnStatus = manager.connection.status
        result([
          "state": self.statusString(vpnStatus),
          "is_connected": vpnStatus == .connected,
        ])
      }
    }
  }

  private func saveAndStart(manager: NETunnelProviderManager, result: @escaping FlutterResult) {
    manager.saveToPreferences { [weak self] saveError in
      guard let self else { return }
      if let saveError {
        self.fail(
          result, code: "SAVE_FAILED", message: "Failed to save VPN preferences.",
          details: saveError.localizedDescription)
        return
      }

      manager.loadFromPreferences { loadError in
        if let loadError {
          self.fail(
            result, code: "LOAD_AFTER_SAVE_FAILED",
            message: "Failed to reload VPN preferences.",
            details: loadError.localizedDescription)
          return
        }

        let vpnStatus = manager.connection.status
        if vpnStatus == .connected || vpnStatus == .connecting || vpnStatus == .reasserting {
          result(true)
          return
        }

        do {
          try manager.connection.startVPNTunnel()
          result(true)
        } catch {
          self.fail(
            result, code: "START_FAILED", message: "Failed to start VPN tunnel.",
            details: error.localizedDescription)
        }
      }
    }
  }

  private func loadAllManagers(
    completion: @escaping (Result<[NETunnelProviderManager], Error>) -> Void
  ) {
    NETunnelProviderManager.loadAllFromPreferences { managers, error in
      if let error {
        completion(.failure(error))
      } else {
        completion(.success(managers ?? []))
      }
    }
  }

  private func findManager(in managers: [NETunnelProviderManager], extensionBundleId: String)
    -> NETunnelProviderManager?
  {
    managers.first {
      guard let tunnelProtocol = $0.protocolConfiguration as? NETunnelProviderProtocol else {
        return false
      }
      return tunnelProtocol.providerBundleIdentifier == extensionBundleId
    }
  }

  private func makeExtensionBundleId() -> String? {
    guard let appBundleId = Bundle.main.bundleIdentifier else { return nil }
    return appBundleId + Self.extensionBundleSuffix
  }

  private func extractServerAddress(from config: String) -> String {
    for rawLine in config.split(whereSeparator: \.isNewline) {
      var line = String(rawLine)
      if let commentIndex = line.firstIndex(of: "#") {
        line = String(line[..<commentIndex])
      }
      line = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if line.isEmpty { continue }

      guard let equalsIndex = line.firstIndex(of: "=") else { continue }
      let key = line[..<equalsIndex].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      guard key == "endpoint" else { continue }

      let value = line[line.index(after: equalsIndex)...]
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if !value.isEmpty {
        return value
      }
    }
    return "AmneziaWG"
  }

  private func sanitizeTunnelName(_ raw: String) -> String {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_=+.-")
    let filteredScalars = raw.unicodeScalars.filter { allowed.contains($0) }
    let filtered = String(String.UnicodeScalarView(filteredScalars))
    let limited = String(filtered.prefix(15))
    if limited.isEmpty {
      return Self.defaultTunnelName
    }
    return limited
  }

  private func statusString(_ status: NEVPNStatus) -> String {
    switch status {
    case .invalid:
      return "invalid"
    case .disconnected:
      return "down"
    case .connecting:
      return "connecting"
    case .connected:
      return "up"
    case .reasserting:
      return "reasserting"
    case .disconnecting:
      return "disconnecting"
    @unknown default:
      return "down"
    }
  }

  private func fail(
    _ result: @escaping FlutterResult, code: String, message: String, details: String? = nil
  ) {
    result(FlutterError(code: code, message: message, details: details))
  }
}

