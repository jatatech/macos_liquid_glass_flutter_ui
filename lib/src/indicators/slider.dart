import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/src/buttons/button_interaction.dart';
import 'package:macos_ui/macos_ui.dart';

const double _kSliderMinWidth = 100.0;
const double _kSliderBorderRadius = 16.0;
const double _kSliderHeight = 4.0;
const double _kContinuousThumbSize = 20;
const double _kOverallHeight = 20;
const double _kTickWidth = 2.0;
const double _kTickHeight = 8.0;

const double _kDiscreteThumbWidth = 6.0;
const double _kDiscreteThumbBorderRadius = 8;

/// {@template macosSlider}
/// A slider is a horizontal track with a control, called a thumb,
/// that people can adjust between a minimum and maximum value.
///
/// The slider doesn't maintain any state itself, instead the user is expected to
/// update this widget with a new [value] whenever the slider changes.
///
/// {@endtemplate}
class MacosSlider extends StatefulWidget {
  /// {@macro macosSlider}
  const MacosSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.discrete = false,
    this.splits = 15,
    this.min = 0.0,
    this.max = 1.0,
    this.color = CupertinoColors.systemBlue,
    this.backgroundColor = MacosColors.sliderBackgroundColor,
    this.tickBackgroundColor = MacosColors.tickBackgroundColor,
    this.thumbColor = MacosColors.sliderThumbColor,
    this.semanticLabel,
  }) : assert(value >= min && value <= max),
       assert(min < max),
       assert(splits >= 2);

  /// The value of this slider.
  ///
  /// This value must be between [min] and [max], inclusive.
  final double value;

  /// Called whenever the value of the slider changes
  final ValueChanged<double>? onChanged;

  /// Whether the slider is discrete or continuous.
  ///
  /// Continuous sliders have a thumb that can be dragged anywhere along the track.
  /// Discrete sliders have a thumb that can only be dragged to the tick marks.
  ///
  /// [splits] will only be considered if this is true.
  final bool discrete;

  /// The minimum value of this slider
  final double min;

  /// The maximum value of this slider
  final double max;

  /// The number of discrete splits when using [discrete] mode.
  ///
  /// This includes the split at [min] and [max]
  final int splits;

  /// The color of the slider (the part where the thumb is sliding on) that is not
  /// considered selected.
  ///
  /// Defaults to [CupertinoColors.quaternaryLabel]
  final Color backgroundColor;

  /// The color of background ticks when using [discrete] mode.
  final Color tickBackgroundColor;

  /// The color of the slider (the part where the thumb is sliding on) that is
  /// considered selected.
  ///
  /// Defaults to [CupertinoColors.systemBlue]
  final Color color;

  /// The color of the thumb.
  final Color thumbColor;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value));
    properties.add(ObjectFlagProperty.has('onChanged', onChanged));
    properties.add(DoubleProperty('min', min));
    properties.add(DoubleProperty('max', max));
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(ColorProperty('tickBackgroundColor', tickBackgroundColor));
    properties.add(ColorProperty('thumbColor', thumbColor));
    properties.add(
      FlagProperty('discrete', value: discrete, ifTrue: 'discrete'),
    );
    properties.add(IntProperty('splits', splits));
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }

  @override
  State<MacosSlider> createState() => _MacosSliderState();
}

class _MacosSliderState extends State<MacosSlider> {
  final _focus = FocusNode();
  bool _hovered = false;
  bool _pressed = false;
  double? _lastEmitted;
  bool get _enabled => widget.onChanged != null;
  double get _step =>
      (widget.max - widget.min) / (widget.discrete ? widget.splits - 1 : 100);
  double get _percentage {
    final fraction = (widget.value - widget.min) / (widget.max - widget.min);
    return widget.discrete
        ? (fraction * (widget.splits - 1)).round() / (widget.splits - 1)
        : fraction;
  }

