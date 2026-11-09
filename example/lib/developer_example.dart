import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

/// Run with `flutter run -d macos -t lib/developer_example.dart`.
Future<void> main() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    await const MacosWindowUtilsConfig().apply();
  }
  runApp(const DeveloperExample());
}

/// Small public-import consumer; the main gallery supplies full acceptance flows.
class DeveloperExample extends StatefulWidget {
  const DeveloperExample({super.key});

  @override
  State<DeveloperExample> createState() => _DeveloperExampleState();
}

class _DeveloperExampleState extends State<DeveloperExample> {
  int _page = 0;
  Object? _selected;
  bool _sync = true;
  bool _opaque = false;

  @override
  Widget build(BuildContext context) => MacosApp(
    title: 'Library example',
    home: MacosWindow(
      disableWallpaperTinting: true,
      sidebar: Sidebar(
        minWidth: MacosChromeData.sidebarMinWidth,
        maxWidth: MacosChromeData.sidebarMaxWidth,
        startWidth: MacosChromeData.sidebarStartWidth,
        builder: (context, controller) => SidebarItems(
          scrollController: controller,
          currentIndex: _page,
          onChanged: (page) => setState(() => _page = page),
          items: const [
            SidebarItem(label: Text('Documents')),
            SidebarItem(label: Text('Settings')),
          ],
        ),
      ),
      child: MacosScaffold(
        toolBar: ToolBar(title: Text(_page == 0 ? 'Documents' : 'Settings')),
        children: [
          ContentArea(
            builder: (context, controller) => _page == 0
                ? _documents(context, controller)
                : _settings(controller),
          ),
        ],
      ),
    ),
  );

  Widget _documents(BuildContext context, ScrollController controller) {
    void selectBrief() => setState(() => _selected = 'brief');
    final commands = [
      MacosGlassCommand(label: 'Select brief', onPressed: selectBrief),
    ];
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(MacosChromeData.contentInset),
      children: [
        // A descriptor opts into native commands; child is the equivalent
        // Flutter fallback, never an arbitrary child hosted inside AppKit.
        SizedBox(
          height: 64,
          child: MacosGlassSurface(
            nativeCommands: commands,
            forceOpaque: _opaque,
            child: Center(
              child: PushButton(
                controlSize: ControlSize.regular,
                onPressed: selectBrief,
                child: const Text('Select brief'),
              ),
            ),
          ),
        ),
        const SizedBox(height: MacosChromeData.gap),
        SizedBox(
          height: 240,
          child: MacosDataTable(
            columns: const [MacosTableColumn(label: 'Title', width: 240)],
            rows: const [
              MacosTableRow(id: 'brief', cells: ['Design brief']),
              MacosTableRow(id: 'notes', cells: ['Field notes']),
            ],
            selectedId: _selected,
            onSelectionChanged: (id) => setState(() => _selected = id),
          ),
        ),
        Text('Selection: ${_selected ?? "none"}'),
      ],
    );
  }

  Widget _settings(ScrollController controller) => ListView(
    controller: controller,
    padding: const EdgeInsets.all(MacosChromeData.contentInset),
    children: [
      MacosCheckbox(
        value: _sync,
        semanticLabel: 'Sync documents',
        onChanged: (value) => setState(() => _sync = value),
      ),
      const Text('Sync documents (session setting)'),
      MacosCheckbox(
        value: _opaque,
        semanticLabel: 'Use opaque command surface',
        onChanged: (value) => setState(() => _opaque = value),
      ),
      const Text('Use opaque command surface'),
    ],
  );
}
