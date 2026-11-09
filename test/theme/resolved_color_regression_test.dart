import 'dart:ui' show ColorSpace;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

void main() {
  const variants = [
    Color(0x400058e0),
    Color(0x801d97ff),
    Color(0xffce9a02),
    Color(0xffabcdef),
    Color(0xff123456),
    Color(0xff654321),
    Color(0xffaabbcc),
    Color.from(
      alpha: .7,
      red: .8,
      green: .2,
      blue: .3,
      colorSpace: ColorSpace.displayP3,
    ),
  ];
  final dynamic = CupertinoDynamicColor(
    color: variants[0],
    darkColor: variants[1],
    highContrastColor: variants[2],
    darkHighContrastColor: variants[3],
    elevatedColor: variants[4],
    darkElevatedColor: variants[5],
    highContrastElevatedColor: variants[6],
    darkHighContrastElevatedColor: variants[7],
  );
  testWidgets('resolved operations agree and traits update live', (
    tester,
  ) async {
    final resolved = <Color>[];
    for (var i = 0; i < 8; i++) {
      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.light(),
          darkTheme: MacosThemeData.dark(),
          themeMode: i.isOdd ? ThemeMode.dark : ThemeMode.light,
          home: MediaQuery(
            data: MediaQueryData(highContrast: i % 4 >= 2),
            child: CupertinoUserInterfaceLevel(
              data: i >= 4
                  ? CupertinoUserInterfaceLevelData.elevated
                  : CupertinoUserInterfaceLevelData.base,
              child: Builder(
                builder: (context) {
                  final snapshot = MacosDynamicColor.resolve(
                    resolved.isEmpty ? dynamic : resolved.last,
                    context,
                  );
                  final again = MacosDynamicColor.resolve(snapshot, context);
                  expect(again, snapshot);
                  expect(again.hashCode, snapshot.hashCode);
                  expect(snapshot, isNot(variants[i]));
                  resolved.add(snapshot);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      final actual = resolved.last;
      final expected = variants[i];
      expect(actual, isA<ResolvedMacosDynamicColor>());
      expect(
        [actual.a, actual.r, actual.g, actual.b, actual.colorSpace],
        [expected.a, expected.r, expected.g, expected.b, expected.colorSpace],
      );
      expect(actual.toARGB32(), expected.toARGB32());
      expect(actual.computeLuminance(), expected.computeLuminance());
      expect(actual.withValues(alpha: .3), expected.withValues(alpha: .3));
      expect(
        actual.withValues(colorSpace: ColorSpace.sRGB),
        expected.withValues(colorSpace: ColorSpace.sRGB),
      );
      expect(actual.withAlpha(120), expected.withAlpha(120));
      expect(actual.withRed(120), expected.withRed(120));
      expect(actual.withGreen(120), expected.withGreen(120));
      expect(actual.withBlue(120), expected.withBlue(120));
      // The inherited equality/hash must continue to include the variants.
      // ignore: deprecated_member_use
      expect(actual.value, expected.toARGB32());
      // ignore: deprecated_member_use
      expect(actual.withOpacity(.3), expected.withOpacity(.3));
      expect(
        Color.alphaBlend(
          actual,
          const Color(0xffeeeeee).withValues(colorSpace: actual.colorSpace),
        ),
        Color.alphaBlend(
          expected,
          const Color(0xffeeeeee).withValues(colorSpace: expected.colorSpace),
        ),
      );
    }
    expect(resolved.first, isNot(resolved.last));
  });

  test('canvas interpolation retains its own semantic endpoints', () {
    final a = MacosThemeData.light().copyWith(
      primaryColor: const Color(0xff0000ff),
      canvasColor: const Color(0xffffffff),
    );
    final b = MacosThemeData.dark().copyWith(
      primaryColor: const Color(0xffff0000),
      canvasColor: const Color(0xff202020),
    );
    for (final t in [0.0, .5, 1.0]) {
      final theme = MacosThemeData.lerp(a, b, t);
      expect(theme.canvasColor, Color.lerp(a.canvasColor, b.canvasColor, t));
      expect(theme.primaryColor, Color.lerp(a.primaryColor, b.primaryColor, t));
    }
  });
}
