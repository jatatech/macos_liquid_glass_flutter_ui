import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/buttons/button_interaction.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

// Value controls share feedback, but retain their own value/gesture ownership.
class ValueControlSurface extends StatelessWidget {
  const ValueControlSurface({
    super.key,
    required this.states,
    required this.child,
    this.radius,
    this.shape = BoxShape.rectangle,
  });
  final Set<WidgetState> states;
  final Widget child;
  final BorderRadius? radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return CustomPaint(
      foregroundPainter: states.contains(WidgetState.focused)
          ? _ValueFocusPainter(
              chrome.focusRing,
              chrome.focusWidth,
              shape,
              radius,
            )
          : null,
      child: ButtonFocusRing(
        states: states,
        radius: radius,
        shape: shape,
        child: Container(
          foregroundDecoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.rectangle ? radius : null,
            color: states.contains(WidgetState.pressed)
                ? chrome.controlPressedOverlay
                : states.contains(WidgetState.hovered)
                ? chrome.controlHoverOverlay
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

// Paint outside the selected surface so a same-colour focus ring remains visible.
// This does not enlarge the public control metrics or its pointer hit region.
class _ValueFocusPainter extends CustomPainter {
  const _ValueFocusPainter(this.color, this.width, this.shape, this.radius);
  final Color color;
  final double width;
  final BoxShape shape;
  final BorderRadius? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final rect = Offset.zero & size;
    if (shape == BoxShape.circle) {
      canvas.drawOval(rect.inflate(width + 1), paint);
    } else {
      canvas.drawRRect(
        (radius ?? BorderRadius.zero).toRRect(rect).inflate(width + 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ValueFocusPainter oldDelegate) =>
      color != oldDelegate.color ||
      width != oldDelegate.width ||
      shape != oldDelegate.shape ||
      radius != oldDelegate.radius;
}

// Optional Flutter RadioGroup integration supplies an explicit group boundary;
// legacy standalone radios keep their value and callback contract.
class RadioValueControl<T> extends StatefulWidget {
  const RadioValueControl({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    required this.builder,
  });
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final Widget Function(BuildContext, Set<WidgetState>) builder;

  @override
  State<RadioValueControl<T>> createState() => _RadioValueControlState<T>();
}

class _RadioValueControlState<T> extends State<RadioValueControl<T>>
    with RadioClient<T> {
  @override
  final focusNode = FocusNode();
  @override
  bool get enabled => widget.onChanged != null;
  @override
  bool get tristate => false;
  @override
  T get radioValue => widget.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    registry = RadioGroup.maybeOf<T>(context);
  }

  @override
  void dispose() {
    registry = null;
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ButtonInteraction(
    focusNode: focusNode,
    onPressed: !enabled
        ? null
        : () {
            if (widget.value != widget.groupValue) {
              widget.onChanged!(widget.value);
            }
          },
    onHeldChanged: (_) {},
    label: widget.label,
    isButton: false,
    checked: widget.value == widget.groupValue,
    inMutuallyExclusiveGroup: true,
    builder: widget.builder,
  );
}
