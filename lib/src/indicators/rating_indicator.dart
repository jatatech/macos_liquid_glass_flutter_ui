import 'package:flutter/foundation.dart';
import 'indicator_interaction.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';
import 'package:macos_ui/src/utils/content_color.dart';

/// A rating indicator uses a series of horizontally arranged
/// graphical symbols to communicate a ranking level. The
/// default symbol is a star.
///
/// A rating indicator doesn’t display partial symbols—its value
/// fills the next symbol for any positive fractional value. Within
/// a rating indicator, symbols are always the same distance apart
/// and don't expand or shrink to fit the control.
class RatingIndicator extends StatelessWidget {
  /// Creates a rating indicator.
  ///
  /// [iconSize] must be non-negative.
  ///
  /// [amount] must be greater than 0
  ///
  /// [value] must be in range of 0 to [amount]
  const RatingIndicator({
    super.key,
    required this.value,
    this.amount = 5,
    this.ratedIcon = CupertinoIcons.star_fill,
    this.unratedIcon = CupertinoIcons.star,
    this.iconColor,
    this.iconSize = 16,
    this.onChanged,
    this.semanticLabel,
  }) : assert(iconSize >= 0),
       assert(amount > 0),
       assert(value >= 0 && value <= amount);

  /// The icon used when the star is rated. [CupertinoIcons.star_fill]
  /// is used by default. If you must replace the star with a custom
  /// symbol, ensure that its purpose is clear.
  final IconData ratedIcon;

  /// The icon used when the star is unrated. [CupertinoIcons.star] is
  /// used by default. If you must replace the star with a custom symbol,
  /// ensure that its purpose is clear.
  final IconData unratedIcon;

  /// The color of the icon. If null, [MacosThemeData.primaryColor] is used
  final Color? iconColor;

  /// The size of the icon. Defaults to 16px
  final double iconSize;

  /// The amount of stars in the indicator. Defaults to 5
  final int amount;

  /// The current value. It must be in range of 0 to [amount]
  final double value;

  /// Called with a fractional rating on pointer down/start/update, or on
  /// keyboard or semantic adjustment. Null makes this read only.
  /// The caller must rebuild with the new value to retain an edit.
  final ValueChanged<double>? onChanged;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IconDataProperty('ratedIcon', ratedIcon));
    properties.add(IconDataProperty('unratedIcon', unratedIcon));
    properties.add(ColorProperty('iconColor', iconColor));
    properties.add(DoubleProperty('iconSize', iconSize));
    properties.add(IntProperty('amount', amount));
    properties.add(DoubleProperty('value', value));
    properties.add(ObjectFlagProperty.has('onChanged', onChanged));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: iconSize * amount,
        child: IndicatorInteraction(
          value: value,
          max: amount.toDouble(),
          step: 1,
          onChanged: onChanged,
          label: semanticLabel,
          builder: (context, displayed) => ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                amount,
                (index) => Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Icon(
                      displayed > index ? ratedIcon : unratedIcon,
                      color: resolveContentColor(
                        iconColor ?? theme.primaryColor,
                        context,
                      ),
                      size: iconSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
