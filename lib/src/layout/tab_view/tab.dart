import 'package:macos_ui/src/library.dart';
import 'package:macos_ui/src/theme/chrome.dart';

const _kTabBorderRadius = BorderRadius.all(Radius.circular(4.0));

/// {@template macosTab}
/// A macOS-style navigational button used to move between the views of a
/// [MacosTabView].
/// {@endtemplate}
class MacosTab extends StatelessWidget {
  /// {@macro macosTab}
  const MacosTab({super.key, required this.label, this.active = false});

  /// The display label for this tab.
  final String label;

  /// Whether this [MacosTab] is currently selected. Handled internally by
  /// [MacosSegmentedControl]'s build function.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _kTabBorderRadius,
        color: active ? chrome.canvas : null,
        border: active ? Border.all(color: chrome.separator) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(label, style: TextStyle(color: chrome.foreground)),
      ),
    );
  }

  /// Copies this [MacosTab] into another.
  MacosTab copyWith({String? label, bool? active}) {
    return MacosTab(
      key: key,
      label: label ?? this.label,
      active: active ?? this.active,
    );
  }
}
