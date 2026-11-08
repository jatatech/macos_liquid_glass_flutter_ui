import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/buttons/button_interaction.dart';
import 'package:macos_ui/src/buttons/value_control.dart';
import 'package:macos_ui/src/library.dart';
import 'package:macos_ui/src/layout/tab_view/tab_navigation.dart';

/// {@template macosSegmentedControl}
/// Displays one or more navigational tabs in a single horizontal group.
///
/// Used by [MacosTabView] to navigate between the different tabs of the tab bar.
///
/// [MacosSegmentedControl] can be considered somewhat analogous to Flutter's
/// material `TabBar` in that it requires a list of [tabs]. Unlike `TabBar`,
/// however, [MacosSegmentedControl] explicitly requires a [controller].
///
/// See also:
/// * [MacosTab], which is a navigational item in a [MacosSegmentedControl].
/// * [MacosTabView], which is a multi-page navigational view.
/// {@endtemplate}
class MacosSegmentedControl extends StatefulWidget {
  /// {@macro macosSegmentedControl}
  ///
  /// [tabs] and [controller] must not be null. [tabs] must contain at least one
  /// tab.
  const MacosSegmentedControl({
    super.key,
    required this.tabs,
    required this.controller,
  }) : assert(tabs.length > 0);

  /// The navigational items of this [MacosSegmentedControl].
  final List<MacosTab> tabs;

  /// The [MacosTabController] that manages the [tabs] in this
  /// [MacosSegmentedControl].
  final MacosTabController controller;

  @override
  State<MacosSegmentedControl> createState() => _MacosSegmentedControlState();
}

class _MacosSegmentedControlState extends State<MacosSegmentedControl> {
  final List<FocusNode> _nodes = [];

  void _changed() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.controller.index >= _nodes.length) return;
      final tabContext = _nodes[widget.controller.index].context;
      if (tabContext != null) Scrollable.ensureVisible(tabContext);
    });
  }

  void _syncNodes() {
    while (_nodes.length < widget.tabs.length) {
      _nodes.add(FocusNode());
    }
    while (_nodes.length > widget.tabs.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncNodes();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(MacosSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    _syncNodes();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    final key = event.logicalKey;
    final navigation = TabNavigation.maybeOf(context);
    final vertical = navigation?.vertical ?? false;
    final reversed =
        (navigation?.reversed ?? false) !=
        (Directionality.of(context) == TextDirection.rtl);
    int? target;
    if (key == LogicalKeyboardKey.home) target = 0;
    if (key == LogicalKeyboardKey.end) target = widget.tabs.length - 1;
    if (key ==
        (vertical
            ? LogicalKeyboardKey.arrowDown
            : LogicalKeyboardKey.arrowRight)) {
      target = index + (reversed ? -1 : 1);
    }
    if (key ==
        (vertical
            ? LogicalKeyboardKey.arrowUp
            : LogicalKeyboardKey.arrowLeft)) {
      target = index + (reversed ? 1 : -1);
    }
    if (target == null) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      target %= widget.tabs.length;
      _nodes[target].requestFocus();
      widget.controller.index = target;
      final tabContext = _nodes[target].context;
      if (tabContext != null) Scrollable.ensureVisible(tabContext);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.controller.length == widget.tabs.length);
    final chrome = MacosChromeData.of(context);
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != widget.controller.index;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chrome.toolbar,
        border: Border.all(color: chrome.separator),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.tabs.length; i++)
                Flexible(
                  child: ButtonInteraction(
                    focusNode: _nodes[i],
                    onKeyEvent: (_, event) => _key(i, event),
                    onPressed: () => widget.controller.index = i,
                    onHeldChanged: (_) {},
                    label: widget.tabs[i].label,
                    selected: widget.controller.index == i,
                    inMutuallyExclusiveGroup: true,
                    builder: (context, states) => ValueControlSurface(
                      states: states,
                      radius: const BorderRadius.all(Radius.circular(4)),
                      child: widget.tabs[i].copyWith(
                        active: widget.controller.index == i,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
