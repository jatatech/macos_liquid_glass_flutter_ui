import 'package:flutter/widgets.dart';
import 'package:macos_ui/src/enums/glass_rendering.dart';
import 'package:macos_ui/src/platform/accessibility.dart';

/// Shared semantic effect tokens and glass selection policy.
class MacosGlassData {
  static const double blurSigma = 18;
  static Color tint(bool dark) => Color(dark ? 0xC02B2C30 : 0xC0F7F8FA);
  static Color edge(bool dark) => Color(dark ? 0x66FFFFFF : 0xAAFFFFFF);
  static LinearGradient highlight(bool dark) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.alphaBlend(Color(dark ? 0x18FFFFFF : 0x40FFFFFF), tint(dark)),
      tint(dark),
    ],
  );

  /// macOS transport failure/older OS remains conservative opaque. Elsewhere,
  /// unavailable AppKit transport is capability absence, not a user preference.
  static MacosGlassRendering rendering({
    required TargetPlatform platform,
    required bool web,
    required MacosAccessibilityData accessibility,
    required MediaQueryData media,
    required bool forceOpaque,
    required bool nativeActive,
    required bool nativeRequested,
  }) {
    final mac = !web && platform == TargetPlatform.macOS;
    if (forceOpaque ||
        media.highContrast ||
        accessibility.increaseContrast ||
        (accessibility.available && accessibility.reduceTransparency) ||
        (mac && !accessibility.available)) {
      return MacosGlassRendering.opaque;
    }
    if (mac && nativeRequested && nativeActive) {
      return MacosGlassRendering.native;
    }
    if (mac && nativeRequested) return MacosGlassRendering.opaque;
    return MacosGlassRendering.approximation;
  }

  static const double commandHeight = 64;
  static const double commandMaxWidth = 480;
  static const double commandInset = 16;
  static const double commandRadius = 24;

  /// Native controls currently support standard text sizes and LTR layout.
  /// Larger text and RTL use the accessible Flutter command layout.
  static bool permitsNative({
    required MacosAccessibilityData accessibility,
    required MediaQueryData media,
    required TextDirection direction,
    required double width,
  }) =>
      accessibility.available &&
      !accessibility.reduceTransparency &&
      !accessibility.increaseContrast &&
      !media.highContrast &&
      media.textScaler.scale(13) <= 17 &&
      direction == TextDirection.ltr &&
      width >= 300;
}
