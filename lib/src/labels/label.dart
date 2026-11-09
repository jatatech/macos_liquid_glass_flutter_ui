import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';
import 'package:macos_liquid_glass_ui/src/utils/content_color.dart';

/// A label is a static text field that describes an onscreen interface
/// element or provides a short message. Although people can’t edit labels,
/// they can sometimes copy label contents.
///
/// ![Label Example](https://developer.apple.com/design/human-interface-guidelines/macos/images/labels.png)
class Label extends StatelessWidget {
  /// Creates a label.
  const Label({
    super.key,
    this.icon,
    required this.text,
    this.child,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// The icon used by the label. If non-null, it's rendered horizontally
  /// before [text].
  ///
  /// Usually an [Icon].
  final Widget? icon;

  /// The text of the label. Usually a [Text]. To make it selectable, use
  /// [SelectableText] instead
  final Widget text;

  /// The widget at the right of [text].
  final Widget? child;

  /// The cross-axis alignment of the label.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);
    final text = DefaultTextStyle(
      style: (theme.typography.body).copyWith(
        color: resolveContentColor(CupertinoColors.label, context),
        fontWeight: FontWeight.w500,
      ),
      child: this.text,
    );
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: IconTheme(
              data: IconThemeData(
                size: theme.typography.body.fontSize ?? 24,
                color: theme.primaryColor,
              ),
              child: icon!,
            ),
          ),
        Flexible(child: text),
        ?child,
      ],
    );
  }
}
