import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

// Internal shared input contract; intentionally not exported to consumers.
class ButtonInteraction extends StatefulWidget {
  const ButtonInteraction({
    super.key,
    required this.onPressed,
    required this.builder,
    required this.onHeldChanged,
    this.onLongPress,
    this.label,
    this.expanded,
    this.cursor,
    this.focusNode,
    this.onKeyEvent,
    this.checked,
    this.mixed,
    this.selected,
    this.inMutuallyExclusiveGroup,
    this.isButton = true,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget Function(BuildContext, Set<WidgetState>) builder;
  final ValueChanged<bool> onHeldChanged;
  final String? label;
  final bool? expanded;
  final MouseCursor? cursor;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool? checked;
  final bool? mixed;
  final bool? selected;
  final bool? inMutuallyExclusiveGroup;
  final bool isButton;

  @override
  State<ButtonInteraction> createState() => _ButtonInteractionState();
}

class _ButtonInteractionState extends State<ButtonInteraction> {
  final _ownedFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _ownedFocus;
  bool _hovered = false;
  bool _pointerHeld = false;
  LogicalKeyboardKey? _keyHeld;
  bool get _enabled => widget.onPressed != null || widget.onLongPress != null;
  bool get _held => _pointerHeld || _keyHeld != null;

  void _change(VoidCallback change) {
    final wasHeld = _held;
    setState(change);
    if (_held != wasHeld) widget.onHeldChanged(_held);
  }

  @override
  void didUpdateWidget(ButtonInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _pointerHeld = false;
      _keyHeld = null;
      widget.onHeldChanged(false);
      if (_focus.hasFocus) _focus.unfocus();
    }
  }

  @override
  void dispose() {
    _ownedFocus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onKeyEvent?.call(node, event) == KeyEventResult.handled) {
      return KeyEventResult.handled;
    }
    final key = event.logicalKey;
    if (!_enabled ||
        (key != LogicalKeyboardKey.enter &&
            key != LogicalKeyboardKey.numpadEnter &&
            key != LogicalKeyboardKey.space)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && _keyHeld == null) {
      _change(() => _keyHeld = key);
    } else if (event is KeyUpEvent && _keyHeld == key) {
      _change(() => _keyHeld = null);
      (widget.onPressed ?? widget.onLongPress)?.call();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    canRequestFocus: _enabled,
    includeSemantics: false,
    onKeyEvent: _onKey,
    onFocusChange: (focused) => _change(() {
      if (!focused) _keyHeld = null;
    }),
    child: MouseRegion(
      cursor: widget.cursor ?? SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: !_enabled
            ? null
            : (_) {
                _focus.requestFocus();
                _change(() => _pointerHeld = true);
              },
        onTapUp: !_enabled ? null : (_) => _change(() => _pointerHeld = false),
        onTapCancel: !_enabled
            ? null
            : () {
                if (_pointerHeld) _change(() => _pointerHeld = false);
              },
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress,
        child: Semantics(
          button: widget.isButton,
          checked: widget.checked,
          mixed: widget.mixed,
          selected: widget.selected,
          inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
          enabled: _enabled,
          focusable: _enabled,
          focused: _enabled ? _focus.hasFocus : null,
          expanded: widget.expanded,
          label: widget.label,
          excludeSemantics: widget.label != null,
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: widget.builder(context, {
            if (!_enabled) WidgetState.disabled,
            if (_enabled && _hovered) WidgetState.hovered,
            if (_enabled && _held) WidgetState.pressed,
            if (_enabled && _focus.hasFocus) WidgetState.focused,
            if (widget.expanded ?? false) WidgetState.selected,
          }),
        ),
      ),
    ),
  );
}

// Surface-independent ring stays fully opaque even when content fades.
class ButtonFocusRing extends StatelessWidget {
  const ButtonFocusRing({
    super.key,
    required this.states,
    required this.child,
    this.radius,
    this.shape = BoxShape.rectangle,
  });
  final Set<WidgetState> states;
  final Widget child;
  final BorderRadiusGeometry? radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return Container(
      foregroundDecoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? radius : null,
        border: states.contains(WidgetState.focused) || chrome.highContrast
            ? Border.all(
                color: states.contains(WidgetState.focused)
                    ? chrome.focusRing
                    : chrome.separator,
                width: states.contains(WidgetState.focused)
                    ? chrome.focusWidth
                    : 1,
              )
            : null,
      ),
      child: child,
    );
  }
}

class ControlOpacity extends StatelessWidget {
  const ControlOpacity({super.key, required this.opacity, required this.child});
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? Opacity(opacity: opacity, child: child)
      : AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 100),
          child: child,
        );
}

// Choose the greater contrast ratio after compositing translucent surfaces.
Color buttonForeground(Color background, Color canvas) =>
    Color.alphaBlend(background, canvas).computeLuminance() > 0.179
    ? CupertinoColors.black
    : CupertinoColors.white;
