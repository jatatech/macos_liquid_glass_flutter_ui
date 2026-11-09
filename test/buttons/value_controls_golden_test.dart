import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'value_controls_test.dart' show host;

// Flutter-only baselines: Ahem test font, bundled CupertinoIcons glyphs,
// 1 logical pixel per physical pixel. No native screenshot comparison.
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
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('appkit_ui_element_colors'),
          null,
        );
  });
  for (final dark in [false, true]) {
    for (final contrast in [false, true]) {
      testWidgets('value matrix dark=$dark contrast=$contrast', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(700, 460);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final controller = MacosTabController(length: 3, initialIndex: 1);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          host(
            RepaintBoundary(
              key: const ValueKey('matrix'),
              child: Builder(
                builder: (context) => ColoredBox(
                  color: MacosChromeData.of(context).canvas,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final enabled in [true, false]) ...[
                          Text(enabled ? 'Enabled' : 'Disabled'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (final value in [false, true, null])
                                MacosCheckbox(
                                  value: value,
                                  onChanged: enabled ? (_) {} : null,
                                ),
                              for (final value in [false, true])
                                MacosRadioButton<bool>(
                                  value: value,
                                  groupValue: true,
                                  onChanged: enabled ? (_) {} : null,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (final size in [
                                ControlSize.mini,
                                ControlSize.small,
                                ControlSize.regular,
                              ])
                                for (final value in [false, true])
                                  MacosSwitch(
                                    value: value,
                                    size: size,
                                    onChanged: enabled ? (_) {} : null,
                                  ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                        MacosSegmentedControl(
                          tabs: const [
                            MacosTab(label: 'All'),
                            MacosTab(label: 'Recent'),
                            MacosTab(label: 'Shared'),
                          ],
                          controller: controller,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            dark: dark,
            contrast: contrast,
            reduced: true,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('matrix')),
          matchesGoldenFile(
            'goldens/values_${dark ? 'dark' : 'light'}_${contrast ? 'contrast' : 'standard'}.png',
          ),
        );
      });
    }
  }
  testWidgets('hover press and focus across each value control', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MacosTabController(length: 2);
    addTearDown(controller.dispose);
    for (final entry in <String, Widget>{
      'checkbox': MacosCheckbox(value: true, onChanged: (_) {}),
      'radio': MacosRadioButton<bool>(
        value: true,
        groupValue: true,
        onChanged: (_) {},
      ),
      'switch': MacosSwitch(value: true, onChanged: (_) {}),
      'segments': MacosSegmentedControl(
        controller: controller,
        tabs: const [
          MacosTab(label: 'All'),
          MacosTab(label: 'Recent'),
        ],
      ),
    }.entries) {
      await tester.pumpWidget(
        host(
          RepaintBoundary(
            key: ValueKey(entry.key),
            child: Builder(
              builder: (context) => ColoredBox(
                color: MacosChromeData.of(context).canvas,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: entry.value,
                ),
              ),
            ),
          ),
          reduced: true,
          contrast: true,
        ),
      );
      await tester.pumpAndSettle();
      final target = entry.key == 'segments'
          ? find.text('All')
          : find.byWidget(entry.value);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(target));
      await mouse.down(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, true);
      await expectLater(
        find.byKey(ValueKey(entry.key)),
        matchesGoldenFile('goldens/values_${entry.key}_held.png'),
      );
      await mouse.cancel();
      await mouse.removePointer();
      await tester.pumpAndSettle();
    }
  });
}
