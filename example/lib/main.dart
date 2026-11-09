import 'dense_content.dart';
import 'document_inspector.dart';
import 'transient_surfaces.dart';
import 'liquid_glass.dart';

import 'package:flutter/cupertino.dart' hide OverlayVisibilityMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode, TimeOfDay;
import 'package:flutter/services.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

Future<void> main() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    await const MacosWindowUtilsConfig().apply();
  }
  runApp(const ShellGallery());
}

/// A public-import-only application shell using the retained upstream APIs.
class ShellGallery extends StatefulWidget {
  const ShellGallery({super.key});

  @override
  State<ShellGallery> createState() => _ShellGalleryState();
}

class _ShellGalleryState extends State<ShellGallery> {
  ThemeMode _appearance = ThemeMode.system;

  @override
  Widget build(BuildContext context) => MacosApp(
    title: 'macOS UI Library',
    debugShowCheckedModeBanner: false,
    themeMode: _appearance,
    home: _LibraryWindow(
      onAppearanceChanged: () => setState(() {
        final isDark =
            _appearance == ThemeMode.dark ||
            (_appearance == ThemeMode.system &&
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark);
        _appearance = isDark ? ThemeMode.light : ThemeMode.dark;
      }),
    ),
  );
}

class _LibraryWindow extends StatefulWidget {
  const _LibraryWindow({required this.onAppearanceChanged});

  final VoidCallback onAppearanceChanged;

  @override
  State<_LibraryWindow> createState() => _LibraryWindowState();
}

