import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';
import 'package:macos_ui/src/buttons/button_interaction.dart';
import 'package:macos_ui/src/buttons/value_control.dart';

/// A widget that aims to approximate the [ListTile] widget found in
/// Flutter's material library.
class MacosListTile extends StatelessWidget {
  /// Builds a [MacosListTile].
  const MacosListTile({
    super.key,
    this.leading,
    this.selected = false,
    this.enabled = true,
    this.focusNode,
    required this.title,
    this.subtitle,
    this.leadingWhitespace = 8,
    this.onClick,
    this.onLongPress,
    this.mouseCursor = MouseCursor.defer,
  });

  /// Controlled selection, rendered on an opaque semantic selection surface.
  final bool selected;

  /// Whether callbacks and keyboard activation are available.
  final bool enabled;

  /// Optional caller-owned keyboard focus node.
  final FocusNode? focusNode;

  /// A widget to display before the [title].
  final Widget? leading;

  /// The primary content of the list tile.
  final Widget title;

  /// Additional content displayed below the [title].
  final Widget? subtitle;

  /// The amount of whitespace between the [leading] and [title] widgets.
  ///
  /// Defaults to `8`.
  final double? leadingWhitespace;

  /// A callback to perform when the widget is clicked.
  final VoidCallback? onClick;

  /// A callback to perform when the widget is long-pressed.
  final VoidCallback? onLongPress;

  /// The [MouseCursor] to use for this widget.
  final MouseCursor mouseCursor;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final chrome = MacosChromeData.of(context);
    Widget content(Color foreground, Color secondary) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null)
          MacosIconTheme(
            data: MacosIconThemeData(color: foreground),
            child: leading!,
          ),
        SizedBox(width: leadingWhitespace),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle(
                style: theme.typography.headline.copyWith(
                  fontWeight: FontWeight.bold,
                  color: foreground,
                ),
                child: title,
              ),
              if (subtitle != null)
                DefaultTextStyle(
                  style: theme.typography.subheadline.copyWith(
                    color: secondary,
                  ),
                  child: subtitle!,
                ),
            ],
          ),
        ),
      ],
    );
    // A callback-free tile is document content, not a disabled button.
    if (onClick == null && onLongPress == null) {
      return Semantics(
        container: true,
        selected: selected ? true : null,
        child: ColoredBox(
          color: selected ? chrome.selection : chrome.canvas,
          child: content(
            selected
                ? buttonForeground(chrome.selection, chrome.canvas)
                : chrome.foreground,
            selected
                ? buttonForeground(chrome.selection, chrome.canvas)
                : chrome.secondaryForeground,
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      child: ButtonInteraction(
        focusNode: focusNode,
        cursor: mouseCursor,
        selected: selected,
        onPressed: enabled ? onClick : null,
        onLongPress: enabled ? onLongPress : null,
        onHeldChanged: (_) {},
        builder: (context, states) {
          final background = selected ? chrome.selection : chrome.canvas;
          final foreground = selected
              ? buttonForeground(background, chrome.canvas)
              : enabled
              ? chrome.foreground
              : chrome.disabledForeground;
          return ValueControlSurface(
            states: states,
            child: ColoredBox(
              color: background,
              child: content(
                foreground,
                selected ? foreground : chrome.secondaryForeground,
              ),
            ),
          );
        },
      ),
    );
  }
}
