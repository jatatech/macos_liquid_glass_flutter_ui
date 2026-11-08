import 'package:flutter/foundation.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

import 'button_interaction.dart';

/// A macOS-style icon button.
class MacosIconButton extends StatefulWidget {
  /// Builds a macOS-style icon button
  const MacosIconButton({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.disabledColor,
    this.hoverColor,
    this.onPressed,
    this.pressedOpacity = 0.4,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.semanticLabel,
    this.boxConstraints = const BoxConstraints(
      minHeight: 20,
      minWidth: 20,
      maxWidth: 30,
      maxHeight: 30,
    ),
    this.padding,
    this.mouseCursor = SystemMouseCursors.basic,
  }) : assert(
         pressedOpacity == null ||
             (pressedOpacity >= 0.0 && pressedOpacity <= 1.0),
       );

  /// The widget to use as the icon.
  ///
  /// Typically an [Icon] widget.
  final Widget icon;

  /// The background color of this [MacosIconButton].
  ///
  /// Defaults to [CupertinoColors.activeBlue]. Set to [Colors.transparent] for
  /// a transparent background color.
  final Color? backgroundColor;

  /// The color of the button's background when the button is disabled.
  final Color? disabledColor;

  /// The color of the button's background when the mouse hovers over it.
  ///
  /// Set to Colors.transparent to disable the hover effect.
  final Color? hoverColor;

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

  /// The shape to make the button.
  ///
  /// Defaults to `BoxShape.rectangle`.
  final BoxShape shape;

  /// The border radius for the button.
  ///
  /// This should only be set if setting [shape] to `BoxShape.rectangle`.
  ///
  /// Defaults to `BorderRadius.circular(7.0)`.
  final BorderRadius? borderRadius;

  ///The alignment of the button's icon.
  ///
  /// Typically buttons are sized to be just big enough to contain the child and its
  /// [padding]. If the button's size is constrained to a fixed size, for example by
  /// enclosing it with a [SizedBox], this property defines how the child is aligned
  /// within the available space.
  ///
  /// Always defaults to [Alignment.center].
  final AlignmentGeometry alignment;

  /// The box constraints for the button.
  ///
  /// Defaults to
  /// ```dart
  /// const BoxConstraints(
  ///   minHeight: 20,
  ///   minWidth: 20,
  ///   maxWidth: 30,
  ///   maxHeight: 30,
  /// ),
  ///```
  final BoxConstraints boxConstraints;

  /// The internal padding for the button's [icon].
  ///
  /// Defaults to `EdgeInsets.all(8)`.
  final EdgeInsetsGeometry? padding;

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
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(ColorProperty('disabledColor', disabledColor));
    properties.add(ColorProperty('hoverColor', hoverColor));
    properties.add(DoubleProperty('pressedOpacity', pressedOpacity));
    properties.add(DiagnosticsProperty('alignment', alignment));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }

  @override
  MacosIconButtonState createState() => MacosIconButtonState();
}

class MacosIconButtonState extends State<MacosIconButton> {
  static const Duration kFadeOutDuration = Duration(milliseconds: 10);
  static const Duration kFadeInDuration = Duration(milliseconds: 100);

  @visibleForTesting
  bool buttonHeldDown = false;

  @override
  Widget build(BuildContext context) {
    final theme = MacosIconButtonTheme.of(context);
    final chrome = MacosChromeData.of(context);
    final radius =
        widget.borderRadius ??
        theme.borderRadius ??
        BorderRadius.circular(MacosChromeData.controlRadius);
    return ButtonInteraction(
      onPressed: widget.onPressed,
      label: widget.semanticLabel,
      cursor: widget.mouseCursor,
      onHeldChanged: (value) => buttonHeldDown = value,
      builder: (context, states) {
        final color = !widget.enabled
            ? widget.disabledColor ?? theme.disabledColor!
            : states.contains(WidgetState.hovered)
            ? widget.hoverColor ?? theme.hoverColor!
            : widget.backgroundColor ?? theme.backgroundColor!;
        return ButtonFocusRing(
          states: states,
          shape: widget.shape,
          radius: radius,
          child: ConstrainedBox(
            constraints: widget.boxConstraints,
            child: ControlOpacity(
              opacity:
                  states.contains(WidgetState.pressed) && !chrome.highContrast
                  ? widget.pressedOpacity ?? 1
                  : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: widget.shape,
                  borderRadius: widget.shape == BoxShape.rectangle
                      ? radius
                      : null,
                  color: MacosDynamicColor.resolve(color, context),
                ),
                child: Padding(
                  padding:
                      widget.padding ??
                      theme.padding ??
                      const EdgeInsets.all(8),
                  child: Align(
                    alignment: widget.alignment,
                    widthFactor: 1,
                    heightFactor: 1,
                    child: FittedBox(fit: BoxFit.scaleDown, child: widget.icon),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