class _LibraryWindowState extends State<_LibraryWindow> {
  int _selection = 0;
  MacosWindowScope? _windowScope;
  void _toggleSidebar() => _windowScope?.toggleSidebar();
  static const _pages = [
    'Application shell',
    'Typography',
    'Colour roles',
    'Value controls',
    'Buttons',
    'Text and search',
    'Documents',
    'Sliders and selectors',
    'Menus and dialogs',
    'Liquid Glass',
    'Document inspector',
  ];
  void _showShell() => setState(() => _selection = 0);
  static const _inset = MacosChromeData.contentInset;
  static const _gap = MacosChromeData.gap;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final chrome = MacosChromeData.of(context);
    final preferences = MacosAccessibility.of(context);
    final window = MacosWindow(
      disableWallpaperTinting: true,
      backgroundColor: chrome.canvas,
      sidebar: Sidebar(
        minWidth: MacosChromeData.sidebarMinWidth,
        maxWidth: MacosChromeData.sidebarMaxWidth,
        startWidth: MacosChromeData.sidebarStartWidth,
        decoration: BoxDecoration(color: chrome.sidebar),
        builder: (context, controller) => SidebarItems(
          scrollController: controller,
          currentIndex: _selection,
          onChanged: (value) => setState(() => _selection = value),
          items: const [
            SidebarItem(
              leading: MacosIcon(CupertinoIcons.macwindow),
              label: Text('Application shell'),
            ),
            SidebarItem(
              label: Text('Foundations'),
              section: true,
              expandDisclosureItems: true,
              disclosureItems: [
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.textformat),
                  label: Text('Typography'),
                ),
                SidebarItem(
                  label: Text('Appearance'),
                  expandDisclosureItems: true,
                  disclosureItems: [
                    SidebarItem(
                      leading: MacosIcon(CupertinoIcons.paintbrush),
                      label: Text('Colour roles'),
                    ),
                  ],
                ),
              ],
            ),
            SidebarItem(
              label: Text('Value controls'),
              leading: MacosIcon(CupertinoIcons.checkmark_circle),
            ),
            SidebarItem(
              leading: MacosIcon(CupertinoIcons.cursor_rays),
              label: Text('Buttons'),
            ),
            SidebarItem(
              label: Text('Text and search'),
              leading: MacosIcon(CupertinoIcons.search),
            ),
            SidebarItem(
              label: Text('Documents'),
              leading: MacosIcon(CupertinoIcons.doc_text),
            ),
            SidebarItem(
              label: Text('Sliders and selectors'),
              leading: MacosIcon(CupertinoIcons.slider_horizontal_3),
            ),
            SidebarItem(
              label: Text('Menus and dialogs'),
              leading: MacosIcon(CupertinoIcons.rectangle_on_rectangle),
            ),
            SidebarItem(
              label: Text('Liquid Glass'),
              leading: MacosIcon(CupertinoIcons.layers),
            ),
            SidebarItem(
              label: Text('Document inspector'),
              leading: MacosIcon(CupertinoIcons.info_circle),
            ),
          ],
        ),
      ),
      child: Builder(
        builder: (context) {
          void toggleSidebar() => MacosWindowScope.of(context).toggleSidebar();
          _windowScope = MacosWindowScope.of(context);
          return Focus(
            autofocus: true,
            child: MacosScaffold(
              toolBar: ToolBar(
                title: Text(_pages[_selection]),
                titleWidth: 200,
                decoration: BoxDecoration(color: chrome.toolbar),
                leading: MacosIconButton(
                  semanticLabel: 'Toggle sidebar',
                  icon: const MacosIcon(CupertinoIcons.sidebar_left),
                  onPressed: toggleSidebar,
                ),
                actions: [
                  ToolBarIconButton(
                    label: 'Change appearance',
                    tooltipMessage: 'Change appearance (⌥⌘L)',
                    icon: const MacosIcon(CupertinoIcons.circle_lefthalf_fill),
                    showLabel: false,
                    onPressed: widget.onAppearanceChanged,
                  ),
                  ToolBarIconButton(
                    label: 'Show application shell',
                    tooltipMessage: 'Show application shell (⌥⌘1)',
                    icon: const MacosIcon(CupertinoIcons.macwindow),
                    showLabel: false,
                    onPressed: _showShell,
                  ),
                  const ToolBarIconButton(
                    label: 'Export selection',
                    icon: MacosIcon(CupertinoIcons.square_arrow_up),
                    showLabel: false,
                  ),
                ],
              ),
              children: [
                ContentArea(
                  builder: (context, controller) => _selection == 9
                      ? const LiquidGlassPage()
                      : ColoredBox(
                          color: chrome.canvas,
                          child: ListView(
                            controller: controller,
                            padding: const EdgeInsets.all(_inset),
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  _pages[_selection],
                                  style: theme.typography.largeTitle,
                                ),
                              ),
                              const SizedBox(height: _gap),
                              Text(
                                'A desktop workspace, built in Flutter.',
                                style: theme.typography.headline,
                              ),
                              const SizedBox(height: _inset),
                              if (_selection == 0) ...[
                                const Text('Window, navigation and content'),
                                const SizedBox(height: _gap),
                                const Text(
                                  'Resize the sidebar, hide it with ⌥⌘S, or switch appearance with ⌥⌘L. '
                                  'Native window controls remain owned by macOS. '
                                  'Open Liquid Glass for the native floating command surface. '
                                  'Use arrows, Home and End to explore the navigation tree. '
                                  'Resize the window to reach commands in More toolbar commands.',
                                ),
                                const SizedBox(height: _inset),
                                Wrap(
                                  spacing: _gap,
                                  runSpacing: _gap,
                                  children: [
                                    PushButton(
                                      controlSize: ControlSize.large,
                                      onPressed: () =>
                                          setState(() => _selection = 1),
                                      child: const Text('Explore typography'),
                                    ),
                                    PushButton(
                                      controlSize: ControlSize.large,
                                      onPressed: () =>
                                          setState(() => _selection = 9),
                                      child: const Text('Open Liquid Glass'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: _inset),
                                Text(
                                  'System accessibility',
                                  style: theme.typography.title2,
                                ),
                                const SizedBox(height: _gap),
                                for (final entry in {
                                  'Preference adapter': preferences.available
                                      ? 'Connected'
                                      : 'Safe fallback',
                                  'Transparency': preferences.reduceTransparency
                                      ? 'Reduced'
                                      : 'Allowed; shell remains opaque',
                                  'Motion':
                                      MediaQuery.disableAnimationsOf(context)
                                      ? 'Reduced'
                                      : 'Standard',
                                  'Contrast': MediaQuery.highContrastOf(context)
                                      ? 'Increased'
                                      : 'Standard',
                                  'Window': chrome.isActive
                                      ? 'Active'
                                      : 'Inactive',
                                }.entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: _gap / 2,
                                    ),
                                    child: Wrap(
                                      spacing: _gap,
                                      runSpacing: _gap / 2,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: theme.typography.headline,
                                        ),
                                        Text(
                                          entry.value,
                                          style: TextStyle(
                                            color: chrome.secondaryForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ] else if (_selection == 1) ...[
                                for (final entry in {
                                  'Large title': theme.typography.largeTitle,
                                  'Title': theme.typography.title1,
                                  'Headline': theme.typography.headline,
                                  'Body — The quick brown fox jumps over the lazy dog.':
                                      theme.typography.body,
                                  'Caption — 8 November 2026':
                                      theme.typography.caption1,
                                }.entries)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: _inset,
                                    ),
                                    child: Text(entry.key, style: entry.value),
                                  ),
                              ] else if (_selection == 10) ...[
                                const DocumentInspector(),
                              ] else if (_selection == 8) ...[
                                const TransientSurfacesPage(),
                              ] else if (_selection == 7) ...[
                                const _SelectorsPage(),
                              ] else if (_selection == 6) ...[
                                const DocumentBrowser(),
                              ] else if (_selection == 5) ...[
                                const _FieldsPage(),
                              ] else if (_selection == 4) ...[
                                const _ButtonsPage(),
                              ] else if (_selection == 3) ...[
                                const _ValueControlsPage(),
                              ] else ...[
                                const Text(
                                  'Surfaces and separators follow MacosTheme. Text and controls retain their existing semantic theme roles.',
                                ),
                                const SizedBox(height: _inset),
                                for (final role in {
                                  'Document canvas': chrome.canvas,
                                  'Sidebar': chrome.sidebar,
                                  'Separator': chrome.separator,
                                  'Focus ring': chrome.focusRing,
                                  'Selection': chrome.selection,
                                  'Hover': chrome.hover,
                                  'Pressed': chrome.pressed,
                                }.entries)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: _gap,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          color: role.value,
                                        ),
                                        const SizedBox(width: _gap),
                                        Expanded(child: Text(role.key)),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
    final shortcuts = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true, alt: true):
            _showShell,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true, alt: true):
            _toggleSidebar,
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true, alt: true):
            widget.onAppearanceChanged,
      },
      child: window,
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return PlatformMenuBar(
        menus: [
          PlatformMenu(
            label: 'macOS UI Library',
            menus: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
            ],
          ),
          PlatformMenu(
            label: 'View',
            menus: [
              PlatformMenuItem(
                label: 'Toggle Sidebar',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyS,
                  meta: true,
                  alt: true,
                ),
                onSelected: _toggleSidebar,
              ),
              PlatformMenuItem(
                label: 'Show Application Shell',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.digit1,
                  meta: true,
                  alt: true,
                ),
                onSelected: _showShell,
              ),
              const PlatformMenuItem(label: 'Export Selection'),
              PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.toggleFullScreen,
              ),
              PlatformMenuItem(
                label: 'Change Appearance',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyL,
                  meta: true,
                  alt: true,
                ),
                onSelected: widget.onAppearanceChanged,
              ),
            ],
          ),
        ],
        child: shortcuts,
      );
    }
    return shortcuts;
  }
}

