import 'dart:math' as math;

import 'package:macos_ui/src/buttons/button_interaction.dart';
import 'package:macos_ui/src/utils/transient_anchor.dart';
import 'package:macos_ui/src/utils/command_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

enum PulldownButtonState { enabled, hovered, pressed }

const double _kMenuItemHeight = 20.0;
const double _kMenuDividerHeight = 10.0;
const EdgeInsets _kMenuItemPadding = EdgeInsets.symmetric(horizontal: 6.0);
const BorderRadius _kBorderRadius = BorderRadius.all(Radius.circular(5.0));
const double _kMenuLeftOffset = 8.0;

enum PulldownMenuAlignment { left, right }

// The widget that is the button wrapping the menu items.
class _MacosPulldownMenuItemButton extends StatefulWidget {
  // ignore: use_super_parameters
  const _MacosPulldownMenuItemButton({
    Key? key,
    this.padding,
    required this.route,
    required this.buttonRect,
    required this.constraints,
    required this.itemIndex,
  }) : super(key: key);

  final _MacosPulldownRoute route;
  final EdgeInsets? padding;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final int itemIndex;

  @override
  _MacosPulldownMenuItemButtonState createState() =>
      _MacosPulldownMenuItemButtonState();
}

class _MacosPulldownMenuItemButtonState
    extends State<_MacosPulldownMenuItemButton> {
  void _activate() {
    final entry = widget.route.items[widget.itemIndex];
    if (entry is! MacosPulldownMenuItem ||
        !entry.enabled ||
        !widget.route.isCurrent) {
      return;
    }
    widget.route.navigator?.pop();
    entry.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.route.items[widget.itemIndex];
    if (entry is! MacosPulldownMenuItem) return entry;
    return ButtonInteraction(
      onPressed: entry.enabled ? _activate : null,
      onHeldChanged: (_) {},
      builder: (context, states) {
        final chrome = MacosChromeData.of(context);
        final highlighted =
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.hovered);
        final background = states.contains(WidgetState.pressed)
            ? chrome.pressed
            : highlighted
            ? (chrome.highContrast
                  ? chrome.selection
                  : MacosPulldownButtonTheme.of(context).highlightColor ??
                        chrome.selection)
            : Colors.transparent;
        return ButtonFocusRing(
          states: states,
          radius: _kBorderRadius,
          child: Container(
            padding: widget.padding,
            constraints: BoxConstraints(
              minHeight: widget.route.itemHeight ?? _kMenuItemHeight,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: _kBorderRadius,
            ),
            child: DefaultTextStyle(
              style: widget.route.style.copyWith(
                color: !entry.enabled
                    ? chrome.disabledForeground
                    : highlighted
                    ? buttonForeground(background, chrome.toolbar)
                    : widget.route.style.color ?? chrome.foreground,
              ),
              child: entry,
            ),
          ),
        );
      },
    );
  }
}

class _MacosPulldownMenu extends StatefulWidget {
  // ignore: use_super_parameters
  const _MacosPulldownMenu({
    Key? key,
    this.padding,
    required this.route,
    required this.buttonRect,
    required this.constraints,
  }) : super(key: key);

  final _MacosPulldownRoute route;
  final EdgeInsets? padding;
  final Rect buttonRect;
  final BoxConstraints constraints;

  @override
  _MacosPulldownMenuState createState() => _MacosPulldownMenuState();
}

class _MacosPulldownMenuState extends State<_MacosPulldownMenu> {
  @override
  Widget build(BuildContext context) {
    // Reuse the delivered command-menu traversal and bounded scrolling.
    return CommandMenu(
      color: MacosPulldownButtonTheme.of(
        context,
      ).pulldownColor?.withValues(alpha: 1),
      children: [
        for (var i = 0; i < widget.route.items.length; i++)
          _MacosPulldownMenuItemButton(
            route: widget.route,
            padding: widget.padding,
            buttonRect: widget.buttonRect,
            constraints: widget.constraints,
            itemIndex: i,
          ),
      ],
    );
  }
}

class _MacosPulldownMenuRouteLayout extends SingleChildLayoutDelegate {
  _MacosPulldownMenuRouteLayout({
    required this.buttonRect,
    required this.route,
    required this.textDirection,
    required this.menuAlignment,
  });

