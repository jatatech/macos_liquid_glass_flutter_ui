import Cocoa
import FlutterMacOS

/// Single registrar-view adapter. Owns command views only, never a window delegate.
final class GlassCommandSurfaces {
  private weak var flutter: NSView?
  private let channel: FlutterMethodChannel
  private var surfaces: [Int: NSView] = [:]
  private var owners: Set<Int> = []
  private var observers: [NSObjectProtocol] = []
  private var preferenceObserver: NSObjectProtocol?

  init(view: NSView?, channel: FlutterMethodChannel) {
    flutter = view
    self.channel = channel
    preferenceObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      let workspace = NSWorkspace.shared
      if workspace.accessibilityDisplayShouldReduceTransparency
        || workspace.accessibilityDisplayShouldIncreaseContrast
      {
        self?.invalidateAll()
      }
    }
    // Observe the registrar's actual window at notification time: it may not
    // have been attached when the plugin was registered.
    for name in [
      NSWindow.willCloseNotification, NSWindow.didMiniaturizeNotification,
      NSWindow.didDeminiaturizeNotification,
    ] {
      observers.append(
        NotificationCenter.default.addObserver(
          forName: name, object: nil, queue: .main
        ) { [weak self] note in
          guard let self, let window = note.object as? NSWindow,
            window === self.flutter?.window
          else { return }
          self.invalidateAll()
        })
    }

  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { self.handle(call, result: result) }
      return
    }
    guard let args = call.arguments as? [String: Any],
      let id = args["id"] as? Int, id > 0
    else {
      result(
        FlutterError(code: "bad_arguments", message: "Expected positive owner id", details: nil))
      return
    }
    if call.method == "remove" {
      owners.remove(id)
      remove(id)
      result(nil)
      return
    }
    if call.method == "focus" {
      guard let backward = args["backward"] as? Bool else {
        result(
          FlutterError(code: "bad_arguments", message: "Expected focus direction", details: nil))
        return
      }
      if #available(macOS 26.0, *), let glass = surfaces[id] as? CommandGlass {
        result(glass.enter(backward: backward))
      } else {
        result(false)
      }
      return
    }
    guard call.method == "update" else {
      result(FlutterMethodNotImplemented)
      return
    }
    owners.insert(id)
    guard let show = args["show"] as? Bool else {
      result(FlutterError(code: "bad_arguments", message: "Expected show flag", details: nil))
      return
    }
    if !show {
      remove(id)
      result(false)
      return
    }
    guard let x = args["x"] as? Double, let y = args["y"] as? Double,
      let width = args["width"] as? Double, let height = args["height"] as? Double,
      let radius = args["radius"] as? Double, let fontSize = args["fontSize"] as? Double,
      [x, y, width, height, radius, fontSize].allSatisfy({ $0.isFinite }),
      width >= 268, height >= 44, height <= 200, radius >= 0,
      fontSize > 0, fontSize <= 17,
      let dark = args["dark"] as? Bool, let reduceMotion = args["reduceMotion"] as? Bool,
      let commands = args["commands"] as? [[String: Any]],
      (1...4).contains(commands.count),
      commands.allSatisfy({ $0["label"] is String && $0["enabled"] is Bool })
    else {
      remove(id)
      result(
        FlutterError(
          code: "bad_arguments", message: "Invalid glass geometry/commands", details: nil))
      return
    }
    let workspace = NSWorkspace.shared
    guard #available(macOS 26.0, *),
      !workspace.accessibilityDisplayShouldReduceTransparency,
      !workspace.accessibilityDisplayShouldIncreaseContrast,
      let flutter, let parent = flutter.superview,
      let window = flutter.window, !window.isMiniaturized
    else {
      remove(id)
      result(false)
      return
    }
    // Flutter coordinates are logical points with a top-left origin. Convert via
    // the actual registrar view instead of assuming the main window's dimensions.
    let local = NSRect(
      x: x, y: flutter.isFlipped ? y : flutter.bounds.height - y - height,
      width: width, height: height)
    guard flutter.bounds.contains(local) else {
      remove(id)
      result(false)
      return
    }
    let glass: CommandGlass
    if let existing = surfaces[id] as? CommandGlass {
      glass = existing
    } else {
      glass = CommandGlass(frame: .zero)
      glass.onAction = { [weak self] index in
        self?.channel.invokeMethod("action", arguments: ["id": id, "index": index])
      }
      glass.onExit = { [weak self, weak glass] backward in
        self?.flutter?.window?.makeFirstResponder(self?.flutter)
        self?.channel.invokeMethod("exitFocus", arguments: ["id": id, "backward": backward])
        glass?.needsDisplay = true
      }
      surfaces[id] = glass
      parent.addSubview(glass, positioned: .above, relativeTo: flutter)
    }
    if glass.superview !== parent {
      glass.removeFromSuperview()
      parent.addSubview(glass, positioned: .above, relativeTo: flutter)
    }
    glass.frame = parent.convert(local, from: flutter)
    glass.cornerRadius = radius
    glass.style = .regular
    glass.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    if #available(macOS 27.0, *) {
      glass.effectIsInteractive = !reduceMotion && !workspace.accessibilityDisplayShouldReduceMotion
    }
    glass.configure(commands: commands, fontSize: fontSize)
    result(true)
  }

  private func remove(_ id: Int) {
    if let surface = surfaces.removeValue(forKey: id) {
      if let responder = surface.window?.firstResponder as? NSView,
        responder.isDescendant(of: surface)
      {
        surface.window?.makeFirstResponder(flutter)
      }
      surface.removeFromSuperview()
    }
  }

  private func invalidateAll() {
    for id in owners {
      remove(id)
      channel.invokeMethod("invalidated", arguments: ["id": id])
    }
  }

  deinit {
    let cleanup = { [views = Array(surfaces.values), observers, preferenceObserver] in
      for view in views { view.removeFromSuperview() }
      for observer in observers { NotificationCenter.default.removeObserver(observer) }
      if let preferenceObserver {
        NSWorkspace.shared.notificationCenter.removeObserver(preferenceObserver)
      }
    }
    if Thread.isMainThread {
      cleanup()
    } else {
      DispatchQueue.main.async(execute: cleanup)
    }
  }
}

