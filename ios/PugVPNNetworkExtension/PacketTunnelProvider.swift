import Foundation
import NetworkExtension
import WireGuardKit
import os.log

enum PacketTunnelProviderError: String, Error {
  case savedProtocolConfigurationIsInvalid
  case dnsResolutionFailure
  case couldNotStartBackend
  case couldNotDetermineFileDescriptor
  case couldNotSetNetworkSettings
}

final class PacketTunnelProvider: NEPacketTunnelProvider {
  private lazy var adapter: WireGuardAdapter = {
    WireGuardAdapter(with: self) { level, message in
      switch level {
      case .verbose:
        os_log("%{public}@", log: OSLog.default, type: .debug, message)
      case .error:
        os_log("%{public}@", log: OSLog.default, type: .error, message)
      }
    }
  }()

  override func startTunnel(
    options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void
  ) {
    guard let tunnelProtocol = protocolConfiguration as? NETunnelProviderProtocol,
      let tunnelConfiguration = tunnelProtocol.asTunnelConfiguration()
    else {
      completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
      return
    }

    adapter.start(tunnelConfiguration: tunnelConfiguration) { adapterError in
      guard let adapterError else {
        completionHandler(nil)
        return
      }

      switch adapterError {
      case .cannotLocateTunnelFileDescriptor:
        completionHandler(PacketTunnelProviderError.couldNotDetermineFileDescriptor)
      case .dnsResolution:
        completionHandler(PacketTunnelProviderError.dnsResolutionFailure)
      case .setNetworkSettings:
        completionHandler(PacketTunnelProviderError.couldNotSetNetworkSettings)
      case .startWireGuardBackend:
        completionHandler(PacketTunnelProviderError.couldNotStartBackend)
      case .invalidState:
        completionHandler(PacketTunnelProviderError.couldNotStartBackend)
      }
    }
  }

  override func stopTunnel(
    with reason: NEProviderStopReason, completionHandler: @escaping () -> Void
  ) {
    adapter.stop { _ in
      completionHandler()
    }
  }

  override func handleAppMessage(
    _ messageData: Data, completionHandler: ((Data?) -> Void)? = nil
  ) {
    guard let completionHandler else { return }
    if messageData.count == 1 && messageData[0] == 0 {
      adapter.getRuntimeConfiguration { settings in
        completionHandler(settings?.data(using: .utf8))
      }
    } else {
      completionHandler(nil)
    }
  }
}

