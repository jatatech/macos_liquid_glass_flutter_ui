import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

const boundaryKey = ValueKey('state-capture');

Color textColor(WidgetTester tester, String text) =>
    (tester
                .widget<RichText>(
                  find.descendant(
                    of: find.text(text),
                    matching: find.byType(RichText),
                  ),
                )
                .text
            as TextSpan)
        .style!
        .color!;

Color fillFor(WidgetTester tester, String text) => tester
    .widgetList<Container>(
      find.ancestor(of: find.text(text), matching: find.byType(Container)),
    )
    .map((c) => c.decoration)
    .whereType<ShapeDecoration>()
    .first
    .color!;

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
}

Future<void> fixture(
  WidgetTester tester,
  MacosThemeData theme, {
  bool highContrast = false,
  Color? selectedColor,
  FocusNode? node,
}) async {
  await tester.pumpWidget(
    MacosApp(
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: MacosTheme(
          data: theme,
          child: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: theme.canvasColor,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 270,
                  child: Column(
                    children: [
                      Expanded(
                        child: SidebarItems(
                          currentIndex: 0,
                          onChanged: (_) {},
                          selectedColor: selectedColor,
                          items: [
                            SidebarItem(
                              focusNode: node,
                              label: const Text('Selected'),
                              leading: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MacosIcon(CupertinoIcons.star),
                                  Icon(CupertinoIcons.star),
                                ],
                              ),
                              trailing: const Text('12'),
                            ),
                            const SidebarItem(
                              label: Text(
                                'Explicit',
                                style: TextStyle(color: Color(0xffaa33aa)),
                              ),
                              leading: MacosIcon(
                                CupertinoIcons.star,
                                color: Color(0xffaa33aa),
                              ),
                              trailing: Icon(
                                CupertinoIcons.star,
                                color: Color(0xffaa33aa),
                              ),
                            ),
                            const SidebarItem(
                              label: Text('Folder'),
                              expandDisclosureItems: true,
                              disclosureItems: [
                                SidebarItem(label: Text('Child')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ToolbarOverflowMenuItem(
                        label: 'Menu',
                        isSelected: true,
                        onPressed: () {},
                      ),
                      const ToolbarOverflowMenuItem(label: 'Disabled'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> checkRow(WidgetTester tester, String label, Color surface) async {
  final fill = Color.alphaBlend(fillFor(tester, label), surface);
  final foreground = textColor(tester, label);
  expect(contrast(foreground, fill), greaterThanOrEqualTo(4.5));
  if (label == 'Selected') {
    expect(textColor(tester, '12'), foreground);
    final row = find
        .ancestor(of: find.text(label), matching: find.byType(Row))
        .first;
    final icons = tester.widgetList<RichText>(
      find.descendant(of: row, matching: find.byType(RichText)),
    );
    for (final icon in icons) {
      expect((icon.text as TextSpan).style!.color, foreground);
    }
    // Check a painted pixel in the row's clear interior, away from glyphs.
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final image = (await tester.runAsync(() => boundary.toImage()))!;
    final bytes = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    final rect = tester.getRect(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is ShapeDecoration,
            ),
          )
          .first,
    );
    final origin = tester.getTopLeft(find.byKey(boundaryKey));
    final x = (rect.right - origin.dx - 5).toInt();
    final y = (rect.center.dy - origin.dy).toInt();
    final offset = (y * image.width + x) * 4;
    final pixel = Color.fromARGB(
      bytes.getUint8(offset + 3),
      bytes.getUint8(offset),
      bytes.getUint8(offset + 1),
      bytes.getUint8(offset + 2),
    );
    expect(pixel.toARGB32(), fill.toARGB32());
    image.dispose();
  }
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('$brightness accents active/inactive contrast and held press', (
      tester,
    ) async {
      for (final accent in AccentColor.values) {
        for (final active in [true, false]) {
          for (final highContrast in [false, true]) {
            final theme = MacosThemeData(
              brightness: brightness,
              accentColor: accent,
              isMainWindow: active,
            );
            await fixture(tester, theme, highContrast: highContrast);
            await checkRow(tester, 'Selected', theme.canvasColor);
            expect(
              contrast(
                textColor(tester, 'Menu'),
                highContrast
                    ? MacosChromeData.of(
                        tester.element(find.text('Menu')),
                      ).foreground
                    : active
                    ? theme.primaryColor
                    : MacosChromeData.of(
                        tester.element(find.text('Menu')),
                      ).separator,
              ),
              greaterThanOrEqualTo(4.5),
            );
            final gesture = await tester.startGesture(
              tester.getCenter(find.text('Selected')),
            );
            await tester.pump(const Duration(milliseconds: 150));
            await checkRow(tester, 'Selected', theme.canvasColor);
            await gesture.cancel();
            await tester.pump();
          }
        }
      }
    });
  }
  testWidgets(
    'dynamic/custom translucent selection, inheritance and explicit overrides',
    (tester) async {
      for (final brightness in Brightness.values) {
        final theme = MacosThemeData(brightness: brightness);
        await fixture(
          tester,
          theme,
          selectedColor: const CupertinoDynamicColor.withBrightness(
            color: Color(0x80ce9a02),
            darkColor: Color(0x801d97ff),
          ),
        );
        await checkRow(tester, 'Selected', theme.canvasColor);
        expect(textColor(tester, 'Explicit'), const Color(0xffaa33aa));
        final explicitRow = find
            .ancestor(of: find.text('Explicit'), matching: find.byType(Row))
            .first;
        for (final rich in tester.widgetList<RichText>(
          find.descendant(of: explicitRow, matching: find.byType(RichText)),
        )) {
          expect((rich.text as TextSpan).style!.color, const Color(0xffaa33aa));
        }
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Explicit')),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(textColor(tester, 'Explicit'), const Color(0xffaa33aa));
        await gesture.cancel();
        await tester.pump();
        final disabled = tester.getSemantics(find.text('Disabled'));
        expect(
          disabled.getSemanticsData().hasAction(ui.SemanticsAction.tap),
          isFalse,
        );
      }
    },
  );
  testWidgets('focus hover disclosure and overflow press follow painted fill', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    final theme = MacosThemeData.dark();
    await fixture(tester, theme, node: node);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    node.requestFocus();
    await tester.pumpAndSettle();
    await checkRow(tester, 'Selected', theme.canvasColor);
    expect(
      tester
          .widgetList<Container>(find.byType(Container))
          .any(
            (c) =>
                c.decoration is ShapeDecoration &&
                (c.decoration! as ShapeDecoration).shape.dimensions.horizontal >
                    0,
          ),
      isTrue,
    );
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Folder')));
    await tester.pump();
    await checkRow(tester, 'Folder', theme.canvasColor);
    final row = find
        .ancestor(of: find.text('Folder'), matching: find.byType(Row))
        .first;
    final disclosure = tester.widget<Icon>(
      find.descendant(of: row, matching: find.byType(Icon)),
    );
    expect(disclosure.color, textColor(tester, 'Folder'));
    await mouse.removePointer();
    final menuGesture = await tester.startGesture(
      tester.getCenter(find.text('Menu')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final chrome = MacosChromeData.of(tester.element(find.text('Menu')));
    expect(
      contrast(textColor(tester, 'Menu'), chrome.pressed),
      greaterThanOrEqualTo(4.5),
    );
    await menuGesture.cancel();
    await tester.pump();
  });

  // Opt-in artifacts are synthetic Flutter renders, never native screenshots or
  // golden updates. No files are written during ordinary regression runs.
  const output = String.fromEnvironment('HIG_COLOR_CAPTURE_DIR');
  if (output.isNotEmpty) {
    testWidgets('capture light/dark held-pointer evidence', (tester) async {
      await tester.runAsync(() async {
        final font = FontLoader('.AppleSystemUIFont')
          ..addFont(
            File(
              '/System/Library/Fonts/SFNS.ttf',
            ).readAsBytes().then((b) => ByteData.sublistView(b)),
          );
        await font.load();
        final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
          ..addFont(
            rootBundle.load(
              'packages/cupertino_icons/assets/CupertinoIcons.ttf',
            ),
          );
        await icons.load();
      });
      for (final brightness in Brightness.values) {
        await fixture(tester, MacosThemeData(brightness: brightness));
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Selected')),
        );
        await tester.pump(const Duration(milliseconds: 150));
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundaryKey),
        );
        final image = (await tester.runAsync(() => boundary.toImage()))!;
        final png = await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        );
        await tester.runAsync(
          () => File(
            '$output/${brightness.name}-pressed.png',
          ).writeAsBytes(png!.buffer.asUint8List()),
        );
        image.dispose();
        await gesture.cancel();
      }
    });
  }
}
