import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

const Duration _kExpand = Duration(milliseconds: 200);
const ShapeBorder _defaultShape = RoundedRectangleBorder(
  //TODO: consider changing to 4.0 or 5.0 - App Store, Notes and Mail seem to use 4.0 or 5.0
  borderRadius: BorderRadius.all(Radius.circular(5.0)),
);

/// {@template sidebarItemSize}
/// Enumerates the size specifications of [SidebarItem]s
///
/// Values were adapted from https://developer.apple.com/design/human-interface-guidelines/components/navigation-and-search/sidebars/#platform-considerations
/// and were eyeballed against apps like App Store, Notes, and Mail.
/// {@endtemplate}
enum SidebarItemSize {
  /// A small [SidebarItem]. Has a [height] of 24 and an [iconSize] of 12.
  small(24.0, 12.0),

  /// A medium [SidebarItem]. Has a [height] of 28 and an [iconSize] of 16.
  medium(29.0, 16.0),

  /// A large [SidebarItem]. Has a [height] of 32 and an [iconSize] of 20.0.
  large(36.0, 18.0);

  /// {@macro sidebarItemSize}
  const SidebarItemSize(this.height, this.iconSize);

  /// The height of the [SidebarItem].
  final double height;

  /// The maximum size of the [SidebarItem]'s leading icon.
  final double iconSize;
}

/// A scrollable widget that renders [SidebarItem]s.
///
/// See also:
///
///  * [SidebarItem], the items used by this sidebar
///  * [Sidebar], a side bar used alongside [MacosScaffold]
class SidebarItems extends StatelessWidget {
  /// Creates a scrollable widget that renders [SidebarItem]s.
  const SidebarItems({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.itemSize = SidebarItemSize.medium,
    this.scrollController,
    this.selectedColor,
    this.unselectedColor,
    this.shape,
    this.cursor = SystemMouseCursors.basic,
  }) : assert(currentIndex >= 0);

  /// The [SidebarItem]s used by the sidebar. If no items are provided,
  /// the sidebar is not rendered.
  final List<SidebarItem> items;

  /// The selected leaf's index in depth-first order, including collapsed leaves.
  /// Section headers and disclosure parents do not consume an index.
  final int currentIndex;

  /// Called when the current selected index should be changed.
  final ValueChanged<int> onChanged;

  /// The size specifications for all [items].
  ///
  /// Defaults to [SidebarItemSize.medium].
  final SidebarItemSize itemSize;

  /// The scroll controller used by this sidebar. If null, a local scroll
  /// controller is created.
  final ScrollController? scrollController;

  /// The color to paint the item when it's selected.
  ///
  /// If null, the color is chosen automatically based on the user’s selected
  /// system accent color and whether the sidebar is in the main window.
  final Color? selectedColor;

  /// The color to paint the item when it's unselected.
  ///
  /// Defaults to transparent.
  final Color? unselectedColor;

  /// The [shape] property specifies the outline (border) of the
  /// decoration. The shape must not be null. It's used alongside
  /// [selectedColor].
  final ShapeBorder? shape;

  /// Specifies the kind of cursor to use for all sidebar items.
  ///
  /// Defaults to [SystemMouseCursors.basic].
  final MouseCursor? cursor;

  @override
  Widget build(BuildContext context) => _SidebarItemsView(configuration: this);
}

class _SidebarItemsView extends StatefulWidget {
  const _SidebarItemsView({required this.configuration});
  final SidebarItems configuration;

  @override
  State<_SidebarItemsView> createState() => _SidebarItemsState();
}

class _SidebarEntry {
  const _SidebarEntry(this.path, this.item, this.parent);
  final String path;
  final SidebarItem item;
  final String? parent;
}

class _SidebarItemsState extends State<_SidebarItemsView> {
  SidebarItems get configuration => widget.configuration;
  final Map<String, FocusNode> _nodes = {};
  final Map<String, bool> _expanded = {};
  final List<_SidebarEntry> _entries = [];

  bool _isExpanded(_SidebarEntry entry) =>
      _expanded[entry.path] ?? entry.item.expandDisclosureItems;

  FocusNode _node(_SidebarEntry entry) =>
      entry.item.focusNode ??
      _nodes.putIfAbsent(entry.path, () => FocusNode(debugLabel: entry.path));

  bool _visible(_SidebarEntry entry) {
    var parent = entry.parent;
    while (parent != null) {
      final ancestor = _entries.firstWhere((e) => e.path == parent);
      if (!_isExpanded(ancestor)) return false;
      parent = ancestor.parent;
    }
    return true;
  }

