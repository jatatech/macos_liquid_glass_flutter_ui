import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../layout/pane_layout.dart';
import 'contextual_date.dart';

/// An AppKit toolbar command. Stable IDs also identify native overflow actions.
@immutable
class MacosNativeToolbarCommand {
  const MacosNativeToolbarCommand({
    required this.id,
    required this.label,
    required this.symbol,
    this.group = 0,
    this.onPressed,
  });
  final String id, label, symbol;
  final int group;
  final VoidCallback? onPressed;
}

/// Semantic order within the toolbar, independent of pane widths.
enum MacosNativeToolbarPlacement { leading, content, trailing }

/// An opt-in typed item. IDs must be unique across the toolbar.
@immutable
sealed class MacosNativeToolbarItem {
  const MacosNativeToolbarItem({required this.id, required this.placement});
  final String id;
  final MacosNativeToolbarPlacement placement;
}

/// A command using the existing callback and disabled-state contract.
@immutable
class MacosNativeToolbarCommandItem extends MacosNativeToolbarItem {
  MacosNativeToolbarCommandItem({
    required this.command,
    this.anchor,
    super.placement = MacosNativeToolbarPlacement.trailing,
  }) : super(id: command.id);
  final MacosNativeToolbarCommand command;

  /// Opaque identity for contextual native presentation. Retain across builds.
  final MacosNativeToolbarAnchor? anchor;
}

/// Momentary commands or an app-controlled exclusive choice. Each enabled
/// activation proposes once, including a repeat on the same option. Cancellation
/// proposes nothing. [selectedId] never changes until the caller rebuilds.
@immutable
class MacosNativeToolbarGroup extends MacosNativeToolbarItem {
  const MacosNativeToolbarGroup({
    required super.id,
    required this.label,
    required this.commands,
    this.mode = MacosNativeToolbarGroupMode.momentary,
    this.selectedId,
    super.placement = MacosNativeToolbarPlacement.content,
  });
  final String label;

  /// One to eight commands with distinct, nonempty IDs within this group.
  final List<MacosNativeToolbarCommand> commands;
  final MacosNativeToolbarGroupMode mode;

  /// Required for exclusive groups; must be null for momentary groups.
  final String? selectedId;
}

enum MacosNativeToolbarGroupMode { momentary, exclusive }

/// Controlled search. The caller owns/disposes [controller] and supplies an
/// equivalent labelled fallback. Native edits update text before [onChanged];
/// programmatic changes do not invoke it. Selection/composition stay in AppKit.
@immutable
class MacosNativeToolbarSearch extends MacosNativeToolbarItem {
  const MacosNativeToolbarSearch({
    required super.id,
    required this.label,
    required this.controller,
    this.onChanged,
    this.enabled = true,
    super.placement = MacosNativeToolbarPlacement.trailing,
  });
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;
}

/// Opaque identity bound to exactly one typed command item in one toolbar.
/// Retain it across builds. It exposes no native view or Flutter coordinates.
class MacosNativeToolbarAnchor {
  MacosNativeToolbarAnchor() : _id = 'anchor-${_next++}';
  static int _next = 0;
  final String _id;
}

/// Caller-owned routing for native Find and bounded contextual dates.
/// Unavailable results let the application reveal its equivalent Flutter UI.
class MacosNativeToolbarController {
  Future<bool> Function(String)? _focus;
  Future<MacosDateSelectionResult> Function(String, MacosDateSelection)? _date;

  /// Returns unavailable when the native anchor is hidden, overflowed, removed,
  /// disabled or covered. Reveal a labelled Flutter fallback before opening it.
  Future<MacosDateSelectionResult> presentDate(
    MacosNativeToolbarAnchor anchor,
    MacosDateSelection selection,
  ) async =>
      await _date?.call(anchor._id, selection) ??
      MacosDateSelectionResult(
        MacosDateSelectionExit.unavailable,
        selection.initialDate,
      );

  /// A false result means the app should focus its fallback field. Editing
  /// shortcuts are not intercepted by the package.
  Future<bool> focusSearch(String id) async => await _focus?.call(id) ?? false;
}

/// Single registrar-window toolbar; never hosts arbitrary Flutter children.
/// AppKit owns titlebar materials, keyboard traversal and overflow. On macOS 26+
/// command groups use NSGlassEffectView; accessibility preferences select opaque
/// AppKit controls. Other platforms/missing plugin use [fallback]. Configure
/// macos_window_utils without fullscreen toolbar removal. The default keeps
/// ordinary content framing; [glassTitlebar] opts into a full-width glass frame.
class MacosNativeToolbar extends StatefulWidget {
  const MacosNativeToolbar({
    super.key,
    required this.title,
    this.windowTitle,
    this.commands = const [],
    this.items,
    this.controller,
    this.paneLayoutController,
    required this.fallback,
    required this.child,
    this.visible = true,
    this.interactive = true,
    this.onEscape,
    this.glassTitlebar = false,
  }) : assert(items == null || commands.length == 0);
  final String title;
  final String? windowTitle;
  final List<MacosNativeToolbarCommand> commands;