  final Rect buttonRect;
  final _MacosPulldownRoute route;
  final TextDirection? textDirection;
  final PulldownMenuAlignment menuAlignment;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: kMinInteractiveDimension,
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    assert(textDirection != null);
    double left;
    switch (menuAlignment) {
      case PulldownMenuAlignment.left:
        switch (textDirection!) {
          case TextDirection.rtl:
            left = buttonRect.right.clamp(0.0, size.width) - childSize.width;
            break;
          case TextDirection.ltr:
            left = buttonRect.left + _kMenuLeftOffset;
            break;
        }
        break;
      case PulldownMenuAlignment.right:
        switch (textDirection!) {
          case TextDirection.rtl:
            left = buttonRect.left + _kMenuLeftOffset;
            break;
          case TextDirection.ltr:
            left = buttonRect.left - childSize.width + buttonRect.width;
            break;
        }
        break;
    }
    final below = buttonRect.bottom + 1;
    final top = below + childSize.height <= size.height
        ? below
        : buttonRect.top - childSize.height - 5;
    return Offset(
      left.clamp(0, math.max(0, size.width - childSize.width)),
      top.clamp(0, math.max(0, size.height - childSize.height)),
    );
  }

  @override
  bool shouldRelayout(_MacosPulldownMenuRouteLayout oldDelegate) {
    return buttonRect != oldDelegate.buttonRect ||
        textDirection != oldDelegate.textDirection;
  }
}

class _MacosPulldownRoute extends PopupRoute {
  _MacosPulldownRoute({
    required this.items,
    required this.padding,
    required this.buttonRect,
    required this.capturedThemes,
    required this.style,
    this.barrierLabel,
    this.itemHeight,
    required this.menuAlignment,
  });

  final List<MacosPulldownMenuEntry> items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final CapturedThemes capturedThemes;
  final TextStyle style;
  final double? itemHeight;
  final PulldownMenuAlignment menuAlignment;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _MacosPulldownRoutePage(
          route: this,
          constraints: constraints,
          items: items,
          padding: padding,
          buttonRect: buttonRect,
          capturedThemes: capturedThemes,
          style: style,
          menuAlignment: menuAlignment,
        );
      },
    );
  }

  void _dismiss() {
    if (isActive) {
      navigator?.removeRoute(this);
    }
  }
}

class _MacosPulldownRoutePage extends StatelessWidget {
  // ignore: use_super_parameters
  const _MacosPulldownRoutePage({
    Key? key,
    required this.route,
    required this.constraints,
    this.items,
    required this.padding,
    required this.buttonRect,
    required this.capturedThemes,
    this.style,
    required this.menuAlignment,
  }) : super(key: key);

  final _MacosPulldownRoute route;
  final BoxConstraints constraints;
  final List<MacosPulldownMenuEntry>? items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final CapturedThemes capturedThemes;
  final TextStyle? style;
  final PulldownMenuAlignment menuAlignment;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final TextDirection? textDirection = Directionality.maybeOf(context);
    final Widget menu = _MacosPulldownMenu(
      route: route,
      padding: padding.resolve(textDirection),
      buttonRect: buttonRect,
      constraints: constraints,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _MacosPulldownMenuRouteLayout(
              buttonRect: buttonRect,
              route: route,
              textDirection: textDirection,
              menuAlignment: menuAlignment,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}

/// An entry in a menu created by a [MacosPulldownButton]. It can be either a
/// [MacosPulldownMenuItem] or a [MacosPulldownMenuDivider].
abstract class MacosPulldownMenuEntry extends Widget {
  const MacosPulldownMenuEntry({super.key});

  double get itemHeight;
}

/// A divider (horizontal line) in a menu created by a [MacosPulldownButton].
class MacosPulldownMenuDivider extends StatelessWidget
    implements MacosPulldownMenuEntry {
  /// Creates a divider for a macOS-style pulldown menu.
  const MacosPulldownMenuDivider({super.key});

  @override
  double get itemHeight => _kMenuDividerHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kMenuDividerHeight,
      padding: _kMenuItemPadding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          color: MacosTheme.of(context).brightness.resolve(
            MacosColors.disabledControlTextColor,
            MacosColors.disabledControlTextColor.darkColor,
          ),
          height: 0.5,
        ),
      ),
    );
  }
}

