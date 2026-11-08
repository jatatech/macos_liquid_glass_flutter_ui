import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

/// A menu-item that belongs in the toolbar overflowed actions menu.
class ToolbarOverflowMenuItem extends StatefulWidget {
  /// Builds a menu-item that belongs in the toolbar overflowed actions menu.
  const ToolbarOverflowMenuItem({
    super.key,
    this.onPressed,
    required this.label,
    this.subMenuItems,
    this.isSelected,
  });

  /// The callback that is called when the menu item is tapped or otherwise
  /// activated.
  ///
  /// If this is set to null, the menu item will be disabled (greyed out).
  final VoidCallback? onPressed;

  /// The label to show as the menu item's content.
  ///
  /// Must be non-null.
  final String label;

  /// Optional submenu entries. Open by hover, click, Enter/Space or Right;
  /// dismiss with Left, Escape or an outside click. Placement stays on screen.
  ///
  /// Used when a toolbar pulldown button is included in the toolbar overflowed actions menu.
  final List<ToolbarOverflowMenuItem>? subMenuItems;

  /// If this menu item is currently selected, i.e. its submenu is open.
  ///
  /// Used when a toolbar pulldown button is included in the toolbar overflowed actions menu.
  final bool? isSelected;

  @override
  State<ToolbarOverflowMenuItem> createState() =>
      _ToolbarOverflowMenuItemState();
}

class _ToolbarOverflowMenuItemState extends State<ToolbarOverflowMenuItem> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  final _popupKey = GlobalKey<ToolbarPopupState>();

  bool get _hasSubMenu => widget.subMenuItems?.isNotEmpty ?? false;
  bool get _enabled => widget.onPressed != null || _hasSubMenu;

  void _activate() {
    if (!_enabled) return;
    if (_hasSubMenu) {
      _popupKey.currentState?.openPopup();
    } else {
      Navigator.pop(context);
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    final highlighted =
        _enabled && (_hovered || _focused || widget.isSelected == true);
    final background = _pressed
        ? chrome.pressed
        : highlighted
        ? chrome.selection
        : chrome.toolbar;
    final foreground = !_enabled
        ? chrome.disabledForeground
        : highlighted
        ? textLuminance(background)
        : chrome.foreground;
    Widget row = Semantics(
      button: true,
      enabled: _enabled,
      child: FocusableActionDetector(
        enabled: _enabled,
        onFocusChange: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) {
          setState(() => _hovered = value);
          if (value && _hasSubMenu) _activate();
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => _activate(),
          ),
        },
        child: Focus(
          canRequestFocus: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _enabled ? _activate : null,
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: Container(
              constraints: const BoxConstraints(minHeight: 28),
              padding: const EdgeInsets.symmetric(
                horizontal: MacosChromeData.gap / 2,
                vertical: MacosChromeData.gap / 3,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(
                  MacosChromeData.controlRadius,
                ),
                border: Border.all(
                  color: _focused ? chrome.focusRing : MacosColors.transparent,
                  width: chrome.focusWidth,
                ),
              ),
              child: DefaultTextStyle(
                style: MacosTheme.of(
                  context,
                ).typography.body.copyWith(color: foreground),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.label)),
                    if (_hasSubMenu)
                      MacosIcon(
                        Directionality.of(context) == TextDirection.ltr
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_left,
                        size: 12,
                        color: foreground,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (_hasSubMenu) {
      row = Shortcuts(
        shortcuts: {
          SingleActivator(
            Directionality.of(context) == TextDirection.ltr
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft,
          ): const ActivateIntent(),
        },
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => _activate(),
            ),
          },
          child: row,
        ),
      );
      row = ToolbarPopup(
        key: _popupKey,
        position: ToolbarPopupPosition.side,
        placement: ToolbarPopupPlacement.start,
        content: (_) => ToolbarOverflowMenu(children: widget.subMenuItems!),
        child: row,
      );
    }
    return row;
  }
}
