import 'dart:math' as math;

import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/utils/transient_anchor.dart';

import 'package:macos_ui/src/library.dart';

/// Where the popup will be placed vertically relative to the child
enum ToolbarPopupPosition {
  /// The popup will be above the child, if there is enough space available
  above,

  /// The popup will be below the child, if there is enough space available
  below,

  /// The popup will be by the side of the child, if there is enough space
  /// available
  side,
}

/// How the popup will be placed relative to the child
enum ToolbarPopupPlacement {
  /// The popup will be placed on the start point of the child.
  start,

  /// The popup will be placed on the center of the child.
  center,

  /// The popup will be placed on the end point of the child.
  end,
}

/// {@template toolbarPopup}
/// A popup widget for the toolbar.
///
/// Used for the menu that encapsulates the overflowed toolbar actions and
/// its possible submenus.
/// {@endtemplate}
class ToolbarPopup<T> extends StatefulWidget {
  /// {@macro toolbarPopup}
  const ToolbarPopup({
    super.key,
    required this.child,
    required this.content,
    this.verticalOffset = 0,
    this.horizontalOffset = 0,
    this.placement = ToolbarPopupPlacement.center,
    this.position = ToolbarPopupPosition.above,
  });

  /// The child widget to show in the popup
  final Widget child;

  /// The content of the popup
  final WidgetBuilder content;

  /// The vertical offset of the popup
  final double verticalOffset;

  /// The horizontal offset of the popup
  final double horizontalOffset;

  /// The placement of the popup.
  ///
  /// Defaults to [ToolbarPopupPlacement.center].
  final ToolbarPopupPlacement placement;

  /// The position of the popup.
  ///
  /// Defaults to [ToolbarPopupPosition.above].
  final ToolbarPopupPosition position;

  @override
  ToolbarPopupState<T> createState() => ToolbarPopupState<T>();
}

class ToolbarPopupState<T> extends State<ToolbarPopup<T>>
    with WidgetsBindingObserver {
  _ToolbarPopupRoute<T>? _dropdownRoute;
  late final _anchor = TransientAnchorWatch(
    () => context,
    removeToolbarPopupRoute,
  );
  final _triggerFocus = FocusNode(skipTraversal: true, canRequestFocus: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => removeToolbarPopupRoute();

  Object? _environment;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final environment = (MacosTheme.of(context), MediaQuery.maybeOf(context));
    if (_environment != null && _environment != environment) {
      final route = _dropdownRoute;
      _dropdownRoute = null;
      _anchor.cancel();
      if (route != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => route._dismiss());
      }
    }
    _environment = environment;
  }

  Future<void> openPopup() {
    if (!mounted || _dropdownRoute != null) return Future.value();
    final sourceRoute = ModalRoute.of(context);
    final primary = FocusManager.instance.primaryFocus;
    final candidates = _triggerFocus.traversalDescendants.where(
      (node) => node.canRequestFocus && !node.skipTraversal,
    );
    final previousFocus =
        primary != null && primary.ancestors.contains(_triggerFocus)
        ? primary
        : candidates.firstOrNull ?? primary;
    final NavigatorState navigator = Navigator.of(context);
    final RenderBox itemBox = context.findRenderObject()! as RenderBox;
    Offset leftTarget = itemBox.localToGlobal(
      itemBox.size.centerLeft(Offset.zero),
      ancestor: navigator.context.findRenderObject(),
    );
    Offset centerTarget = itemBox.localToGlobal(
      itemBox.size.center(Offset.zero),
      ancestor: navigator.context.findRenderObject(),
    );
    Offset rightTarget = itemBox.localToGlobal(
      itemBox.size.centerRight(Offset.zero),
      ancestor: navigator.context.findRenderObject(),
    );

    assert(debugCheckHasDirectionality(context));

    final directionality = Directionality.of(context);
    // The target according to the current directionality.
    final Offset directionalityTarget = () {
      switch (widget.placement) {
        case ToolbarPopupPlacement.start:
          if (directionality == TextDirection.ltr) {
            return leftTarget;
          } else {
            return rightTarget;
          }
        case ToolbarPopupPlacement.end:
          if (directionality == TextDirection.ltr) {
            return rightTarget;
          } else {
            return leftTarget;
          }
        case ToolbarPopupPlacement.center:
          return centerTarget;
      }
    }();

    // The placement according to the current directionality.
    final ToolbarPopupPlacement directionalityPlacement = () {
      switch (widget.placement) {
        case ToolbarPopupPlacement.start:
          if (directionality == TextDirection.rtl) {
            return ToolbarPopupPlacement.end;
          }
          continue next;
        case ToolbarPopupPlacement.end:
          if (directionality == TextDirection.rtl) {
            return ToolbarPopupPlacement.start;
          }
          continue next;
        next:
        default:
          return widget.placement;
      }
    }();

    final Rect itemRect = directionalityTarget & itemBox.size;
    _dropdownRoute = _ToolbarPopupRoute<T>(
      target: directionalityTarget,
      placementOffset: directionalityTarget,
      placement: directionalityPlacement,
      position: widget.position,
      content: _ToolbarPopupContentManager(content: widget.content),
      buttonRect: itemRect,
      elevation: 4,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      transitionAnimationDuration: const Duration(milliseconds: 100),
      verticalOffset: widget.verticalOffset,
      horizontalOffset: widget.horizontalOffset,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    );
    final route = _dropdownRoute!;
    final result = navigator.push(route);
    _anchor.watch();
    return result.then((T? newValue) {
      if (!identical(_dropdownRoute, route)) return;
      _anchor.cancel();
      if (identical(_dropdownRoute, route)) _dropdownRoute = null;
      if (!mounted) return;
      if (sourceRoute?.isCurrent == true &&
          previousFocus?.context != null &&
          previousFocus!.canRequestFocus) {
        previousFocus.requestFocus();
      }
    });
  }

  bool get isOpen => _dropdownRoute != null;

  void removeToolbarPopupRoute() {
    _anchor.cancel();
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _triggerFocus.dispose();
    removeToolbarPopupRoute();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return Focus(focusNode: _triggerFocus, child: widget.child);
  }
}