  void _focus(_SidebarEntry entry) {
    _node(entry).requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _node(entry).context;
      if (context != null) Scrollable.ensureVisible(context);
    });
  }

  void _toggle(_SidebarEntry entry) {
    final expanded = _isExpanded(entry);
    if (expanded &&
        _entries.any(
          (e) => e.path.startsWith('${entry.path}/') && _node(e).hasFocus,
        )) {
      _focus(entry);
    }
    setState(() => _expanded[entry.path] = !expanded);
    if (configuration.key is PageStorageKey) {
      PageStorage.maybeOf(context)?.writeState(
        context,
        !expanded,
        identifier: (configuration.key, entry.path),
      );
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final visible = _entries
        .where(
          (e) =>
              _visible(e) &&
              (e.item.section != true || e.item.disclosureItems != null),
        )
        .toList();
    final index = visible.indexWhere((e) => _node(e).hasFocus);
    if (index < 0) return KeyEventResult.ignored;
    final entry = visible[index];
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _focus(visible[(index + 1).clamp(0, visible.length - 1)]);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _focus(visible[(index - 1).clamp(0, visible.length - 1)]);
    } else if (key == LogicalKeyboardKey.home) {
      _focus(visible.first);
    } else if (key == LogicalKeyboardKey.end) {
      _focus(visible.last);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (entry.item.disclosureItems != null) {
        if (!_isExpanded(entry)) {
          _toggle(entry);
        } else if (index + 1 < visible.length &&
            visible[index + 1].path.startsWith('${entry.path}/')) {
          _focus(visible[index + 1]);
        }
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (entry.item.disclosureItems != null && _isExpanded(entry)) {
        _toggle(entry);
      } else if (entry.parent != null) {
        _focus(_entries.firstWhere((e) => e.path == entry.parent));
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (configuration.items.isEmpty) return const SizedBox.shrink();
    _entries.clear();
    void collect(List<SidebarItem> items, String? parent) {
      for (var i = 0; i < items.length; i++) {
        final path = parent == null ? '$i' : '$parent/$i';
        _entries.add(_SidebarEntry(path, items[i], parent));
        if (!_expanded.containsKey(path)) {
          final stored = configuration.key is PageStorageKey
              ? PageStorage.maybeOf(
                  context,
                )?.readState(context, identifier: (configuration.key, path))
              : null;
          _expanded[path] = stored is bool
              ? stored
              : items[i].expandDisclosureItems;
        }
        if (items[i].disclosureItems != null) {
          collect(items[i].disclosureItems!, path);
        }
      }
    }

    collect(configuration.items, null);
    final selectable = _entries
        .where((e) => e.item.disclosureItems == null && e.item.section != true)
        .toList();
    assert(
      selectable.isEmpty || configuration.currentIndex < selectable.length,
    );
    final selected = selectable.isEmpty
        ? null
        : selectable[configuration.currentIndex];
    final chrome = MacosChromeData.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget branch(_SidebarEntry entry) {
      final item = entry.item;
      final disclosure = item.disclosureItems != null;
      final expanded = disclosure && _isExpanded(entry);
      final focusNode = _node(entry);
      final row = item.section == true && !disclosure
          ? _SidebarHeaderItem(item: item)
          : _SidebarItem(
              key: ValueKey(entry.path),
              item: item,
              focusNode: focusNode,
              expanded: disclosure ? expanded : null,
              selected: entry == selected,
              onClick: () {
                focusNode.requestFocus();
                if (disclosure) {
                  _toggle(entry);
                } else {
                  configuration.onChanged(selectable.indexOf(entry));
                }
              },
            );
      if (!disclosure) return row;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          ExcludeFocus(
            excluding: !expanded,
            child: ExcludeSemantics(
              excluding: !expanded,
              child: IgnorePointer(
                ignoring: !expanded,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: expanded ? 1 : 0),
                  duration: reduceMotion ? Duration.zero : _kExpand,
                  builder: (context, value, child) => Offstage(
                    offstage: reduceMotion ? !expanded : value == 0,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        heightFactor: reduceMotion ? (expanded ? 1 : 0) : value,
                        child: child,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: MacosChromeData.gap),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _entries
                          .where((e) => e.parent == entry.path)
                          .map(branch)
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _SidebarItemsConfiguration(
      selectedColor: configuration.selectedColor ?? chrome.selection,
      unselectedColor: configuration.unselectedColor ?? MacosColors.transparent,
      shape: configuration.shape ?? _defaultShape,
      itemSize: configuration.itemSize,
      child: FocusTraversalGroup(
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: _onKey,
          child: MouseRegion(
            cursor: configuration.cursor ?? SystemMouseCursors.basic,
            child: ListView(
              controller: configuration.scrollController,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.all(
                10 - MacosTheme.of(context).visualDensity.horizontal,
              ),
              children: _entries
                  .where((e) => e.parent == null)
                  .map(branch)
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItemsConfiguration extends InheritedWidget {
  // ignore: use_super_parameters
  const _SidebarItemsConfiguration({
    Key? key,
    required super.child,
    this.selectedColor = MacosColors.transparent,
    this.unselectedColor = MacosColors.transparent,
    this.shape = _defaultShape,
    this.itemSize = SidebarItemSize.medium,
  }) : super(key: key);

  final Color selectedColor;
  final Color unselectedColor;
  final ShapeBorder shape;
  final SidebarItemSize itemSize;

  static _SidebarItemsConfiguration of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SidebarItemsConfiguration>()!;
  }

  @override
  bool updateShouldNotify(_SidebarItemsConfiguration oldWidget) {
    return true;
  }
}

class _SidebarHeaderItem extends StatelessWidget {
  // ignore: use_super_parameters
  const _SidebarHeaderItem({Key? key, required this.item}) : super(key: key);

  final SidebarItem item;

  bool get hasLeading => item.leading != null;
  bool get hasTrailing => item.trailing != null;

  DefaultTextStyle _buildLabelWithDefaultTextStyle(
    TextStyle labelStyle,
    BuildContext context,
  ) {
    return DefaultTextStyle(
      style: labelStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: (labelStyle.fontSize ?? 14.0) * 0.85,
        color: MacosChromeData.of(context).secondaryForeground,
        overflow: TextOverflow.ellipsis,
      ),
      child: item.label,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);

    final double spacing = 10.0 + theme.visualDensity.horizontal;
    final itemSize = _SidebarItemsConfiguration.of(context).itemSize;

    TextStyle? labelStyle;
    switch (itemSize) {
      case SidebarItemSize.small:
        labelStyle = theme.typography.subheadline;
        break;
      case SidebarItemSize.medium:
        labelStyle = theme.typography.body;
        break;
      case SidebarItemSize.large:
        labelStyle = theme.typography.title3;
        break;
    }

    return Semantics(
      label: item.semanticLabel,
      excludeSemantics: item.semanticLabel != null,
      child: Container(
        width: 134.0 + theme.visualDensity.horizontal,
        constraints: BoxConstraints(
          minHeight: itemSize.height + theme.visualDensity.vertical,
        ),
        decoration: ShapeDecoration(
          color: MacosColors.transparent,
          shape: item.shape ?? _SidebarItemsConfiguration.of(context).shape,
        ),
        padding: EdgeInsets.symmetric(
          vertical: 7 + theme.visualDensity.horizontal,
          horizontal: spacing,
        ),
        child: Row(
          children: [
            if (hasLeading)
              Padding(
                padding: EdgeInsets.only(right: spacing),
                child: MacosIconTheme.merge(
                  data: MacosIconThemeData(
                    color: theme.primaryColor,
                    size: itemSize.iconSize,
                  ),
                  child: item.leading!,
                ),
              ),
            Expanded(
              child: _buildLabelWithDefaultTextStyle(labelStyle, context),
            ),
            if (hasTrailing) ...[
              const Spacer(),
              DefaultTextStyle(
                style: labelStyle.copyWith(color: null),
                child: item.trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A macOS style navigation-list item intended for use in a [Sidebar]
class _SidebarItem extends StatefulWidget {
  /// Builds a [_SidebarItem].
  // ignore: use_super_parameters
  const _SidebarItem({
    Key? key,
    required this.item,
    required this.onClick,
    required this.selected,
    required this.focusNode,
    this.expanded,
  }) : super(key: key);

  /// The widget to lay out first.
  ///
  /// Typically an [Icon]
  final SidebarItem item;
  final FocusNode focusNode;
  final bool? expanded;

  /// Whether the item is selected or not
  final bool selected;

  /// A function to perform when the widget is clicked or tapped.
  ///
  /// Typically a [Navigator] call
  final VoidCallback? onClick;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  SidebarItem get item => widget.item;
  bool get selected => widget.selected;
  VoidCallback? get onClick => widget.onClick;
  bool _focus = false;
  bool _hover = false;
  bool _pressed = false;

  void _handleActionTap() => onClick?.call();

  DefaultTextStyle _buildLabelWithDefaultTextStyle(
    TextStyle labelStyle,
    Color selectedColor,
    BuildContext context,
  ) {
    if (item.section == true) {
      return DefaultTextStyle(
        style: labelStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: (labelStyle.fontSize ?? 14.0) * 0.85,
          color: MacosChromeData.of(context).secondaryForeground,
          overflow: TextOverflow.ellipsis,
        ),
        child: item.label,
      );
    }

    return DefaultTextStyle(
      style: labelStyle.copyWith(
        color: selected ? textLuminance(selectedColor) : null,
        overflow: TextOverflow.ellipsis,
      ),
      child: item.label,
    );
  }

  Map<Type, Action<Intent>> get _actionMap => <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (ActivateIntent intent) => _handleActionTap(),
    ),
    ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
      onInvoke: (ButtonActivateIntent intent) => _handleActionTap(),
    ),
  };
  bool get hasLeading => item.leading != null;

  bool get hasTrailing => item.trailing != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);
    final chrome = MacosChromeData.of(context);

    final selectedColor = MacosDynamicColor.resolve(
      item.selectedColor ??
          _SidebarItemsConfiguration.of(context).selectedColor,
      context,
    );
    final textBackground = _pressed ? chrome.pressed : selectedColor;
    final unselectedColor = MacosDynamicColor.resolve(
      item.unselectedColor ??
          _SidebarItemsConfiguration.of(context).unselectedColor,
      context,
    );

    final double spacing = 10.0 + theme.visualDensity.horizontal;
    final itemSize = _SidebarItemsConfiguration.of(context).itemSize;

    TextStyle? labelStyle;
    switch (itemSize) {
      case SidebarItemSize.small:
        labelStyle = theme.typography.subheadline;
        break;
      case SidebarItemSize.medium:
        labelStyle = theme.typography.body;
        break;
      case SidebarItemSize.large:
        labelStyle = theme.typography.title3;
        break;
    }

    return MergeSemantics(
      child: Semantics(
        container: true,
        label: item.semanticLabel,
        excludeSemantics: item.semanticLabel != null,
        onTap: onClick,
        onFocus: widget.focusNode.requestFocus,
        button: true,
        focusable: true,
        focused: widget.focusNode.hasFocus,
        expanded: widget.expanded,
        enabled: onClick != null,
        selected: selected,
        child: GestureDetector(
          onTap: onClick,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: FocusableActionDetector(
            focusNode: widget.focusNode,
            includeFocusSemantics: false,
            onFocusChange: (_) => setState(() {}),
            onShowFocusHighlight: (value) => setState(() => _focus = value),
            onShowHoverHighlight: (value) => setState(() => _hover = value),
            descendantsAreFocusable: false,
            enabled: onClick != null,
            //mouseCursor: SystemMouseCursors.basic,
            actions: _actionMap,
            child: Container(
              width: 134.0 + theme.visualDensity.horizontal,
              constraints: BoxConstraints(
                minHeight: itemSize.height + theme.visualDensity.vertical,
              ),
              decoration: ShapeDecoration(
                color: _pressed
                    ? chrome.pressed
                    : selected
                    ? selectedColor
                    : _hover
                    ? chrome.hover
                    : unselectedColor,
                shape: _focus
                    ? RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MacosChromeData.controlRadius,
                            ),
                            side: BorderSide(
                              color: chrome.focusRing,
                              width: chrome.focusWidth,
                            ),
                          ) +
                          (item.shape ??
                              _SidebarItemsConfiguration.of(context).shape)
                    : item.shape ??
                          _SidebarItemsConfiguration.of(context).shape,
              ),
              padding: EdgeInsets.symmetric(
                vertical: 7 + theme.visualDensity.horizontal,
                horizontal: spacing,
              ),
              child: Row(
                children: [
                  if (widget.expanded != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: MacosChromeData.gap / 2,
                      ),
                      child: Icon(
                        widget.expanded!
                            ? CupertinoIcons.chevron_down
                            : CupertinoIcons.chevron_right,
                        size: itemSize.iconSize,
                        color: chrome.secondaryForeground,
                      ),
                    ),
                  if (hasLeading)
                    Padding(
                      padding: EdgeInsets.only(right: spacing),
                      child: MacosIconTheme.merge(
                        data: MacosIconThemeData(
                          color: selected
                              ? textLuminance(textBackground)
                              : theme.primaryColor,
                          size: itemSize.iconSize,
                        ),
                        child: item.leading!,
                      ),
                    ),
                  Expanded(
                    child: _buildLabelWithDefaultTextStyle(
                      labelStyle,
                      textBackground,
                      context,
                    ),
                  ),
                  if (hasTrailing) ...[
                    DefaultTextStyle(
                      style: labelStyle.copyWith(
                        color: selected ? textLuminance(textBackground) : null,
                      ),
                      child: item.trailing!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
