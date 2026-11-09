import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

void main() {
  // Endpoint identity matters: MacosColor equality deliberately preserves type.
  final cases = <(Object, Object, Object Function(double))>[
    (
      const HelpButtonThemeData(color: MacosColors.black),
      const HelpButtonThemeData(color: MacosColors.white),
      (t) => HelpButtonThemeData.lerp(
        const HelpButtonThemeData(color: MacosColors.black),
        const HelpButtonThemeData(color: MacosColors.white),
        t,
      ),
    ),
    (
      const MacosIconButtonThemeData(backgroundColor: MacosColors.black),
      const MacosIconButtonThemeData(backgroundColor: MacosColors.white),
      (t) => MacosIconButtonThemeData.lerp(
        const MacosIconButtonThemeData(backgroundColor: MacosColors.black),
        const MacosIconButtonThemeData(backgroundColor: MacosColors.white),
        t,
      ),
    ),
    (
      const MacosPopupButtonThemeData(backgroundColor: MacosColors.black),
      const MacosPopupButtonThemeData(backgroundColor: MacosColors.white),
      (t) => MacosPopupButtonThemeData.lerp(
        const MacosPopupButtonThemeData(backgroundColor: MacosColors.black),
        const MacosPopupButtonThemeData(backgroundColor: MacosColors.white),
        t,
      ),
    ),
    (
      const MacosPulldownButtonThemeData(backgroundColor: MacosColors.black),
      const MacosPulldownButtonThemeData(backgroundColor: MacosColors.white),
      (t) => MacosPulldownButtonThemeData.lerp(
        const MacosPulldownButtonThemeData(backgroundColor: MacosColors.black),
        const MacosPulldownButtonThemeData(backgroundColor: MacosColors.white),
        t,
      ),
    ),
    (
      const MacosIconThemeData(color: MacosColors.black),
      const MacosIconThemeData(color: MacosColors.white),
      (t) => MacosIconThemeData.lerp(
        const MacosIconThemeData(color: MacosColors.black),
        const MacosIconThemeData(color: MacosColors.white),
        t,
      ),
    ),
  ];
  for (final (a, b, lerp) in cases) {
    test('${a.runtimeType} preserves endpoints and interpolates channels', () {
      expect(lerp(0), same(a));
      expect(lerp(1), same(b));
      final middle = lerp(0.5);
      final Color? color = switch (middle) {
        HelpButtonThemeData value => value.color,
        MacosIconButtonThemeData value => value.backgroundColor,
        MacosPopupButtonThemeData value => value.backgroundColor,
        MacosPulldownButtonThemeData value => value.backgroundColor,
        MacosIconThemeData value => value.color,
        _ => throw StateError('Missing theme'),
      };
      expect(color!.r, closeTo(0.5, 0.001));
      expect(color.g, closeTo(0.5, 0.001));
      expect(color.b, closeTo(0.5, 0.001));
      expect(color.a, 1);
    });
  }
  test('nullable icon themes still fade and interpolate size', () {
    expect(MacosIconThemeData.lerp(null, null, 0.5).color, isNull);
    const b = MacosIconThemeData(color: MacosColors.white, size: 20);
    expect(MacosIconThemeData.lerp(null, b, 0.5).color!.a, 0.5);
    expect(MacosIconThemeData.lerp(null, b, 0.5).size, 10);
    expect(MacosIconThemeData.lerp(b, null, 0.5).color!.a, 0.5);
  });
}