class _ButtonsPage extends StatefulWidget {
  const _ButtonsPage();

  @override
  State<_ButtonsPage> createState() => _ButtonsPageState();
}

class _ButtonsPageState extends State<_ButtonsPage> {
  bool _expanded = false;
  String _result = 'No button action yet';
  void _record(String result) => setState(() => _result = result);

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tab between commands, then use Enter or Space. '
          'Hover and hold to inspect feedback. Secondary click does not activate.',
        ),
        const SizedBox(height: MacosChromeData.contentInset),
        Text('Push buttons', style: theme.typography.title2),
        const SizedBox(height: MacosChromeData.gap),
        Wrap(
          spacing: MacosChromeData.gap,
          runSpacing: MacosChromeData.gap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final size in ControlSize.values)
              PushButton(
                controlSize: size,
                onPressed: () => _record('Saved with ${size.name} button'),
                child: Text('Save ${size.name}'),
              ),
            PushButton(
              controlSize: ControlSize.regular,
              secondary: true,
              onPressed: () => _record('Cancelled'),
              child: const Text('Cancel'),
            ),
            const PushButton(
              controlSize: ControlSize.regular,
              child: Text('Save unavailable'),
            ),
            PushButton(
              controlSize: ControlSize.large,
              onPressed: () => _record('Document and attachments saved'),
              child: const Text(
                'Save document and all attached reference material',
              ),
            ),
          ],
        ),
        const SizedBox(height: MacosChromeData.contentInset),
        Text('Icon, disclosure and help', style: theme.typography.title2),
        const SizedBox(height: MacosChromeData.gap),
        Wrap(
          spacing: MacosChromeData.gap,
          runSpacing: MacosChromeData.gap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MacosIconButton(
              semanticLabel: 'Add attachment',
              icon: const MacosIcon(CupertinoIcons.add),
              onPressed: () => _record('Attachment added'),
            ),
            const MacosIconButton(
              semanticLabel: 'Remove attachment unavailable',
              icon: MacosIcon(CupertinoIcons.minus),
            ),
            MacosDisclosureButton(
              semanticLabel: 'Attachment details',
              isPressed: _expanded,
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
            const MacosDisclosureButton(semanticLabel: 'Details unavailable'),
            HelpButton(
              semanticLabel: 'Attachment help',
              onPressed: () =>
                  _record('Choose Add attachment to include a file.'),
            ),
            const HelpButton(semanticLabel: 'Help unavailable'),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: MacosChromeData.gap),
          const Text('Attachments are included when you save this document.'),
        ],
        const SizedBox(height: MacosChromeData.contentInset),
        Semantics(liveRegion: true, child: Text(_result)),
      ],
    );
  }
}

