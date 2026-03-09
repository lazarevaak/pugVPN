import NetworkExtension
import WireGuardKit

extension NETunnelProviderProtocol {
  func asTunnelConfiguration(called name: String? = nil) -> TunnelConfiguration? {
    guard let config = providerConfiguration?["WgQuickConfig"] as? String else {
      return nil
    }
    return try? TunnelConfiguration(fromWgQuickConfig: config, called: name)
  }
}

