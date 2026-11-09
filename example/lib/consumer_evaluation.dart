// M7.3 consumer fixtures. Shell pattern adapted from developer_example.dart.
// Upstream macos_ui MIT attribution: ../../NOTICE.md and ../../LICENSE.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

Future<void> main() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    await const MacosWindowUtilsConfig().apply();
  }
  runApp(const ConsumerEvaluation());
}

/// Six bounded skill tasks share this session-only consumer shell.
class ConsumerEvaluation extends StatefulWidget {
  const ConsumerEvaluation({super.key});

  @override
  State<ConsumerEvaluation> createState() => _ConsumerEvaluationState();
}

class _ConsumerEvaluationState extends State<ConsumerEvaluation> {
  final _name = TextEditingController(text: 'Field notebook');
  final _query = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'Consumer search');
  final _glassFocus = FocusNode(debugLabel: 'Consumer glass');
  final _overlayFocus = FocusNode(debugLabel: 'Consumer overlay');
  OverlayEntry? _overlay;
  FocusNode? _returnFocus; // Borrowed from the requesting Flutter control.
  int _page = 0;
  bool _sync = true;
  bool _opaque = false;
  bool _hidden = false;
  int _saves = 0;
  int _next = 0;
  int _edits = 0;
  int _itemSelections = 0;
  int _fieldSelections = 0;
  String _submitted = '';
  MacosGlassRendering _rendering = MacosGlassRendering.opaque;
  Object? _record;
  final _ratingProposals = <double>[];
  final _capacityProposals = <double>[];
  double _rating = 1.25;
  double _capacity = 37.5;

  void _find() {
    setState(() => _page = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeOverlay({bool restoreFocus = true}) {
    _overlay?.remove();
    _overlay?.dispose();
    _overlay = null;
    if (mounted) {
      setState(() {});
      if (restoreFocus && _returnFocus?.context != null) {
        _returnFocus!.requestFocus();
      }
      _returnFocus = null;
    }
  }

  void _openOverlay(BuildContext context) {
    if (_overlay != null) return;
    _returnFocus = FocusManager.instance.primaryFocus;
    final chrome = MacosChromeData.of(context);
    _overlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: BlockSemantics(
          child: ColoredBox(
            color: chrome.canvas,
            child: FocusScope(
              child: Focus(
                focusNode: _overlayFocus,
                autofocus: true,
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    _closeOverlay();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Center(
                  child: PushButton(
                    controlSize: ControlSize.regular,
                    onPressed: _closeOverlay,
                    child: const Text('Cancel preview'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Occlude for the entire visible lifetime, including any future fade tail.
    setState(() {});
    Overlay.of(context).insert(_overlay!);
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay?.dispose();
    _name.dispose();
    _query.dispose();
    _searchFocus.dispose();
    _glassFocus.dispose();
    _overlayFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MacosApp(
    title: 'Consumer task evaluation',
    home: MacosWindow(
      disableWallpaperTinting: true,
      sidebar: Sidebar(
        minWidth: MacosChromeData.sidebarMinWidth,
        startWidth: MacosChromeData.sidebarStartWidth,
        maxWidth: MacosChromeData.sidebarMaxWidth,
        builder: (context, controller) => SidebarItems(
          scrollController: controller, // Borrowed, never disposed here.
          currentIndex: _page,
          onChanged: (value) => setState(() {
            if (_page != value) _rendering = MacosGlassRendering.opaque;
            _page = value;
          }),
          items: const [
            SidebarItem(
              label: Text('Workspace'),
              expandDisclosureItems: true,
              disclosureItems: [
                SidebarItem(label: Text('Find records')),
                SidebarItem(label: Text('Preferences')),
              ],
            ),
            SidebarItem(label: Text('Glass preview')),
            SidebarItem(label: Text('Repaired records')),
          ],
        ),
      ),
      child: MacosScaffold(
        toolBar: ToolBar(
          title: const Text('Notebook'),
          actions: [
            ToolBarIconButton(
              label: 'Save session',
              icon: const MacosIcon(CupertinoIcons.check_mark),
              showLabel: true,
              onPressed: () => setState(() => _saves++),
            ),
            const ToolBarIconButton(
              label: 'Export unavailable',
              icon: MacosIcon(CupertinoIcons.share),
              showLabel: true,
            ),
            CustomToolbarItem(
              inToolbarBuilder: (context) => SizedBox(
                width: 220,
                child: PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: _find,
                  child: const Text('Find documents'),
                ),
              ),
              inOverflowedBuilder: (context) => ToolbarOverflowMenuItem(
                label: 'Find documents',
                onPressed: _find,
              ),
            ),
          ],
        ),
        children: [
          ContentArea(
            builder: (context, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.all(MacosChromeData.contentInset),
              children: [
                Text('Session saves: $_saves'),
                if (_page == 0) ..._search(),
                if (_page == 1) ..._settings(),
                if (_page == 2) ..._glass(context),
                if (_page == 3) ..._repair(),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _search() => [
    const Text('Search notebook records'),
    Semantics(
      label: 'Record query',
      child: MacosSearchField(
        controller: _query,
        focusNode: _searchFocus,
        results: [
          SearchResultItem(
            'Alpine notes',
            onSelected: () => setState(() => _itemSelections++),
          ),
          const SearchResultItem('Coastal notes'),
        ],
        // Never rewrite controller.text here: preserve the full IME value.
        onChanged: (_) => setState(() => _edits++),
        onResultSelected: (_) => setState(() => _fieldSelections++),
        onSubmitted: (value) => setState(() => _submitted = value),
      ),
    ),
    Text('Edits: $_edits; item: $_itemSelections; result: $_fieldSelections'),
    Text('Submitted: $_submitted'),
  ];

  List<Widget> _settings() => [
    const Text('Notebook name'),
    MacosTextField(controller: _name),
    const Text('Sync notebook (session setting)'),
    MacosCheckbox(
      value: _sync,
      semanticLabel: 'Sync notebook',
      onChanged: (value) => setState(() => _sync = value),
    ),
    const Text('Managed backup'),
    const MacosCheckbox(
      value: true,
      semanticLabel: 'Managed backup',
      onChanged: null,
    ),
    const Text('Opaque commands'),
    MacosCheckbox(
      value: _opaque,
      semanticLabel: 'Opaque commands',
      onChanged: (value) => setState(() => _opaque = value),
    ),
  ];

  List<Widget> _glass(BuildContext context) => [
    // Diagnostics belong in this evaluation, not an ordinary renderer setup UI.
    Text('Actual commands: ${_rendering.name}; next: $_next'),
    Wrap(
      spacing: MacosChromeData.gap,
      runSpacing: MacosChromeData.gap,
      children: [
        PushButton(
          controlSize: ControlSize.regular,
          onPressed: () => setState(() => _hidden = !_hidden),
          child: Text(_hidden ? 'Show commands' : 'Hide commands'),
        ),
        PushButton(
          controlSize: ControlSize.regular,
          onPressed: () => _openOverlay(context),
          child: const Text('Preview overlay'),
        ),
      ],
    ),
    ExcludeFocus(
      excluding: _hidden,
      child: ExcludeSemantics(
        excluding: _hidden,
        child: IgnorePointer(
          ignoring: _hidden,
          child: Offstage(
            offstage: _hidden,
            child: TickerMode(
              enabled: !_hidden,
              child: SizedBox(
                height: 300,
                child: NotebookCommands(
                  focusNode: _glassFocus,
                  forceOpaque: _opaque,
                  nativeOccluded: _overlay != null,
                  onRenderingChanged: (value) {
                    if (mounted) setState(() => _rendering = value);
                  },
                  onNext: () => setState(() => _next++),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ];

  // Task 5 replaces the recorded fabricated/Material/private API input.
  List<Widget> _repair() => [
    const Label(text: Text('Survey records')),
    SizedBox(
      height: 160,
      child: MacosDataTable(
        columns: const [MacosTableColumn(label: 'Name', width: 180)],
        rows: const [
          MacosTableRow(id: 'alpine', cells: ['Alpine survey']),
          MacosTableRow(id: 'coast', cells: ['Coastal survey']),
        ],
        selectedId: _record,
        onSelectionChanged: (value) => setState(() => _record = value),
      ),
    ),
    Text('Record: ${_record ?? "none"}'),
    RatingIndicator(
      value: _rating,
      semanticLabel: 'Survey rating',
      onChanged: (value) => setState(() {
        _ratingProposals.add(value);
        _rating = value;
      }),
    ),
    Text('Rating: $_rating; proposals: $_ratingProposals'),
    CapacityIndicator(
      value: _capacity,
      semanticLabel: 'Notebook capacity',
      onChanged: (value) => setState(() {
        _capacityProposals.add(value);
        _capacity = value;
      }),
    ),
    Text('Capacity: $_capacity; proposals: $_capacityProposals'),
  ];
}

/// Task 4's feature, independently mountable without window utility ownership.
class NotebookCommands extends StatelessWidget {
  const NotebookCommands({
    super.key,
    required this.onNext,
    this.focusNode,
    this.forceOpaque = false,
    this.nativeOccluded = false,
    this.onRenderingChanged,
  });
  final VoidCallback onNext;
  final FocusNode? focusNode;
  final bool forceOpaque;
  final bool nativeOccluded;
  final ValueChanged<MacosGlassRendering>? onRenderingChanged;

  @override
  Widget build(BuildContext context) => MacosGlassCommandSurface(
    focusNode: focusNode,
    forceOpaque: forceOpaque,
    nativeOccluded: nativeOccluded,
    onRenderingChanged: onRenderingChanged,
    commands: [
      MacosGlassCommand(label: 'Next record', onPressed: onNext),
      const MacosGlassCommand(label: 'Archive unavailable'),
    ],
    child: ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: const [Text('Readable notebook document')],
    ),
  );
}
