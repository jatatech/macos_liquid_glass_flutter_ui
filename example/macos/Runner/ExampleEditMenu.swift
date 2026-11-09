import Cocoa

/// Application composition, not a package/global shortcut service. Preserve the
/// XIB's localized responder-chain Edit menu when PlatformMenuBar replaces it.
final class ExampleEditMenu {
  private let template: NSMenuItem
  private weak var observedMenu: NSMenu?
  private weak var installedItem: NSMenuItem?

  static func standardMenu(in menu: NSMenu) -> NSMenuItem? {
    menu.items.first { item in
      item.submenu?.items.contains { $0.action == #selector(NSText.selectAll(_:)) } == true
    }
  }

  init(source: NSMenuItem) {
    template = source.copy() as! NSMenuItem
  }

  // Called after Flutter's Menu.setMenus completes, never on a timer or an
  // unrelated application notification. Keep Flutter's menu delegate intact.
  func restore() {
    guard let menu = NSApp.mainMenu, menu !== observedMenu else { return }
    observedMenu = menu
    guard menu.numberOfItems > 0 else { return }
    guard Self.standardMenu(in: menu) == nil else { return }
    let item = template.copy() as! NSMenuItem
    // The composing app already supplies its task-scoped Find command. Do not
    // let the XIB's generic text Find submenu shadow that application's ⌘F.
    func hasFindShortcut(_ menu: NSMenu) -> Bool {
      menu.items.contains {
        ($0.keyEquivalent == "f" && $0.keyEquivalentModifierMask == .command)
          || ($0.submenu.map(hasFindShortcut) ?? false)
      }
    }
    if hasFindShortcut(menu), let submenu = item.submenu {
      for entry in submenu.items
      where entry.submenu?.items.contains(where: {
        $0.action == NSSelectorFromString("performFindPanelAction:")
      }) == true {
        submenu.removeItem(entry)
      }
    }
    menu.insertItem(item, at: min(1, menu.numberOfItems))
    installedItem = item
  }

  deinit {
    if let installedItem { installedItem.menu?.removeItem(installedItem) }
  }
}
