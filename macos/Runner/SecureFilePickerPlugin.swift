import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

class SecureFilePickerPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.doudou/secure_file_picker",
      binaryMessenger: registrar.messenger
    )
    let instance = SecureFilePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickVideos":
      pickVideos(result: result)
    case "pickDirectory":
      pickDirectory(result: result)
    case "pickSubtitle":
      pickSubtitle(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func makeBookmark(for url: URL) -> String? {
    let accessed = url.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        url.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let data = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      return data.base64EncodedString()
    } catch {
      NSLog("SecureFilePicker: bookmark failed for \(url.path): \(error)")
      return nil
    }
  }

  private func pickVideos(result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.title = "选择视频"
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    applyVideoTypes(to: panel)

    guard panel.runModal() == .OK else {
      result([])
      return
    }

    var items: [[String: String]] = []
    for url in panel.urls {
      guard let bookmark = makeBookmark(for: url) else {
        continue
      }
      items.append([
        "path": url.path,
        "bookmark": bookmark,
      ])
    }
    result(items)
  }

  private func pickDirectory(result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.title = "选择文件夹"
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = true
    panel.canChooseFiles = false

    guard panel.runModal() == .OK, let url = panel.url else {
      result(nil)
      return
    }

    guard let bookmark = makeBookmark(for: url) else {
      result(nil)
      return
    }

    result([
      "path": url.path,
      "bookmark": bookmark,
    ])
  }

  private func pickSubtitle(result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.title = "选择字幕"
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true

    if #available(macOS 11.0, *) {
      panel.allowedContentTypes = [UTType(filenameExtension: "srt")].compactMap { $0 }
    } else {
      panel.allowedFileTypes = ["srt"]
    }

    guard panel.runModal() == .OK, let url = panel.url else {
      result(nil)
      return
    }

    guard let bookmark = makeBookmark(for: url) else {
      result(nil)
      return
    }

    result([
      "path": url.path,
      "bookmark": bookmark,
    ])
  }

  private func applyVideoTypes(to panel: NSOpenPanel) {
    let extensions = ["mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v"]
    if #available(macOS 11.0, *) {
      panel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
    } else {
      panel.allowedFileTypes = extensions
    }
  }
}
