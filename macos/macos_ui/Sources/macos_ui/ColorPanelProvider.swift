import Cocoa
import FlutterMacOS

// NSColorPanel.shared is application-wide. This provider owns only its target,
// close observer and current stream; window integration remains utility-owned.
class ColorPanelProvider: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var closeObserver: NSObjectProtocol?
  private let panel = NSColorPanel.shared
  private var ownsPanel = false

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    guard arguments == nil else {
      return FlutterError(code: "bad_arguments", message: "Expected no arguments", details: nil)
    }
    closePanel()
    eventSink = events
    return nil
  }

  func openPanel(pickerMode: String, color: UInt32?) -> Bool {
    precondition(Thread.isMainThread)
    let modes: [String: NSColorPanel.Mode] = [
      "none": .none, "gray": .gray, "RBG": .RGB, "CMYK": .CMYK, "HSB": .HSB,
      "customPalette": .customPalette, "colorList": .colorList, "wheel": .wheel,
      "crayon": .crayon,
    ]
    guard let name = pickerMode.components(separatedBy: ".").last,
      let mode = modes[name], eventSink != nil
    else { return false }
    closePanel()
    NSColorPanel.setPickerMode(mode)
    if let color {
      panel.color = NSColor(
        srgbRed: CGFloat((color >> 16) & 255) / 255,
        green: CGFloat((color >> 8) & 255) / 255,
        blue: CGFloat(color & 255) / 255,
        alpha: CGFloat((color >> 24) & 255) / 255)
    }
    ownsPanel = true
    panel.setTarget(self)
    panel.setAction(#selector(colorChanged(_:)))
    panel.isContinuous = true
    panel.showsAlpha = true
    panel.isReleasedWhenClosed = false
    closeObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification, object: panel, queue: .main
    ) { [weak self] _ in
      self?.eventSink?(FlutterEndOfEventStream)
      self?.detach()
    }
    panel.makeKeyAndOrderFront(self)
    return true
  }

  @objc private func colorChanged(_ sender: NSColorPanel) {
    precondition(Thread.isMainThread)
    guard let color = sender.color.usingColorSpace(.sRGB) else { return }
    let value =
      (UInt32(round(color.alphaComponent * 255)) << 24)
      | (UInt32(round(color.redComponent * 255)) << 16)
      | (UInt32(round(color.greenComponent * 255)) << 8)
      | UInt32(round(color.blueComponent * 255))
    eventSink?(String(value))
  }

  private func detach() {
    if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
    closeObserver = nil
    if ownsPanel {
      panel.setTarget(nil)
      panel.setAction(nil)
    }
    ownsPanel = false
  }

  func closePanel() {
    precondition(Thread.isMainThread)
    let owned = ownsPanel
    detach()
    if owned { panel.orderOut(nil) }
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    closePanel()
    eventSink = nil
    return nil
  }

  deinit {
    if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
    if ownsPanel {
      panel.setTarget(nil)
      panel.setAction(nil)
      panel.orderOut(nil)
    }
  }
}
