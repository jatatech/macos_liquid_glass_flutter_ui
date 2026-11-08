import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// Document workflow using only the package's exported transient surfaces.
class TransientSurfacesPage extends StatefulWidget {
  const TransientSurfacesPage({super.key});
  @override
  State<TransientSurfacesPage> createState() => _TransientSurfacesPageState();
}

class _TransientSurfacesPageState extends State<TransientSurfacesPage> {
  final _details = GlobalKey<ToolbarPopupState<void>>();
  String _status = 'Draft';
  bool _reviewOpen = false;
  bool _archiveOpen = false;

  Future<void> _archive() async {
    if (_archiveOpen) return;
    _archiveOpen = true;
    final confirmed = await showMacosAlertDialog<bool>(
      context: context,
      builder: (dialogContext) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.archivebox, size: 48),
        title: const Text('Archive design brief?'),
        message: const Text(
          'The working copy will become read only. You can cancel to keep editing.',
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Archive'),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
      ),
    );
    _archiveOpen = false;
    if (mounted && confirmed == true) setState(() => _status = 'Archived');
  }

  Future<void> _review() async {
    if (_reviewOpen) return;
    _reviewOpen = true;
    final approved = await showMacosSheet<bool>(
      context: context,
      builder: (sheetContext) => MacosSheet(
        child: Padding(
          padding: const EdgeInsets.all(MacosChromeData.contentInset),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review design brief',
                  style: MacosTheme.of(sheetContext).typography.title1,
                ),
                const SizedBox(height: MacosChromeData.gap),
                const Text(
                  'Check the summary before marking this working copy ready. Escape cancels without changing the document.',
                ),
                const SizedBox(height: MacosChromeData.gap),
                const MacosTextField(placeholder: 'Review note', maxLines: 3),
                const SizedBox(height: MacosChromeData.contentInset),
                Wrap(
                  spacing: MacosChromeData.gap,
                  runSpacing: MacosChromeData.gap,
                  children: [
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: const Text('Mark ready'),
                    ),
                    PushButton(
                      controlSize: ControlSize.large,
                      secondary: true,
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: const Text('Cancel review'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _reviewOpen = false;
    if (mounted && approved == true) {
      setState(() => _status = 'Ready for review');
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Design brief', style: MacosTheme.of(context).typography.title1),
      const SizedBox(height: MacosChromeData.gap),
      Semantics(liveRegion: true, child: Text('Document status: $_status')),
      const SizedBox(height: MacosChromeData.contentInset),
      Wrap(
        spacing: MacosChromeData.gap,
        runSpacing: MacosChromeData.gap,
        children: [
          MacosPulldownButton(
            title: 'Document actions',
            items: [
              MacosPulldownMenuItem(
                title: const Text('Review changes…'),
                onTap: _review,
              ),
              const MacosPulldownMenuDivider(),
              MacosPulldownMenuItem(
                title: const Text('Archive document…'),
                onTap: _archive,
              ),
              const MacosPulldownMenuItem(
                title: Text('Restore previous version'),
                enabled: false,
              ),
            ],
          ),
          ToolbarPopup<void>(
            key: _details,
            position: ToolbarPopupPosition.below,
            placement: ToolbarPopupPlacement.start,
            content: (popupContext) => ToolbarOverflowMenu(
              children: [
                const Padding(
                  padding: EdgeInsets.all(MacosChromeData.gap),
                  child: SizedBox(
                    width: 240,
                    child: Text(
                      'Design brief\nWorking copy · edited today\nFlutter anchored surface',
                    ),
                  ),
                ),
                ToolbarOverflowMenuItem(
                  label: 'Close details',
                  onPressed: () {},
                ),
              ],
            ),
            child: MacosTooltip(
              message: 'Inspect the working copy without changing it',
              child: PushButton(
                controlSize: ControlSize.large,
                secondary: true,
                onPressed: () => _details.currentState?.openPopup(),
                child: const Text('Document details'),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: MacosChromeData.contentInset),
      const Text(
        'Use Enter or Space to open commands; arrows navigate menus. Escape closes the current surface and returns focus. Clicking outside dismisses menus and details; review and archive require an explicit choice.',
      ),
    ],
  );
}