  void _emit(double value) {
    value = value.clamp(widget.min, widget.max);
    if (widget.discrete) {
      value = widget.min + ((value - widget.min) / _step).round() * _step;
    }
    value = value.clamp(widget.min, widget.max);
    if (_enabled && value != (_lastEmitted ?? widget.value)) {
      _lastEmitted = value;
      widget.onChanged!(value);
    }
  }

  void _update(double width, double position, bool rtl) {
    if (width <= 0) return;
    final fraction = (position / width).clamp(0.0, 1.0);
    _emit(
      widget.min + (rtl ? 1 - fraction : fraction) * (widget.max - widget.min),
    );
  }

  @override
  void didUpdateWidget(MacosSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _pressed = false;
      _focus.unfocus();
    }
    if (!_pressed) _lastEmitted = null;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CupertinoApp-only consumers remain supported.
    final chrome = MacosTheme.maybeOf(context) == null
        ? null
        : MacosChromeData.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final states = <WidgetState>{
      if (_focus.hasFocus) WidgetState.focused,
      if (!_enabled) WidgetState.disabled,
    };
    final accent = MacosDynamicColor.resolve(widget.color, context);
    final track = MacosDynamicColor.resolve(widget.backgroundColor, context);
    final thumb = MacosDynamicColor.resolve(widget.thumbColor, context);
    return Focus(
      focusNode: _focus,
      canRequestFocus: _enabled,
      includeSemantics: false,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (_, event) {
        if (!_enabled ||
            event is KeyUpEvent ||
            HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isAltPressed) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        _lastEmitted = null;
        if (key == LogicalKeyboardKey.home) {
          _emit(widget.min);
        } else if (key == LogicalKeyboardKey.end) {
          _emit(widget.max);
        } else if (key == LogicalKeyboardKey.arrowUp ||
            key ==
                (rtl
                    ? LogicalKeyboardKey.arrowLeft
                    : LogicalKeyboardKey.arrowRight)) {
          _emit(widget.value + _step);
        } else if (key == LogicalKeyboardKey.arrowDown ||
            key ==
                (rtl
                    ? LogicalKeyboardKey.arrowRight
                    : LogicalKeyboardKey.arrowLeft)) {
          _emit(widget.value - _step);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Semantics(
        slider: true,
        enabled: _enabled,
        focusable: _enabled,
        focused: _focus.hasFocus,
        label: widget.semanticLabel,
        value: widget.value.toStringAsFixed(2),
        increasedValue: widget.value < widget.max
            ? (widget.value + _step)
                  .clamp(widget.min, widget.max)
                  .toStringAsFixed(2)
            : null,
        decreasedValue: widget.value > widget.min
            ? (widget.value - _step)
                  .clamp(widget.min, widget.max)
                  .toStringAsFixed(2)
            : null,
        onIncrease: _enabled && widget.value < widget.max
            ? () {
                _lastEmitted = null;
                _emit(widget.value + _step);
              }
            : null,
        onDecrease: _enabled && widget.value > widget.min
            ? () {
                _lastEmitted = null;
                _emit(widget.value - _step);
              }
            : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final outerWidth = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : _kSliderMinWidth;
              final padding = widget.discrete
                  ? _kDiscreteThumbWidth / 2
                  : _kContinuousThumbSize / 2;
              final width = (outerWidth - padding * 2).clamp(
                0.0,
                double.infinity,
              );
              Widget content = SizedBox(
                width: outerWidth,
                height: _kOverallHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTapUp: !_enabled
                      ? null
                      : (details) {
                          _focus.requestFocus();
                          _lastEmitted = null;
                          _update(
                            width,
                            details.localPosition.dx - padding,
                            rtl,
                          );
                        },
                  onHorizontalDragStart: !_enabled
                      ? null
                      : (details) {
                          _focus.requestFocus();
                          _lastEmitted = null;
                          setState(() => _pressed = true);
                          _update(
                            width,
                            details.localPosition.dx - padding,
                            rtl,
                          );
                        },
                  onHorizontalDragUpdate: !_enabled
                      ? null
                      : (details) {
                          _update(
                            width,
                            details.localPosition.dx - padding,
                            rtl,
                          );
                        },
                  onHorizontalDragEnd: !_enabled
                      ? null
                      : (_) => setState(() {
                          _pressed = false;
                          _lastEmitted = null;
                        }),
                  onHorizontalDragCancel: !_enabled
                      ? null
                      : () => setState(() {
                          _pressed = false;
                          _lastEmitted = null;
                        }),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: padding),
                          height: _kSliderHeight,
                          decoration: BoxDecoration(
                            color: track,
                            borderRadius: BorderRadius.circular(
                              _kSliderBorderRadius,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: rtl
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: padding),
                          height: _kSliderHeight,
                          width: width * _percentage,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(
                              _kSliderBorderRadius,
                            ),
                          ),
                        ),
                      ),
                      if (widget.discrete)
                        Positioned.fill(
                          left: padding,
                          right: padding,
                          child: Transform.flip(
                            flipX: rtl,
                            child: CustomPaint(
                              painter: _DiscreteTickPainter(
                                ticks: widget.splits,
                                selectedPercentage: _percentage,
                                backgroundColor: MacosDynamicColor.resolve(
                                  widget.tickBackgroundColor,
                                  context,
                                ),
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left:
                            padding +
                            width * (rtl ? 1 - _percentage : _percentage) -
                            (widget.discrete
                                    ? _kDiscreteThumbWidth
                                    : _kContinuousThumbSize) /
                                2,
                        width: widget.discrete
                            ? _kDiscreteThumbWidth
                            : _kContinuousThumbSize,
                        height: _kContinuousThumbSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              _kDiscreteThumbBorderRadius,
                            ),
                            border:
                                _hovered ||
                                    _pressed ||
                                    (chrome?.highContrast ?? false)
                                ? Border.all(
                                    color: _pressed
                                        ? accent
                                        : chrome?.separator ?? accent,
                                  )
                                : null,
                          ),
                          position: DecorationPosition.foreground,
                          child: widget.discrete
                              ? _DiscreteThumb(color: thumb)
                              : _ContinuousThumb(color: thumb),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              if (!_enabled) content = Opacity(opacity: 0.5, child: content);
              return chrome == null
                  ? content
                  : ButtonFocusRing(
                      states: states,
                      radius: BorderRadius.circular(
                        MacosChromeData.controlRadius,
                      ),
                      child: content,
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _ContinuousThumb extends StatelessWidget {
  const _ContinuousThumb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kContinuousThumbSize,
      width: _kContinuousThumbSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(
          Radius.circular(_kContinuousThumbSize),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 1,
            spreadRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _DiscreteThumb extends StatelessWidget {
  const _DiscreteThumb({required this.color});

  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kContinuousThumbSize,
      width: _kDiscreteThumbWidth,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(
          Radius.circular(_kDiscreteThumbBorderRadius),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 1,
            spreadRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _DiscreteTickPainter extends CustomPainter {
  _DiscreteTickPainter({
    required this.ticks,
    required this.selectedPercentage,
    required this.backgroundColor,
    required this.color,
  });

  final int ticks;
  final double selectedPercentage;
  final Color backgroundColor;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    var width = size.width;

    var spaceBetween = width / (ticks - 1);

    var paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    var backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < ticks; i++) {
      var x = spaceBetween * i;

      var isPastSelectedPercentage = x / width > selectedPercentage;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - 1,
            (size.height / 2) - (_kTickHeight / 2),
            _kTickWidth,
            _kTickHeight,
          ),
          const Radius.circular(8),
        ),
        isPastSelectedPercentage ? backgroundPaint : paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiscreteTickPainter oldDelegate) {
    return oldDelegate.ticks != ticks ||
        oldDelegate.selectedPercentage != selectedPercentage ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.color != color;
  }
}
