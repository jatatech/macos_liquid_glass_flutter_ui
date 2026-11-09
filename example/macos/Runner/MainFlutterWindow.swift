import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var editMenu: ExampleEditMenu?
  private var menuChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 480, height: 400)

    RegisterGeneratedPlugins(registry: flutterViewController)

    if let menu = NSApp.mainMenu, let source = ExampleEditMenu.standardMenu(in: menu) {
      editMenu = ExampleEditMenu(source: source)
    }
    let menuChannel = FlutterMethodChannel(
      name: "example.shell_gallery/menu_composition",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    self.menuChannel = menuChannel
    menuChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "restoreEditMenu" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard call.arguments == nil, let editMenu = self?.editMenu else {
        result(
          FlutterError(code: "unavailable", message: "Original Edit menu unavailable", details: nil)
        )
        return
      }
      editMenu.restore()
      result(nil)
    }

    super.awakeFromNib()
  }

  deinit { menuChannel?.setMethodCallHandler(nil) }
}
