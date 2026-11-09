import 'dart:ui' show SemanticsAction, SemanticsActionEvent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

typedef Factory = Widget Function(VoidCallback? callback);

final factories = <String, Factory>{
  'push': (callback) => PushButton(
    controlSize: ControlSize.regular,
    semanticLabel: 'Command',
    onPressed: callback,
    child: const Text('Visible command'),
  ),
  'icon': (callback) => MacosIconButton(
    semanticLabel: 'Command',
    onPressed: callback,
    icon: const MacosIcon(CupertinoIcons.add),
  ),
  'disclosure': (callback) => MacosDisclosureButton(
    semanticLabel: 'Command',
    onPressed: callback,
    isPressed: true,
  ),
  'help': (callback) =>
      HelpButton(semanticLabel: 'Command', onPressed: callback),
};

Widget host(
  Widget child, {
  bool dark = false,
  bool reduced = false,
  bool contrast = false,
  double scale = 1,
}) => MacosApp(
  theme: MacosThemeData.light(),
  darkTheme: MacosThemeData.dark(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduced,
      highContrast: contrast,
      textScaler: TextScaler.linear(scale),
    ),
    child: Center(child: child),
  ),
);

void main() {
  for (final entry in factories.entries) {
    testWidgets(
      '${entry.key}: Tab, Enter/Space, repeat, AX and secondary click',
      (tester) async {
        var count = 0;
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(host(entry.value(() => count++)));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Command')),
          matchesSemantics(
            label: 'Command',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            isFocused: true,
            hasTapAction: true,
            hasExpandedState: entry.key == 'disclosure',
            isExpanded: entry.key == 'disclosure',
          ),
        );
        for (final key in [
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.space,
        ]) {
          await tester.sendKeyDownEvent(key);
          await tester.sendKeyRepeatEvent(key);
          await tester.pump(const Duration(milliseconds: 150));
          expect(count, key == LogicalKeyboardKey.enter ? 0 : 1);
          await tester.sendKeyUpEvent(key);
          await tester.pumpAndSettle();
        }
        expect(count, 2);
        final target = find.bySemanticsLabel('Command');
        final secondary = await tester.startGesture(
          tester.getCenter(target),
          buttons: kSecondaryMouseButton,
          kind: PointerDeviceKind.mouse,
        );
        await secondary.up();
        await tester.pumpAndSettle();
        expect(count, 2);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(count, 3);
        tester.binding.performSemanticsAction(
          SemanticsActionEvent(
            type: SemanticsAction.tap,
            viewId: tester.view.viewId,
            nodeId: tester.getSemantics(target).id,
          ),
        );
        expect(count, 4);
        semantics.dispose();
      },
    );

    testWidgets(
      '${entry.key}: disabling during a press cancels keyboard and pointer',
      (tester) async {
        var count = 0;
        Future<void> pump(bool enabled) => tester.pumpWidget(
          host(entry.value(enabled ? () => count++ : null)),
        );
        await pump(true);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        await pump(false);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(count, 0);
        final semantics = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Command')),
          matchesSemantics(
            label: 'Command',
            isButton: true,
            hasEnabledState: true,
            hasExpandedState: entry.key == 'disclosure',
            isExpanded: entry.key == 'disclosure',
          ),
        );
        semantics.dispose();
        await pump(true);
        final gesture = await tester.press(find.bySemanticsLabel('Command'));
        await pump(false);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(count, 0);
        await pump(true);
        await tester.tap(find.bySemanticsLabel('Command'));
        await tester.pumpAndSettle();
        expect(count, 1);
      },
    );

    testWidgets(
      '${entry.key}: light/dark hover, focus and live contrast/motion',
      (tester) async {
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        for (final dark in [false, true]) {
          await tester.pumpWidget(host(entry.value(() {}), dark: dark));
          final target = find.bySemanticsLabel('Command');
          List<Object?> surface() => [
            ...tester
                .widgetList<Container>(
                  find.descendant(of: target, matching: find.byType(Container)),
                )
                .expand((w) => [w.decoration, w.foregroundDecoration]),
            ...tester
                .widgetList<DecoratedBox>(
                  find.descendant(
                    of: target,
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .map((w) => w.decoration),
            ...tester
                .widgetList<AnimatedOpacity>(
                  find.descendant(
                    of: target,
                    matching: find.byType(AnimatedOpacity),
                  ),
                )
                .map((w) => w.opacity),
          ];
          await tester.pumpAndSettle();
          final resting = surface();
          await mouse.moveTo(tester.getCenter(target));
          await tester.pumpAndSettle();
          expect(surface(), isNot(resting));
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final hovered = surface();
          await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
          await tester.pump(const Duration(milliseconds: 20));
          expect(surface(), isNot(hovered));
          await tester.pumpWidget(
            host(entry.value(() {}), dark: dark, reduced: true, contrast: true),
          );
          await tester.pump();
          // Reduced motion replaces any in-flight implicit fade immediately.
          expect(
            find.descendant(of: target, matching: find.byType(AnimatedOpacity)),
            findsNothing,
          );
          final outlines = tester
              .widgetList<Container>(
                find.descendant(of: target, matching: find.byType(Container)),
              )
              .map((w) => w.foregroundDecoration)
              .whereType<BoxDecoration>()
              .where((d) => d.border != null);
          expect(outlines, isNotEmpty);
          final border = outlines.first.border! as Border;
          expect(border.top.width, 3);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await mouse.moveTo(Offset.zero);
        }
      },
    );
  }

  testWidgets(
    'Tab skips disabled and excluded controls and focus loss cancels press',
    (tester) async {
      var count = 0;
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              factories['push']!(() => count++),
              const HelpButton(),
              ExcludeFocus(
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: factories['icon']!(() => count++),
                  ),
                ),
              ),
              HelpButton(semanticLabel: 'Last', onPressed: () => count++),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(count, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(count, 1);
    },
  );

  testWidgets(
    'push sizes grow at 200% with long labels; styling overrides remain',
    (tester) async {
      for (final size in ControlSize.values) {
        await tester.pumpWidget(
          host(
            SizedBox(
              width: 140,
              child: PushButton(
                controlSize: size,
                color: CupertinoColors.systemGreen,
                padding: const EdgeInsets.all(15),
                borderRadius: BorderRadius.circular(12),
                onPressed: () {},
                child: const Text(
                  'Save document and all attachments with a long label',
                ),
              ),
            ),
            scale: 2,
          ),
        );
        expect(tester.takeException(), isNull);
        final container = tester
            .widgetList<Container>(find.byType(Container))
            .firstWhere((w) => w.decoration is BoxDecoration);
        final decoration = container.decoration! as BoxDecoration;
        expect(
          decoration.color,
          MacosDynamicColor.resolve(
            CupertinoColors.systemGreen,
            tester.element(find.byType(PushButton)),
          ),
        );
        expect(decoration.borderRadius, BorderRadius.circular(12));
        expect(container.padding, const EdgeInsets.all(15));
        expect(tester.getSize(find.byType(PushButton)).height, greaterThan(60));
      }
    },
  );

  testWidgets('disclosure expansion and default help name update', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    for (final expanded in [false, true, false]) {
      await tester.pumpWidget(
        host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MacosDisclosureButton(isPressed: expanded, onPressed: () {}),
              HelpButton(onPressed: () {}),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Show details')),
        matchesSemantics(
          label: 'Show details',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: expanded,
        ),
      );
      expect(find.bySemanticsLabel('Help'), findsOneWidget);
    }
    semantics.dispose();
  });
  testWidgets(
    'default help and high contrast push foregrounds remain readable',
    (tester) async {
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HelpButton(onPressed: () {}),
                PushButton(
                  controlSize: ControlSize.regular,
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ],
            ),
            dark: dark,
            contrast: true,
          ),
        );
        await tester.pumpAndSettle();
        final help = find.byType(HelpButton);
        final helpSurface = tester
            .widgetList<Container>(
              find.descendant(of: help, matching: find.byType(Container)),
            )
            .firstWhere((w) => w.decoration != null);
        final background = (helpSurface.decoration! as BoxDecoration).color!;
        final icon = tester.widget<Icon>(
          find.descendant(of: help, matching: find.byType(Icon)),
        );
        final canvas = MacosTheme.of(tester.element(help)).canvasColor;
        final luminances = [
          icon.color!.computeLuminance(),
          Color.alphaBlend(background, canvas).computeLuminance(),
        ]..sort();
        expect(
          (luminances.last + 0.05) / (luminances.first + 0.05),
          greaterThanOrEqualTo(4.5),
        );
        final push = find.byType(PushButton);
        final style = tester
            .widget<DefaultTextStyle>(
              find.descendant(
                of: push,
                matching: find.byType(DefaultTextStyle),
              ),
            )
            .style;
        final surface = tester
            .widgetList<Container>(
              find.descendant(of: push, matching: find.byType(Container)),
            )
            .firstWhere((w) => w.decoration != null);
        final colors = [
          style.color!.computeLuminance(),
          (surface.decoration! as BoxDecoration).color!.computeLuminance(),
        ]..sort();
        expect(
          (colors.last + 0.05) / (colors.first + 0.05),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  testWidgets(
    'local help theme and icon style overrides survive hover and disabling',
    (tester) async {
      Widget content(bool enabled) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HelpButtonTheme(
            data: const HelpButtonThemeData(
              color: Color(0xFF112233),
              disabledColor: Color(0xFF445566),
            ),
            child: HelpButton(onPressed: enabled ? () {} : null),
          ),
          MacosIconButton(
            icon: const MacosIcon(CupertinoIcons.add),
            onPressed: enabled ? () {} : null,
            backgroundColor: const Color(0xFF123456),
            hoverColor: const Color(0xFF234567),
            disabledColor: const Color(0xFF345678),
            borderRadius: BorderRadius.circular(11),
            padding: const EdgeInsets.all(2),
            boxConstraints: const BoxConstraints.tightFor(
              width: 26,
              height: 26,
            ),
          ),
        ],
      );
      await tester.pumpWidget(host(content(true)));
      await tester.pumpAndSettle();
      Color iconBackground() {
        final surface = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(MacosIconButton),
                matching: find.byType(DecoratedBox),
              )
              .last,
        );
        return (surface.decoration as BoxDecoration).color!;
      }

      expect(iconBackground(), const Color(0xFF123456));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(MacosIconButton)));
      await tester.pumpAndSettle();
      expect(iconBackground(), const Color(0xFF234567));
      await tester.pumpWidget(host(content(false)));
      await tester.pumpAndSettle();
      expect(iconBackground(), const Color(0xFF345678));
      final helpSurface = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(HelpButton),
              matching: find.byType(Container),
            ),
          )
          .firstWhere((w) => w.decoration != null);
      expect(
        (helpSurface.decoration! as BoxDecoration).color,
        const Color(0xFF445566),
      );
      await mouse.removePointer();
    },
  );
}
