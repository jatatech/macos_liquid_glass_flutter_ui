import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

import 'example_menu.dart';

/// Offline, session-only photography workspace using public library APIs.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    WidgetsBinding.instance.platformMenuDelegate = DefaultPlatformMenuDelegate(
      channel: const ExampleMenuChannel(),
    );
    await const MacosWindowUtilsConfig(
      enableFullSizeContentView: false,
      makeTitlebarTransparent: false,
      removeMenubarInFullScreenMode: false,
      autoHideToolbarAndMenuBarInFullScreenMode: false,
    ).apply();
    final frame = await WindowManipulator.getWindowFrame();
    await WindowManipulator.setWindowFrame(
      Rect.fromLTWH(frame.left, frame.top, 1280, 800),
    );
    await WindowManipulator.setWindowMinSize(const Size(700, 540));
  }
  runApp(const FieldnotesApp());
}

class FieldnotesApp extends StatefulWidget {
  const FieldnotesApp({super.key});
  @override
  State<FieldnotesApp> createState() => _FieldnotesAppState();
}

class _FieldnotesAppState extends State<FieldnotesApp> {
  bool dark = true;
  @override
  Widget build(BuildContext context) => MacosApp(
    title: 'Fieldnotes',
    debugShowCheckedModeBanner: false,
    theme: MacosThemeData.light(),
    darkTheme: MacosThemeData.dark(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: FieldnotesLibrary(onAppearance: () => setState(() => dark = !dark)),
  );
}

@immutable
class FieldPhoto {
  const FieldPhoto(this.asset, this.title, this.album, this.date, this.note);
  final String asset, title, album, date, note;
  String get path => 'assets/fieldnotes/$asset.jpg';
  String get filename => 'FN_${asset.toUpperCase()}.jpg';
}

// Editorial sample metadata; photography sources/licenses accompany the assets.
const fieldPhotos = [
  FieldPhoto(
    'lake',
    'First light on the lake',
    'Mountains',
    '6 November 2026',
    'A quiet shoreline before the first boats arrived. Keep the pale morning light and the reflection in the final selection.',
  ),
  FieldPhoto(
    'alpine',
    'An afternoon afloat',
    'Mountains',
    '6 November 2026',
    'The water was clear enough to see the lakebed. A small boat gives the landscape its sense of scale.',
  ),
  FieldPhoto(
    'coast',
    'Between the tides',
    'Coast',
    '4 November 2026',
    'Low waves and a nearly empty horizon. Part of the study of changing light along the coast.',
  ),
  FieldPhoto(
    'forest',
    'The long way home',
    'Woodland',
    '3 November 2026',
    'The path follows the light through the trees. Retain the warm highlights against the darker woodland.',
  ),
  FieldPhoto(
    'dunes',
    'Beyond the red valley',
    'Desert',
    '29 October 2026',
    'An open road through sandstone country. The distant formations belong in the wider landscape edit.',
  ),
  FieldPhoto(
    'aurora',
    'A sky worth waiting for',
    'After dark',
    '27 October 2026',
    'The colour appeared just after the clouds cleared. A favourite from the night-sky collection.',
  ),
  FieldPhoto(
    'ridge',
    'Above the cloud line',
    'Mountains',
    '24 October 2026',
    'Layers of snow and rock disappearing into cloud. Look for the softer details along the far ridge.',
  ),
  FieldPhoto(
    'waterfall',
    'The sound of falling water',
    'Woodland',
    '22 October 2026',
    'A sheltered waterfall after a week of rain. Leave room around the pool when preparing the print.',
  ),
  FieldPhoto(
    'sea',
    'The last light',
    'Coast',
    '20 October 2026',
    'The sky changed quickly after sunset. A quieter companion to the open-water photographs.',
  ),
  FieldPhoto(
    'woods',
    'Stillness in the pines',
    'Woodland',
    '18 October 2026',
    'Mist settled between the trees for a few minutes. The diagonal light makes this frame worth keeping.',
  ),
  FieldPhoto(
    'valley',
    'A meadow beneath the cliffs',
    'Mountains',
    '15 October 2026',
    'The foreground tells as much of the story as the mountain. Include the meadow in the landscape sequence.',
  ),
  FieldPhoto(
    'summit',
    'After everyone had gone',
    'After dark',
    '12 October 2026',
    'One last frame before packing up. Keep the natural colour of the sky rather than lifting every shadow.',
  ),
];

class FieldnotesLibrary extends StatefulWidget {
  const FieldnotesLibrary({super.key, required this.onAppearance});
  final VoidCallback onAppearance;
  @override
  State<FieldnotesLibrary> createState() => _FieldnotesLibraryState();
}

class _FieldnotesLibraryState extends State<FieldnotesLibrary> {
  static const albums = [
    'All photographs',
    'Favourites',
    'Mountains',
    'Woodland',
    'Coast',
    'After dark',
    'Desert',
  ];
  static const icons = [
    CupertinoIcons.photo_on_rectangle,
    CupertinoIcons.heart,
    CupertinoIcons.triangle,
    CupertinoIcons.tree,
    CupertinoIcons.drop,
    CupertinoIcons.moon_stars,
    CupertinoIcons.sun_max,
  ];
  final search = TextEditingController();
  final searchFocus = FocusNode();
  final toolbar = MacosNativeToolbarController();
  final panes = MacosPaneLayoutController();
  final notes = <String, TextEditingController>{};
  final favourites = <String>{'lake', 'aurora', 'forest', 'sea'};
  int album = 0;
  String selected = 'lake';
  String query = '';
  bool detail = false;
  BuildContext? shellContext;