@available(macOS 26.0, *)
private final class CommandGlass: NSGlassEffectView {
  var onAction: ((Int) -> Void)?
  var onExit: ((Bool) -> Void)?
  private var buttons: [NSButton] = []
  private var signature = ""

  func configure(commands: [[String: Any]], fontSize: Double) {
    let next = commands.map { "\($0["label"]!)|\($0["enabled"]!)" }.joined() + "\(fontSize)"
    if next != signature {
      signature = next
      let focusedIndex = buttons.firstIndex { window?.firstResponder === $0 }
      for button in buttons { button.removeFromSuperview() }
      buttons = commands.enumerated().map { index, item in
        let button = GlassButton(
          title: item["label"] as! String, target: self, action: #selector(activate))
        button.tag = index
        button.isEnabled = item["enabled"] as! Bool
        button.bezelStyle = .rounded
        button.font = .systemFont(ofSize: fontSize)
        button.contentTintColor = .labelColor
        button.focusRingType = .exterior
        button.onTraverse = { [weak self] backward in
          self?.traverse(from: index, backward: backward)
        }
        button.onEscape = { [weak self] in self?.onExit?(true) }
        return button
      }
      let content = NSView(frame: bounds)
      content.autoresizingMask = [.width, .height]
      for button in buttons { content.addSubview(button) }
      contentView = content
      if let focusedIndex {
        if focusedIndex < buttons.count, buttons[focusedIndex].isEnabled {
          window?.makeFirstResponder(buttons[focusedIndex])
        } else {
          onExit?(false)
        }
      }
    }
    let inset: CGFloat = 12
    let gap: CGFloat = 8
    let buttonWidth =
      (bounds.width - 2 * inset - gap * CGFloat(buttons.count - 1)) / CGFloat(buttons.count)
    for (index, button) in buttons.enumerated() {
      button.frame = NSRect(
        x: inset + CGFloat(index) * (buttonWidth + gap),
        y: (bounds.height - 32) / 2, width: buttonWidth, height: 32)
    }
  }

  func enter(backward: Bool) -> Bool {
    let enabled = buttons.filter { $0.isEnabled }
    if let button = backward ? enabled.last : enabled.first {
      return window?.makeFirstResponder(button) == true
    }
    return false
  }

  private func traverse(from index: Int, backward: Bool) {
    let indices = backward ? Array((0..<index).reversed()) : Array((index + 1)..<buttons.count)
    if let next = indices.first(where: { buttons[$0].isEnabled }) {
      window?.makeFirstResponder(buttons[next])
    } else {
      onExit?(backward)
    }
  }

  @objc private func activate(_ sender: NSButton) {
    guard sender.isEnabled else { return }
    onAction?(sender.tag)
  }
}

/// Tab crosses the toolkit boundary explicitly; no application shortcuts are
/// installed. AppKit retains activation, pointer and accessibility behaviour.
private final class GlassButton: NSButton {
  var onTraverse: ((Bool) -> Void)?
  var onEscape: (() -> Void)?

  override var acceptsFirstResponder: Bool { true }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 48 {
      onTraverse?(event.modifierFlags.contains(.shift))
    } else if event.keyCode == 53 {
      onEscape?()
    } else if event.keyCode == 49 || event.keyCode == 36 {
      if !event.isARepeat { performClick(nil) }
    } else {
      super.keyDown(with: event)
    }
  }
}
