import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let channelName = "pug_vpn/awg"
  private let applicationDirectories: [URL] = [
    URL(fileURLWithPath: "/Applications", isDirectory: true),
    URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true),
    URL(fileURLWithPath: "/System/Applications", isDirectory: true),
    URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
      "Applications",
      isDirectory: true
    ),
  ]

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler(handleMethodCall)

    super.awakeFromNib()
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "listInstalledApps":
      listInstalledApps(result: result)
    case "loadInstalledAppIcons":
      loadInstalledAppIcons(call.arguments, result: result)
    case "pickInstalledApps":
      presentAppPicker(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func listInstalledApps(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let apps = self.discoverInstalledApps()
      DispatchQueue.main.async {
        result(apps)
      }
    }
  }

  private func presentAppPicker(result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.prompt = "Select"
    panel.message = "Choose the macOS apps that should use the VPN."
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = true
    panel.allowedFileTypes = ["app"]
    panel.resolvesAliases = true
    panel.canCreateDirectories = false

    panel.beginSheetModal(for: self) { response in
      guard response == .OK else {
        result([[String: String]]())
        return
      }

      let apps = panel.urls.compactMap { url in
        self.buildAppPayload(url: url)
      }.sorted {
        let left = ($0["label"] ?? "").localizedCaseInsensitiveCompare(
          $1["label"] ?? ""
        )
        return left == .orderedAscending
      }
      result(apps)
    }
  }

  private func discoverInstalledApps() -> [[String: String]] {
    var appsByIdentifier = [String: [String: String]]()

    for directory in applicationDirectories {
      for url in applicationBundleURLs(in: directory) {
        guard let payload = buildAppPayload(url: url, includeIcon: false) else {
          continue
        }

        if payload["packageName"] == Bundle.main.bundleIdentifier {
          continue
        }

        appsByIdentifier[payload["packageName"] ?? url.path] = payload
      }
    }

    return appsByIdentifier.values.sorted {
      ($0["label"] ?? "").localizedCaseInsensitiveCompare($1["label"] ?? "") == .orderedAscending
    }
  }

  private func loadInstalledAppIcons(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let entries = arguments as? [[String: Any?]] else {
      result([[String: String]]())
      return
    }

    DispatchQueue.global(qos: .utility).async {
      let icons = entries.compactMap { entry -> [String: String]? in
        guard let packageName = entry["packageName"] as? String, !packageName.isEmpty else {
          return nil
        }
        guard let sourcePath = entry["sourcePath"] as? String, !sourcePath.isEmpty else {
          return nil
        }
        guard let iconBase64 = self.iconBase64(for: sourcePath) else {
          return nil
        }
        return [
          "packageName": packageName,
          "iconBase64": iconBase64,
        ]
      }

      DispatchQueue.main.async {
        result(icons)
      }
    }
  }

  private func applicationBundleURLs(in directory: URL) -> [URL] {
    let resourceKeys: Set<URLResourceKey> = [.isApplicationKey, .isDirectoryKey]
    guard FileManager.default.fileExists(atPath: directory.path) else {
      return []
    }

    guard let entries = try? FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: Array(resourceKeys),
      options: [.skipsHiddenFiles]
    ) else {
      return []
    }

    var appURLs: [URL] = []

    for entry in entries {
      guard let values = try? entry.resourceValues(forKeys: resourceKeys) else {
        continue
      }

      if values.isApplication == true || entry.pathExtension.caseInsensitiveCompare("app") == .orderedSame {
        appURLs.append(entry)
        continue
      }

      guard values.isDirectory == true else {
        continue
      }

      guard let nestedEntries = try? FileManager.default.contentsOfDirectory(
        at: entry,
        includingPropertiesForKeys: Array(resourceKeys),
        options: [.skipsHiddenFiles]
      ) else {
        continue
      }

      for nestedEntry in nestedEntries {
        guard let nestedValues = try? nestedEntry.resourceValues(forKeys: resourceKeys) else {
          continue
        }

        if nestedValues.isApplication == true ||
          nestedEntry.pathExtension.caseInsensitiveCompare("app") == .orderedSame
        {
          appURLs.append(nestedEntry)
        }
      }
    }

    return appURLs
  }

  private func buildAppPayload(url: URL, includeIcon: Bool = true) -> [String: String]? {
    let bundle = Bundle(url: url)
    let bundleIdentifier = bundle?.bundleIdentifier
    let displayName =
      bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
      bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String ??
      url.deletingPathExtension().lastPathComponent
    let packageName = bundleIdentifier?.isEmpty == false ? bundleIdentifier! : url.path

    return [
      "packageName": packageName,
      "label": displayName,
      "sourcePath": url.path,
      "iconBase64": includeIcon ? (iconBase64(for: url.path) ?? "") : "",
    ]
  }

  private func iconBase64(for filePath: String) -> String? {
    let image = NSWorkspace.shared.icon(forFile: filePath)
    image.size = NSSize(width: 128, height: 128)
    guard
      let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:])
    else {
      return nil
    }
    return pngData.base64EncodedString()
  }
}
