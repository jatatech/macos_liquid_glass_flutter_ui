import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';
import 'package:macos_window_utils/widgets/macos_toolbar_passthrough.dart';

/// A pulldown button suitable for the toolbar.
class ToolBarPullDownButton extends ToolbarItem {
  /// Builds a pulldown button suitable for the toolbar.
  ///
  /// It essentially wraps a [MacosPulldownButton] with the appropriate toolbar
  /// styling.
  ///
  /// If it overflows the available toolbar width, it becomes a
  /// [ToolbarOverflowMenuItem], that opens a subsequent submenu with the
  /// pulldown items.
  const ToolBarPullDownButton({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    this.tooltipMessage,
  });

  /// The label that describes this button's action.
  ///
  /// Must be provided so that it can be shown in the [ToolbarOverflowMenu].
  final String label;

  /// An icon to use as title for the pull-down button.
  ///
  /// It is recommended to use icons from the [CupertinoIcons] library for this.
  final IconData icon;

  /// The list of menu entries for the pull-down menu.
  ///
  /// Can be either [MacosPulldownMenuItem]s or [MacosPulldownMenuDivider]s.
  ///
  /// If the list of items is null, then the pull-down button will be disabled,
  /// i.e. it will be displayed in grey and not respond to input.
  ///
  /// If the button overflows the available toolbar width, its items will be
  /// shown in a submenu next to the button's [ToolbarOverflowMenuItem].
  ///
  /// For this reason, you must set the [label] property of all
  /// [MacosPulldownMenuItem]s, as it's necessary for setting the submenu's
  /// content.
  final List<MacosPulldownMenuEntry>? items;

  /// An optional message to appear in a tooltip when user hovers over the
  /// pull-down button.
  final String? tooltipMessage;

  @override
  Widget build(BuildContext context, ToolbarItemDisplayMode displayMode) {
    final brightness = MacosTheme.of(context).brightness;

    if (displayMode == ToolbarItemDisplayMode.inToolbar) {
      Widget pulldownButton = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: MacosPulldownButtonTheme(
          data: MacosPulldownButtonTheme.of(context).copyWith(
            iconColor: brightness.resolve(
              const Color.fromRGBO(0, 0, 0, 0.5),
              const Color.fromRGBO(255, 255, 255, 0.5),
            ),
          ),
          child: Semantics(
            label: label,
            child: MacosPulldownButton(icon: icon, items: items),
          ),
        ),
      );

      if (tooltipMessage != null) {
        pulldownButton = MacosTooltip(
          message: tooltipMessage!,
          child: pulldownButton,
        );
      }
      return MacosToolbarPassthrough(child: pulldownButton);
    } else {
      return ToolbarOverflowMenuItem(
        label: label,
        subMenuItems: items?.whereType<MacosPulldownMenuItem>().map((entry) {
          assert(entry.label != null, 'Toolbar pulldown items require labels.');
          return ToolbarOverflowMenuItem(
            label: entry.label ?? '',
            onPressed: entry.enabled && entry.onTap != null
                ? () {
                    entry.onTap!();
                  }
                : null,
          );
        }).toList(),
      );
    }
  }
}
