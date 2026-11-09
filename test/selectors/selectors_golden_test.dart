import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import '../fields/field_interactions_test.dart' show host;

// Flutter Ahem / CupertinoIcons 1.0.8 / DPR 1, deterministic selected dates.
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
      testWidgets('selectors dark=$dark contrast=$contrast', (t) async {
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          host(
            RepaintBoundary(
              key: const ValueKey('selectors'),
              child: Builder(
                builder: (context) => ColoredBox(
                  color: MacosChromeData.of(context).canvas,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MacosSlider(value: 0.4, onChanged: (_) {}),
                        MacosSlider(
                          value: 15,
                          min: 10,
                          max: 20,
                          splits: 3,
                          discrete: true,
                          onChanged: (_) {},
                        ),
                        const MacosSlider(value: 0.4, onChanged: null),
                        const ProgressBar(value: 35, semanticLabel: 'Export'),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ProgressCircle(value: 35),
                            ProgressCircle(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MacosPopupButton<String>(
                          items: const [
                            MacosPopupMenuItem(
                              value: 'a',
                              child: Text('Balanced'),
                            ),
                          ],
                          value: 'a',
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 8),
                        MacosColorWell(
                          color: CupertinoColors.systemGreen,
                          onColorSelected: (_) {},
                        ),
                        const SizedBox(height: 8),
                        MacosDatePicker(
                          initialDate: DateTime(2024, 2, 29),
                          onDateChanged: (_) {},
                        ),
                        const SizedBox(height: 8),
                        MacosTimePicker(
                          initialTime: const TimeOfDay(hour: 10, minute: 30),
                          onTimeChanged: (_) {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            dark: dark,
            contrast: contrast,
            motion: true,
          ),
        );
        await t.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('selectors')),
          matchesGoldenFile(
            'goldens/selectors_${dark ? 'dark' : 'light'}_${contrast ? 'contrast' : 'standard'}.png',
          ),
        );
        await t.pumpWidget(const SizedBox());
      });
    }
  }
}
