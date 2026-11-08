import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

/// Real Flutter document covers under a native sibling command bar.
class LiquidGlassPage extends StatefulWidget {
  const LiquidGlassPage({super.key});
  @override
  State<LiquidGlassPage> createState() => _LiquidGlassPageState();
}

class _LiquidGlassPageState extends State<LiquidGlassPage> {
  final _scroll = ScrollController();
  final _commandsFocus = FocusNode(debugLabel: 'Gallery native commands');
  bool _opaque = false;
  bool _dense = false;
  MacosGlassRendering _navigationRendering = MacosGlassRendering.opaque;
  bool _show = true;
  bool _contrast = false;
  bool _motion = false;
  bool _largeText = false;
  int _document = 0;
  MacosGlassRendering _rendering = MacosGlassRendering.opaque;
  static const _titles = [
    'Coastal survey',
    'Autumn field notes',
    'Forest census',
    'Clay studies',
  ];
  static const _coverColors = [
    Color(0xFF176EBA),
    Color(0xFFBA710F),
    Color(0xFF26744B),
    Color(0xFFA84232),
  ];

  @override
  void dispose() {
    _scroll.dispose();
    _commandsFocus.dispose();
    super.dispose();
  }

  void _move(int delta) {
    setState(() => _document = (_document + delta) % _titles.length);
    final target = (_document * 240.0).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if (MediaQuery.disableAnimationsOf(context) || _motion) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    final type = MacosTheme.of(context).typography;
    final content = ListView.builder(
      key: const ValueKey('glass-documents'),
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: 12,
      itemBuilder: (context, index) {
        final cover = index % _titles.length;
        if (_dense) {
          return Container(
            color: chrome.canvas,
            padding: EdgeInsets.fromLTRB(
              MacosChromeData.contentInset,
              index == 0 ? 96 : MacosChromeData.contentInset,
              MacosChromeData.contentInset,
              MacosChromeData.contentInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}. ${_titles[cover]}', style: type.title2),
                const SizedBox(height: MacosChromeData.gap),
                Text(
                  'Survey record · 8 November 2026\n'
                  'Site observations and source references remain on an opaque '
                  'document canvas. Navigation and actions float above this '
                  'scrolling collection without applying blur to the text itself.',
                  style: type.body,
                ),
                const SizedBox(height: MacosChromeData.gap),
                Text(
                  'Status: reviewed · Collection: field studies',
                  style: type.caption1,
                ),
              ],
            ),
          );
        }
        return Container(
          constraints: const BoxConstraints(minHeight: 240),
          color: _coverColors[cover],
          padding: EdgeInsets.fromLTRB(
            MacosChromeData.contentInset,
            index == 0 ? 96 : MacosChromeData.contentInset,
            MacosChromeData.contentInset,
            MacosChromeData.contentInset,
          ),
          child: DefaultTextStyle(
            style: type.body.copyWith(color: CupertinoColors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _titles[cover],
                  style: type.largeTitle.copyWith(color: CupertinoColors.white),
                ),
                const SizedBox(height: MacosChromeData.gap),
                Text('Document ${index + 1} · Working collection'),
                const SizedBox(height: 64),
                const Text('Observations, references and field drawings'),
                const SizedBox(height: MacosChromeData.gap),
                const Text(
                  'Scroll these Flutter covers beneath the stationary AppKit commands.',
                ),
              ],
            ),
          ),
        );
      },
    );
    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: chrome.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.5,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(MacosChromeData.gap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Liquid Glass', style: type.title1),
                      const SizedBox(height: MacosChromeData.gap / 2),
                      Text(
                        'Commands: ${_rendering.name} · Navigation: ${_navigationRendering.name}',
                      ),
                      const SizedBox(height: MacosChromeData.gap / 2),
                      Wrap(
                        spacing: MacosChromeData.gap,
                        runSpacing: MacosChromeData.gap / 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          PushButton(
                            controlSize: ControlSize.regular,
                            onPressed: () => setState(() => _opaque = !_opaque),
                            child: Text(
                              _opaque
                                  ? 'Use automatic glass'
                                  : 'Compare opaque',
                            ),
                          ),
                          PushButton(
                            controlSize: ControlSize.regular,
                            onPressed: () =>
                                setState(() => _contrast = !_contrast),
                            child: Text('Test contrast: $_contrast'),
                          ),
                          PushButton(
                            controlSize: ControlSize.regular,
                            onPressed: () => setState(() => _motion = !_motion),
                            child: Text('Test reduced motion: $_motion'),
                          ),
                          PushButton(
                            controlSize: ControlSize.regular,
                            onPressed: () =>
                                setState(() => _largeText = !_largeText),
                            child: Text('Test large text: $_largeText'),
                          ),
                          PushButton(
                            controlSize: ControlSize.regular,
                            onPressed:
                                _show &&
                                    _rendering == MacosGlassRendering.native
                                ? () => _commandsFocus.requestFocus()
                                : null,
                            child: const Text('Focus commands'),
                          ),
                          PushButton(
                            controlSize: ControlSize.regular,
                            onPressed: () => showMacosAlertDialog<void>(
                              context: context,
                              builder: (dialogContext) => MacosAlertDialog(
                                appIcon: const MacosIcon(CupertinoIcons.doc),
                                title: const Text('Glass temporarily covered'),
                                message: const Text(
                                  'Escape returns to the document.',
                                ),
                                primaryButton: PushButton(
                                  controlSize: ControlSize.large,
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('Done'),
                                ),
                              ),
                            ),
                            child: const Text('Test dialog'),
                          ),
                          if (!_show)
                            PushButton(
                              controlSize: ControlSize.regular,
                              onPressed: () => setState(() => _show = true),
                              child: const Text('Show commands'),
                            ),
                          Text('Selected: ${_titles[_document]}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _show
                  ? MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        highContrast:
                            MediaQuery.highContrastOf(context) || _contrast,
                        disableAnimations:
                            MediaQuery.disableAnimationsOf(context) || _motion,
                        textScaler: _largeText
                            ? const TextScaler.linear(2)
                            : MediaQuery.textScalerOf(context),
                      ),
                      child: MacosGlassCommandSurface(
                        focusNode: _commandsFocus,
                        forceOpaque: _opaque,
                        onRenderingChanged: (mode) =>
                            setState(() => _rendering = mode),
                        commands: [
                          MacosGlassCommand(
                            label: 'Previous',
                            onPressed: () => _move(-1),
                          ),
                          MacosGlassCommand(
                            label: 'Next',
                            onPressed: () => _move(1),
                          ),
                          MacosGlassCommand(
                            label: 'Hide',
                            onPressed: () => setState(() {
                              _show = false;
                              _rendering = MacosGlassRendering.opaque;
                            }),
                          ),
                        ],
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            content,
                            Positioned(
                              top: MacosGlassData.commandInset,
                              left: MacosGlassData.commandInset,
                              right: MacosGlassData.commandInset,
                              child: MacosGlassSurface(
                                forceOpaque: _opaque,
                                onRenderingChanged: (mode) =>
                                    setState(() => _navigationRendering = mode),
                                nativeCommands: [
                                  MacosGlassCommand(
                                    label: _dense ? 'Covers' : '✓ Covers',
                                    onPressed: () =>
                                        setState(() => _dense = false),
                                  ),
                                  MacosGlassCommand(
                                    label: _dense ? '✓ Notes' : 'Notes',
                                    onPressed: () =>
                                        setState(() => _dense = true),
                                  ),
                                  const MacosGlassCommand(label: 'Archived'),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    MacosChromeData.gap,
                                  ),
                                  child: Wrap(
                                    spacing: MacosChromeData.gap,
                                    runSpacing: MacosChromeData.gap,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      PushButton(
                                        controlSize: ControlSize.regular,
                                        onPressed: () =>
                                            setState(() => _dense = false),
                                        child: Text(
                                          _dense ? 'Covers' : '✓ Covers',
                                        ),
                                      ),
                                      PushButton(
                                        controlSize: ControlSize.regular,
                                        onPressed: () =>
                                            setState(() => _dense = true),
                                        child: Text(
                                          _dense ? '✓ Notes' : 'Notes',
                                        ),
                                      ),
                                      const PushButton(
                                        controlSize: ControlSize.regular,
                                        onPressed: null,
                                        child: Text('Archived'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : content,
            ),
          ],
        ),
      ),
    );
  }
}
