import 'package:flutter/cupertino.dart' hide OverlayVisibilityMode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'field_interactions_test.dart' show host;

// Flutter Ahem, CupertinoIcons 1.0.8, DPR 1; not native typography evidence.
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
      testWidgets('fields dark=$dark contrast=$contrast', (t) async {
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetDevicePixelRatio);
        final c = TextEditingController(text: 'Report');
        final focus = FocusNode();
        await t.pumpWidget(
          host(
            RepaintBoundary(
              key: const ValueKey('fields'),
              child: Builder(
                builder: (context) => ColoredBox(
                  color: MacosChromeData.of(context).canvas,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MacosTextField(
                          controller: c,
                          focusNode: focus,
                          showCursor: false,
                          clearButtonMode: OverlayVisibilityMode.editing,
                        ),
                        const SizedBox(height: 12),
                        const MacosTextField(
                          placeholder: 'Read only',
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        const MacosTextField(
                          placeholder: 'Disabled',
                          enabled: false,
                        ),
                        const SizedBox(height: 12),
                        const MacosSearchField(placeholder: 'Find documents'),
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
        focus.requestFocus();
        await t.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('fields')),
          matchesGoldenFile(
            'goldens/fields_${dark ? 'dark' : 'light'}_${contrast ? 'contrast' : 'standard'}.png',
          ),
        );
        await t.pumpWidget(const SizedBox());
        c.dispose();
        focus.dispose();
      });
    }
  }
}
