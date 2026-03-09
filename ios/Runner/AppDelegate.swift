import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "pug_vpn/awg"
  private let iosVpnManager = IosAwgVpnManager()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler(handleMethodCall)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "prepare":
      iosVpnManager.prepare(result: result)
    case "connect":
      guard
        let args = call.arguments as? [String: Any],
        let config = args["config"] as? String
      else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "config is required.",
            details: nil
          ))
        return
      }

      let rawTunnelName = (args["tunnelName"] as? String) ?? "pugvpn"
      let tunnelName = sanitizeTunnelName(rawTunnelName)
      iosVpnManager.connect(config: config, tunnelName: tunnelName, result: result)
    case "disconnect":
      iosVpnManager.disconnect(result: result)
    case "status":
      iosVpnManager.status(result: result)
    case "importConfig":
      guard
        let args = call.arguments as? [String: Any],
        let config = args["config"] as? String
      else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "config is required.",
            details: nil
          ))
        return
      }

      let rawTunnelName = (args["tunnelName"] as? String) ?? "pugvpn"
      let tunnelName = sanitizeTunnelName(rawTunnelName)
      presentImportShareSheet(
        config: config,
        tunnelName: tunnelName,
        result: result
      )
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentImportShareSheet(
    config: String,
    tunnelName: String,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      guard let controller = self.window?.rootViewController else {
        result(
          FlutterError(
            code: "NO_UI",
            message: "Unable to open iOS share sheet.",
            details: nil
          ))
        return
      }

      let filename = "\(tunnelName)-\(Int(Date().timeIntervalSince1970)).conf"
      let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      let fileURL = tempDir.appendingPathComponent(filename)

      do {
        try config.write(to: fileURL, atomically: true, encoding: .utf8)
      } catch {
        result(
          FlutterError(
            code: "WRITE_FAILED",
            message: "Unable to write config file for import.",
            details: error.localizedDescription
          ))
        return
      }

      let activityVC = UIActivityViewController(
        activityItems: [fileURL],
        applicationActivities: nil
      )

      if let popover = activityVC.popoverPresentationController {
        popover.sourceView = controller.view
        popover.sourceRect = CGRect(
          x: controller.view.bounds.midX,
          y: controller.view.bounds.midY,
          width: 0,
          height: 0
        )
        popover.permittedArrowDirections = []
      }

      activityVC.completionWithItemsHandler = { _, completed, _, _ in
        result(completed)
      }
      controller.present(activityVC, animated: true)
    }
  }

  private func sanitizeTunnelName(_ raw: String) -> String {
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_=+.-")
    let filteredScalars = raw.unicodeScalars.filter { allowed.contains($0) }
    let filtered = String(String.UnicodeScalarView(filteredScalars))
    let limited = String(filtered.prefix(15))
    if limited.isEmpty {
      return "pugvpn"
    }
    return limited
  }
}
