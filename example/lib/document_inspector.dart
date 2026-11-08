import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// Readable document metadata using only public package imports.
class DocumentInspector extends StatefulWidget {
  const DocumentInspector({
    super.key,
    this.title = 'Field notes — coastal habitat restoration, November 2026',
    this.readOnly = false,
  });

  final String title;
  final bool readOnly;

  @override
  State<DocumentInspector> createState() => _DocumentInspectorState();
}

class _DocumentInspectorState extends State<DocumentInspector> {
  double _rating = 3;
  double _budget = 60;
  bool _editable = true;
  double _savedRating = 3;
  double _savedBudget = 60;
  String _status = 'No unsaved metadata changes.';
  bool get _canEdit => _editable && !widget.readOnly;
  void _edit(VoidCallback change) => setState(() {
    change();
    _status = _rating != _savedRating || _budget != _savedBudget
        ? 'Unsaved metadata changes.'
        : 'No unsaved metadata changes.';
  });
  bool _contrast = false;
  bool _reduceEffects = false;
  bool _largeText = false;
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        highContrast: media.highContrast || _contrast,
        disableAnimations: media.disableAnimations || _reduceEffects,
        accessibleNavigation: media.accessibleNavigation || _reduceEffects,
        textScaler: _largeText ? const TextScaler.linear(2) : media.textScaler,
      ),
      child: Directionality(
        textDirection: _rtl ? TextDirection.rtl : Directionality.of(context),
        child: Builder(
          builder: (context) {
            final chrome = MacosChromeData.of(context);
            return ColoredBox(
              color: chrome.canvas,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Label(
                    icon: const MacosIcon(CupertinoIcons.doc_text),
                    text: Text(
                      widget.title,
                      style: MacosTheme.of(context).typography.title2,
                    ),
                  ),
                  const SizedBox(height: MacosChromeData.gap),
                  const Text('Document inspector'),
                  const Text(
                    'Local metadata for a 24-page working document. '
                    'Rating and offline allocation changes stay in this example.',
                  ),
                  const SizedBox(height: MacosChromeData.contentInset),
                  Text('Editorial rating: ${_rating.round()} of 5'),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: RatingIndicator(
                      value: _rating,
                      iconSize: 24,
                      semanticLabel: 'Editorial rating',
                      onChanged: _canEdit
                          ? (value) => _edit(() => _rating = value)
                          : null,
                    ),
                  ),
                  const SizedBox(height: MacosChromeData.contentInset),
                  Text('Offline allocation: ${_budget.round()} percent'),
                  CapacityIndicator(
                    value: _budget,
                    discrete: true,
                    semanticLabel: 'Offline allocation',
                    onChanged: _canEdit
                        ? (value) => _edit(() => _budget = value)
                        : null,
                  ),
                  const SizedBox(height: MacosChromeData.gap),
                  const Text('Storage used: 72 percent · read only'),
                  const CapacityIndicator(
                    value: 72,
                    semanticLabel: 'Storage used',
                  ),
                  const SizedBox(height: MacosChromeData.gap),
                  const Text('Search relevance · legacy read-only comparison'),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    // Deliberate compatibility example for the retained deprecated API.
                    // ignore: deprecated_member_use
                    child: const RelevanceIndicator(
                      value: 14,
                      semanticLabel: 'Search relevance',
                    ),
                  ),
                  const SizedBox(height: MacosChromeData.contentInset),
                  Wrap(
                    spacing: MacosChromeData.gap,
                    runSpacing: MacosChromeData.gap,
                    children: [
                      PushButton(
                        controlSize: ControlSize.regular,
                        onPressed:
                            _canEdit &&
                                (_rating != _savedRating ||
                                    _budget != _savedBudget)
                            ? () => setState(() {
                                _savedRating = _rating;
                                _savedBudget = _budget;
                                _status = 'Metadata saved in this session.';
                              })
                            : null,
                        child: const Text('Save metadata'),
                      ),
                      PushButton(
                        controlSize: ControlSize.regular,
                        onPressed:
                            _canEdit &&
                                (_rating != _savedRating ||
                                    _budget != _savedBudget)
                            ? () => setState(() {
                                _rating = _savedRating;
                                _budget = _savedBudget;
                                _status = 'Changes reverted.';
                              })
                            : null,
                        child: const Text('Revert metadata'),
                      ),
                    ],
                  ),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      widget.readOnly
                          ? 'Archived document — metadata is read only.'
                          : _status,
                    ),
                  ),
                  const Text('Inspector preview settings'),
                  _option(
                    'Allow metadata edits',
                    _editable,
                    (v) => setState(() => _editable = v),
                  ),
                  _option(
                    'Increase contrast locally',
                    _contrast,
                    (v) => setState(() => _contrast = v),
                  ),
                  _option(
                    'Reduce effects locally',
                    _reduceEffects,
                    (v) => setState(() => _reduceEffects = v),
                  ),
                  _option(
                    'Double text size locally',
                    _largeText,
                    (v) => setState(() => _largeText = v),
                  ),
                  _option(
                    'Right-to-left layout locally',
                    _rtl,
                    (v) => setState(() => _rtl = v),
                  ),
                  const SizedBox(height: MacosChromeData.gap),
                  const Text(
                    'Tab to an editable indicator. Use arrows or Home/End. '
                    'Pointer edits update immediately; Save retains this session draft and Revert restores it. '
                    'Read-only indicators remain readable and leave the tab order. '
                    'Open Liquid Glass in the sidebar for the native navigation and command example.',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _option(String label, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: MacosChromeData.gap / 2),
        child: Row(
          children: [
            MacosCheckbox(
              value: value,
              semanticLabel: label,
              onChanged: onChanged,
            ),
            const SizedBox(width: MacosChromeData.gap),
            Expanded(child: Text(label)),
          ],
        ),
      );
}
