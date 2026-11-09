import 'package:macos_liquid_glass_ui/src/utils/transient_route.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';

const _kDialogBorderRadius = BorderRadius.all(Radius.circular(12.0));
const _kDefaultDialogConstraints = BoxConstraints(minWidth: 260, maxWidth: 260);

/// A macOS-style AlertDialog.
///
/// A [MacosAlertDialog] must display an [appIcon], [title], [message],
/// and [primaryButton].
///
/// To display a [MacosAlertDialog] call [showMacosAlertDialog].
/// ```dart
/// showMacosAlertDialog(
///    context: context,
///    builder: (_) => MacosAlertDialog(
///     appIcon: FlutterLogo(
///       size: 56,
///     ),
///     title: Text('Alert Dialog with Primary Action'),
///     message: Text(
///       'This is an alert dialog with a primary action and no secondary action',
///     ),
///     primaryButton: PushButton(
///       controlSize: ControlSize.large,
///       child: Text('Primary'),
///       onPressed: Navigator.of(context).pop,
///     ),
///   ),
/// ),
/// ```
class MacosAlertDialog extends StatelessWidget {
  /// Builds a macOS-style Alert Dialog
  const MacosAlertDialog({
    super.key,
    required this.appIcon,
    required this.title,
    required this.message,
    required this.primaryButton,
    this.secondaryButton,
    this.horizontalActions = true,
    this.suppress,
  });

  /// This should be your application's icon.
  ///
  /// The size of this widget should be 64x64.
  final Widget appIcon;

  /// The title for the dialog.
  ///
  /// Typically a Text widget.
  final Widget title;

  /// The content to display in the dialog.
  ///
  /// Typically a Text widget.
  final Widget message;

  /// The primary action a user can take.
  ///
  /// Must a [PushButton] with a [ControlSize] of `large`.
  final PushButton primaryButton;

  /// The secondary action a user can take.
  ///
  /// Must a [PushButton] with a [ControlSize] of `large`.
  final PushButton? secondaryButton;

  /// Determines whether to lay out [primaryButton] and [secondaryButton]
  /// horizontally or vertically.
  ///
  /// Defaults to `true`.
  final bool? horizontalActions;

  /// A widget to allow users to suppress alerts of this type.
  ///
  /// The logic for this should be user-implemented. Here is a sample of a
  /// widget that can be passed in for this parameter:
  /// ```dart
  /// class DoNotNotifyRow extends StatefulWidget {
  ///   const DoNotNotifyRow({Key? key}) : super(key: key);
  ///
  ///   @override
  ///   _DoNotNotifyRowState createState() => _DoNotNotifyRowState();
  /// }
  ///
  /// class _DoNotNotifyRowState extends State<DoNotNotifyRow> {
  ///   bool suppress = false;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Row(
  ///       mainAxisAlignment: MainAxisAlignment.center,
  ///       children: [
  ///         MacosCheckbox(
  ///  value: suppress,
  ///  onChanged: (value) {
  ///    setState(() => suppress = value);
  ///  },
  ///         ),
  ///         const SizedBox(width: 8),
  ///         Text('Don\'t ask again'),
  ///       ],
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// Notable, the above widget is a `StatefulWidget`. Your widget must be
  /// stateful or your checkbox will not update as you expect.
  final Widget? suppress;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    assert(primaryButton.controlSize == ControlSize.large);
    if (secondaryButton != null) {
      assert(secondaryButton is PushButton);
      assert(secondaryButton!.controlSize == ControlSize.large);
    }
    final chrome = MacosChromeData.of(context);

    final outerBorderColor = chrome.separator;
    final innerBorderColor = chrome.toolbar;

    return Dialog(
      backgroundColor: chrome.toolbar,
      shape: const RoundedRectangleBorder(borderRadius: _kDialogBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: innerBorderColor),
          borderRadius: _kDialogBorderRadius,
        ),
        foregroundDecoration: BoxDecoration(
          border: Border.all(width: 1, color: outerBorderColor),
          borderRadius: _kDialogBorderRadius,
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: _kDefaultDialogConstraints,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 64,
                    maxWidth: 64,
                  ),
                  child: appIcon,
                ),
                const SizedBox(height: 16),
                DefaultTextStyle(
                  style: MacosTheme.of(context).typography.headline,
                  textAlign: TextAlign.center,
                  child: title,
                ),
                const SizedBox(height: 10),
                DefaultTextStyle(
                  textAlign: TextAlign.center,
                  style: MacosTheme.of(context).typography.body,
                  child: message,
                ),
                const SizedBox(height: 16),
                if (secondaryButton == null) ...[
                  Row(children: [Expanded(child: primaryButton)]),
                ] else ...[
                  if ((horizontalActions ?? true) &&
                      MediaQuery.textScalerOf(context).scale(13) < 20) ...[
                    Row(
                      children: [
                        if (secondaryButton != null) ...[
                          Expanded(child: secondaryButton!),
                          const SizedBox(width: 8.0),
                        ],
                        Expanded(child: primaryButton),
                      ],
                    ),
                  ] else ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [Expanded(child: primaryButton)]),
                        const SizedBox(height: 8.0),
                        if (secondaryButton != null) ...[
                          Row(children: [Expanded(child: secondaryButton!)]),
                        ],
                      ],
                    ),
                  ],
                ],
                if (suppress != null) ...[
                  const SizedBox(height: 16),
                  DefaultTextStyle(
                    style: MacosTheme.of(context).typography.headline,
                    child: suppress!,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays a macos alert dialog above the current contents of the app.
Future<T?> showMacosAlertDialog<T>({
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