/// An item in a menu created by a [MacosPulldownButton], typically a [Text]
/// widget.
class MacosPulldownMenuItem extends StatelessWidget
    implements MacosPulldownMenuEntry {
  /// Creates an item for a macOS-style pulldown menu.
  const MacosPulldownMenuItem({
    super.key,
    required this.title,
    this.onTap,
    this.enabled = true,
    this.alignment = AlignmentDirectional.centerStart,
    this.label,
  });

  @override
  double get itemHeight => _kMenuItemHeight;

  /// The widget to use as a menu item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Called when the pulldown menu item is tapped.
  final VoidCallback? onTap;

  /// Whether or not a user can select this menu item.
  ///
  /// Defaults to `true`.
  final bool enabled;

  /// Defines how the item is positioned within the container.
  ///
  /// This property must not be null. It defaults to [AlignmentDirectional.centerStart].
  final AlignmentGeometry alignment;

  /// An optional label to describe the action of this menu item.
  ///
  /// It must be set when the pulldown menu is used in the toolbar.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: _kMenuItemHeight),
      alignment: alignment,
      child: title,
    );
  }
}

/// A macOS-style pull-down button.
///
/// A pull-down button (often referred to as a pull-down menu) is a type of
/// pop-up button that, when clicked, displays a menu containing a list of
/// choices. The menu appears below the button.
///
/// Use a pull-down button to present a list of commands.
///
/// A pull-down button can either show a [title] or an [icon] to describe the
/// contents of the button's menu. If you use an icon, make sure it clearly
/// communicates the button’s purpose.
///
/// See also:
///
///  * [MacosPulldownMenuItem], the class used to represent the menu options.
///  * [MacosPulldownMenuDivider], the class used to represent a horizontal
///    divider for the menu.
class MacosPulldownButton extends StatefulWidget {
  /// Creates a macOS-style pull-down button.
  ///
  /// If [items] is null, the button will be disabled, the down caret
  /// icon will be greyed out.
  ///
  /// A [title] or an [icon] must be provided, to be displayed as the
  /// pull-down button's title, but not both at the same time.
  ///
  /// If the button is disabled and [icon] is null, [disabledTitle] will be
  /// displayed if it is non-null. If [disabledTitle] is null, then [title]
  /// will be displayed if it is non-null.
  ///
  /// The [autofocus] argument must not be null.
  const MacosPulldownButton({
    super.key,
    required this.items,
    this.title,
    this.disabledTitle,
    this.icon,
    this.onTap,
    this.style,
    this.itemHeight = _kMenuItemHeight,
    this.focusNode,
    this.autofocus = false,
    this.alignment = AlignmentDirectional.centerStart,
    this.menuAlignment = PulldownMenuAlignment.left,
  }) : assert(itemHeight == null || itemHeight >= _kMenuItemHeight),
       assert(
         (title != null || icon != null) && !(title != null && icon != null),
         "There should be either a title or an icon argument provided, and not both at at the same time.",
       );

  /// The list of menu entries for the pull-down menu.
  ///
  /// Can be either [MacosPulldownMenuItem]s or [MacosPulldownMenuDivider]s.
  ///
  /// If the list of items is null, then the pull-down button will be disabled,
  /// i.e. it will be displayed in grey and not respond to input.
  final List<MacosPulldownMenuEntry>? items;

  /// The text to display as title for the pull-down button.
  ///
  /// If this is provided, [icon] should be null.
  ///
  /// If the pull-down is disabled and [disabledTitle] is null, then this
  /// is displayed instead.
  final String? title;

  /// The text that is displayed when the pull-down is disabled.
  ///
  /// If the pulldown is disabled ([items] is null), this is displayed as a
  /// title for the pull-down button.
  final String? disabledTitle;

  /// An icon to use as title for the pull-down button. Makes the pull-down
  /// button behave and render as an icon-button with a caret.
  ///
  /// If this is provided, [title] should be null.
  ///
  /// It is recommended to use icons from the CupertinoIcons library for this.
  final IconData? icon;

