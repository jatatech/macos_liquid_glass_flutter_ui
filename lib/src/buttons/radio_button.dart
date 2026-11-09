import 'package:flutter/rendering.dart';
import 'package:macos_liquid_glass_ui/src/buttons/value_control.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

/// A radio button is a small, circular button followed by a
/// title. Typically presented in groups of two to five, radio
/// buttons provide the user a set of related but mutually exclusive
/// choices. A radio button’s state is either on (a filled circle)
/// or off (an empty circle).
///
/// ![RadioButton example](https://developer.apple.com/design/human-interface-guidelines/macos/images/radioButtons.png)
class MacosRadioButton<T> extends StatelessWidget {
  /// Creates a radio button.
  ///
  /// [size] must be non-negative
  const MacosRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.size = 16,
    this.onColor,
    this.offColor = CupertinoColors.tertiaryLabel,
    this.innerColor,
    this.semanticLabel,
  }) : assert(size >= 0);

  /// Whether the button is checked or not
  final T value;

  /// The currently selected value for a group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  final T? groupValue;

  /// Called when [value] changes. If null, the button will be
  /// considered disabled.
  final ValueChanged<T?>? onChanged;

  /// The size of the button. Defaults to 16px
  final double size;

  /// The color of the border when [value] is true. If null,
  /// [MacosThemeData.primaryColor] is used
  final Color? onColor;

  /// The color of the border when [value] is false.
  /// [CupertinoColors.tertiaryLabel] is used by default
  final Color offColor;

  /// The color in the middle. If null, the following colors are
  /// used when:
  ///
  ///   - Disabled: [CupertinoColors.quaternarySystemFill]
  ///   - On: [CupertinoColors.white]
  ///   - Off: [CupertinoColors.tertiarySystemFill]
  final Color? innerColor;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  /// Whether the button is disabled or not
  bool get isDisabled => onChanged == null;

  /// Whether the button is selected or not.
  bool get selected => value == groupValue;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // properties.add(StringProperty(
    //   'state',
    //   value ? 'checked' : 'unchecked',
    // ));
    properties.add(
      FlagProperty('disabled', value: isDisabled, ifFalse: 'enabled'),
    );
    properties.add(DoubleProperty('size', size));
    properties.add(ColorProperty('onColor', onColor));
    properties.add(ColorProperty('offColor', offColor));
    properties.add(ColorProperty('innerColor', innerColor));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final MacosThemeData theme = MacosTheme.of(context);
    final isLight = !theme.brightness.isDark;
    return RadioValueControl<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      label: semanticLabel,
      builder: (context, states) => ValueControlSurface(
        states: states,
        shape: BoxShape.circle,
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            border: Border.all(
              width: selected ? size / 4.0 : 1,
              color: MacosDynamicColor.resolve(
                isDisabled
                    ? CupertinoColors.quaternaryLabel
                    : selected
                    ? onColor ?? theme.primaryColor
                    : offColor,
                context,
              ),
            ),
            shape: BoxShape.circle,
            color: MacosDynamicColor.resolve(
              innerColor ??
                  (isDisabled
                      ? CupertinoColors.quaternarySystemFill
                      : selected || isLight
                      ? CupertinoColors.white
                      : CupertinoColors.tertiarySystemFill),
              context,
            ),
          ),
        ),
      ),
    );
  }
}
