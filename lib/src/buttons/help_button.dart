import 'package:flutter/foundation.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

import 'button_interaction.dart';

/// A help button appears within a view and opens app-specific help documentation when clicked.
/// For help documentation creation guidance, see Help. All help buttons are circular,
/// consistently sized buttons that contain a question mark icon. Whenever possible,
/// open a help topic related to the current context. For example,
/// the Rules pane of Mail preferences includes a help button.
/// When clicked, it opens directly to a Rules preferences help topic.
class HelpButton extends StatefulWidget {
  ///pressedOpacity, if non-null, must be in the range if 0.0 to 1.0
  const HelpButton({
    super.key,
    this.color,
    this.disabledColor,
    this.onPressed,
    this.pressedOpacity = 0.4,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.mouseCursor = SystemMouseCursors.basic,
  }) : assert(
         pressedOpacity == null ||
             (pressedOpacity >= 0.0 && pressedOpacity <= 1.0),
       );

  /// The color of the button's background.
  final Color? color;

  /// The color of the button's background when the button is disabled.
  ///
  /// Defaults to [CupertinoColors.quaternarySystemFill] when [color] is
  /// specified.
  final Color? disabledColor;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  /// The opacity that the button will fade to when it is pressed.
  /// The button will have an opacity of 1.0 when it is not pressed.
  ///
  /// This defaults to 0.4. If null, opacity will not change on pressed if using
  /// your own custom effects is desired.
  final double? pressedOpacity;

  /// The alignment of the button's [child].
  ///
  /// Typically buttons are sized to be just big enough to contain the child and its
  /// [padding]. If the button's size is constrained to a fixed size, for example by
  /// enclosing it with a [SizedBox], this property defines how the child is aligned
  /// within the available space.
  ///
  /// Always defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  /// The mouse cursor to use when hovering over this widget.
  final MouseCursor? mouseCursor;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('disabledColor', disabledColor));
    properties.add(DoubleProperty('pressedOpacity', pressedOpacity));
    properties.add(DiagnosticsProperty('alignment', alignment));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }

  @override
  HelpButtonState createState() => HelpButtonState();
}

class HelpButtonState extends State<HelpButton> {
  static const Duration kFadeOutDuration = Duration(milliseconds: 10);
  static const Duration kFadeInDuration = Duration(milliseconds: 100);

  @visibleForTesting
  bool buttonHeldDown = false;

  @override
  Widget build(BuildContext context) {
    final theme = HelpButtonTheme.of(context);
    final chrome = MacosChromeData.of(context);
    final background = MacosDynamicColor.resolve(
      widget.enabled
          ? widget.color ?? theme.color!
          : widget.disabledColor ?? theme.disabledColor!,
      context,
    );
    return ButtonInteraction(
      onPressed: widget.onPressed,
      label: widget.semanticLabel ?? 'Help',
      cursor: widget.mouseCursor,
      onHeldChanged: (value) => buttonHeldDown = value,
      builder: (context, states) => ButtonFocusRing(
        states: states,
        shape: BoxShape.circle,
        child: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 20, height: 20),
          child: ControlOpacity(
            opacity:
                states.contains(WidgetState.pressed) && !chrome.highContrast
                ? widget.pressedOpacity ?? 1
                : 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: background,
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: states.contains(WidgetState.pressed)
                    ? chrome.controlPressedOverlay
                    : states.contains(WidgetState.hovered)
                    ? chrome.controlHoverOverlay
                    : null,
              ),
              child: Align(
                alignment: widget.alignment,
                child: Icon(
                  CupertinoIcons.question,
                  size: 13,
                  color: widget.enabled
                      ? buttonForeground(background, chrome.theme.canvasColor)
                      : chrome.disabledForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