  /// Null retains the legacy layout. When non-null, [commands] must be empty.
  final List<MacosNativeToolbarItem>? items;
  final MacosNativeToolbarController? controller;

  /// Share with the descendant MacosWindow. Its content-relative geometry bounds
  /// the context title; AppKit still owns toolbar placement and overflow.
  final MacosPaneLayoutController? paneLayoutController;
  final Widget fallback, child;

  /// Also hosts a full-width native glass titlebar background. The app must
  /// initialise macos_window_utils first, retaining its native parent view. This
  /// host constrains Flutter to contentLayoutGuide without replacing that parent.
  /// Existing consumers retain their frame configuration by default.
  final bool glassTitlebar;
  final bool visible;
  final bool interactive;
  final VoidCallback? onEscape;
  @override
  State<MacosNativeToolbar> createState() => _MacosNativeToolbarState();
}

class _MacosNativeToolbarState extends State<MacosNativeToolbar> {
  static const channel = MethodChannel(
    'dev.groovinchip.macos_ui/window_toolbar',
  );
  final revisions = <String, int>{};
  final searches = <String, TextEditingController>{};
  bool receivingEdit = false;
  Iterable<MacosNativeToolbarSearch> get searchItems =>
      (widget.items ?? const <MacosNativeToolbarItem>[])
          .whereType<MacosNativeToolbarSearch>();
  Iterable<MacosNativeToolbarCommand> get commandItems => widget.items == null
      ? widget.commands
      : widget.items!.whereType<MacosNativeToolbarCommandItem>().map(
          (i) => i.command,
        );

  void bindSearches() {
    for (final controller in searches.values.toSet()) {
      controller.removeListener(searchChanged);
    }
    searches.clear();
    for (final item in searchItems) {
      searches[item.id] = item.controller;
    }
    for (final controller in searches.values.toSet()) {
      controller.addListener(searchChanged);
    }
  }

  void searchChanged() {
    if (!receivingEdit) sync();
  }

