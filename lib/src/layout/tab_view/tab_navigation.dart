import 'package:flutter/widgets.dart';

// Internal physical-key mapping for the retained rotated side-tab layout.
class TabNavigation extends InheritedWidget {
  const TabNavigation({
    super.key,
    required this.vertical,
    required this.reversed,
    required super.child,
  });
  final bool vertical;
  final bool reversed;

  static TabNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabNavigation>();

  @override
  bool updateShouldNotify(TabNavigation oldWidget) =>
      vertical != oldWidget.vertical || reversed != oldWidget.reversed;
}