class _ValueControlsPage extends StatefulWidget {
  const _ValueControlsPage();
  @override
  State<_ValueControlsPage> createState() => _ValueControlsPageState();
}

class _ValueControlsPageState extends State<_ValueControlsPage> {
  bool _sync = false;
  bool? _attachments;
  String? _storage = 'local';
  final _controller = MacosTabController(length: 3);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _row(Widget control, String label) => Padding(
    padding: const EdgeInsets.only(bottom: MacosChromeData.gap),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        control,
        const SizedBox(width: MacosChromeData.gap),
        Expanded(child: Text(label)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Use Tab, Space or Enter. Drag a switch; use arrows in the storage group and view segments.',
      ),
      const SizedBox(height: MacosChromeData.contentInset),
      for (final size in [
        ControlSize.mini,
        ControlSize.small,
        ControlSize.regular,
      ])
        _row(
          MacosSwitch(
            value: _sync,
            size: size,
            semanticLabel: 'Sync ${size.name}',
            onChanged: (value) => setState(() => _sync = value),
          ),
          'Sync documents — ${size.name}',
        ),
      _row(
        const MacosSwitch(
          value: true,
          onChanged: null,
          semanticLabel: 'Managed sync',
        ),
        'Sync managed by your organisation',
      ),
      _row(
        MacosCheckbox(
          value: _attachments,
          semanticLabel: 'Include attachments',
          onChanged: (value) => setState(() => _attachments = value),
        ),
        'Include attachments from selected documents (initially mixed)',
      ),
      _row(
        const MacosCheckbox(
          value: null,
          onChanged: null,
          semanticLabel: 'Managed attachments',
        ),
        'Mixed attachments — managed',
      ),
      RadioGroup<String>(
        groupValue: _storage,
        onChanged: (value) => setState(() => _storage = value),
        child: Column(
          children: [
            for (final entry in {
              'local': 'On this Mac',
              'cloud': 'In cloud storage',
              'archive': 'Archive unavailable',
            }.entries)
              _row(
                MacosRadioButton<String>(
                  value: entry.key,
                  groupValue: _storage,
                  semanticLabel: entry.value,
                  onChanged: entry.key == 'archive'
                      ? null
                      : (value) => setState(() => _storage = value),
                ),
                entry.value,
              ),
          ],
        ),
      ),
      const SizedBox(height: MacosChromeData.gap),
      MacosSegmentedControl(
        controller: _controller,
        tabs: const [
          MacosTab(label: 'Summary'),
          MacosTab(label: 'Standard'),
          MacosTab(label: 'Detailed'),
        ],
      ),
      const SizedBox(height: MacosChromeData.gap),
      ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Text(
          'Preview detail level: ${['Summary', 'Standard', 'Detailed'][_controller.index]}',
        ),
      ),
      Semantics(
        liveRegion: true,
        child: Text(
          'Sync ${_sync ? 'on' : 'off'}; attachments ${_attachments == null
              ? 'mixed'
              : _attachments!
              ? 'included'
              : 'excluded'}; storage $_storage',
        ),
      ),
    ],
  );
}

