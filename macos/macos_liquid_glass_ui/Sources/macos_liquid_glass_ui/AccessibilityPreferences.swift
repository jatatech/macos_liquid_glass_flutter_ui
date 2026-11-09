import Cocoa
import FlutterMacOS

/// Application-wide workspace preferences; does not take ownership of windows.
final class AccessibilityPreferences: NSObject, FlutterStreamHandler {
  private var observer: NSObjectProtocol?
  private var sink: FlutterEventSink?

  private func emit() {
    precondition(Thread.isMainThread)
    let workspace = NSWorkspace.shared
    sink?([
      "reduceTransparency": workspace.accessibilityDisplayShouldReduceTransparency,
      "reduceMotion": workspace.accessibilityDisplayShouldReduceMotion,
      "increaseContrast": workspace.accessibilityDisplayShouldIncreaseContrast,
    ])
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    precondition(Thread.isMainThread)
    guard arguments == nil else {
      return FlutterError(code: "invalid_arguments", message: "No arguments expected", details: nil)
    }
    stop()
    sink = events
    observer = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
      object: nil, queue: .main
    ) { [weak self] _ in self?.emit() }
    emit()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    precondition(Thread.isMainThread)
    stop()
    return nil
  }

  private func stop() {
    if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    observer = nil
    sink = nil
  }

  deinit { stop() }
}