class _ToolbarPopupMenu<T> extends StatefulWidget {
  const _ToolbarPopupMenu({
    super.key,
    required this.route,
    required this.buttonRect,
    required this.constraints,
    this.dropdownColor,
  });

  final _ToolbarPopupRoute<T> route;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final Color? dropdownColor;

  @override
  _ToolbarPopupMenuState<T> createState() => _ToolbarPopupMenuState<T>();
}

class _ToolbarPopupMenuState<T> extends State<_ToolbarPopupMenu<T>> {
  late CurvedAnimation _fadeOpacity;

  @override
  void initState() {
    super.initState();
    _fadeOpacity = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.0, 0.5),
      reverseCurve: const Interval(0.75, 1.0),
    );
  }

  @override
  void dispose() {
    _fadeOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: reduceMotion ? const AlwaysStoppedAnimation(1.0) : _fadeOpacity,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        child: widget.route.content,
      ),
    );
  }
}

class _ToolbarPopupMenuRouteLayout<T> extends SingleChildLayoutDelegate {
  _ToolbarPopupMenuRouteLayout({
    required this.buttonRect,
    required this.route,
    required this.textDirection,
    required this.target,
    required this.verticalOffset,
    required this.horizontalOffset,
    required this.placementOffset,
    required this.placement,
    required this.position,
  });

  final Rect buttonRect;
  final _ToolbarPopupRoute<T> route;
  final TextDirection? textDirection;
  final Offset target;
  final double verticalOffset;
  final double horizontalOffset;
  final Offset placementOffset;
  final ToolbarPopupPlacement placement;
  final ToolbarPopupPosition position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen().deflate(
      EdgeInsets.all(math.max(0, horizontalOffset)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final defaultOffset = position == ToolbarPopupPosition.side
        ? horizontalPositionDependentBox(
            size: size,
            childSize: childSize,
            target: target,
            verticalOffset: verticalOffset,
            margin: horizontalOffset,
            preferLeft: placement == ToolbarPopupPlacement.end,
          )
        : positionDependentBox(
            size: size,
            childSize: childSize,
            target: target,
            verticalOffset: verticalOffset,
            preferBelow: position == ToolbarPopupPosition.below,
            margin: horizontalOffset,
          );
    final double x;
    if (position == ToolbarPopupPosition.side) {
      x = defaultOffset.dx;
    } else {
      x = switch (placement) {
        ToolbarPopupPlacement.start => placementOffset.dx,
        ToolbarPopupPlacement.end => placementOffset.dx - childSize.width,
        ToolbarPopupPlacement.center => defaultOffset.dx,
      };
    }
    return Offset(
      x.clamp(0, math.max(0, size.width - childSize.width)),
      defaultOffset.dy.clamp(0, math.max(0, size.height - childSize.height)),
    );
  }

  @override
  bool shouldRelayout(_ToolbarPopupMenuRouteLayout<T> oldDelegate) {
    return oldDelegate.target != target ||
        oldDelegate.placementOffset != placementOffset ||
        buttonRect != oldDelegate.buttonRect;
  }
}

class _ToolbarPopupRoute<T> extends PopupRoute<T> {
  _ToolbarPopupRoute({
    required this.content,
    required this.buttonRect,
    required this.target,
    required this.placementOffset,
    required this.placement,
    this.elevation = 8,
    required this.capturedThemes,
    required this.transitionAnimationDuration,
    this.barrierLabel,
    required this.verticalOffset,
    required this.horizontalOffset,
    required this.position,
  });

