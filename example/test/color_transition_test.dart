import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:shell_gallery/main.dart';

void main() {
  testWidgets(
    'gallery selection survives light/dark and reduced-motion changes',
    (tester) async {
      const output = String.fromEnvironment('HIG_COLOR_CAPTURE_DIR');
      if (output.isNotEmpty) {
        await tester.runAsync(() async {
          final font = FontLoader('.AppleSystemUIFont')
            ..addFont(
              File(
                '/System/Library/Fonts/SFNS.ttf',
              ).readAsBytes().then((b) => ByteData.sublistView(b)),
            );
          await font.load();
          for (final family in [
            'CupertinoSystemText',
            'CupertinoSystemDisplay',
          ]) {
            final system = FontLoader(family)
              ..addFont(
                File(
                  '/System/Library/Fonts/SFNS.ttf',
                ).readAsBytes().then((b) => ByteData.sublistView(b)),
              );
            await system.load();
          }
          final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
            ..addFont(
              rootBundle.load(
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
              ),
            );
          await icons.load();
        });
      }
      tester.view.physicalSize = const Size(1100, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      const capture = ValueKey('gallery-color-capture');
      for (final brightness in Brightness.values) {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        await tester.pumpWidget(
          const RepaintBoundary(key: capture, child: ShellGallery()),
        );
        await tester.pumpAndSettle();
        final selectedLabel = find.descendant(
          of: find.byType(SidebarItems),
          matching: find.text('Application shell'),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(selectedLabel),
        );
        await tester.pump(const Duration(milliseconds: 150));
        final context = tester.element(selectedLabel);
        expect(MacosTheme.of(context).brightness, brightness);
        expect(MediaQuery.disableAnimationsOf(context), isTrue);
        final label = tester.widget<RichText>(
          find.descendant(of: selectedLabel, matching: find.byType(RichText)),
        );
        final foreground = (label.text as TextSpan).style!.color!;
        final fill = MacosChromeData.of(context).pressed;
        final x = foreground.computeLuminance();
        final y = fill.computeLuminance();
        expect(
          ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05),
          greaterThanOrEqualTo(4.5),
        );
        if (output.isNotEmpty) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(capture),
          );
          final image = (await tester.runAsync(() => boundary.toImage()))!;
          final data = await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          );
          await tester.runAsync(
            () => File(
              '$output/gallery-${brightness.name}-pressed.png',
            ).writeAsBytes(data!.buffer.asUint8List()),
          );
          image.dispose();
        }
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      // Retire the gallery's borrowed/native-simulation resources before teardown.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
