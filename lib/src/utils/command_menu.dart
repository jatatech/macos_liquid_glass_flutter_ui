import 'package:flutter/services.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

class CommandMenu extends StatefulWidget {
  const CommandMenu({super.key, required this.children, this.color});
  final List<Widget> children;
  final Color? color;

  @override
  State<CommandMenu> createState() => _ToolbarOverflowMenuState();
}

class _ToolbarOverflowMenuState extends State<CommandMenu> {
  final _node = FocusNode(skipTraversal: true);

  void _focus(FocusNode node) {
    node.requestFocus();
    final context = node.context;
    if (context != null) Scrollable.ensureVisible(context, alignment: 0.5);
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: Focus(
        focusNode: _node,
        autofocus: true,
        onFocusChange: (focused) {
          if (focused && _node.hasPrimaryFocus) _node.nextFocus();
        },
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.escape ||
              key ==
                  (Directionality.of(context) == TextDirection.ltr
                      ? LogicalKeyboardKey.arrowLeft
                      : LogicalKeyboardKey.arrowRight)) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          final nodes = node.traversalDescendants
              .where((n) => n.canRequestFocus && !n.skipTraversal)
              .toList();
          if (nodes.isEmpty) return KeyEventResult.ignored;
          final current = nodes.indexWhere((n) => n.hasFocus);
          if (key == LogicalKeyboardKey.arrowDown) {
            _focus(nodes[(current + 1) % nodes.length]);
          } else if (key == LogicalKeyboardKey.arrowUp) {
            _focus(nodes[(current - 1) % nodes.length]);
          } else if (key == LogicalKeyboardKey.home) {
            _focus(nodes.first);
          } else if (key == LogicalKeyboardKey.end) {
            _focus(nodes.last);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          child: IntrinsicWidth(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.color ?? chrome.toolbar,
                border: Border.all(color: chrome.separator),
                borderRadius: BorderRadius.circular(
                  MacosChromeData.controlRadius,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MacosChromeData.gap / 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
