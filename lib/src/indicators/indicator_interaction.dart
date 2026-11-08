import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/buttons/button_interaction.dart';

/// Internal controlled adjustment shared by capacity and rating indicators.
/// Pointer down/start/update proposals preserve the upstream continuous contract.
class IndicatorInteraction extends StatefulWidget {
  const IndicatorInteraction({
    super.key,
    required this.value,
    required this.max,
    required this.step,
    this.snap = true,
    required this.onChanged,
    required this.label,
    required this.builder,
  });

  final double value;
  final double max;
  final double step;
  final bool snap;
  final ValueChanged<double>? onChanged;
  final String? label;
  final Widget Function(BuildContext, double) builder;

  @override
  State<IndicatorInteraction> createState() => _IndicatorInteractionState();
}

class _IndicatorInteractionState extends State<IndicatorInteraction> {
  final _focus = FocusNode();
  bool _dragging = false;
  bool _hovered = false;
  bool _cancelled = false;
  bool get _editable => widget.onChanged != null;
  double _quantize(double value) =>
      (widget.snap ? (value / widget.step).round() * widget.step : value).clamp(
        0.0,
        widget.max,
      );
  void _emit(double value) {
    final next = _quantize(value);
    if (_editable && next != widget.value) widget.onChanged!(next);
  }

  @override
  void didUpdateWidget(IndicatorInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editable ||
        oldWidget.max != widget.max ||
        oldWidget.step != widget.step ||
        oldWidget.snap != widget.snap) {
      _dragging = false;
      _cancelled = !_editable;
    }
    if (!_editable) _focus.unfocus();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final chrome = MacosTheme.maybeOf(context) == null
        ? null
        : MacosChromeData.of(context);
    String describe(double value) =>
        '${value.toStringAsFixed(2)} of ${widget.max.toStringAsFixed(2)}';
    return Focus(
      focusNode: _focus,
      canRequestFocus: _editable,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() {
        if (!focused) {
          _dragging = false;
          _cancelled = true;
        }
      }),
      onKeyEvent: (_, event) {
        if (!_editable ||
            event is KeyUpEvent ||
            HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isAltPressed) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.escape && _dragging) {
          setState(() {
            _dragging = false;
            _cancelled = true;
          });
        } else if (key == LogicalKeyboardKey.home) {
          _emit(0);
        } else if (key == LogicalKeyboardKey.end) {
          _emit(widget.max);
        } else if (key == LogicalKeyboardKey.arrowUp ||
            key ==
                (rtl
                    ? LogicalKeyboardKey.arrowLeft
                    : LogicalKeyboardKey.arrowRight)) {
          _emit(widget.value + widget.step);
        } else if (key == LogicalKeyboardKey.arrowDown ||
            key ==
                (rtl
                    ? LogicalKeyboardKey.arrowRight
                    : LogicalKeyboardKey.arrowLeft)) {
          _emit(widget.value - widget.step);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Semantics(
        slider: _editable,
        focusable: _editable,
        focused: _focus.hasFocus,
        label: widget.label,
        value: describe(widget.value),
        increasedValue: _editable && widget.value < widget.max
            ? describe(_quantize(widget.value + widget.step))
            : null,
        decreasedValue: _editable && widget.value > 0
            ? describe(_quantize(widget.value - widget.step))
            : null,
        onIncrease: _editable && widget.value < widget.max
            ? () => _emit(widget.value + widget.step)
            : null,
        onDecrease: _editable && widget.value > 0
            ? () => _emit(widget.value - widget.step)
            : null,
        child: MouseRegion(
          cursor: _editable ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              double position(Offset offset) {
                if (!width.isFinite || width <= 0) return widget.value;
                final fraction = (offset.dx / width).clamp(0.0, 1.0);
                return (rtl ? 1 - fraction : fraction) * widget.max;
              }

              Widget content = GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onPanDown: !_editable
                    ? null
                    : (event) {
                        _cancelled = false;
                        _focus.requestFocus();
                        widget.onChanged!(position(event.localPosition));
                      },
                onPanStart: !_editable
                    ? null
                    : (event) {
                        if (!_cancelled) {
                          setState(() => _dragging = true);
                          widget.onChanged!(position(event.localPosition));
                        }
                      },
                onPanUpdate: !_editable
                    ? null
                    : (event) {
                        if (!_cancelled) {
                          widget.onChanged!(position(event.localPosition));
                        }
                      },
                onPanEnd: !_editable
                    ? null
                    : (_) => setState(() => _dragging = false),
                onPanCancel: !_editable
                    ? null
                    : () => setState(() => _dragging = false),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _editable && chrome != null
                        ? (_dragging
                              ? chrome.controlPressedOverlay
                              : _hovered
                              ? chrome.controlHoverOverlay
                              : null)
                        : null,
                    borderRadius: BorderRadius.circular(
                      MacosChromeData.controlRadius,
                    ),
                  ),
                  child: widget.builder(context, widget.value),
                ),
              );
              if (chrome != null) {
                content = ButtonFocusRing(
                  states: {if (_focus.hasFocus) WidgetState.focused},
                  radius: BorderRadius.circular(MacosChromeData.controlRadius),
                  child: content,
                );
              }
              return Listener(
                onPointerDown: (_) => _cancelled = false,
                onPointerCancel: (_) {
                  _cancelled = true;
                  setState(() => _dragging = false);
                },
                child: content,
              );
            },
          ),
        ),
      ),
    );
  }
}
