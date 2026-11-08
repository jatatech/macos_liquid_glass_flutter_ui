import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// A command shared by native glass and its Flutter representations.
@immutable
class MacosGlassCommand {
  const MacosGlassCommand({required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;
}

/// A content region with floating commands, built on [MacosGlassSurface].
/// Reserve bottom padding so documents scroll clear of the commands. Native
/// commands require translation-only, visible bounds and explicit coordination
/// via [nativeOccluded] for custom overlays. Existing window utilities retain
/// window ownership. Flutter approximation and opaque modes share controls.
class MacosGlassCommandSurface extends StatelessWidget {
  const MacosGlassCommandSurface({
    super.key,
    required this.child,
    required this.commands,
    this.forceOpaque = false,
    this.nativeOccluded = false,
    this.focusNode,
    this.onRenderingChanged,
  }) : assert(commands.length > 0 && commands.length <= 4);

  final Widget child;
  final List<MacosGlassCommand> commands;
  final bool forceOpaque;
  final bool nativeOccluded;
  final FocusNode? focusNode;
  final ValueChanged<MacosGlassRendering>? onRenderingChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      assert(constraints.hasBoundedWidth && constraints.hasBoundedHeight);
      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          Positioned(
            bottom: MacosGlassData.commandInset,
            left: MacosGlassData.commandInset,
            right: MacosGlassData.commandInset,
            child: Center(
              child: SizedBox(
                width: math.min(
                  MacosGlassData.commandMaxWidth,
                  math.max(
                    0,
                    constraints.maxWidth - 2 * MacosGlassData.commandInset,
                  ),
                ),
                child: MacosGlassSurface(
                  nativeCommands: commands,
                  forceOpaque: forceOpaque,
                  nativeOccluded: nativeOccluded,
                  focusNode: focusNode,
                  onRenderingChanged: onRenderingChanged,
                  child: Padding(
                    padding: const EdgeInsets.all(MacosChromeData.gap),
                    child: Wrap(
                      spacing: MacosChromeData.gap,
                      runSpacing: MacosChromeData.gap,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final command in commands)
                          PushButton(
                            controlSize: ControlSize.regular,
                            onPressed: command.onPressed,
                            child: Text(command.label),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
