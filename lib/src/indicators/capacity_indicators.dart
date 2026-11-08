import 'package:flutter/foundation.dart';
import 'indicator_interaction.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';
import 'package:macos_ui/src/utils/content_color.dart';

const double _kCapacityIndicatorMinWidth = 100.0;

/// A capacity indicator illustrates the current level in
/// relation to a finite capacity. Capacity indicators are
/// often used when communicating factors like disk and
/// battery usage. Mail, for example, uses a capacity indicator
/// to show the percentage of data used in relation to an
/// email account’s quota.
///
/// There are two types of capacity indicators:
///
/// * Continuous
///
/// A horizontal translucent track that fills with a colored bar
/// to indicate the current value. Tick marks are often displayed
/// to provide context.
///
/// ![Continuous Capacity Indicator](https://developer.apple.com/design/human-interface-guidelines/macos/images/indicators-continous.png)
///
/// * Discrete
///
/// A horizontal row of separate, equally sized, rectangular segments.
/// The number of segments matches the total capacity, and the segments
/// fill completely—never partially—with color to indicate the current
/// value.
///
/// ![Discrete Capacity Indicator](https://developer.apple.com/design/human-interface-guidelines/macos/images/indicators-discrete.png)
class CapacityIndicator extends StatelessWidget {
  /// Creates a capacity indicator.
  ///
  /// [value] must be in range of 0 to 100.
  const CapacityIndicator({
    super.key,
    required this.value,
    this.onChanged,
    this.discrete = false,
    this.splits = 10,
    this.color = CupertinoColors.systemGreen,
    this.borderColor = CupertinoColors.tertiaryLabel,
    this.backgroundColor = CupertinoColors.tertiarySystemGroupedBackground,
    this.semanticLabel,
  }) : assert(value >= 0 && value <= 100),
       assert(splits > 0);

  /// The current value of the indicator. Must be in the range of 0 to 100.
  final double value;

  /// Called with a proposed controlled value on pointer down/start/update, keyboard
  /// or semantic adjustment. Null makes this a read-only indicator.
  /// Continuous pointer values are unsnapped; keyboard steps by one percent.
  /// Both display modes preserve fractional pointer values. Discrete keyboard and
  /// semantic input steps by 100 / splits.
  final ValueChanged<double>? onChanged;

  /// Whether the indicator is discrete or not
  ///
  /// ![Discrete Capacity Indicator](https://developer.apple.com/design/human-interface-guidelines/macos/images/indicators-discrete.png)
  final bool discrete;

  /// How many equal cells the indicator has if [discrete]
  /// is true. Defaults to 10.
  final int splits;

  /// The color to fill the cells. [CupertinoColors.systemGreen] is
  /// used by default.
  final Color color;

  /// The background color of the cells. [CupertinoColors.tertiarySystemGroupedBackground]
  /// is used by default
  final Color backgroundColor;

  /// The border color of the cells. [CupertinoColors.tertiaryLabel]
  /// is used by default
  final Color borderColor;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value));
    properties.add(ObjectFlagProperty.has('onChanged', onChanged));
    properties.add(
      FlagProperty('discrete', value: discrete, ifFalse: 'continuous'),
    );
    properties.add(IntProperty('splits', splits));
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(ColorProperty('borderColor', borderColor));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _kCapacityIndicatorMinWidth;
        return SizedBox(
          width: width,
          child: IndicatorInteraction(
            value: value,
            max: 100,
            step: discrete ? 100 / splits : 1,
            snap: discrete,
            onChanged: onChanged,
            label: semanticLabel,
            builder: (context, displayed) {
              if (!discrete) {
                return CapacityIndicatorCell(
                  value: displayed,
                  color: color,
                  backgroundColor: backgroundColor,
                  borderColor: borderColor,
                );
              }
              return Row(
                children: List.generate(
                  splits,
                  (index) => Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: index == splits - 1 ? 0 : 2,
                      ),
                      child: CapacityIndicatorCell(
                        value: // Tolerate floating-point error at snapped cell boundaries.
                        (displayed / 100 * splits + 1e-10).floor() > index
                            ? 100
                            : 0,
                        color: color,
                        backgroundColor: backgroundColor,
                        borderColor: borderColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// The cell [CapacityIndicator] uses to draw itself.
class CapacityIndicatorCell extends StatelessWidget {
  /// Creates a capacity indicator cell.
  ///
  /// [value] must be in the range of 0 to 100
  const CapacityIndicatorCell({
    super.key,
    this.value = 100,
    this.color = CupertinoColors.systemGreen,
    this.borderColor = CupertinoColors.tertiaryLabel,
    this.backgroundColor = CupertinoColors.tertiarySystemGroupedBackground,
  }) : assert(value >= 0 && value <= 100);

  /// The color of the cell.
  final Color color;

  /// The background color of the cell.
  final Color backgroundColor;

  /// The border color of the cell.
  final Color borderColor;

  /// The current value of the cell.
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: CustomPaint(
        painter: _CapacityCellPainter(
          color: resolveContentColor(color, context),
          backgroundColor: resolveContentColor(backgroundColor, context),
          borderColor:
              (MediaQuery.maybeOf(context)?.highContrast ?? false) &&
                  MacosTheme.maybeOf(context) != null
              ? MacosChromeData.of(context).foreground
              : resolveContentColor(borderColor, context),
          rtl: Directionality.of(context) == TextDirection.rtl,
          highContrast: MediaQuery.maybeOf(context)?.highContrast ?? false,
          value: value,
        ),
      ),
    );
  }
}

class _CapacityCellPainter extends CustomPainter {
  const _CapacityCellPainter({
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.value,
    required this.rtl,
    required this.highContrast,
  });

  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final double value;
  final bool rtl;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 2.0;
    if (rtl) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    /// Draw background
    canvas.drawRRect(
      const BorderRadius.all(
        Radius.circular(radius),
      ).toRRect(Offset.zero & size),
      Paint()..color = backgroundColor,
    );

    /// Draw inside
    canvas.drawRRect(
      BorderRadius.horizontal(
        left: const Radius.circular(radius),
        right: value == 100 ? const Radius.circular(radius) : Radius.zero,
      ).toRRect(
        Offset.zero & Size(size.width * (value / 100).clamp(0, 1), size.height),
      ),
      Paint()..color = color,
    );

    /// Draw border
    canvas.drawRRect(
      const BorderRadius.all(
        Radius.circular(radius),
      ).toRRect(Offset.zero & size),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = highContrast ? 1.5 : 0.5,
    );
    if (rtl) canvas.restore();
  }

  @override
  bool shouldRepaint(_CapacityCellPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.rtl != rtl ||
      oldDelegate.highContrast != highContrast;

  @override
  bool shouldRebuildSemantics(_CapacityCellPainter oldDelegate) => false;
}
