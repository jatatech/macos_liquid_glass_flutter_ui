import 'package:macos_liquid_glass_ui/src/utils/transient_route.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

const _kSheetBorderRadius = BorderRadius.all(Radius.circular(12.0));
const EdgeInsets _defaultInsetPadding = EdgeInsets.symmetric(
  horizontal: 140.0,
  vertical: 48.0,
);

/// {@template macosSheet}
/// A Flutter modal surface within the selected Navigator. It prevents further
/// interaction until dismissed; it is not an AppKit window-attached sheet.
/// {@endtemplate}
class MacosSheet extends StatelessWidget {
  /// {@macro macosSheet}
  const MacosSheet({
    super.key,
    required this.child,
    this.insetPadding = _defaultInsetPadding,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
    this.backgroundColor,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// Default insets adapt to one eighth of a small viewport on each edge.
  /// Explicit custom insets are retained.
  /// The amount of padding added to [MediaQueryData.viewInsets] on the outside
  /// of the dialog. This defines the minimum space between the screen's edges
  /// and the dialog.
  final EdgeInsets? insetPadding;

  /// The duration of the animation to show when the system keyboard intrudes
  /// into the space that the dialog is placed in.
  final Duration insetAnimationDuration;

  /// The curve to use for the animation shown when the system keyboard intrudes
  /// into the space that the dialog is placed in.
  final Curve insetAnimationCurve;

  /// The background color for this widget.
  ///
  /// Defaults to the opaque semantic toolbar surface.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final chrome = MacosChromeData.of(context);

    final outerBorderColor = chrome.separator;
    final innerBorderColor = chrome.toolbar;

    final size = MediaQuery.sizeOf(context);
    final requested = insetPadding ?? EdgeInsets.zero;
    final EdgeInsets effectivePadding =
        MediaQuery.viewInsetsOf(context) +
        (insetPadding != _defaultInsetPadding
            ? requested
            : EdgeInsets.fromLTRB(
                requested.left.clamp(0, size.width / 8),
                requested.top.clamp(0, size.height / 8),
                requested.right.clamp(0, size.width / 8),
                requested.bottom.clamp(0, size.height / 8),
              ));

    return AnimatedPadding(
      padding: effectivePadding,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : insetAnimationDuration,
      curve: insetAnimationCurve,
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor ?? chrome.toolbar,
              borderRadius: _kSheetBorderRadius,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: innerBorderColor),
                borderRadius: _kSheetBorderRadius,
              ),
              foregroundDecoration: BoxDecoration(
                border: Border.all(width: 1, color: outerBorderColor),
                borderRadius: _kSheetBorderRadius,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays a [MacosSheet] above the current application.
Future<T?> showMacosSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  barrierColor ??= MacosDynamicColor.resolve(
    MacosColors.controlBackgroundColor,
    context,
  ).withValues(alpha: 0.6);

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    MacosTransientRoute<T>(
      settings: routeSettings,
      builder: builder,
      themes: InheritedTheme.capture(
        from: context,
        to: Navigator.of(context, rootNavigator: useRootNavigator).context,
      ),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel:
          barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}
