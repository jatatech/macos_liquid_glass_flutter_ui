import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

/// Semantic, opaque shell roles derived from the current [MacosTheme].
/// These roles describe Flutter chrome, not native glass.
class MacosChromeData {
  MacosChromeData._(this.theme, this.highContrast, this.isActive);

  /// Resolves live theme and accessibility changes without caching a snapshot.
  static MacosChromeData of(BuildContext context) => MacosChromeData._(
    MacosTheme.of(context),
    MediaQuery.maybeOf(context)?.highContrast ?? false,
    MacosTheme.of(context).isMainWindow ?? true,
  );

  final MacosThemeData theme;
  final bool highContrast;
  final bool isActive;
  bool get _dark => theme.brightness == Brightness.dark;

  Color get canvas => _dark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  Color get sidebar => theme.canvasColor.withValues(alpha: 1);
  Color get toolbar => sidebar;
  Color get foreground =>
      _dark ? const Color(0xFFF5F5F5) : const Color(0xFF202020);
  Color get secondaryForeground =>
      _dark ? const Color(0xFFBEBEBE) : const Color(0xFF595959);
  Color get disabledForeground => secondaryForeground;
  Color get separator => highContrast
      ? secondaryForeground
      : (_dark ? const Color(0xFF595959) : const Color(0xFFD0D0D0));
  Color get focusRing => highContrast ? foreground : theme.primaryColor;
  Color get selection => highContrast
      ? foreground
      : isActive
      ? theme.primaryColor
      : separator;
  Color get hover => _dark ? const Color(0xFF414141) : const Color(0xFFE5E5E5);
  Color get pressed =>
      _dark ? const Color(0xFF555555) : const Color(0xFFD3D3D3);

  /// Disabled wins over pressed, selected and hovered states.
  Color backgroundFor(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return toolbar;
    if (states.contains(WidgetState.pressed)) return pressed;
    if (states.contains(WidgetState.selected)) return selection;
    if (states.contains(WidgetState.hovered)) return hover;
    return toolbar;
  }

  /// State overlays preserve explicitly supplied control background colours.
  Color get controlHoverOverlay => foreground.withValues(alpha: 0.06);
  Color get controlPressedOverlay => foreground.withValues(alpha: 0.14);

  double get focusWidth => highContrast ? 3 : 2;
  static const double contentInset = 24;
  static const double gap = 12;
  static const double controlRadius = 7;
  static const double sidebarMinWidth = 210;
  static const double sidebarMaxWidth = 280;
  static const double sidebarStartWidth = 230;
}