class _FieldsPage extends StatefulWidget {
  const _FieldsPage();
  @override
  State<_FieldsPage> createState() => _FieldsPageState();
}

class _FieldsPageState extends State<_FieldsPage> {
  final _name = TextEditingController(text: 'Quarterly report');
  final _reference = TextEditingController(text: 'REPORT-2026-11');
  String? _error;
  String _status = 'Choose a document or enter a search query.';
  @override
  void dispose() {
    _name.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Document name'),
        const SizedBox(height: MacosChromeData.gap),
        Semantics(
          label: 'Document name',
          child: MacosTextField(
            controller: _name,
            placeholder: 'Enter a descriptive document name',
            clearButtonMode: OverlayVisibilityMode.editing,
            decoration: _error == null
                ? kDefaultRoundedBorderDecoration
                : BoxDecoration(
                    color: chrome.canvas,
                    border: Border.all(color: MacosColors.systemRedColor),
                    borderRadius: BorderRadius.circular(
                      MacosChromeData.controlRadius,
                    ),
                  ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _save(),
          ),
        ),
        if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
        const SizedBox(height: MacosChromeData.gap),
        PushButton(
          controlSize: ControlSize.regular,
          onPressed: _save,
          child: const Text('Save name'),
        ),
        const SizedBox(height: MacosChromeData.contentInset),
        const Text('Reference (read only; select and copy)'),
        Semantics(
          label: 'Document reference',
          child: MacosTextField(controller: _reference, readOnly: true),
        ),
        const SizedBox(height: MacosChromeData.gap),
        const Text('Managed by your organisation'),
        Semantics(
          label: 'Managed folder',
          child: MacosTextField(placeholder: 'Team documents', enabled: false),
        ),
        const SizedBox(height: MacosChromeData.contentInset),
        const Text('Find a document'),
        Semantics(
          label: 'Find a document',
          child: MacosSearchField(
            placeholder: 'Search titles; use arrows and Enter to choose',
            results: const [
              SearchResultItem('Quarterly report'),
              SearchResultItem('Project brief'),
              SearchResultItem('Meeting notes'),
            ],
            emptyWidget: const Padding(
              padding: EdgeInsets.all(MacosChromeData.gap),
              child: Text('No matching documents'),
            ),
            onChanged: (query) => setState(
              () => _status = query.isEmpty
                  ? 'Search cleared'
                  : 'Searching for $query',
            ),
            onSubmitted: (query) =>
                setState(() => _status = 'Search submitted: $query'),
            onResultSelected: (result) =>
                setState(() => _status = 'Opened ${result.searchKey}'),
          ),
        ),
        const SizedBox(height: MacosChromeData.gap),
        Semantics(liveRegion: true, child: Text(_status)),
      ],
    );
  }

  void _save() => setState(() {
    _error = _name.text.trim().isEmpty
        ? 'Enter a document name before saving.'
        : null;
    if (_error == null) _status = 'Saved ${_name.text}';
  });
}

