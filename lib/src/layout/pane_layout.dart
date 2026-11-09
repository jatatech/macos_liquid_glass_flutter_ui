import 'package:flutter/widgets.dart';

/// Measured logical regions inside the Flutter viewport, below native chrome.
/// Hidden panes have zero width. Widths describe logical leading/trailing panes;
/// [content] is a physical rectangle in viewport coordinates. No multiwindow contract.
@immutable
class MacosPaneLayout {
  const MacosPaneLayout({
    required this.size,
    required this.leadingWidth,
    required this.trailingWidth,
    this.textDirection = TextDirection.ltr,
  });
  final TextDirection textDirection;
  final Size size;
  final double leadingWidth, trailingWidth;
  Rect get content => Rect.fromLTWH(
    textDirection == TextDirection.rtl ? trailingWidth : leadingWidth,
    0,
    (size.width - leadingWidth - trailingWidth).clamp(0, size.width),
    size.height,
  );
  @override
  bool operator ==(Object other) =>
      other is MacosPaneLayout &&
      size == other.size &&
      textDirection == other.textDirection &&
      leadingWidth == other.leadingWidth &&
      trailingWidth == other.trailingWidth;
  @override
  int get hashCode =>
      Object.hash(size, leadingWidth, trailingWidth, textDirection);
}

/// Caller-owned, one-window geometry feed. Share between MacosWindow and its
/// retained MacosNativeToolbar; dispose after both unmount. Shell updates arrive
/// after layout, so listeners can rebuild safely. Do not write application widths
/// here: Sidebar and existing shell controls remain the layout owners.
class MacosPaneLayoutController extends ValueNotifier<MacosPaneLayout?> {
  MacosPaneLayoutController() : super(null);
}