  final Widget content;
  final Rect buttonRect;
  final int elevation;
  final CapturedThemes capturedThemes;
  final double verticalOffset;
  final double horizontalOffset;

  final Duration transitionAnimationDuration;

  final Offset target;
  final Offset placementOffset;
  final ToolbarPopupPlacement placement;
  final ToolbarPopupPosition position;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(context, animation, secondaryAnimation) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _ToolbarPopupRoutePage<T>(
          target: target,
          placementOffset: placementOffset,
          placement: placement,
          route: this,
          constraints: constraints,
          content: content,
          buttonRect: buttonRect,
          elevation: elevation,
          capturedThemes: capturedThemes,
          verticalOffset: verticalOffset,
          horizontalOffset: horizontalOffset,
          position: position,
        );
      },
    );
  }

  void _dismiss() {
    if (isActive) {
      navigator?.removeRoute(this);
    }
  }
}

class _ToolbarPopupRoutePage<T> extends StatelessWidget {
  const _ToolbarPopupRoutePage({
    super.key,
    required this.route,
    required this.constraints,
    required this.content,
    required this.buttonRect,
    this.elevation = 8,
    required this.capturedThemes,
    required this.verticalOffset,
    required this.horizontalOffset,
    this.style,
    required this.target,
    required this.placement,
    required this.placementOffset,
    required this.position,
  });

  final _ToolbarPopupRoute<T> route;
  final BoxConstraints constraints;
  final Widget content;
  final Rect buttonRect;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle? style;
  final double verticalOffset;
  final double horizontalOffset;
  final Offset target;
  final Offset placementOffset;
  final ToolbarPopupPlacement placement;
  final ToolbarPopupPosition position;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final TextDirection? textDirection = Directionality.maybeOf(context);
    final Widget menu = _ToolbarPopupMenu<T>(
      route: route,
      buttonRect: buttonRect,
      constraints: constraints,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _ToolbarPopupMenuRouteLayout<T>(
              target: target,
              placement: placement,
              position: position,
              placementOffset: placementOffset,
              buttonRect: buttonRect,
              route: route,
              textDirection: textDirection,
              verticalOffset: verticalOffset,
              horizontalOffset: horizontalOffset,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}

class _ToolbarPopupContentManager extends StatefulWidget {
  // ignore: use_super_parameters
  const _ToolbarPopupContentManager({Key? key, required this.content})
    : super(key: key);

  final WidgetBuilder content;

  @override
  State<_ToolbarPopupContentManager> createState() =>
      _ToolbarPopupContentManagerState();
}

class _ToolbarPopupContentManagerState
    extends State<_ToolbarPopupContentManager> {
  final GlobalKey key = GlobalKey();

  Size size = Size.zero;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final context = key.currentContext;
      if (context == null) return;
      final RenderBox box = context.findRenderObject() as RenderBox;
      setState(() => size = box.size);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: _ToolbarPopupContentSizeInfo(
        size: size,
        child: widget.content(context),
      ),
    );
  }
}

class _ToolbarPopupContentSizeInfo extends InheritedWidget {
  // ignore: use_super_parameters
  const _ToolbarPopupContentSizeInfo({
    Key? key,
    required super.child,
    required this.size,
  }) : super(key: key);

  final Size size;

  @override
  bool updateShouldNotify(_ToolbarPopupContentSizeInfo oldWidget) {
    return oldWidget.size != size;
  }
}

Offset horizontalPositionDependentBox({
  required Size size,
  required Size childSize,
  required Offset target,
  required bool preferLeft,
  double verticalOffset = 0.0,
  double margin = 10.0,
}) {
  // Horizontal DIRECTION
  final bool fitsLeft =
      target.dx + verticalOffset + childSize.width <= size.width - margin;
  final bool fitsRight = target.dx - verticalOffset - childSize.width >= margin;
  final bool tooltipLeft = preferLeft
      ? fitsLeft || !fitsRight
      : !(fitsRight || !fitsLeft);
  double x;
  if (tooltipLeft) {
    x = math.min(target.dx + verticalOffset, size.width - margin);
  } else {
    x = math.max(target.dx - verticalOffset - childSize.width, margin);
  }
  // Vertical DIRECTION
  double y;
  if (size.height - margin * 2.0 < childSize.height) {
    y = (size.height - childSize.height) / 2.0;
  } else {
    final double normalizedTargetY = target.dy.clamp(
      margin,
      size.height - margin,
    );
    final double edge = margin + childSize.height / 2.0;
    if (normalizedTargetY < edge) {
      y = margin;
    } else if (normalizedTargetY > size.height - edge) {
      y = size.height - margin - childSize.height;
    } else {
      y = normalizedTargetY - childSize.height / 2.0;
    }
  }
  return Offset(x, y);
}
