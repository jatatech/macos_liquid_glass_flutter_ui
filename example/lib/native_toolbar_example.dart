import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'example_menu.dart';

/// Standalone native toolbar example; do not install two owners in one engine.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    WidgetsBinding.instance.platformMenuDelegate = DefaultPlatformMenuDelegate(
      channel: const ExampleMenuChannel(),
    );
  }
  await const MacosWindowUtilsConfig(
    enableFullSizeContentView: false,
    makeTitlebarTransparent: false,
    removeMenubarInFullScreenMode: false,
    autoHideToolbarAndMenuBarInFullScreenMode: false,
  ).apply();
  runApp(const MacosApp(home: NativeToolbarExample()));
}

class NativeToolbarExample extends StatefulWidget {
  const NativeToolbarExample({super.key});
  @override
  State<NativeToolbarExample> createState() => _NativeToolbarExampleState();
}

class _NativeToolbarExampleState extends State<NativeToolbarExample> {
  static const documents = ['Design brief', 'Site survey', 'Meeting notes'];
  final dateAnchor = MacosNativeToolbarAnchor();
  final dateFallback = GlobalKey<MacosDateSelectionFallbackState>();
  DateTime dateDraft = DateTime.utc(2026, 11, 8);
  bool showDateFallback = false;
  MacosDateSelection? dateTask;
  String dateStatus = 'Jump selects a document by its project date.';
  final search = TextEditingController();
  final panes = MacosPaneLayoutController();
  final drafts = <int, TextEditingController>{};
  BuildContext? shellContext;
  String presentation = 'comfortable';
  final toolbar = MacosNativeToolbarController();
  final searchFocus = FocusNode();
  String query = '';
  int? selected;
  bool detail = false;

  @override
  void initState() {
    super.initState();
    panes.addListener(paneChanged);
    resetDateTask();
  }

  void resetDateTask() {
    dateTask = MacosDateSelection(
      initialDate: dateDraft.isBefore(DateTime.utc(2026, 11, 7))
          ? DateTime.utc(2026, 11, 7)
          : dateDraft.isAfter(DateTime.utc(2026, 11, 9))
          ? DateTime.utc(2026, 11, 9)
          : dateDraft,
      minimumDate: DateTime.utc(2026, 11, 7),
      maximumDate: DateTime.utc(2026, 11, 9),
      title: 'Jump to project date',
      commitLabel: 'Jump',
      cancelLabel: 'Cancel',
    );
  }

  void dateResult(MacosDateSelectionResult result) {
    if (!mounted) return;
    setState(() {
      if (result.exit != MacosDateSelectionExit.cancelled &&
          result.exit != MacosDateSelectionExit.unavailable) {
        dateDraft = result.date;
      }
      if (result.exit == MacosDateSelectionExit.committed) {
        final candidates = results;
        if (candidates.isNotEmpty) {
          selected = candidates.reduce(
            (a, b) =>
                (DateTime.utc(
                      2026,
                      11,
                      7 + a,
                    ).difference(result.date).inDays).abs() <=
                    (DateTime.utc(
                      2026,
                      11,
                      7 + b,
                    ).difference(result.date).inDays).abs()
                ? a
                : b,
          );
        }
      }
      dateStatus = result.exit == MacosDateSelectionExit.committed
          ? 'Jumped to ${result.date.year}-${result.date.month}-${result.date.day}.'
          : 'Date task ${result.exit.name}; collection and document edits retained.';
      resetDateTask();
    });
  }

