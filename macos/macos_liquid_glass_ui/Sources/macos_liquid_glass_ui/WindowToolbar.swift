import Cocoa
import FlutterMacOS

@available(macOS 26.0, *)
private final class ToolbarGlassBackground: NSGlassEffectView {
  override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
private final class ToolbarOpaqueBackground: NSBox {
  override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// Owns only the registrar window's toolbar, with no window delegate replacement.
final class WindowToolbar: NSObject, NSToolbarDelegate, NSSearchFieldDelegate, NSPopoverDelegate {
  private weak var view: NSView?
  private let channel: FlutterMethodChannel
  private var toolbar: NSToolbar?
  private var previous: NSToolbar?
  private weak var ownedWindow: NSWindow?
  private struct WindowState {
    let fullSize: Bool
    let transparent: Bool
    let opaque: Bool
    let background: NSColor?
    let toolbarStyle: NSWindow.ToolbarStyle
    let titleVisibility: NSWindow.TitleVisibility
    var title: String
    init(_ window: NSWindow, keepingToolbarValues previous: WindowState? = nil) {
      fullSize = window.styleMask.contains(.fullSizeContentView)
      transparent = window.titlebarAppearsTransparent
      opaque = window.isOpaque
      background = window.backgroundColor
      toolbarStyle = previous?.toolbarStyle ?? window.toolbarStyle
      titleVisibility = previous?.titleVisibility ?? window.titleVisibility
      title = previous?.title ?? window.title
    }
  }
  private var originalState: WindowState?
  private var appliedState: WindowState?
  private var groups: [[String: Any]] = []
  private var signature = ""
  private var typedItems: [[String: Any]]?
  private var searchItems: [String: NSSearchToolbarItem] = [:]
  private var searchRevisions: [String: Int] = [:]
  private var modelQueries: [String: String] = [:]
  private var pendingQueries: [String: String] = [:]
  private var contentWidth: CGFloat?
  private var titleWidthConstraint: NSLayoutConstraint?
  private var datePopover: NSPopover?
  private var datePicker: NSDatePicker?
  private var dateTextual: NSDatePicker?
  private var dateResult: FlutterResult?
  private var dateAnchor: String?
  private var dateAnchorRect: NSRect?
  private var dateObservers: [NSObjectProtocol] = []
  private weak var dateInvoker: NSView?
  private var dateCalendar = Calendar(identifier: .gregorian)
  private var contextTitle = ""
  private weak var contextLabel: NSTextField?
  private var monitor: Any?
  private var interactive = true
  private var glassTitlebarRequested = false
  private var titlebarBackground: NSView?
  private var titlebarMode = ""
  private var contentConstraints: [NSLayoutConstraint] = []
  private var originalTranslates = true
  private var originalWindowOpaque = true
  private var originalBackground: NSColor?
  private var observer: NSObjectProtocol?
  private var menuObservers: [NSObjectProtocol] = []
  private var trackingMenus: [ObjectIdentifier: NSMenu] = [:]
  init(view: NSView?, channel: FlutterMethodChannel) {
    self.view = view
    self.channel = channel
    super.init()
    observer = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      self?.rebuild()
    }
    let center = NotificationCenter.default
    menuObservers.append(
      center.addObserver(
        forName: NSMenu.didBeginTrackingNotification, object: nil, queue: .main
      ) { [weak self] notification in
        guard let menu = notification.object as? NSMenu else { return }
        self?.trackingMenus[ObjectIdentifier(menu)] = menu
      })
    menuObservers.append(
      center.addObserver(
        forName: NSMenu.didEndTrackingNotification, object: nil, queue: .main
      ) { [weak self] notification in
        guard let menu = notification.object as? NSMenu else { return }
        self?.trackingMenus.removeValue(forKey: ObjectIdentifier(menu))
      })
    monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if let self, let popover = self.datePopover, event.keyCode == 53,
        event.window === popover.contentViewController?.view.window,
        self.trackingMenus.isEmpty, NSApp.mainMenu?.highlightedItem == nil,
        RunLoop.current.currentMode != .eventTracking,
        self.ownedWindow?.attachedSheet == nil,
        !(event.window?.firstResponder is NSTextView)
      {
        self.finishDate("dismissed")
        return nil
      }
      guard let self, let window = self.view?.window,
        event.window === window, window.isKeyWindow,
        self.trackingMenus.isEmpty, NSApp.mainMenu?.highlightedItem == nil,
        RunLoop.current.currentMode != .eventTracking,
        window.toolbar === self.toolbar, self.toolbar?.isVisible == true, self.interactive,
        window.attachedSheet == nil, event.keyCode == 53,
        !(window.firstResponder is NSTextView)
      else { return event }
      if self.datePopover != nil {
        self.finishDate("dismissed")
        return nil
      }
      window.makeFirstResponder(self.view)
      self.channel.invokeMethod("escape", arguments: nil)
      return nil
    }
  }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard Thread.isMainThread else {
      DispatchQueue.main.async { self.handle(call, result: result) }
      return
    }
    if call.method == "remove" {
      remove()
      result(nil)
      return
    }
    if call.method == "presentDate" {
      presentDate(call.arguments, result: result)
      return
    }
    if call.method == "focusSearch" {
      guard let id = call.arguments as? String, let item = searchItems[id],
        ownedWindow?.toolbar === toolbar, toolbar?.isVisible == true, interactive,
        item.searchField.isEnabled, view?.window?.isKeyWindow == true,
        view?.window?.attachedSheet == nil
      else {
        result(false)
        return
      }
      item.beginSearchInteraction()
      result(true)
      return
    }
    guard call.method == "update" || call.method == "updateTyped",
      let args = call.arguments as? [String: Any],
      let title = args["title"] as? String, let visible = args["visible"] as? Bool,
      let commands = args["commands"] as? [[String: Any]], commands.count <= 20,
      Set(commands.compactMap { $0["id"] as? String }).count == commands.count,
      commands.allSatisfy({
        $0["id"] is String && $0["label"] is String
          && $0["symbol"] is String && $0["group"] is Int && $0["enabled"] is Bool
      })
    else {
      result(FlutterError(code: "bad_arguments", message: "Invalid toolbar", details: nil))
      return
    }
    if call.method == "updateTyped" && args["items"] == nil {
      result(FlutterError(code: "bad_arguments", message: "Missing typed items", details: nil))
      return
    }
    let items = args["items"] as? [[String: Any]]
    if args["items"] != nil {
      guard let items, commands.isEmpty, items.count <= 20,
        Set(items.compactMap { $0["id"] as? String }).count == items.count,
        items.allSatisfy({ item in
          guard let id = item["id"] as? String, !id.isEmpty,
            item["label"] is String, item["enabled"] is Bool,
            let placement = item["placement"] as? String,
            ["leading", "content", "trailing"].contains(placement)
          else { return false }
          if item["type"] as? String == "group" {
            guard let mode = item["mode"] as? String, ["momentary", "exclusive"].contains(mode),
              let options = item["commands"] as? [[String: Any]], (1...8).contains(options.count),
              Set(options.compactMap { $0["id"] as? String }).count == options.count,
              options.allSatisfy({
                ($0["id"] as? String).map { !$0.isEmpty } == true && $0["label"] is String
                  && $0["symbol"] is String && $0["enabled"] is Bool
              })
            else { return false }
            let selected = item["selected"]
            guard selected == nil || selected is NSNull || selected is String else { return false }
            if let selected = selected as? String {
              return mode == "exclusive" && options.contains { $0["id"] as? String == selected }
            }
            return mode == "momentary"
          }
          if item["type"] as? String == "anchor" {
            return item["symbol"] is String
              && (item["anchor"] as? String).map { !$0.isEmpty } == true
          }
          if item["type"] as? String == "command" { return item["symbol"] is String }
          return item["type"] as? String == "search" && item["query"] is String
            && (item["revision"] as? Int).map { $0 >= 0 } == true
        })
      else {
        result(FlutterError(code: "bad_arguments", message: "Invalid typed toolbar", details: nil))
        return
      }
    }
    if let items {
      let anchors = items.filter { $0["type"] as? String == "anchor" }.compactMap {
        $0["anchor"] as? String
      }
      if Set(anchors).count != anchors.count {
        result(FlutterError(code: "bad_arguments", message: "Duplicate anchors", details: nil))
        return
      }
    }
    var nextContentWidth: CGFloat?
    if let raw = args["paneLayout"], !(raw is NSNull) {
      guard let layout = raw as? [String: Any],
        let width = layout["width"] as? Double, let height = layout["height"] as? Double,
        let leading = layout["leading"] as? Double, let trailing = layout["trailing"] as? Double,
        [width, height, leading, trailing].allSatisfy({ $0.isFinite && $0 >= 0 }),
        leading + trailing <= width
      else {
        result(FlutterError(code: "bad_arguments", message: "Invalid pane layout", details: nil))
        return
      }
      nextContentWidth = CGFloat(width - leading - trailing)
    }
    guard let window = view?.window else {
      result(false)
      return
    }
    if toolbar == nil {
      previous = window.toolbar
      ownedWindow = window
      originalState = WindowState(window)
      originalWindowOpaque = window.isOpaque
      originalBackground = window.backgroundColor
      // Distinct mounts must not join AppKit's identifier-synchronized family:
      // detached toolbars can still be retained by accessibility/item clients.
      let bar = NSToolbar(identifier: "macos_ui.window_commands." + UUID().uuidString)
      bar.delegate = self
      bar.displayMode = .iconOnly
      bar.allowsUserCustomization = false
      toolbar = bar
      window.styleMask.remove(.fullSizeContentView)
      window.titlebarAppearsTransparent = false
      window.toolbarStyle = .unified
      window.titleVisibility = .hidden
      window.toolbar = bar
      appliedState = WindowState(window)
    }
    // A later native owner wins. Do not reconfigure its frame or title on updates.
    guard ownedWindow === window, window.toolbar === toolbar else {
      finishDate("invalidated")
      result(false)
      return
    }
    glassTitlebarRequested = args["glassTitlebar"] as? Bool ?? false
    configureTitlebar()
    window.title = args["windowTitle"] as? String ?? title
    appliedState?.title = window.title
    contentWidth = nextContentWidth
    titleWidthConstraint?.constant = min(260, max(1, contentWidth ?? 260))
    contextTitle = title
    contextLabel?.stringValue = title
    toolbar?.isVisible = visible
    interactive = args["interactive"] as? Bool ?? true
    let wasTyped = typedItems != nil
    typedItems = items
    validateDateAnchor()
    if let items {
      let retained = Set(
        items.filter { $0["type"] as? String == "search" }.map { $0["id"] as! String })
      for id in Array(searchItems.keys) where !retained.contains(id) { discardSearch(id) }
      for descriptor in items where descriptor["type"] as? String == "search" {
        updateSearch(descriptor)
      }
      rebuild()
      validateDateAnchor()
      result(true)
      return
    }
    finishDate("invalidated")
    for id in Array(searchItems.keys) { discardSearch(id) }
    let next = commands.map { command in
      ["id", "label", "symbol", "group", "enabled"].map { String(describing: command[$0]!) }.joined(
        separator: "|")
    }.joined(separator: "\n")
    if signature != next || wasTyped {
      signature = next
      groups = commands
      rebuild()
    }
    result(true)
  }
  private func rebuild() {
    guard let toolbar, ownedWindow?.toolbar === toolbar else { return }
    configureTitlebar()
    if typedItems != nil {
      let desired = toolbarDefaultItemIdentifiers(toolbar)
      for index in toolbar.items.indices.reversed()
      where !desired.contains(toolbar.items[index].itemIdentifier) {
        toolbar.removeItem(at: index)
      }
      for (index, id) in desired.enumerated() {
        if index < toolbar.items.count && toolbar.items[index].itemIdentifier == id { continue }
        if let old = toolbar.items.indices.first(where: {
          $0 >= index && toolbar.items[$0].itemIdentifier == id
        }) {
          toolbar.removeItem(at: old)
        }
        toolbar.insertItem(withItemIdentifier: id, at: index)
      }
      while toolbar.items.count > desired.count { toolbar.removeItem(at: toolbar.items.count - 1) }
      // Refresh commands without detaching any retained search field/editor.
      for item in toolbar.items {
        guard
          let descriptor = typedItems?.first(where: {
            "typed." + ($0["type"] as! String) + "." + ($0["id"] as! String)
              == item.itemIdentifier.rawValue
          }),
          descriptor["type"] as? String != "search"
        else { continue }
        if let group = item as? NSToolbarItemGroup, descriptor["type"] as? String == "group" {
          if group.subitems.count != (descriptor["commands"] as! [[String: Any]]).count
            || group.selectionMode
              != (descriptor["mode"] as? String == "exclusive" ? .selectOne : .momentary),
            let index = toolbar.items.firstIndex(where: { $0 === group })
          {
            toolbar.removeItem(at: index)
            toolbar.insertItem(withItemIdentifier: group.itemIdentifier, at: index)
          } else {
            configureGroup(group, descriptor: descriptor)
          }
          continue
        }
        if descriptor["type"] as? String == "anchor" {
          if let button = item.view as? NSButton {
            configureAnchor(button, item: item, descriptor: descriptor)
          }
          continue
        }
        let replacement = commandItem(item.itemIdentifier, commands: [descriptor])
        item.view = replacement.view
        item.label = replacement.label
        item.autovalidates = false
        item.menuFormRepresentation = replacement.menuFormRepresentation
      }
    } else {
      while !toolbar.items.isEmpty { toolbar.removeItem(at: 0) }
      for id in toolbarDefaultItemIdentifiers(toolbar) {
        toolbar.insertItem(withItemIdentifier: id, at: toolbar.items.count)
      }
    }
  }
  private func discardSearch(_ id: String) {
    if let item = searchItems.removeValue(forKey: id) {
      if item.searchField.currentEditor() != nil { view?.window?.makeFirstResponder(view) }
      item.searchField.delegate = nil
      item.searchField.target = nil
    }
    searchRevisions[id] = nil
    modelQueries[id] = nil
    pendingQueries[id] = nil
  }

  private func updateSearch(_ descriptor: [String: Any]) {
    let id = descriptor["id"] as! String
    let item: NSSearchToolbarItem
    if let retained = searchItems[id] {
      item = retained
    } else {
      item = NSSearchToolbarItem(itemIdentifier: NSToolbarItem.Identifier("typed.search." + id))
      let field = NSSearchField()
      field.identifier = NSUserInterfaceItemIdentifier(id)
      field.delegate = self
      field.target = self
      field.action = #selector(searchAction)
      field.sendsSearchStringImmediately = true
      field.sendsWholeSearchString = false
      item.searchField = field
      item.resignsFirstResponderWithCancel = false
      item.preferredWidthForSearchField = 220
      item.autovalidates = false
      searchItems[id] = item
      searchRevisions[id] = descriptor["revision"] as? Int ?? 0
    }
    let field = item.searchField
    let label = descriptor["label"] as! String
    item.label = label
    item.paletteLabel = label
    field.placeholderString = label
    field.setAccessibilityLabel(label)
    let enabled = descriptor["enabled"] as! Bool && interactive
    if (!enabled || toolbar?.isVisible == false) && field.currentEditor() != nil {
      view?.window?.makeFirstResponder(view)
    }
    field.isEnabled = enabled
    let query = descriptor["query"] as! String
    let revision = descriptor["revision"] as! Int
    if revision >= (searchRevisions[id] ?? 0), modelQueries[id] != query {
      modelQueries[id] = query
      if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() {
        pendingQueries[id] = query
      } else {
        pendingQueries[id] = nil
        if field.stringValue != query { field.stringValue = query }
      }
    }
  }

  func controlTextDidChange(_ notification: Notification) {
    guard let field = notification.object as? NSSearchField else { return }
    publishSearch(field)
  }

  func controlTextDidEndEditing(_ notification: Notification) {
    guard let field = notification.object as? NSSearchField, let id = field.identifier?.rawValue
    else { return }
    if let query = pendingQueries.removeValue(forKey: id) {
      field.stringValue = query
    } else {
      publishSearch(field)
    }
  }

  @objc private func searchAction(_ sender: NSSearchField) { publishSearch(sender) }

  private func publishSearch(_ field: NSSearchField) {
    guard let id = field.identifier?.rawValue, searchItems[id]?.searchField === field,
      field.isEnabled, interactive, toolbar?.isVisible == true,
      ownedWindow?.toolbar === toolbar
    else { return }
    // Editing notifications and search actions can describe the same edit.
    // Marked text stays entirely in AppKit until it commits.
    if let editor = field.currentEditor() as? NSTextView, editor.hasMarkedText() { return }
    if let pending = pendingQueries.removeValue(forKey: id) {
      field.stringValue = pending
      return
    }
    guard modelQueries[id] != field.stringValue else { return }
    modelQueries[id] = field.stringValue
    let revision = (searchRevisions[id] ?? 0) + 1
    searchRevisions[id] = revision
    channel.invokeMethod(
      "searchChanged",
      arguments: [
        "id": id, "query": field.stringValue, "revision": revision,
      ])
  }

  private func configureTitlebar() {
    guard let window = view?.window, let root = window.contentView, let view else { return }
    let workspace = NSWorkspace.shared
    var permitsGlass = false
    if #available(macOS 26.0, *) {
      permitsGlass =
        !workspace.accessibilityDisplayShouldReduceTransparency
        && !workspace.accessibilityDisplayShouldIncreaseContrast
    }
    let hosted = glassTitlebarRequested && root !== view && view.isDescendant(of: root)
    let mode = hosted ? (permitsGlass ? "glass" : "opaque") : "system"
    if mode == titlebarMode && (mode == "system" || titlebarBackground?.superview === root) {
      return
    }
    defer { appliedState = WindowState(window, keepingToolbarValues: appliedState) }
    titlebarBackground?.removeFromSuperview()
    titlebarBackground = nil
    titlebarMode = mode
    guard hosted, let guide = window.contentLayoutGuide else {
      restoreContentLayout()
      window.styleMask.remove(.fullSizeContentView)
      window.titlebarAppearsTransparent = false
      window.isOpaque = originalWindowOpaque
      window.backgroundColor = originalBackground
      return
    }
    window.styleMask.insert(.fullSizeContentView)
    window.titlebarAppearsTransparent = true
    if contentConstraints.isEmpty {
      originalTranslates = view.translatesAutoresizingMaskIntoConstraints
      view.translatesAutoresizingMaskIntoConstraints = false
      contentConstraints = [
        view.leadingAnchor.constraint(equalTo: root.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: root.trailingAnchor),
        view.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        NSLayoutConstraint(
          item: view, attribute: .top, relatedBy: .equal,
          toItem: guide, attribute: .top, multiplier: 1, constant: 0),
      ]
      NSLayoutConstraint.activate(contentConstraints)
    }
    let background: NSView
    if #available(macOS 26.0, *), permitsGlass {
      let glass = ToolbarGlassBackground()
      glass.style = .regular
      glass.cornerRadius = 0
      background = glass
      window.isOpaque = false
      window.backgroundColor = .clear
    } else {
      let opaque = ToolbarOpaqueBackground()
      opaque.boxType = .custom
      opaque.borderWidth = 0
      opaque.fillColor = .windowBackgroundColor
      opaque.contentViewMargins = .zero
      background = opaque
      window.isOpaque = true
      window.backgroundColor = originalBackground
    }
    background.translatesAutoresizingMaskIntoConstraints = false
    // The frames are disjoint. Keep the titlebar above native sidebar backdrop
    // siblings so a retained sidebar cannot cover part of the glass frame.
    root.addSubview(background, positioned: .above, relativeTo: view)
    NSLayoutConstraint.activate([
      background.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      background.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      background.topAnchor.constraint(equalTo: root.topAnchor),
      NSLayoutConstraint(
        item: background, attribute: .bottom, relatedBy: .equal,
        toItem: guide, attribute: .top, multiplier: 1, constant: 0),
    ])
    titlebarBackground = background
  }

  private func restoreContentLayout(restoreFrame: Bool = true) {
    guard !contentConstraints.isEmpty else { return }
    NSLayoutConstraint.deactivate(contentConstraints)
    contentConstraints = []
    if view?.translatesAutoresizingMaskIntoConstraints == false {
      view?.translatesAutoresizingMaskIntoConstraints = originalTranslates
    }
    if restoreFrame, let root = view?.superview { view?.frame = root.bounds }
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }
  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    if let typedItems {
      var ids: [NSToolbarItem.Identifier] = []
      for role in ["leading", "content", "trailing"] {
        if role != "leading" { ids.append(.flexibleSpace) }
        if role == "content" { ids.append(NSToolbarItem.Identifier("context")) }
        ids += typedItems.filter { $0["placement"] as? String == role }.map {
          NSToolbarItem.Identifier("typed." + ($0["type"] as! String) + "." + ($0["id"] as! String))
        }
      }
      return ids
    }
    let ordered = Array(Set(groups.compactMap { $0["group"] as? Int })).sorted()
    var ids: [NSToolbarItem.Identifier] = []
    if ordered.contains(0) { ids.append(NSToolbarItem.Identifier("group.0")) }
    ids.append(.flexibleSpace)
    ids.append(NSToolbarItem.Identifier("context"))
    ids.append(.flexibleSpace)
    for (index, group) in ordered.filter({ $0 != 0 }).enumerated() {
      if index > 0 { ids.append(.space) }
      ids.append(NSToolbarItem.Identifier("group.\(group)"))
    }
    return ids
  }
  func toolbar(
    _ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    if identifier.rawValue == "context" {
      let item = NSToolbarItem(itemIdentifier: identifier)
      let label = NSTextField(labelWithString: contextTitle)
      label.font = .systemFont(ofSize: 13, weight: .semibold)
      label.lineBreakMode = .byTruncatingTail
      label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      let limit = label.widthAnchor.constraint(
        lessThanOrEqualToConstant: min(260, max(1, contentWidth ?? 260)))
      limit.isActive = true
      titleWidthConstraint = limit
      item.view = label
      item.label = contextTitle
      item.visibilityPriority = .low
      contextLabel = label
      return item
    }
    if let descriptor = typedItems?.first(where: {
      "typed." + ($0["type"] as! String) + "." + ($0["id"] as! String) == identifier.rawValue
    }) {
      if descriptor["type"] as? String == "search" {
        return searchItems[descriptor["id"] as! String]
      }
      if descriptor["type"] as? String == "anchor" {
        let item = NSToolbarItem(itemIdentifier: identifier)
        let button = NSButton(title: "", target: self, action: #selector(activate))
        button.bezelStyle = .texturedRounded
        button.imagePosition = .imageOnly
        item.view = button
        configureAnchor(button, item: item, descriptor: descriptor)
        return item
      }
      if descriptor["type"] as? String == "group" {
        let options = descriptor["commands"] as! [[String: Any]]
        let group = NSToolbarItemGroup(
          itemIdentifier: identifier, titles: options.map { $0["label"] as! String },
          selectionMode: descriptor["mode"] as? String == "exclusive" ? .selectOne : .momentary,
          labels: options.map { $0["label"] as! String }, target: self,
          action: #selector(groupAction))
        configureGroup(group, descriptor: descriptor)
        return group
      }
      return commandItem(identifier, commands: [descriptor])
    }
    guard let group = Int(identifier.rawValue.replacingOccurrences(of: "group.", with: "")) else {
      return nil
    }
    let commands = groups.filter { $0["group"] as? Int == group }
    return commandItem(identifier, commands: commands)
  }

  private func configureAnchor(_ button: NSButton, item: NSToolbarItem, descriptor: [String: Any]) {
    let label = descriptor["label"] as! String
    let enabled = descriptor["enabled"] as! Bool && interactive && toolbar?.isVisible == true
    button.identifier = NSUserInterfaceItemIdentifier(descriptor["id"] as! String)
    button.image =
      NSImage(systemSymbolName: descriptor["symbol"] as! String, accessibilityDescription: label)
      ?? NSImage(systemSymbolName: "questionmark.square", accessibilityDescription: label)
    button.toolTip = label
    button.setAccessibilityLabel(label)
    button.isEnabled = enabled
    item.label = label
    item.autovalidates = false
    item.isEnabled = enabled
    let entry = NSMenuItem(title: label, action: #selector(menuAction), keyEquivalent: "")
    entry.target = self
    entry.representedObject = descriptor["id"]
    entry.isEnabled = enabled
    item.menuFormRepresentation = entry
  }

  private func configureGroup(_ group: NSToolbarItemGroup, descriptor: [String: Any]) {
    let options = descriptor["commands"] as! [[String: Any]]
    group.label = descriptor["label"] as! String
    // AppKit uses title, not label, for the adaptive collapsed popup.
    group.title = group.label
    group.autovalidates = false
    let available =
      descriptor["enabled"] as! Bool && interactive && toolbar?.isVisible == true
      && options.contains { $0["enabled"] as? Bool == true }
    if !available, let control = group.view, let responder = ownedWindow?.firstResponder as? NSView,
      responder === control || responder.isDescendant(of: control)
    {
      ownedWindow?.makeFirstResponder(view)
    }
    group.isEnabled = available
    (group.view as? NSControl)?.isEnabled = available
    group.selectionMode = descriptor["mode"] as? String == "exclusive" ? .selectOne : .momentary
    if descriptor["mode"] as? String == "exclusive" {
      group.selectedIndex = options.firstIndex {
        $0["id"] as? String == descriptor["selected"] as? String
      }!
    } else if let segments = group.view as? NSSegmentedControl {
      for index in options.indices { segments.setSelected(false, forSegment: index) }
    }
    let menu = NSMenu()
    menu.autoenablesItems = false
    for (index, option) in options.enumerated() {
      let label = option["label"] as! String
      let enabled =
        option["enabled"] as! Bool && descriptor["enabled"] as! Bool && interactive
        && toolbar?.isVisible == true
      let subitem = group.subitems[index]
      subitem.label = label
      subitem.autovalidates = false
      subitem.isEnabled = enabled
      if let segments = group.view as? NSSegmentedControl {
        segments.setLabel(label, forSegment: index)
        segments.setEnabled(enabled, forSegment: index)
      }
      let entry = NSMenuItem(title: label, action: #selector(groupMenuAction), keyEquivalent: "")
      entry.target = self
      entry.representedObject = ["id": descriptor["id"]!, "command": option["id"]!]
      entry.isEnabled = enabled
      entry.state =
        descriptor["mode"] as? String == "exclusive" && group.selectedIndex == index ? .on : .off
      menu.addItem(entry)
    }
    let overflow = NSMenuItem(title: group.label, action: nil, keyEquivalent: "")
    overflow.submenu = menu
    group.menuFormRepresentation = overflow
  }

  @objc private func groupAction(_ sender: AnyObject) {
    guard
      let group = toolbar?.items.compactMap({ $0 as? NSToolbarItemGroup }).first(where: {
        $0 === sender || $0.view === sender
      }),
      let descriptor = typedItems?.first(where: {
        "typed.group." + ($0["id"] as! String) == group.itemIdentifier.rawValue
      }), let options = descriptor["commands"] as? [[String: Any]]
    else { return }
    let index = (sender as? NSSegmentedControl)?.selectedSegment ?? group.selectedIndex
    // Restore controlled selection immediately; the application decides whether
    // to accept the proposal through its next model update.
    configureGroup(group, descriptor: descriptor)
    guard options.indices.contains(index) else { return }
    publishGroup(descriptor["id"] as! String, command: options[index]["id"] as! String)
  }

  @objc private func groupMenuAction(_ sender: NSMenuItem) {
    guard sender.isEnabled, let args = sender.representedObject as? [String: String],
      let id = args["id"], let command = args["command"]
    else { return }
    publishGroup(id, command: command)
  }

  private func publishGroup(_ id: String, command: String) {
    guard interactive, toolbar?.isVisible == true, ownedWindow?.toolbar === toolbar,
      let descriptor = typedItems?.first(where: {
        $0["id"] as? String == id && $0["type"] as? String == "group"
      }),
      descriptor["enabled"] as? Bool == true,
      let options = descriptor["commands"] as? [[String: Any]],
      options.contains(where: { $0["id"] as? String == command && $0["enabled"] as? Bool == true })
    else { return }
    channel.invokeMethod("groupAction", arguments: ["id": id, "command": command])
    view?.window?.makeFirstResponder(view)
  }

  private func commandItem(_ identifier: NSToolbarItem.Identifier, commands: [[String: Any]])
    -> NSToolbarItem
  {
    let item = NSToolbarItem(itemIdentifier: identifier)
    item.label = commands.map { $0["label"] as! String }.joined(separator: ", ")
    item.autovalidates = false
    let width = CGFloat(commands.count * 36 + 8)
    let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 36))
    content.autoresizingMask = [.width, .height]
    let menu = NSMenu()
    menu.autoenablesItems = false
    for (index, command) in commands.enumerated() {
      let id = command["id"] as! String
      let label = command["label"] as! String
      let enabled = command["enabled"] as! Bool
      let button = NSButton(
        image: NSImage(
          systemSymbolName: command["symbol"] as! String,
          accessibilityDescription: label)
          ?? NSImage(systemSymbolName: "questionmark.square", accessibilityDescription: label)
          ?? NSImage(), target: self, action: #selector(activate))
      button.image = button.image?.withSymbolConfiguration(
        NSImage.SymbolConfiguration(pointSize: 16, weight: .medium))
      button.contentTintColor = .labelColor
      button.identifier = NSUserInterfaceItemIdentifier(id)
      button.setAccessibilityLabel(label)
      button.toolTip = label
      button.isEnabled = enabled
      button.isBordered = false
      button.frame = NSRect(x: 4 + index * 36, y: 2, width: 36, height: 32)
      content.addSubview(button)
      let entry = NSMenuItem(title: label, action: #selector(menuAction), keyEquivalent: "")
      entry.representedObject = id
      entry.target = self
      entry.isEnabled = enabled
      menu.addItem(entry)
    }
    let workspace = NSWorkspace.shared
    if #available(macOS 26.0, *), !workspace.accessibilityDisplayShouldReduceTransparency,
      !workspace.accessibilityDisplayShouldIncreaseContrast
    {
      let glass = NSGlassEffectView(frame: content.frame)
      glass.style = .regular
      glass.cornerRadius = 18
      glass.contentView = content
      if #available(macOS 27.0, *) {
        glass.effectIsInteractive = !workspace.accessibilityDisplayShouldReduceMotion
      }
      item.view = glass
    } else {
      content.wantsLayer = true
      content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
      item.view = content
    }
    if let hosted = item.view {
      hosted.widthAnchor.constraint(equalToConstant: width).isActive = true
      hosted.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    let overflow = NSMenuItem(title: item.label, action: nil, keyEquivalent: "")
    overflow.submenu = menu
    item.menuFormRepresentation = overflow
    return item
  }
  @objc private func activate(_ sender: NSButton) {
    guard sender.isEnabled, let id = sender.identifier?.rawValue else { return }
    channel.invokeMethod("action", arguments: id)
    view?.window?.makeFirstResponder(view)
  }
  @objc private func menuAction(_ sender: NSMenuItem) {
    guard sender.isEnabled, let id = sender.representedObject as? String else { return }
    channel.invokeMethod("action", arguments: id)
    view?.window?.makeFirstResponder(view)
  }
  // Only a current visible toolbar item is an eligible native anchor. In
  // particular, an overflow menu has no persistent toolbar positioning view.
  private func anchorItem(_ token: String) -> NSToolbarItem? {
    guard interactive, let toolbar, toolbar.isVisible, ownedWindow?.toolbar === toolbar,
      ownedWindow?.attachedSheet == nil,
      let descriptor = typedItems?.first(where: { $0["anchor"] as? String == token }),
      descriptor["type"] as? String == "anchor", descriptor["enabled"] as? Bool == true,
      let item = toolbar.visibleItems?.first(where: {
        $0.itemIdentifier.rawValue == "typed.anchor." + (descriptor["id"] as! String)
      }), let button = item.view as? NSButton, button.isEnabled,
      button.window === ownedWindow, !button.isHiddenOrHasHiddenAncestor,
      !button.visibleRect.isEmpty
    else { return nil }
    return item
  }

  private func civilDate(_ raw: Any?, calendar: Calendar) -> Date? {
    guard let parts = raw as? [Int], parts.count == 3, (1...9999).contains(parts[0]),
      (1...12).contains(parts[1]), (1...31).contains(parts[2]),
      let date = calendar.date(
        from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
      calendar.component(.year, from: date) == parts[0],
      calendar.component(.month, from: date) == parts[1],
      calendar.component(.day, from: date) == parts[2]
    else { return nil }
    return date
  }
  private func dateParts(_ date: Date) -> [Int] {
    [.year, .month, .day].map { dateCalendar.component($0, from: date) }
  }

  private func presentDate(_ raw: Any?, result: @escaping FlutterResult) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    guard let args = raw as? [String: Any], args["calendar"] as? String == "gregorian",
      let token = args["anchor"] as? String,
      let title = args["title"] as? String, let commit = args["commitLabel"] as? String,
      let cancel = args["cancelLabel"] as? String, let locale = args["locale"] as? String,
      let date = civilDate(args["date"], calendar: calendar),
      let minimum = civilDate(args["minimum"], calendar: calendar),
      let maximum = civilDate(args["maximum"], calendar: calendar),
      minimum <= date, date <= maximum
    else {
      result(FlutterError(code: "bad_arguments", message: "Invalid civil date task", details: nil))
      return
    }
    guard let item = anchorItem(token), let invoker = item.view,
      ownedWindow?.isKeyWindow == true
    else {
      result(["exit": "unavailable", "date": args["date"]!])
      return
    }
    finishDate("superseded")
    dateCalendar = calendar
    let picker = NSDatePicker()
    picker.datePickerStyle = .clockAndCalendar
    picker.datePickerElements = .yearMonthDay
    picker.calendar = calendar
    picker.timeZone = calendar.timeZone
    picker.locale = Locale(identifier: locale)
    picker.dateValue = date
    picker.minDate = minimum
    picker.maxDate = maximum
    picker.setAccessibilityLabel(title)
    picker.sizeToFit()
    // The graphical control browses months; the textual control permits precise
    // year entry without a custom calendar implementation.
    let textual = NSDatePicker()
    textual.datePickerStyle = .textFieldAndStepper
    textual.datePickerElements = .yearMonthDay
    textual.calendar = calendar
    textual.timeZone = calendar.timeZone
    textual.locale = picker.locale
    textual.minDate = minimum
    textual.maxDate = maximum
    textual.dateValue = date
    textual.setAccessibilityLabel(title)
    textual.target = self
    textual.action = #selector(dateChanged)
    picker.target = self
    picker.action = #selector(dateChanged)
    let cancelButton = NSButton(title: cancel, target: self, action: #selector(cancelDate))
    let commitButton = NSButton(title: commit, target: self, action: #selector(commitDate))
    let actions = NSStackView(views: [cancelButton, commitButton])
    actions.orientation = .horizontal
    let stack = NSStackView(views: [NSTextField(labelWithString: title), picker, textual, actions])
    stack.orientation = .vertical
    stack.spacing = 8
    stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    let controller = NSViewController()
    controller.view = stack
    stack.layoutSubtreeIfNeeded()
    let popover = NSPopover()
    popover.behavior = .transient
    popover.animates = false
    popover.delegate = self
    popover.contentViewController = controller
    popover.contentSize = stack.fittingSize
    dateResult = result
    dateAnchor = token
    dateInvoker = invoker
    datePicker = picker
    dateTextual = textual
    datePopover = popover
    dateAnchorRect = invoker.convert(invoker.bounds, to: nil)
    // Notification-driven only while open; no capture, frame loop or timer.
    let center = NotificationCenter.default
    for name in [
      NSWindow.didResizeNotification, NSWindow.didMoveNotification,
      NSWindow.willCloseNotification, NSView.frameDidChangeNotification,
    ] {
      dateObservers.append(
        center.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
          guard let self else { return }
          if [
            NSWindow.willCloseNotification, NSWindow.didResizeNotification,
            NSWindow.didMoveNotification,
          ].contains(note.name),
            note.object as? NSWindow === self.ownedWindow
          {
            self.finishDate("invalidated")
          } else {
            DispatchQueue.main.async { [weak self] in self?.validateDateAnchor() }
          }
        })
    }
    invoker.postsFrameChangedNotifications = true
    popover.show(relativeTo: invoker.bounds, of: invoker, preferredEdge: .minY)
    if !popover.isShown { finishDate("unavailable") }
  }

  @objc private func dateChanged(_ sender: NSDatePicker) {
    guard let picker = datePicker else { return }
    picker.dateValue = sender.dateValue
    if let stack = datePopover?.contentViewController?.view as? NSStackView {
      for case let other as NSDatePicker in stack.arrangedSubviews where other !== sender {
        other.dateValue = sender.dateValue
      }
    }
  }
  @objc private func commitDate() { finishDate("committed") }
  @objc private func cancelDate() { finishDate("cancelled") }
  func popoverDidClose(_ notification: Notification) {
    guard notification.object as? NSPopover === datePopover else { return }
    finishDate("dismissed")
  }
  func popoverShouldDetach(_ popover: NSPopover) -> Bool { false }
  private func validateDateAnchor() {
    guard let token = dateAnchor else { return }
    guard let invoker = anchorItem(token)?.view, invoker === dateInvoker,
      invoker.convert(invoker.bounds, to: nil) == dateAnchorRect
    else {
      finishDate("invalidated")
      return
    }
  }
  private func finishDate(_ exit: String) {
    guard let completion = dateResult, let picker = datePicker else { return }
    if let textual = dateTextual, textual.currentEditor() != nil {
      textual.validateEditing()
      picker.dateValue = textual.dateValue
    }
    // Clear ownership before closing: delegate reentrancy cannot complete twice.
    dateResult = nil
    let popover = datePopover
    let invoker = dateAnchor.flatMap { anchorItem($0)?.view }
    let date = dateParts(picker.dateValue)
    datePopover = nil
    datePicker = nil
    dateTextual = nil
    dateAnchor = nil
    dateAnchorRect = nil
    dateInvoker = nil
    for observer in dateObservers { NotificationCenter.default.removeObserver(observer) }
    dateObservers = []
    popover?.delegate = nil
    popover?.close()
    if let window = ownedWindow, window.attachedSheet == nil, window.isKeyWindow,
      trackingMenus.isEmpty, !(window.firstResponder is NSTextView),
      NSApp.keyWindow === window
    {
      if let invoker, !window.makeFirstResponder(invoker) {
        window.makeFirstResponder(view)
      } else if invoker == nil {
        window.makeFirstResponder(view)
      }
    }
    completion(["exit": exit, "date": date])
  }

  private func remove() {
    finishDate("disposed")
    // Compare before replacing the toolbar: AppKit may change frame properties
    // when the previous toolbar is reinstalled. Restore only values we still own.
    let window = ownedWindow
    let current = window.map { WindowState($0) }
    let ownsToolbar = toolbar != nil && window?.toolbar === toolbar
    titlebarBackground?.removeFromSuperview()
    titlebarBackground = nil
    titlebarMode = ""
    restoreContentLayout(restoreFrame: ownsToolbar)
    if ownsToolbar, let window, let current, let applied = appliedState,
      let original = originalState
    {
      window.toolbar = previous
      // Own only fullSizeContentView, never fullscreen or unrelated style bits.
      if current.fullSize == applied.fullSize {
        if original.fullSize {
          window.styleMask.insert(.fullSizeContentView)
        } else {
          window.styleMask.remove(.fullSizeContentView)
        }
      }
      if current.transparent == applied.transparent {
        window.titlebarAppearsTransparent = original.transparent
      }
      if current.opaque == applied.opaque { window.isOpaque = original.opaque }
      if current.background == applied.background { window.backgroundColor = original.background }
      if current.toolbarStyle == applied.toolbarStyle {
        window.toolbarStyle = original.toolbarStyle
      }
      if current.titleVisibility == applied.titleVisibility {
        window.titleVisibility = original.titleVisibility
      }
      if current.title == applied.title { window.title = original.title }
    }
    // A detached toolbar can remain retained by an item/accessibility client.
    // Empty it and revoke callbacks. Mount identifiers are unique so AppKit
    // cannot synchronize updates into a detached previous mount.
    toolbar?.delegate = nil
    while let toolbar, !toolbar.items.isEmpty { toolbar.removeItem(at: 0) }
    ownedWindow = nil
    originalState = nil
    appliedState = nil
    toolbar = nil
    previous = nil
    signature = ""
    contentWidth = nil
    titleWidthConstraint = nil
    groups = []
    typedItems = nil
    for id in Array(searchItems.keys) { discardSearch(id) }
  }
  deinit {
    finishDate("disposed")
    if let monitor { NSEvent.removeMonitor(monitor) }
    if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    for token in menuObservers { NotificationCenter.default.removeObserver(token) }
  }
}
