import 'package:macos_liquid_glass_ui/src/utils/command_menu.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

/// A menu that includes all overflowed toolbar actions.
class ToolbarOverflowMenu extends StatelessWidget {
  /// Builds a menu that includes all overflowed toolbar actions and appears
  /// as a popup below the [ToolbarOverflowButton].
  ///
  /// Has a similar styling to a pulldown menu.
  const ToolbarOverflowMenu({super.key, required this.children});

  /// The list of children widgets to lay out vertically inside the menu.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CommandMenu(children: children);
}
