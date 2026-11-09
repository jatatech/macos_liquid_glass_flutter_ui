import 'package:flutter/rendering.dart';
import 'package:macos_liquid_glass_ui/src/buttons/button_interaction.dart';
import 'package:macos_liquid_glass_ui/src/buttons/value_control.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

/// A checkbox is a type of button that lets the user choose between
/// two opposite states, actions, or values. A selected checkbox is
/// considered on when it contains a checkmark and off when it's empty.
/// A checkbox is almost always followed by a title unless it appears in
/// a checklist.
class MacosCheckbox extends StatelessWidget {
  /// Creates a checkbox.
  ///
  /// [size] must be non-negative
  const MacosCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 14.0,
    this.activeColor,
    this.disabledColor = CupertinoColors.quaternaryLabel,
    this.offBorderColor = CupertinoColors.tertiaryLabel,
    this.semanticLabel,
  }) : assert(size >= 0);

  /// Whether the checkbox is checked or not. If null, it'll be considered
  /// mixed.
  final bool? value;

  /// Called whenever the state of the checkbox changes. If null, the checkbox
  /// will be considered disabled
  final ValueChanged<bool>? onChanged;

  /// The size of the checkbox. It must be non-negative.
  final double size;

  /// The background color when the checkbox is on or mixed. If null,
  /// [MacosThemeData.accentColor] is used
  final Color? activeColor;

  /// The background color when the checkbox is disabled. [CupertinoColors.quaternaryLabel]
  /// is used by default
  final Color disabledColor;

  /// The color of the border when the checkbox is off. [CupertinoColors.tertiaryLabel]
  /// is used by default
  final Color offBorderColor;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  /// Whether the checkbox is mixed or not.
  bool get isMixed => value == null;

  /// Whether the checkbox is disabled or not.
  bool get isDisabled => onChanged == null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty(
        'state',
        isMixed
            ? 'mixed'
            : value!
            ? 'checked'
            : 'unchecked',
      ),
    );
    properties.add(
      FlagProperty('disabled', value: isDisabled, ifFalse: 'enabled'),
    );
    properties.add(DoubleProperty('size', size));
    properties.add(ColorProperty('activeColor', activeColor));
    properties.add(ColorProperty('disabledColor', disabledColor));
    properties.add(ColorProperty('offBorderColor', offBorderColor));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final chrome = MacosChromeData.of(context);
    final fill = MacosDynamicColor.resolve(
      isDisabled ? disabledColor : activeColor ?? chrome.selection,
      context,
    );
    final border = MacosDynamicColor.resolve(offBorderColor, context);
    return ButtonInteraction(
      onPressed: isDisabled ? null : () => onChanged!(value != true),
      onHeldChanged: (_) {},
      label: semanticLabel,
      isButton: false,
      checked: value == true,
      mixed: isMixed,
      builder: (context, states) => ValueControlSurface(
        states: states,
        radius: const BorderRadius.all(Radius.circular(3.5)),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: value == false ? chrome.canvas : fill,
            borderRadius: const BorderRadius.all(Radius.circular(3.5)),
            border: Border.all(
              color: chrome.highContrast ? chrome.foreground : border,
            ),
          ),
          child: value == false
              ? null
              : Icon(
                  isMixed ? CupertinoIcons.minus : CupertinoIcons.checkmark,
                  size: (size - 3).clamp(0, size),
                  color: buttonForeground(fill, chrome.canvas),
                ),
        ),
      ),
    );
  }
}
