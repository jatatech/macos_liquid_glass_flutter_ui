import 'dart:ui' show SemanticsAction;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  test('capability absence differs from accessibility and macOS failure', () {
    MacosGlassRendering mode({
      TargetPlatform platform = TargetPlatform.linux,
      bool web = false,
      bool opaque = false,
      bool active = false,
      bool requested = true,
      MacosAccessibilityData preferences = const MacosAccessibilityData(),
      MediaQueryData media = const MediaQueryData(),
    }) => MacosGlassData.rendering(
      platform: platform,
      web: web,
      accessibility: preferences,
      media: media,
      forceOpaque: opaque,
      nativeActive: active,
      nativeRequested: requested,
    );
    for (final platform in TargetPlatform.values) {
      expect(
        mode(platform: platform),
        platform == TargetPlatform.macOS
            ? MacosGlassRendering.opaque
            : MacosGlassRendering.approximation,
      );
    }
    expect(
      mode(web: true, platform: TargetPlatform.macOS),
      MacosGlassRendering.approximation,
    );
    expect(mode(opaque: true, active: true), MacosGlassRendering.opaque);
    expect(
      mode(media: const MediaQueryData(highContrast: true)),
      MacosGlassRendering.opaque,
    );
    expect(
      mode(preferences: const MacosAccessibilityData(available: true)),
      MacosGlassRendering.opaque,
    );
    expect(
      mode(preferences: const MacosAccessibilityData(increaseContrast: true)),
      MacosGlassRendering.opaque,
    );
    expect(
      mode(media: const MediaQueryData(disableAnimations: true)),
      MacosGlassRendering.approximation,
    );
    const permitted = MacosAccessibilityData(
      available: true,
      reduceTransparency: false,
    );
    expect(
      mode(platform: TargetPlatform.macOS, preferences: permitted),
      MacosGlassRendering.opaque,
    );
    expect(
      mode(
        platform: TargetPlatform.macOS,
        preferences: permitted,
        requested: false,
      ),
      MacosGlassRendering.approximation,
    );
    expect(
      mode(
        platform: TargetPlatform.macOS,
        preferences: permitted,
        active: true,
      ),
      MacosGlassRendering.native,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'portable ${brightness.name} surface interactions and live policy',
      (tester) async {
        var count = 0;
        final modes = <MacosGlassRendering>[];
        final calls = <MethodCall>[];
        const channel = MethodChannel('dev.groovinchip.macos_ui/glass');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            calls.add(call);
            return true;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        final capture = GlobalKey();
        Widget app({
          bool contrast = false,
          bool opaque = false,
          bool motion = false,
          bool flipAppearance = false,
          double width = 480,
          double scale = 1,
        }) => MacosApp(
          themeMode: (brightness == Brightness.dark) != flipAppearance
              ? ThemeMode.dark
              : ThemeMode.light,
          home: MediaQuery(
            data: MediaQueryData(
              highContrast: contrast,
              disableAnimations: motion,
              textScaler: TextScaler.linear(scale),
            ),
            child: Center(
              child: RepaintBoundary(
                key: capture,
                child: SizedBox(
                  width: width,
                  height: 240,
                  child: MacosGlassCommandSurface(
                    forceOpaque: opaque,
                    onRenderingChanged: modes.add,
                    commands: [
                      MacosGlassCommand(
                        label: 'Open notes',
                        onPressed: () => count++,
                      ),
                      const MacosGlassCommand(label: 'Archived'),
                    ],
                    child: const ColoredBox(
                      color: Color(0xFF176EBA),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text('Field collection'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(modes, [MacosGlassRendering.approximation]);
        expect(find.byType(BackdropFilter), findsOneWidget);
        final semantics = tester.ensureSemantics();
        expect(
          tester
              .getSemantics(find.text('Archived'))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          false,
        );
        await tester.tap(find.text('Open notes'));
        expect(count, 1);
        await tester.tap(
          find.text('Open notes'),
          buttons: kSecondaryMouseButton,
        );
        expect(count, 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(count, 2);
        semantics.dispose();
        // New baselines only; inherited component goldens remain untouched.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(capture),
          matchesGoldenFile(
            'goldens/glass_approximation_${brightness.name}.png',
          ),
        );
        await tester.pumpWidget(app(motion: true, flipAppearance: true));
        await tester.pumpAndSettle();
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(
          MacosTheme.of(
            tester.element(find.byType(MacosGlassSurface)),
          ).brightness,
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        );
        await tester.pumpWidget(app(contrast: true));
        await tester.pumpAndSettle();
        expect(modes.last, MacosGlassRendering.opaque);
        expect(find.byType(BackdropFilter), findsNothing);
        await tester.pumpWidget(app(opaque: true));
        await tester.pumpAndSettle();
        expect(find.byType(BackdropFilter), findsNothing);
        await tester.pumpWidget(app(width: 220, scale: 2));
        await tester.pumpAndSettle();
        expect(modes.last, MacosGlassRendering.approximation);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Open notes'));
        expect(count, 3);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(
          calls,
          isEmpty,
        ); // No native bridge requests on portable targets.
      },
    );
  }

  testWidgets('nested shared Flutter surfaces avoid nested backdrop filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MacosApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: MacosGlassSurface(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: MacosGlassSurface(child: Text('Nested label')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('Nested label'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