  List<FieldPhoto> get results => fieldPhotos.where((photo) {
    final inAlbum =
        album == 0 ||
        (album == 1
            ? favourites.contains(photo.asset)
            : photo.album == albums[album]);
    return inAlbum &&
        '${photo.title} ${photo.album} ${photo.note}'.toLowerCase().contains(
          query.toLowerCase(),
        );
  }).toList();
  FieldPhoto get photo => fieldPhotos.firstWhere((p) => p.asset == selected);

  void filter(String value) => setState(() => query = value);
  void selectAlbum(int value) => setState(() {
    album = value;
    detail = false;
    if (results.isNotEmpty && !results.any((p) => p.asset == selected)) {
      selected = results.first.asset;
    }
  });
  void toggleFavourite() => setState(() {
    if (!favourites.add(selected)) favourites.remove(selected);
  });
  void move(int delta) {
    final matches = results;
    final index = matches.indexWhere((p) => p.asset == selected);
    if (index + delta >= 0 && index + delta < matches.length) {
      setState(() => selected = matches[index + delta].asset);
    }
  }

  Future<void> find() async {
    if (detail) setState(() => detail = false);
    if (!await toolbar.focusSearch('photo-search') && mounted) {
      searchFocus.requestFocus();
    }
  }

  void paneChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    panes.addListener(paneChanged);
  }

