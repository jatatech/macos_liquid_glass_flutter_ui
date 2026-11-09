import 'package:flutter/widgets.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

/// Resolve to a concrete value for paint/decoration equality. The inherited
/// CupertinoDynamicColor equality and withValues operate on its effective colour,
/// not the resolvedColor carried by ResolvedMacosDynamicColor.
Color resolveContentColor(Color color, BuildContext context) {
  final resolved = MacosDynamicColor.resolve(color, context);
  return resolved is ResolvedMacosDynamicColor
      ? resolved.resolvedColor
      : resolved;
}
