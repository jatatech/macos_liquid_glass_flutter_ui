import 'package:macos_ui/src/buttons/segmented_control.dart';
import 'package:macos_ui/src/layout/tab_view/tab.dart';
import 'package:macos_ui/src/layout/tab_view/tab_controller.dart';
import 'package:macos_ui/src/library.dart';
import 'package:macos_ui/src/theme/chrome.dart';
import 'package:macos_ui/src/layout/tab_view/tab_navigation.dart';

const _kTabViewRadius = BorderRadius.all(Radius.circular(5.0));

/// Specifies layout position for [MacosTab] options inside [MacosTabView].
enum MacosTabPosition {
  /// The left side of the [MacosTabView].
  left,

  /// The right side of the [MacosTabView].
  right,

  /// The top side of the [MacosTabView].
  top,

  /// The bottom side of the [MacosTabView].
  bottom,
}

/// {@template macosTabView}
/// A multipage interface that displays one page at a time.
///
// ignore: unintended_html_in_doc_comment
/// <image alt='' src='https://docs-assets.developer.apple.com/published/db00e4fdc8/tabview_2x_bf87676c-ac06-41f4-a430-0b95b43cd278.png' width='400' height='400' />
///
/// A tab view contains a row of navigational items, [tabs], that move the
/// user through the provided views ([children]). The user selects the desired
/// page by clicking the appropriate tab.
///
/// The tab controller's [MacosTabController.length] must equal the length of
/// the [children] list and the length of the [tabs] list.
/// {@endtemplate}
class MacosTabView extends StatefulWidget {
  /// {@macro macosTabView}
  const MacosTabView({
    super.key,
    required this.controller,
    required this.tabs,
    required this.children,
    this.position = MacosTabPosition.top,
    this.padding = const EdgeInsets.all(12.0),
  }) : assert(
         controller.length == children.length &&
             controller.length == tabs.length,
       );

  /// This widget's selection state.
  final MacosTabController controller;

  /// A list of navigational items, typically a length of two or more.
  final List<MacosTab> tabs;

  /// The views to navigate between.
  ///
  /// There must be one widget per tab.
  final List<Widget> children;

  /// The placement of the [tabs], typically [MacosTabPosition.top].
  final MacosTabPosition position;

  /// The padding of the tab view widget.
  ///
  /// Defaults to `EdgeInsets.all(12.0)`.
  final EdgeInsetsGeometry padding;

  @override
  State<MacosTabView> createState() => _MacosTabViewState();
}

class _MacosTabViewState extends State<MacosTabView> {
  late List<Widget> _childrenWithKey;
  int? _currentIndex;
  late final ScrollController _tabScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateChildren();
    widget.controller.addListener(_handleTabControllerTick);
    _currentIndex = widget.controller.index;
  }

  @override
  void didUpdateWidget(MacosTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleTabControllerTick);
      widget.controller.addListener(_handleTabControllerTick);
      _currentIndex = widget.controller.index;
    }
    if (widget.children != oldWidget.children) {
      _updateChildren();
    }
  }

  int get _tabRotation {
    switch (widget.position) {
      case MacosTabPosition.left:
        return 3;
      case MacosTabPosition.right:
        return 1;
      case MacosTabPosition.top:
        return 0;
      case MacosTabPosition.bottom:
        return 0;
    }
  }

  void _handleTabControllerTick() {
    if (widget.controller.index != _currentIndex) {
      _currentIndex = widget.controller.index;
    }
    setState(() {
      // Rebuild the children after an index change
      // has completed.
    });
  }

  void _updateChildren() {
    _childrenWithKey = KeyedSubtree.ensureUniqueKeysForList(widget.children);
  }

  @override
  void dispose() {
    _tabScroll.dispose();
    widget.controller.removeListener(_handleTabControllerTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      if (widget.controller.length != widget.children.length) {
        throw FlutterError(
          "Controller's length property (${widget.controller.length}) does not match the "
          "number of tabs (${widget.children.length}) present in TabBar's tabs property.",
        );
      }
      return true;
    }());

    assert(widget.controller.length == widget.tabs.length);
    final chrome = MacosChromeData.of(context);
    final vertical =
        widget.position == MacosTabPosition.left ||
        widget.position == MacosTabPosition.right;
    final content = Padding(
      padding: widget.padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: chrome.canvas,
          border: Border.all(color: chrome.separator),
          borderRadius: _kTabViewRadius,
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            for (var i = 0; i < _childrenWithKey.length; i++)
              ExcludeFocus(
                excluding: i != _currentIndex,
                child: ExcludeSemantics(
                  excluding: i != _currentIndex,
                  child: IgnorePointer(
                    ignoring: i != _currentIndex,
                    child: TickerMode(
                      enabled: i == _currentIndex,
                      child: _childrenWithKey[i],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (widget.tabs.isEmpty) return content;
    final tabs = RotatedBox(
      quarterTurns: _tabRotation,
      child: SingleChildScrollView(
        controller: _tabScroll,
        primary: false,
        scrollDirection: Axis.horizontal,
        child: TabNavigation(
          vertical: vertical,
          reversed: widget.position == MacosTabPosition.left,
          child: MacosSegmentedControl(
            controller: widget.controller,
            tabs: widget.tabs,
          ),
        ),
      ),
    );
    final tabsFirst =
        widget.position == MacosTabPosition.top ||
        widget.position == MacosTabPosition.left;
    return Flex(
      direction: vertical ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tabsFirst) tabs,
        Flexible(child: content),
        if (!tabsFirst) tabs,
      ],
    );
  }
}
