import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'dense_content_interactions_test.dart' show host;

// Ahem text, loaded CupertinoIcons 1.0.8, DPR 1, fixed blue accent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final icons = FontLoader('packages/cupertino_icons/CupertinoIcons');
    icons.addFont(
      rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
    );
    await icons.load();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('appkit_ui_element_colors'),
          (call) async => call.method == 'getColorComponents'
              ? {'hueComponent': 0.6085324903200698}
              : null,
        );
  });
  tearDownAll(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('appkit_ui_element_colors'),
          null,
        ),
  );
  for (final dark in [false, true]) {
    for (final contrast in [false, true]) {
      testWidgets('dense content dark=$dark contrast=$contrast', (t) async {
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetDevicePixelRatio);
        final focus = FocusNode();
        final tabs = MacosTabController(length: 2);
        final scroll = ScrollController();
        await t.pumpWidget(
          host(
            RepaintBoundary(
              key: const ValueKey('dense'),
              child: MacosTabView(
                controller: tabs,
                tabs: const [
                  MacosTab(label: 'Files'),
                  MacosTab(label: 'History'),
                ],
                children: [
                  ScrollConfiguration(
                    behavior: const MacosScrollBehavior().copyWith(
                      scrollbars: false,
                    ),
                    child: MacosScrollbar(
                      controller: scroll,
                      thumbVisibility: true,
                      child: ListView(
                        controller: scroll,
                        padding: const EdgeInsets.all(8),
                        children: [
                          for (var i = 0; i < 10; i++)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12,
                                right: 12,
                              ),
                              child: MacosListTile(
                                key: ValueKey('row-$i'),
                                title: Text(
                                  [
                                    'Selected',
                                    'Hovered',
                                    'Pressed',
                                    'Disabled',
                                    'Document',
                                  ][i.clamp(0, 4)],
                                ),
                                subtitle: const Text('Ready for review'),
                                leading: const MacosIcon(
                                  CupertinoIcons.doc_text,
                                ),
                                focusNode: i == 0 ? focus : null,
                                selected: i == 0,
                                enabled: i != 3,
                                onClick: () {},
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Text('No hidden content'),
                ],
              ),
            ),
            dark: dark,
            contrast: contrast,
            motion: true,
          ),
        );
        await t.pumpAndSettle();
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(
          location: t.getCenter(find.byKey(const ValueKey('row-1'))),
        );
        await mouse.moveTo(t.getCenter(find.byKey(const ValueKey('row-1'))));
        final press = await t.startGesture(
          t.getCenter(find.byKey(const ValueKey('row-2'))),
        );
        await t.pump(const Duration(milliseconds: 110));
        focus.requestFocus();
        await t.pump();
        await expectLater(
          find.byKey(const ValueKey('dense')),
          matchesGoldenFile(
            'goldens/dense_${dark ? 'dark' : 'light'}_${contrast ? 'contrast' : 'standard'}.png',
          ),
        );
        await press.cancel();
        await mouse.removePointer();
        await t.pumpWidget(const SizedBox());
        focus.dispose();
        tabs.dispose();
        scroll.dispose();
      });
    }
  }
}
