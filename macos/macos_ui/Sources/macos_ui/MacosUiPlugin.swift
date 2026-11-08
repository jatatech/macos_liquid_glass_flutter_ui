import Cocoa
import FlutterMacOS

public class MacOSUiPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private let colorPanelProvider: ColorPanelProvider
  private var eventSink: FlutterEventSink?
  private var glassSurfaces: GlassCommandSurfaces?

  init(colorPanelProvider: ColorPanelProvider) {
    self.colorPanelProvider = colorPanelProvider
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "dev.groovinchip.macos_ui",
      binaryMessenger: registrar.messenger)

    let colorSelectionChannel = FlutterEventChannel(
      name: "dev.groovinchip.macos_ui/color_panel",
      binaryMessenger: registrar.messenger)

    let accessibilityChannel = FlutterEventChannel(
      name: "dev.groovinchip.macos_ui/accessibility",
      binaryMessenger: registrar.messenger)
    accessibilityChannel.setStreamHandler(AccessibilityPreferences())

    let colorPanelProvider = ColorPanelProvider()

    let instance = MacOSUiPlugin(colorPanelProvider: colorPanelProvider)
    let glassChannel = FlutterMethodChannel(
      name: "dev.groovinchip.macos_ui/glass", binaryMessenger: registrar.messenger)
    let glassSurfaces = GlassCommandSurfaces(
      view: registrar.viewController?.view ?? registrar.view, channel: glassChannel)
    instance.glassSurfaces = glassSurfaces
    glassChannel.setMethodCallHandler { [weak glassSurfaces] call, result in
      guard let glassSurfaces else {
        result(FlutterError(code: "cancelled", message: "Glass owner disposed", details: nil))
        return
      }
      glassSurfaces.handle(call, result: result)
    }
    colorSelectionChannel.setStreamHandler(colorPanelProvider)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { self.handle(call, result: result) }
      return
    }
    switch call.method {
    case "color_panel":
      guard let arguments = call.arguments as? [String: Any],
        let mode = arguments["mode"] as? String,
        arguments["color"] == nil || arguments["color"] is NSNull || arguments["color"] is NSNumber
      else {
        result(
          FlutterError(
            code: "bad_arguments", message: "Expected mode and optional ARGB colour", details: nil))
        return
      }
      let number = arguments["color"] as? NSNumber
      if let number,
        number.doubleValue < 0 || number.doubleValue > Double(UInt32.max)
          || number.doubleValue.rounded() != number.doubleValue
      {
        result(FlutterError(code: "bad_arguments", message: "Invalid ARGB colour", details: nil))
        return
      }
      if colorPanelProvider.openPanel(pickerMode: mode, color: number?.uint32Value) {
        result(nil)
      } else {
        result(
          FlutterError(
            code: "unavailable", message: "Unknown mode or no active listener", details: nil))
      }
    case "close_color_panel":
      guard call.arguments == nil else {
        result(FlutterError(code: "bad_arguments", message: "Expected no arguments", details: nil))
        return
      }
      colorPanelProvider.closePanel()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
