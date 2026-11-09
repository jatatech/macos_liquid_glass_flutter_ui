import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';
import 'package:macos_liquid_glass_ui/src/buttons/button_interaction.dart';

// Shared disabled and live-contrast boundary; component theme overrides survive.
class PickerSurface extends StatelessWidget {
  const PickerSurface({super.key, required this.enabled, required this.child});
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return Semantics(
      enabled: enabled,
      child: ExcludeFocus(
        excluding: !enabled,
        child: IgnorePointer(
          ignoring: !enabled,
          child: ExcludeSemantics(
            excluding: !enabled,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: chrome.highContrast
                    ? Border.all(color: chrome.separator)
                    : null,
              ),
              child: Opacity(opacity: enabled ? 1 : 0.5, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class PickerControlSurface extends StatelessWidget {
  const PickerControlSurface({
    super.key,
    required this.states,
    required this.child,
    this.shape = BoxShape.rectangle,
  });
  final Set<WidgetState> states;
  final Widget child;
  final BoxShape shape;
  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return ButtonFocusRing(
      states: states,
      shape: shape,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: shape,
          color: states.contains(WidgetState.pressed)
              ? chrome.controlPressedOverlay
              : states.contains(WidgetState.hovered)
              ? chrome.controlHoverOverlay
              : null,
        ),
        child: child,
      ),
    );
  }
}

class PickerField extends StatefulWidget {
  const PickerField({
    super.key,
    required this.element,
    required this.selected,
    required this.onSelected,
    required this.background,
    required this.foreground,
  });
  final String element;
  final bool selected;
  final VoidCallback onSelected;
  final Color background;
  final Color foreground;
  @override
  State<PickerField> createState() => _PickerFieldState();
}

class _PickerFieldState extends State<PickerField> {
  final _focus = FocusNode();
  void _select() {
    _focus.requestFocus();
    widget.onSelected();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onFocusChange: (focused) {
      if (focused && !widget.selected) widget.onSelected();
    },
    child: ButtonInteraction(
      focusNode: _focus,
      onPressed: _select,
      selected: widget.selected,
      onHeldChanged: (_) {},
      builder: (context, states) => PickerControlSurface(
        states: states,
        child: ColoredBox(
          color: widget.background,
          child: Text(
            widget.element,
            style: MacosTheme.of(context).typography.body.copyWith(
              color: widget.foreground,
              letterSpacing: -0.08,
            ),
          ),
        ),
      ),
    ),
  );
}