  /// Called when the pull-down button is tapped.
  ///
  /// The callback will not be invoked if the pull-down button is disabled.
  final VoidCallback? onTap;

  /// The text style to use for text in the pull-down button and the pull-down
  /// menu that appears when you tap the button.
  ///
  /// Defaults to MacosTheme.of(context).typography.body.
  final TextStyle? style;

  /// Menu items grow with their intrinsic content and text scaling. If null,
  /// only the intrinsic height and entry minimum are used.
  ///
  /// The default value is [_kMenuItemHeight], a minimum rather than a fixed height.
  final double? itemHeight;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// Defines how the title is positioned within the button.
  ///
  /// This property must not be null. It defaults to [AlignmentDirectional.centerStart].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// Defines the pulldown menu's alignment relevant to the button.
  ///
  /// Defaults to [PulldownMenuAlignment.left].
  final PulldownMenuAlignment menuAlignment;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('itemHeight', itemHeight));
    properties.add(
      FlagProperty('hasAutofocus', value: autofocus, ifFalse: 'noAutofocus'),
    );
    properties.add(DiagnosticsProperty('alignment', alignment));
    properties.add(DiagnosticsProperty('menuAlignment', menuAlignment));
  }

  @override
  State<MacosPulldownButton> createState() => _MacosPulldownButtonState();
}