  @override
  void dispose() {
    panes.removeListener(paneChanged);
    panes.dispose();
    search.dispose();
    searchFocus.dispose();
    for (final controller in notes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    final type = MacosTheme.of(context).typography;
    final matches = results;
    final index = matches.indexWhere((p) => p.asset == selected);
    final commands = [
      MacosNativeToolbarCommand(
        id: 'back',
        label: 'Back to photographs',
        symbol: 'chevron.backward',
        onPressed: detail ? () => setState(() => detail = false) : null,
      ),
      MacosNativeToolbarCommand(
        id: 'open',
        label: 'Open photograph',
        symbol: 'arrow.up.left.and.arrow.down.right',
        onPressed: !detail && index >= 0
            ? () => setState(() => detail = true)
            : null,
      ),
      MacosNativeToolbarCommand(
        id: 'favourite',
        label: favourites.contains(selected)
            ? 'Remove favourite'
            : 'Add favourite',
        symbol: favourites.contains(selected) ? 'heart.fill' : 'heart',
        onPressed: index >= 0 ? toggleFavourite : null,
      ),
      MacosNativeToolbarCommand(
        id: 'inspector',
        label: 'Toggle photo information',
        symbol: 'sidebar.right',
        onPressed:
            (panes.value?.size.width ?? 0) >= 1050 && shellContext != null
            ? () => MacosWindowScope.of(shellContext!).toggleEndSidebar()
            : null,
      ),
      MacosNativeToolbarCommand(
        id: 'appearance',
        label: 'Switch appearance',
        symbol: 'circle.lefthalf.filled',
        onPressed: widget.onAppearance,
      ),
    ];
    Widget library = MacosNativeToolbar(
      title: detail ? photo.title : 'Fieldnotes',
      windowTitle: detail
          ? '${photo.title} — Fieldnotes'
          : 'Fieldnotes — ${albums[album]}',
      controller: toolbar,
      paneLayoutController: panes,
      glassTitlebar: true,
      items: [
        MacosNativeToolbarCommandItem(
          command: commands.first,
          placement: MacosNativeToolbarPlacement.leading,
        ),
        for (final command in commands.skip(1))
          MacosNativeToolbarCommandItem(command: command),
        MacosNativeToolbarSearch(
          id: 'photo-search',
          label: 'Search photographs',
          controller: search,
          enabled: !detail,
          onChanged: filter,
        ),
      ],
      fallback: Padding(
        padding: const EdgeInsets.all(MacosChromeData.gap),
        child: Wrap(
          spacing: MacosChromeData.gap,
          runSpacing: MacosChromeData.gap,
          children: [
            SizedBox(
              width: 220,
              child: MacosTextField(
                controller: search,
                focusNode: searchFocus,
                placeholder: 'Search photographs',
                enabled: !detail,
                onChanged: filter,
              ),
            ),
            for (final command in commands)
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: command.onPressed,
                child: Text(command.label),
              ),
          ],
        ),
      ),
      child: MacosWindow(
        paneLayoutController: panes,
        disableWallpaperTinting: true,
        sidebar: Sidebar(
          minWidth: 180,
          startWidth: 200,
          maxWidth: 260,
          windowBreakpoint: 820,
          topOffset: 0,
          builder: (context, controller) => Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 22),
                  child: Row(
                    children: [
                      const MacosIcon(
                        CupertinoIcons.camera_on_rectangle,
                        size: 25,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fieldnotes',
                          style: type.title3.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Text(
                    'LIBRARY',
                    style: type.caption1.copyWith(
                      color: chrome.secondaryForeground,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                Expanded(
                  child: SidebarItems(
                    scrollController: controller,
                    currentIndex: album,
                    onChanged: selectAlbum,
                    itemSize: SidebarItemSize.large,
                    items: [
                      for (var i = 0; i < albums.length; i++)
                        SidebarItem(
                          leading: MacosIcon(icons[i], size: 17),
                          label: Text(albums[i]),
                          trailing: Text(
                            '${i == 0
                                ? fieldPhotos.length
                                : i == 1
                                ? favourites.length
                                : fieldPhotos.where((p) => p.album == albums[i]).length}',
                            style: type.caption1,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        endSidebar: Sidebar(
          minWidth: 230,
          startWidth: 250,
          maxWidth: 320,
          windowBreakpoint: 1050,
          topOffset: 0,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Text('Photo information', style: type.headline),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  MacosChromeData.controlRadius,
                ),
                child: Image.asset(
                  photo.path,
                  height: 142,
                  fit: BoxFit.cover,
                  semanticLabel: photo.title,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                photo.title,
                style: type.title3.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              Text(
                photo.album,
                style: type.body.copyWith(color: chrome.secondaryForeground),
              ),
              const SizedBox(height: 24),
              _metadata(context, 'Added', photo.date),
              _metadata(context, 'File', photo.filename),
              _metadata(context, 'Collection', photo.album),
              const SizedBox(height: 22),
              Text(
                'FIELD NOTES',
                style: type.caption1.copyWith(
                  color: chrome.secondaryForeground,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 10),
              MacosTextField(
                key: ValueKey(photo.asset),
                controller: notes.putIfAbsent(
                  photo.asset,
                  () => TextEditingController(text: photo.note),
                ),
                maxLines: 7,
                style: type.body.copyWith(height: 1.5),
              ),
              const SizedBox(height: 18),
              PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: toggleFavourite,
                child: Text(
                  favourites.contains(selected)
                      ? 'Remove from favourites'
                      : 'Add to favourites',
                ),
              ),
            ],
          ),
        ),
        child: Builder(
          builder: (context) {
            shellContext = context;
            return MacosScaffold(
              backgroundColor: chrome.canvas,
              children: [
                ContentArea(
                  builder: (context, controller) {
                    if (detail) {
                      return MacosGlassCommandSurface(
                        commands: [
                          MacosGlassCommand(
                            label: 'Previous',
                            onPressed: index > 0 ? () => move(-1) : null,
                          ),
                          MacosGlassCommand(
                            label: favourites.contains(selected)
                                ? 'Unfavourite'
                                : 'Favourite',
                            onPressed: toggleFavourite,
                          ),
                          MacosGlassCommand(
                            label: 'Next',
                            onPressed: index >= 0 && index < matches.length - 1
                                ? () => move(1)
                                : null,
                          ),
                        ],
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              photo.path,
                              fit: BoxFit.cover,
                              semanticLabel: photo.title,
                            ),
                          ],
                        ),
                      );
                    }
                    return MacosScrollbar(
                      controller: controller,
                      child: CustomScrollView(
                        controller: controller,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    albums[album],
                                    style: type.largeTitle.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      query.isEmpty
                                          ? '${matches.length} photographs · Autumn collection'
                                          : '${matches.length} results for “$query”',
                                      style: type.body.copyWith(
                                        color: chrome.secondaryForeground,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (matches.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No photographs found',
                                      style: type.title2,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Try another title, collection or word from your notes.',
                                    ),
                                    const SizedBox(height: 16),
                                    PushButton(
                                      controlSize: ControlSize.regular,
                                      onPressed: () {
                                        search.clear();
                                        filter('');
                                      },
                                      child: const Text('Clear search'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                              sliver: SliverLayoutBuilder(
                                builder: (context, constraints) {
                                  final columns =
                                      (constraints.crossAxisExtent / 250)
                                          .floor()
                                          .clamp(1, 4);
                                  final textScale = MediaQuery.textScalerOf(
                                    context,
                                  ).scale(1);
                                  return SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columns,
                                          crossAxisSpacing: 18,
                                          mainAxisSpacing: 18,
                                          mainAxisExtent: 198 + 55 * textScale,
                                        ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, n) =>
                                          _tile(context, matches[n]),
                                      childCount: matches.length,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
    library = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): find,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (detail) setState(() => detail = false);
        },
      },
      child: Focus(autofocus: true, child: library),
    );
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      library = PlatformMenuBar(
        menus: [
          const PlatformMenu(
            label: 'Fieldnotes',
            menus: [
              PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
            ],
          ),
          PlatformMenu(
            label: 'Photographs',
            menus: [
              PlatformMenuItem(
                label: 'Find photographs',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyF,
                  meta: true,
                ),
                onSelected: find,
              ),
              for (final command in commands)
                PlatformMenuItem(
                  label: command.label,
                  onSelected: command.onPressed,
                ),
            ],
          ),
          PlatformMenu(
            label: 'Window',
            menus: [
              PlatformMenuItem(
                label: 'Enter Full Screen',
                onSelected: WindowManipulator.enterFullscreen,
              ),
            ],
          ),
        ],
        child: library,
      );
    }
    return library;
  }

  Widget _metadata(BuildContext context, String label, String value) {
    final type = MacosTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: type.caption1.copyWith(
              color: MacosChromeData.of(context).secondaryForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: type.body),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, FieldPhoto item) {
    final chrome = MacosChromeData.of(context);
    final type = MacosTheme.of(context).typography;
    final active = selected == item.asset;
    return Semantics(
      selected: active,
      label: '${item.title}, ${item.album}',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.topLeft,
        onPressed: () => setState(() => selected = item.asset),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? chrome.focusRing : CupertinoColors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  MacosChromeData.controlRadius,
                ),
                child: Image.asset(
                  item.path,
                  height: 178,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (favourites.contains(item.asset))
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: MacosIcon(
                        CupertinoIcons.heart_fill,
                        size: 12,
                        color: chrome.foreground,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                item.album,
                style: type.caption1.copyWith(
                  color: chrome.secondaryForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