class _SelectorsPage extends StatefulWidget {
  const _SelectorsPage();
  @override
  State<_SelectorsPage> createState() => _SelectorsPageState();
}

class _SelectorsPageState extends State<_SelectorsPage> {
  double _volume = 50;
  String _quality = 'balanced';
  Color _colour = CupertinoColors.systemBlue;
  DateTime _date = DateTime(2026, 11, 8);
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 30);
  bool _enabled = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Export settings', style: MacosTheme.of(context).typography.title2),
      const SizedBox(height: MacosChromeData.gap),
      Wrap(
        spacing: MacosChromeData.gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MacosSwitch(
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const Text('Enable export controls'),
        ],
      ),
      const SizedBox(height: MacosChromeData.gap),
      Text('Volume: ${_volume.round()} percent'),
      MacosSlider(
        value: _volume,
        min: 0,
        max: 100,
        semanticLabel: 'Export volume',
        onChanged: _enabled ? (value) => setState(() => _volume = value) : null,
      ),
      const SizedBox(height: MacosChromeData.gap),
      const Text('Quality'),
      MacosSlider(
        value: _quality == 'balanced' ? 1 : 2,
        min: 1,
        max: 2,
        splits: 2,
        discrete: true,
        semanticLabel: 'Export quality',
        onChanged: _enabled
            ? (value) =>
                  setState(() => _quality = value == 1 ? 'balanced' : 'best')
            : null,
      ),
      MacosPopupButton<String>(
        value: _quality,
        items: const [
          MacosPopupMenuItem(value: 'balanced', child: Text('Balanced')),
          MacosPopupMenuItem(value: 'best', child: Text('Best quality')),
          MacosPopupMenuItem(
            value: 'managed',
            enabled: false,
            child: Text('Managed by policy'),
          ),
        ],
        onChanged: _enabled
            ? (value) => setState(() => _quality = value!)
            : null,
      ),
      const SizedBox(height: MacosChromeData.gap),
      const Text('Highlight colour'),
      MacosColorWell(
        color: _colour,
        enabled: _enabled,
        semanticLabel: 'Export highlight colour',
        onColorSelected: (value) => setState(() => _colour = value),
      ),
      const SizedBox(height: MacosChromeData.gap),
      Text(
        'Scheduled: ${_date.year}-${_date.month}-${_date.day} at ${_time.format(context)}',
      ),
      Wrap(
        spacing: MacosChromeData.contentInset,
        runSpacing: MacosChromeData.gap,
        children: [
          MacosDatePicker(
            initialDate: _date,
            enabled: _enabled,
            onDateChanged: (value) => setState(() => _date = value),
          ),
          MacosTimePicker(
            initialTime: _time,
            enabled: _enabled,
            onTimeChanged: (value) => setState(() => _time = value),
          ),
        ],
      ),
      const SizedBox(height: MacosChromeData.contentInset),
      const Text('Example export progress: 35 percent'),
      const ProgressBar(value: 35, semanticLabel: 'Example export'),
      const SizedBox(height: MacosChromeData.gap),
      const Wrap(
        spacing: MacosChromeData.gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ProgressCircle(value: 35, semanticLabel: 'Example indexing'),
          ProgressCircle(semanticLabel: 'Example connection pending'),
          Text('Waiting for connection'),
        ],
      ),
    ],
  );
}
