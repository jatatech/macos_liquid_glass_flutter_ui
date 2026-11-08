import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'transient_interactions_test.dart' show host, alert;

// Ahem text, CupertinoIcons 1.0.8, DPR 1, fixed blue accent.
// Static surface matrix; route ownership is covered by interaction tests.
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
      testWidgets('transients dark=$dark contrast=$contrast', (t) async {
        t.view.physicalSize = const Size(800, 600);
        addTearDown(t.view.resetPhysicalSize);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          host(
            Builder(
              builder: (context) => ColoredBox(
                color: MacosChromeData.of(context).canvas,
                child: Row(
                  children: [
                    Expanded(child: alert(context)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 170,
                              child: MacosSheet(
                                insetPadding: EdgeInsets.zero,
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Review document'),
                                      SizedBox(height: 12),
                                      Text('Opaque sheet content'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ToolbarOverflowMenu(
                              children: [
                                const ToolbarOverflowMenuItem(
                                  label: 'Disabled command',
                                ),
                                ToolbarOverflowMenuItem(
                                  label: 'Hovered command',
                                  onPressed: () {},
                                ),
                                const MacosPulldownMenuDivider(),
                                const ToolbarOverflowMenuItem(
                                  label: 'More commands',
                                  subMenuItems: [
                                    ToolbarOverflowMenuItem(label: 'Child'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const MacosTooltip(
                              message: 'Document help',
                              useMousePosition: false,
                              child: Text('Hover for help'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            dark: dark,
            contrast: contrast,
            motion: true,
          ),
        );
        await t.pumpAndSettle();
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(t.getCenter(find.text('Hovered command')));
        await t.pumpAndSettle();
        final state = t.state(find.byType(MacosTooltip));
        // ignore: avoid_dynamic_calls
        (state as dynamic).ensureTooltipVisible();
        await t.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('transient-frame')),
          matchesGoldenFile(
            'goldens/transients_${dark ? 'dark' : 'light'}_${contrast ? 'contrast' : 'standard'}.png',
          ),
        );
        await mouse.removePointer();
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      });
    }
  }
}
