import Flutter
import UIKit

/// iOS Files 앱 openURL → Flutter bridge (채널명 Android와 공유: "excelia/intent").
/// security-scoped URL은 Flutter 파서가 직접 다루기 어려우므로 tmp에 복사한
/// 뒤 경로를 돌려준다 (Android 동작과 일관).
@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "excelia/intent"
  private var methodChannel: FlutterMethodChannel?
  private var pendingPath: String?

  private static let intentCachePrefix = "intent_"
  private static let intentCacheTTL: TimeInterval = 7 * 24 * 60 * 60

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      methodChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "getInitialPath":
          let path = self?.pendingPath
          self?.pendingPath = nil
          result(path)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    purgeStaleIntentCache()

    if let url = launchOptions?[.url] as? URL {
      pendingPath = copyToTmp(url: url)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if let path = copyToTmp(url: url) {
      methodChannel?.invokeMethod("onNewFile", arguments: path)
      return true
    }
    return super.application(app, open: url, options: options)
  }

  /// Security-scoped URL 을 tmp 디렉토리로 복사하고 절대경로 반환.
  private func copyToTmp(url: URL) -> String? {
    let needsScope = url.startAccessingSecurityScopedResource()
    defer { if needsScope { url.stopAccessingSecurityScopedResource() } }

    let fm = FileManager.default
    let ts = Int(Date().timeIntervalSince1970 * 1000)
    let dest = fm.temporaryDirectory
      .appendingPathComponent("\(Self.intentCachePrefix)\(ts)_\(url.lastPathComponent)")

    do {
      try fm.copyItem(at: url, to: dest)
      return dest.path
    } catch {
      return nil
    }
  }

  /// tmp에 누적된 오래된 intent 복사본 정리. iOS가 tmp를 자동 회수하는 타이밍은
  /// 보장되지 않으므로 앱 시작 시 7일 초과 `intent_*` 파일을 삭제해 상한을 둔다.
  private func purgeStaleIntentCache() {
    let fm = FileManager.default
    let tmpDir = fm.temporaryDirectory
    let cutoff = Date().addingTimeInterval(-Self.intentCacheTTL)
    guard let files = try? fm.contentsOfDirectory(
      at: tmpDir,
      includingPropertiesForKeys: [.contentModificationDateKey],
      options: [.skipsHiddenFiles]
    ) else { return }
    for url in files where url.lastPathComponent.hasPrefix(Self.intentCachePrefix) {
      let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
      if let mtime = values?.contentModificationDate, mtime < cutoff {
        try? fm.removeItem(at: url)
      }
    }
  }
}
