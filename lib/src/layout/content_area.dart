import 'package:macos_ui/src/layout/scaffold.dart';
import 'package:macos_ui/src/library.dart';

/// The widget that fills the rest of the body of the macOS [MacosScaffold].
///
/// A [MacosScaffold] can contain only one [ContentArea].
class ContentArea extends StatefulWidget {
  /// Creates a widget that fills the body of the scaffold.
  /// The [builder] can be null to show an empty widget.
  ///
  /// The width of this
  /// widget is automatically calculated in [MacosScaffoldScope].
  const ContentArea({required this.builder, this.minWidth = 300})
    : super(key: const Key('macos_scaffold_content_area'));

  /// The builder that creates a child to display in this widget.
  final ScrollableWidgetBuilder? builder;

  /// Specifies the minimum width that this [ContentArea] can have.
  final double minWidth;

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand().copyWith(
        minWidth: widget.minWidth,
      ),
      child: SafeArea(
        left: false,
        right: false,
        child:
            widget.builder?.call(context, _controller) ??
            const SizedBox.shrink(),
      ),
    );
  }
}
