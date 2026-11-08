import 'package:flutter/foundation.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

import 'button_interaction.dart';

/// A macOS style disclosure button.
class MacosDisclosureButton extends StatefulWidget {
  /// Creates a `DisclosureButton` with the appropriate icon/background colors based
  /// on light/dark themes.
  const MacosDisclosureButton({
    super.key,
    this.fillColor,
    this.semanticLabel,
    this.isPressed = false,
    this.mouseCursor = SystemMouseCursors.basic,
    this.onPressed,
  });

  /// The callback that is called when the button is tapped.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  /// The color to fill the space around the icon with.
  final Color? fillColor;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  /// The mouse cursor to use when hovering over this widget.
  final MouseCursor? mouseCursor;

  /// Whether the button is in the active state (chevron pointing up)
  /// or inactive state (chevron pointing down).
  final bool isPressed;

  /// Whether the button is enabled or disabled. Buttons are disabled by default.
  ///
  /// To enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('fillColor', fillColor));
    properties.add(ColorProperty('hoverColor', fillColor));
    properties.add(StringProperty('semanticLabel', semanticLabel));
    properties.add(
      FlagProperty('enabled', value: enabled, ifFalse: 'disabled'),
    );
  }

  @override
  MacosDisclosureButtonState createState() => MacosDisclosureButtonState();
}

class MacosDisclosureButtonState extends State<MacosDisclosureButton> {
  static const Duration kFadeOutDuration = Duration(milliseconds: 10);
  static const Duration kFadeInDuration = Duration(milliseconds: 100);

  @visibleForTesting
  bool buttonHeldDown = false;

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    final radius = BorderRadius.circular(MacosChromeData.controlRadius);
    return ButtonInteraction(
      onPressed: widget.onPressed,
      label: widget.semanticLabel ?? 'Show details',
      expanded: widget.isPressed,
      cursor: widget.mouseCursor,
      onHeldChanged: (value) => buttonHeldDown = value,
      builder: (context, states) => ButtonFocusRing(
        states: states,
        radius: radius,
        child: Container(
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          decoration: BoxDecoration(
            color: widget.fillColor == null
                ? chrome.backgroundFor(
                    states.difference({WidgetState.selected}),
                  )
                : MacosDynamicColor.resolve(widget.fillColor!, context),
            borderRadius: radius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            color:
                widget.fillColor != null && states.contains(WidgetState.pressed)
                ? chrome.controlPressedOverlay
                : widget.fillColor != null &&
                      states.contains(WidgetState.hovered)
                ? chrome.controlHoverOverlay
                : null,
          ),
          child: RotatedBox(
            quarterTurns: widget.isPressed ? 1 : 3,
            child: Icon(
              CupertinoIcons.back,
              size: 14,
              color: widget.enabled
                  ? chrome.foreground
                  : chrome.disabledForeground,
            ),
          ),
        ),
      ),
    );
  }
}
