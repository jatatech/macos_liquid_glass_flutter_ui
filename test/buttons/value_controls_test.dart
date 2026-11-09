import 'dart:ui'
    show SemanticsAction, SemanticsActionEvent, Tristate, CheckedState;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/buttons/button_interaction.dart';

Widget host(
  Widget child, {
  bool dark = false,
  bool reduced = false,
  bool contrast = false,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MacosApp(
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduced,
      highContrast: contrast,
      textScaler: TextScaler.linear(scale),
    ),
    child: Directionality(
      textDirection: direction,
      child: Center(child: child),
    ),
  ),
);

typedef Factory = Widget Function(ValueChanged<bool>? changed);
final factories = <String, Factory>{
  'checkbox': (changed) =>
      MacosCheckbox(value: null, onChanged: changed, semanticLabel: 'Value'),
  'radio': (changed) => MacosRadioButton<bool>(
    value: true,
    groupValue: false,
    onChanged: changed == null ? null : (v) => changed(v!),
    semanticLabel: 'Value',
  ),
  'switch': (changed) =>
      MacosSwitch(value: false, onChanged: changed, semanticLabel: 'Value'),
};

void main() {
  for (final entry in factories.entries) {
    testWidgets(
      '${entry.key}: keys, repeat, pointer and semantics activate once',
      (tester) async {
        final semantics = tester.ensureSemantics();

        final values = <bool>[];
        await tester.pumpWidget(host(entry.value(values.add)));
        await tester.pumpAndSettle();
        final target = find.bySemanticsLabel('Value');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          tester
                  .getSemantics(target)
                  .getSemanticsData()
                  .flagsCollection
                  .isFocused ==
              Tristate.isTrue,
          isTrue,
        );
        for (final key in [
          LogicalKeyboardKey.space,
          LogicalKeyboardKey.enter,
        ]) {
          final before = values.length;
          await tester.sendKeyDownEvent(key);
          await tester.sendKeyRepeatEvent(key);
          await tester.pump();
          expect(values.length, before);
          await tester.sendKeyUpEvent(key);
          expect(values.length, before + 1);
        }
        final secondary = await tester.startGesture(
          tester.getCenter(target),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await secondary.up();
        await tester.pumpAndSettle();
        expect(values.length, 2);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(values.length, 3);
        tester.binding.performSemanticsAction(
          SemanticsActionEvent(
            type: SemanticsAction.tap,
            viewId: tester.view.viewId,
            nodeId: tester.getSemantics(target).id,
          ),
        );
        await tester.pumpAndSettle();
        expect(values, [true, true, true, true]);
        // The callback alone must not mutate a controlled value.
        if (entry.key == 'switch') {
          expect(
            tester.widget<MacosSwitch>(find.byType(MacosSwitch)).value,
            false,
          );
        }
        if (entry.key == 'checkbox') {
          expect(
            tester
                    .getSemantics(target)
                    .getSemanticsData()
                    .flagsCollection
                    .isChecked ==
                CheckedState.mixed,
            true,
          );
        }
        if (entry.key == 'radio') {
          expect(
            tester
                .getSemantics(target)
                .getSemanticsData()
                .flagsCollection
                .isInMutuallyExclusiveGroup,
            true,
          );
        }
        semantics.dispose();
      },
    );

    testWidgets('${entry.key}: disable and focus loss cancel held activation', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(host(entry.value((_) => count++)));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pumpWidget(host(entry.value(null)));
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.tap(find.bySemanticsLabel('Value'));
      await tester.pumpAndSettle();
      expect(count, 0);
      final node = tester.getSemantics(find.bySemanticsLabel('Value'));
      expect(
        node.getSemanticsData().flagsCollection.isEnabled == Tristate.isTrue,
        false,
      );
      expect(
        node.getSemanticsData().flagsCollection.isFocused != Tristate.none,
        false,
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), false);
      await tester.pumpWidget(host(entry.value((_) => count++)));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      expect(count, 0);
    });
  }

  for (final entry in factories.entries) {
    testWidgets(
      '${entry.key}: live contrast during hold and pointer cancellation',
      (tester) async {
        var count = 0;
        final control = entry.value((_) => count++);
        await tester.pumpWidget(host(control));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        await tester.pumpWidget(
          host(control, contrast: true, reduced: true, dark: true),
        );
        await tester.pumpAndSettle();
        final ring = find.byType(ButtonFocusRing);
        final container = tester.widget<Container>(
          find.descendant(of: ring, matching: find.byType(Container)).first,
        );
        final decoration = container.foregroundDecoration! as BoxDecoration;
        expect((decoration.border! as Border).top.width, 3);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(count, 1);
        final gesture = await tester.startGesture(
          tester.getCenter(find.bySemanticsLabel('Value')),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(count, 1);
      },
    );
  }

  testWidgets('checkbox and radio honour explicit colours and sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MacosCheckbox(
          value: true,
          size: 24,
          activeColor: const Color(0xFFD02030),
          offBorderColor: CupertinoColors.black,
          disabledColor: Color(0xFFFFDD20),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MacosCheckbox)), const Size(24, 24));
    BoxDecoration decorationOf(Type type) => tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(type),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .first;
    expect(decorationOf(MacosCheckbox).color, const Color(0xFFD02030));
    await tester.pumpWidget(
      host(
        const MacosCheckbox(
          value: true,
          disabledColor: Color(0xFFFFDD20),
          onChanged: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(decorationOf(MacosCheckbox).color, const Color(0xFFFFDD20));
    await tester.pumpWidget(
      host(
        MacosRadioButton<int>(
          value: 1,
          groupValue: 1,
          size: 24,
          onColor: const Color(0xFFD02030),
          innerColor: const Color(0xFFFFDD20),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final decoration = decorationOf(MacosRadioButton<int>);
    expect(decoration.color, const Color(0xFFFFDD20));
    expect((decoration.border! as Border).top.color, const Color(0xFFD02030));
    expect(
      tester.getSize(find.byType(MacosRadioButton<int>)),
      const Size(24, 24),
    );
  });

  testWidgets('switch drag commit, cancellation, disable and RTL', (
    tester,
  ) async {
    final changes = <bool>[];
    for (final rtl in [false, true]) {
      await tester.pumpWidget(
        host(
          MacosSwitch(value: false, onChanged: changes.add),
          direction: rtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      );
      await tester.pumpAndSettle();
      final target = find.byType(MacosSwitch);
      final gesture = await tester.startGesture(tester.getCenter(target));
      await gesture.moveBy(Offset(rtl ? -22 : 22, 0));
      await gesture.moveBy(Offset(rtl ? -22 : 22, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(changes.length, rtl ? 2 : 1);
      final cancel = await tester.startGesture(tester.getCenter(target));
      await cancel.moveBy(const Offset(25, 0));
      await cancel.moveBy(const Offset(25, 0));
      await cancel.cancel();
      await tester.pumpAndSettle();
      expect(changes.length, rtl ? 2 : 1);
    }
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MacosSwitch)),
    );
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pumpWidget(
      host(const MacosSwitch(value: false, onChanged: null)),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [true, true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switch size updates layout and live reduced motion settles value',
    (tester) async {
      Widget control(
        ControlSize size,
        bool value,
        bool reduced,
        bool contrast,
      ) => host(
        MacosSwitch(size: size, value: value, onChanged: (_) {}),
        reduced: reduced,
        contrast: contrast,
      );
      await tester.pumpWidget(control(ControlSize.mini, false, false, false));
      expect(tester.getSize(find.byType(MacosSwitch)), const Size(26, 15));
      await tester.pumpWidget(control(ControlSize.regular, true, false, false));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(control(ControlSize.regular, true, true, true));
      await tester.pump();
      expect(tester.getSize(find.byType(MacosSwitch)), const Size(38, 22));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'radio group arrows skip disabled, wrap and do not repeat selected callbacks',
    (tester) async {
      int? selected = 0;
      var changes = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              void change(int? value) => setState(() {
                selected = value;
                changes++;
              });
              return RadioGroup<int>(
                groupValue: selected,
                onChanged: change,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MacosRadioButton<int>(
                      value: 0,
                      groupValue: selected,
                      onChanged: change,
                      semanticLabel: 'Local',
                    ),
                    MacosRadioButton<int>(
                      value: 2,
                      groupValue: selected,
                      onChanged: null,
                      semanticLabel: 'Disabled',
                    ),
                    MacosRadioButton<int>(
                      value: 1,
                      groupValue: selected,
                      onChanged: change,
                      semanticLabel: 'Cloud',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected, 1);
      expect(changes, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(changes, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected, 0);
      expect(changes, 2);
    },
  );

  testWidgets(
    'segments listen, replace controller, navigate RTL and fit scaled labels',
    (tester) async {
      final first = MacosTabController(length: 3);
      final second = MacosTabController(length: 3);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var changes = 0;
      second.addListener(() => changes++);
      Widget control(MacosTabController controller) => host(
        SizedBox(
          width: 210,
          child: MacosSegmentedControl(
            controller: controller,
            tabs: const [
              MacosTab(label: 'All documents'),
              MacosTab(label: 'Recently edited'),
              MacosTab(label: 'Shared with me'),
            ],
          ),
        ),
        scale: 2,
        direction: TextDirection.rtl,
      );
      await tester.pumpWidget(control(first));
      first.index = 2;
      await tester.pump();
      expect(tester.widget<MacosTab>(find.byType(MacosTab).last).active, true);
      await tester.pumpWidget(control(second));
      first.index = 1;
      await tester.pump();
      expect(tester.widget<MacosTab>(find.byType(MacosTab).first).active, true);
      await tester.tap(find.text('All documents'));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(second.index, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(second.index, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(changes, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