class _MacosPulldownButtonState extends State<MacosPulldownButton>
    with WidgetsBindingObserver {
  _MacosPulldownRoute? _pulldownRoute;
  final _ownedFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _ownedFocus;
  late final _anchor = TransientAnchorWatch(
    () => context,
    _removeMacosPulldownRoute,
  );
  bool get _enabled => widget.items?.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.autofocus) _focus.requestFocus();
  }

  @override
  void didChangeMetrics() => _removeMacosPulldownRoute();

  void _invalidateLater() {
    final route = _pulldownRoute;
    _pulldownRoute = null;
    _anchor.cancel();
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => route._dismiss());
    }
  }

  Object? _environment;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final environment = (
      MacosTheme.of(context),
      MediaQuery.maybeOf(context),
      TickerMode.valuesOf(context).enabled,
      Focus.maybeOf(context)?.descendantsAreFocusable,
      MacosPulldownButtonTheme.of(context),
    );
    if (_environment != null && _environment != environment) {
      final route = _pulldownRoute;
      _pulldownRoute = null;
      _anchor.cancel();
      if (route != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => route._dismiss());
      }
    }
    _environment = environment;
  }

  @override
  void didUpdateWidget(MacosPulldownButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled ||
        widget.items != oldWidget.items ||
        widget.style != oldWidget.style) {
      _invalidateLater();
    }
  }

  void _removeMacosPulldownRoute() {
    final route = _pulldownRoute;
    _pulldownRoute = null;
    _anchor.cancel();
    route?._dismiss();
    if (mounted) setState(() {});
  }

  void _handleTap() {
    if (!_enabled || _pulldownRoute != null) return;
    final navigator = Navigator.of(context);
    final sourceRoute = ModalRoute.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final route = _MacosPulldownRoute(
      items: List.of(widget.items!),
      buttonRect:
          box.localToGlobal(
            Offset.zero,
            ancestor: navigator.context.findRenderObject(),
          ) &
          box.size,
      padding: _kMenuItemPadding,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      style: widget.style ?? MacosTheme.of(context).typography.body,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      itemHeight: widget.itemHeight,
      menuAlignment: widget.menuAlignment,
    );
    final focus = _focus;
    setState(() => _pulldownRoute = route);
    navigator.push(route).then((_) {
      if (!mounted || !identical(_pulldownRoute, route)) return;
      _anchor.cancel();
      setState(() => _pulldownRoute = null);
      if (sourceRoute?.isCurrent == true &&
          focus.context != null &&
          focus.canRequestFocus) {
        focus.requestFocus();
      }
    });
    _anchor.watch();
    widget.onTap?.call();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _anchor.cancel();
    _pulldownRoute?._dismiss();
    _ownedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ButtonInteraction(
    focusNode: _focus,
    onPressed: _enabled ? _handleTap : null,
    onHeldChanged: (_) {},
    expanded: _pulldownRoute != null,
    onKeyEvent: (_, event) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
          event is KeyDownEvent) {
        _handleTap();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    builder: (context, states) {
      final styles = _getButtonStyles(
        states.contains(WidgetState.pressed) || _pulldownRoute != null
            ? PulldownButtonState.pressed
            : states.contains(WidgetState.hovered)
            ? PulldownButtonState.hovered
            : PulldownButtonState.enabled,
        _enabled,
        widget.icon != null,
        context,
      );
      return ButtonFocusRing(
        states: states,
        radius: _kBorderRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: styles.bgColor,
            border: Border.all(color: styles.borderColor),
            borderRadius: _kBorderRadius,
          ),
          child: DefaultTextStyle(
            style: (widget.style ?? MacosTheme.of(context).typography.body)
                .copyWith(
                  color: _enabled
                      ? widget.style?.color ?? styles.textColor
                      : styles.textColor,
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Align(
                    widthFactor: 1,
                    alignment: widget.alignment,
                    child: widget.icon != null
                        ? MacosIcon(widget.icon!, color: styles.textColor)
                        : Text(
                            _enabled
                                ? widget.title!
                                : widget.disabledTitle ?? widget.title!,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CustomPaint(
                    painter: _DownCaretPainter(
                      color: styles.caretColor,
                      backgroundColor: styles.caretBgColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// Pull-down buttons styling can be differentiated according to:
//
// pullDownButtonState: a button can be either enabled, hovered, or pressed.
// enabled: if a button is disabled (greyed out) or not.
// hasIcon: if it has a string or an icon as its title.
//
// We use this utility function to get the appropriate styling, according to the
// macOS Design Guidelines and the current MacosPulldownButtonTheme.
_ButtonStyles _getButtonStyles(
  PulldownButtonState pullDownButtonState,
  bool enabled,
  bool hasIcon,
  BuildContext context,
) {
  final chrome = MacosChromeData.of(context);
  final theme = MacosPulldownButtonTheme.of(context);
  final base = theme.backgroundColor ?? chrome.toolbar;
  final background = switch (pullDownButtonState) {
    PulldownButtonState.pressed => Color.alphaBlend(
      chrome.controlPressedOverlay,
      base,
    ),
    PulldownButtonState.hovered => Color.alphaBlend(
      chrome.controlHoverOverlay,
      base,
    ),
    PulldownButtonState.enabled => base,
  };
  final highlight = chrome.highContrast
      ? chrome.selection
      : theme.highlightColor ?? chrome.selection;
  final foreground = !enabled
      ? chrome.disabledForeground
      : hasIcon
      ? theme.iconColor ?? chrome.foreground
      : chrome.foreground;
  return _ButtonStyles(
    textColor: foreground,
    bgColor: background,
    borderColor: chrome.separator,
    caretColor: enabled && !hasIcon
        ? buttonForeground(highlight, background)
        : foreground,
    caretBgColor: enabled && !hasIcon ? highlight : MacosColors.transparent,
  );
}

class _ButtonStyles {
  _ButtonStyles({
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
    required this.caretColor,
    required this.caretBgColor,
  });

  Color textColor;
  Color bgColor;
  Color borderColor;
  Color caretColor;
  Color caretBgColor;
}

class _DownCaretPainter extends CustomPainter {
  const _DownCaretPainter({required this.color, required this.backgroundColor});

  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 4.0;
    final hPadding = size.height / 3;

    /// Draw background
    canvas.drawRRect(
      const BorderRadius.all(
        Radius.circular(radius),
      ).toRRect(Offset.zero & size),
      Paint()..color = backgroundColor,
    );

    /// Draw carets
    final p1 = Offset(hPadding, size.height / 2 - 1.0);
    final p2 = Offset(size.width / 2, size.height / 2 + 2.0);
    final p3 = Offset(size.width / 2 + 1.0, size.height / 2 + 1.0);
    final p4 = Offset(size.width - hPadding, size.height / 2 - 1.0);
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.75;
    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p3, p4, paint);
  }

  @override
  bool shouldRepaint(_DownCaretPainter oldDelegate) =>
      color != oldDelegate.color ||
      backgroundColor != oldDelegate.backgroundColor;

  @override
  bool shouldRebuildSemantics(_DownCaretPainter oldDelegate) => false;
}
