import 'package:flutter/services.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

/// Shared modal ownership for Flutter alert and sheet surfaces.
class MacosTransientRoute<T> extends PopupRoute<T> {
  MacosTransientRoute({
    required this.builder,
    required this.themes,
    required this.barrierDismissible,
    required this.barrierColor,
    required this.barrierLabel,
    super.settings,
  }) : super(traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);

  final WidgetBuilder builder;
  final CapturedThemes themes;
  @override
  final bool barrierDismissible;
  @override
  final Color? barrierColor;
  @override
  final String? barrierLabel;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 100);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => themes.wrap(
    SafeArea(
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          onKeyEvent: (_, event) {
            if (event.logicalKey != LogicalKeyboardKey.escape) {
              return KeyEventResult.ignored;
            }
            // Escape is an explicit cancellation even for a non-clickable
            // barrier. maybePop respects an application's PopScope veto.
            if (event is KeyDownEvent && isCurrent) navigator?.maybePop();
            return KeyEventResult.handled;
          },
          child: Builder(builder: builder),
        ),
      ),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // A reversing surface is visually present only; it cannot receive focus,
    // pointers or semantic actions, even if reduction of motion changes live.
    final exiting = animation.status == AnimationStatus.reverse || !isCurrent;
    final content = ExcludeFocus(
      excluding: exiting,
      child: ExcludeSemantics(
        excluding: exiting,
        child: IgnorePointer(ignoring: exiting, child: child),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return content;
    return FadeTransition(opacity: animation, child: content);
  }
}