  Future<void> jumpToDate() async {
    if (detail || results.isEmpty) return;
    final result = await toolbar.presentDate(dateAnchor, dateTask!);
    if (!mounted) return;
    if (result.exit != MacosDateSelectionExit.unavailable) {
      dateResult(result);
      return;
    }
    setState(() => showDateFallback = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) dateFallback.currentState?.open();
    });
  }

  void paneChanged() => setState(() {});

  List<int> get results => [
    for (var i = 0; i < documents.length; i++)
      if (documents[i].toLowerCase().contains(query.toLowerCase())) i,
  ];

  @override
  void dispose() {
    searchFocus.dispose();
    search.dispose();
    panes.removeListener(paneChanged);
    panes.dispose();
    for (final draft in drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void changeQuery(String value) => setState(() => query = value);
    Future<void> findDocuments() async {
      if (detail) return;
      if (!await toolbar.focusSearch('document-search') && mounted) {
        searchFocus.requestFocus();
      }
    }

    final matches = results;
    final position = matches.indexOf(selected ?? -1);
    // Nullable callbacks are the single enabled-state source for every surface.
    final VoidCallback? back = detail
        ? () => setState(() => detail = false)
        : null;
    final VoidCallback? previous = detail && position > 0
        ? () => setState(() => selected = matches[position - 1])
        : null;
    final VoidCallback? next =
        detail && position >= 0 && position < matches.length - 1
        ? () => setState(() => selected = matches[position + 1])
        : null;
    final commands = [
      MacosNativeToolbarCommand(
        id: 'back',
        label: 'Back to collection',
        symbol: 'arrow.left',
        onPressed: back,
      ),
      MacosNativeToolbarCommand(
        id: 'previous',
        label: 'Previous document',
        symbol: 'chevron.left',
        group: 1,
        onPressed: previous,
      ),
      MacosNativeToolbarCommand(
        id: 'next',
        label: 'Next document',
        symbol: 'chevron.right',
        group: 1,
        onPressed: next,
      ),
    ];
    final paneCommands = [
      MacosNativeToolbarCommand(
        id: 'sidebar',
        label: 'Toggle navigation',
        symbol: 'sidebar.left',
        onPressed: (panes.value?.size.width ?? 0) > 900
            ? () => MacosWindowScope.of(shellContext!).toggleSidebar()
            : null,
      ),
      MacosNativeToolbarCommand(
        id: 'inspector',
        label: 'Toggle inspector',
        symbol: 'sidebar.right',
        onPressed: (panes.value?.size.width ?? 0) > 1100
            ? () => MacosWindowScope.of(shellContext!).toggleEndSidebar()
            : null,
      ),
    ];
    final views = [
      for (final name in ['comfortable', 'compact'])
        MacosNativeToolbarCommand(
          id: name,
          label: name == 'compact' ? 'Compact rows' : 'Comfortable rows',
          symbol: 'list.bullet',
          onPressed: !detail ? () => setState(() => presentation = name) : null,
        ),
    ];
    final dateCommand = MacosNativeToolbarCommand(
      id: 'project-date',
      label: 'Jump to project date',
      symbol: 'calendar',
      onPressed: !detail && matches.isNotEmpty ? jumpToDate : null,
    );
    final allCommands = [...commands, ...paneCommands, ...views];
    const keys = [
      SingleActivator(LogicalKeyboardKey.digit1, meta: true, alt: true),
      SingleActivator(LogicalKeyboardKey.digit2, meta: true, alt: true),
      SingleActivator(LogicalKeyboardKey.digit3, meta: true, alt: true),
      SingleActivator(LogicalKeyboardKey.digit4, meta: true, alt: true),
      SingleActivator(LogicalKeyboardKey.digit5, meta: true, alt: true),
      SingleActivator(LogicalKeyboardKey.digit6, meta: true, alt: true),
      SingleActivator(LogicalKeyboardKey.digit7, meta: true, alt: true),
    ];
    final window = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            findDocuments,
        for (var i = 0; i < allCommands.length; i++)
          // Consume unavailable commands without changing state.
          keys[i]: allCommands[i].onPressed ?? () {},
      },
      child: Focus(
        autofocus: true,
        child: MacosNativeToolbar(
          title: detail ? documents[selected!] : 'Project documents',
          controller: toolbar,
          paneLayoutController: panes,
          glassTitlebar: true,
          items: [
            MacosNativeToolbarCommandItem(
              command: commands.first,
              placement: MacosNativeToolbarPlacement.leading,
            ),
            MacosNativeToolbarGroup(
              id: 'browse',
              label: 'Browse documents',
              commands: commands.skip(1).toList(),
            ),
            MacosNativeToolbarGroup(
              id: 'presentation',
              label: 'Row spacing',
              commands: views,
              mode: MacosNativeToolbarGroupMode.exclusive,
              selectedId: presentation,
            ),
            for (final command in paneCommands)
              MacosNativeToolbarCommandItem(command: command),
            MacosNativeToolbarCommandItem(
              command: dateCommand,
              anchor: dateAnchor,
            ),
            MacosNativeToolbarSearch(
              id: 'document-search',
              label: 'Filter project document titles',
              controller: search,
              enabled: !detail,
              onChanged: changeQuery,
            ),
          ],
          fallback: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .35,
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: MacosChromeData.gap,
                runSpacing: MacosChromeData.gap,
                children: [
                  SizedBox(
                    width: 220,
                    child: MacosTextField(
                      controller: search,
                      focusNode: searchFocus,
                      enabled: !detail,
                      placeholder: 'Filter project document titles',
                      onChanged: changeQuery,
                    ),
                  ),
                  PushButton(
                    controlSize: ControlSize.regular,
                    onPressed: !detail
                        ? () {
                            search.clear();
                            changeQuery('');
                            searchFocus.requestFocus();
                          }
                        : null,
                    child: const Text('Clear search'),
                  ),
                  for (final command in [...allCommands, dateCommand])
                    Semantics(
                      selected: views.contains(command)
                          ? presentation == command.id
                          : null,
                      child: PushButton(
                        controlSize: ControlSize.regular,
                        onPressed: command.onPressed,
                        child: Text(command.label),
                      ),
                    ),
                ],
              ),
            ),
          ),
          child: MacosWindow(
            paneLayoutController: panes,
            disableWallpaperTinting: true,
            sidebar: Sidebar(
              minWidth: 180,
              startWidth: 200,
              maxWidth: 280,
              windowBreakpoint: 900,
              topOffset: 0,
              builder: (context, controller) => ListView(
                controller: controller,
                children: const [Text('Workspace'), Text('Project documents')],
              ),
            ),
            endSidebar: Sidebar(
              minWidth: 200,
              startWidth: 240,
              maxWidth: 300,
              windowBreakpoint: 1100,
              topOffset: 0,
              shownByDefault: false,
              builder: (context, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.all(MacosChromeData.contentInset),
                children: [
                  const Text('Selected document'),
                  if (selected == null)
                    const Text('Select a document to inspect.')
                  else ...[
                    Text(documents[selected!]),
                    const Text('Session draft'),
                    MacosTextField(
                      key: ValueKey(selected),
                      controller: drafts.putIfAbsent(
                        selected!,
                        TextEditingController.new,
                      ),
                      placeholder: 'Notes for selected document',
                    ),
                  ],
                ],
              ),
            ),
            child: Builder(
              builder: (context) {
                shellContext = context;
                return MacosScaffold(
                  children: [
                    ContentArea(
                      builder: (context, controller) => MacosScrollbar(
                        controller: controller,
                        child: Padding(
                          padding: const EdgeInsets.all(
                            MacosChromeData.contentInset,
                          ),
                          child: detail
                              ? SingleChildScrollView(
                                  controller: controller,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        documents[selected!],
                                        style: MacosTheme.of(
                                          context,
                                        ).typography.title1,
                                      ),
                                      const SizedBox(
                                        height: MacosChromeData.gap,
                                      ),
                                      const Text(
                                        'Readable document content. Previous/Next '
                                        'browse the filtered results; Back returns to the '
                                        'collection with query and selection retained.',
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Project documents'),
                                    Text(dateStatus),
                                    if (showDateFallback)
                                      MacosDateSelectionFallback(
                                        key: dateFallback,
                                        selection: dateTask!,
                                        enabled: !detail && matches.isNotEmpty,
                                        onResult: dateResult,
                                      ),
                                    const SizedBox(height: MacosChromeData.gap),
                                    if (matches.isEmpty)
                                      const Text(
                                        'No matching documents. Clear the filter.',
                                      ),
                                    Expanded(
                                      child: ListView(
                                        controller: controller,
                                        children: [
                                          for (final index in matches)
                                            MacosListTile(
                                              title: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      presentation == 'compact'
                                                      ? 0
                                                      : MacosChromeData.gap,
                                                ),
                                                child: Text(documents[index]),
                                              ),
                                              selected: selected == index,
                                              onClick: () => setState(
                                                () => selected = index,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    PushButton(
                                      controlSize: ControlSize.regular,
                                      onPressed: matches.contains(selected)
                                          ? () => setState(() => detail = true)
                                          : null,
                                      child: const Text(
                                        'Open selected document',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return window;
    // App-owned menus reuse the same command callbacks as toolbar and shortcuts.
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Documents',
          menus: [
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ],
        ),
        PlatformMenu(
          label: 'Navigate',
          menus: [
            PlatformMenuItem(
              label: 'Find project documents',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyF,
                meta: true,
              ),
              onSelected: !detail ? findDocuments : null,
            ),
            for (var i = 0; i < allCommands.length; i++)
              PlatformMenuItem(
                label: allCommands[i].label,
                shortcut: keys[i],
                onSelected: allCommands[i].onPressed,
              ),
            PlatformMenuItem(
              label: dateCommand.label,
              onSelected: dateCommand.onPressed,
            ),
          ],
        ),
        PlatformMenu(
          label: 'Window',
          menus: [
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.toggleFullScreen,
            ),
          ],
        ),
      ],
      child: window,
    );
  }
}