  /// A false result means the app should focus its fallback field. Editing
  /// shortcuts are not intercepted by the package.
  Future<bool> focusSearch(String id) async {
    if (!mounted ||
        !native ||
        !widget.visible ||
        !routeActive ||
        !searchItems.any((s) => s.id == id && s.enabled)) {
      return false;
    }
    try {
      return await channel.invokeMethod<bool>('focusSearch', id) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<MacosDateSelectionResult> presentDate(
    String anchor,
    MacosDateSelection selection,
  ) async {
    final unavailable = MacosDateSelectionResult(
      MacosDateSelectionExit.unavailable,
      selection.initialDate,
    );
    if (!mounted ||
        !native ||
        !widget.visible ||
        !routeActive ||
        !(widget.items ?? const <MacosNativeToolbarItem>[])
            .whereType<MacosNativeToolbarCommandItem>()
            .any(
              (item) =>
                  item.anchor?._id == anchor && item.command.onPressed != null,
            )) {
      return unavailable;
    }
    try {
      final raw = await channel.invokeMapMethod<String, dynamic>(
        'presentDate',
        {'anchor': anchor, ...selection.toMap()},
      );
      if (raw == null) return unavailable;
      final exit = MacosDateSelectionExit.values.firstWhere(
        (e) => e.name == raw['exit'],
        orElse: () => MacosDateSelectionExit.unavailable,
      );
      final parts = raw['date'];
      if (parts is! List || parts.length != 3 || parts.any((p) => p is! int)) {
        return unavailable;
      }
      final date = DateTime.utc(
        parts[0] as int,
        parts[1] as int,
        parts[2] as int,
      );
      if (!selection.contains(date) ||
          date.year != parts[0] ||
          date.month != parts[1] ||
          date.day != parts[2]) {
        return unavailable;
      }
      return MacosDateSelectionResult(exit, date);
    } on PlatformException {
      return unavailable;
    } on MissingPluginException {
      return unavailable;
    }
  }

  bool native = false, busy = false, dirty = false;
  bool routeActive = true;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  @override
  void initState() {
    super.initState();
    bindSearches();
    widget.paneLayoutController?.addListener(sync);
    widget.controller?._focus = focusSearch;
    widget.controller?._date = presentDate;
    if (supported) {
      channel.setMethodCallHandler((call) async {
        if (!mounted || !widget.visible || !routeActive) return;
        if (call.method == 'escape') widget.onEscape?.call();
        if (call.method == 'searchChanged' && call.arguments is Map) {
          final args = call.arguments as Map;
          final id = args['id'],
              query = args['query'],
              revision = args['revision'];
          if (id is! String ||
              query is! String ||
              revision is! int ||
              revision <= (revisions[id] ?? 0)) {
            return;
          }
          for (final item in searchItems) {
            if (item.id != id || !item.enabled) continue;
            revisions[id] = revision;
            receivingEdit = true;
            try {
              if (item.controller.text != query) item.controller.text = query;
            } finally {
              receivingEdit = false;
            }
            item.onChanged?.call(query);
          }
        }
        if (call.method == 'groupAction' && call.arguments is Map) {
          final args = call.arguments as Map;
          for (final group
              in (widget.items ?? const <MacosNativeToolbarItem>[])
                  .whereType<MacosNativeToolbarGroup>()) {
            if (group.id != args['id']) continue;
            for (final command in group.commands) {
              if (command.id == args['command']) command.onPressed?.call();
            }
          }
        }
        if (call.method == 'action') {
          for (final command in commandItems) {
            if (command.id == call.arguments) command.onPressed?.call();
          }
        }
      });
      sync();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeActive =
        widget.interactive && (ModalRoute.isCurrentOf(context) ?? true);
    sync();
  }

  @override
  void didUpdateWidget(MacosNativeToolbar old) {
    super.didUpdateWidget(old);
    if (old.paneLayoutController != widget.paneLayoutController) {
      old.paneLayoutController?.removeListener(sync);
      widget.paneLayoutController?.addListener(sync);
    }
    if (old.controller != widget.controller) {
      old.controller?._focus = null;
      old.controller?._date = null;
    }
    widget.controller?._focus = focusSearch;
    widget.controller?._date = presentDate;
    bindSearches();
    routeActive =
        widget.interactive && (ModalRoute.isCurrentOf(context) ?? true);
    sync();
  }

  Future<void> sync() async {
    if (!supported) return;
    dirty = true;
    if (busy) return;
    busy = true;
    while (dirty && mounted) {
      dirty = false;
      final current = widget;
      bool available = false;
      try {
        available =
            await channel.invokeMethod<bool>(
              current.items == null ? 'update' : 'updateTyped',
              {
                'title': current.title,
                'windowTitle': current.windowTitle ?? current.title,
                'visible': current.visible,
                'glassTitlebar': current.glassTitlebar,
                'interactive': routeActive,
                if (current.paneLayoutController?.value case final layout?)
                  'paneLayout': {
                    'width': layout.size.width,
                    'height': layout.size.height,
                    'leading': layout.leadingWidth,
                    'trailing': layout.trailingWidth,
                  },
                if (current.items != null)
                  'items': [
                    for (final item in current.items!)
                      {
                        'id': item.id,
                        'placement': item.placement.name,
                        if (item is MacosNativeToolbarCommandItem) ...{
                          'type': item.anchor == null ? 'command' : 'anchor',
                          if (item.anchor != null) 'anchor': item.anchor!._id,
                          'label': item.command.label,
                          'symbol': item.command.symbol,
                          'enabled':
                              item.command.onPressed != null && routeActive,
                        },
                        if (item is MacosNativeToolbarGroup) ...{
                          'type': 'group',
                          'label': item.label,
                          'enabled': routeActive,
                          'mode': item.mode.name,
                          'selected': item.selectedId,
                          'commands': [
                            for (final c in item.commands)
                              {
                                'id': c.id,
                                'label': c.label,
                                'symbol': c.symbol,
                                'enabled': c.onPressed != null && routeActive,
                              },
                          ],
                        },
                        if (item is MacosNativeToolbarSearch) ...{
                          'type': 'search',
                          'label': item.label,
                          'query': item.controller.text,
                          'revision': revisions[item.id] ?? 0,
                          'enabled': item.enabled && routeActive,
                        },
                      },
                  ],
                'commands': [
                  for (final c in current.commands)
                    {
                      'id': c.id,
                      'label': c.label,
                      'symbol': c.symbol,
                      'group': c.group,
                      'enabled': c.onPressed != null && routeActive,
                    },
                ],
              },
            ) ==
            true;
      } on PlatformException {
        available = false;
      } on MissingPluginException {
        available = false;
      }
      // A rejected update leaves the last accepted AppKit toolbar installed.
      // Tear it down in this same queue before exposing its Flutter replacement.
      // Native removal preserves any later external window/toolbar owner.
      if (!available && native) await remove();
      if (mounted && native != available) setState(() => native = available);
    }
    busy = false;
    if (!mounted) await remove();
  }

  Future<void> remove() async {
    try {
      await channel.invokeMethod<void>('remove');
    } on PlatformException {
      /* Already unavailable. */
    } on MissingPluginException {
      /* Fallback has no native owner. */
    }
  }

  @override
  void dispose() {
    widget.controller?._focus = null;
    widget.controller?._date = null;
    widget.paneLayoutController?.removeListener(sync);
    for (final controller in searches.values.toSet()) {
      controller.removeListener(searchChanged);
    }
    if (supported) {
      channel.setMethodCallHandler(null);
      if (!busy) remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!native && widget.visible) widget.fallback,
      Expanded(child: widget.child),
    ],
  );
}
