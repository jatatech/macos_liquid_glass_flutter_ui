import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

Widget host(Widget child, {bool rtl = false, bool contrast = false}) =>
    MacosApp(
      home: MediaQuery(
        data: MediaQueryData(
          highContrast: contrast,
          textScaler: const TextScaler.linear(2),
        ),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Center(child: SizedBox(width: 200, child: child)),
        ),
      ),
    );

void main() {
  testWidgets(
    'capacity controlled range, discrete steps, primary and secondary pointer',
    (tester) async {
      final values = <double>[];
      await tester.pumpWidget(
        host(
          CapacityIndicator(
            value: 20,
            splits: 4,
            discrete: true,
            onChanged: values.add,
          ),
        ),
      );
      final rect = tester.getRect(find.byType(CapacityIndicator));
      await tester.tapAt(Offset(rect.left + rect.width * .8, rect.center.dy));
      expect(values, [80, 80]);
      await tester.pump();
      expect(
        tester.widget<CapacityIndicator>(find.byType(CapacityIndicator)).value,
        20,
      );
      values.clear();
      final secondary = await tester.startGesture(
        rect.center,
        buttons: kSecondaryMouseButton,
      );
      await secondary.up();
      expect(values, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      expect(values, [100]);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      expect(values, [100, 0]);
    },
  );

  testWidgets(
    'pan proposals update immediately, cancellation and release add no commit',
    (tester) async {
      final values = <double>[];
      await tester.pumpWidget(
        host(CapacityIndicator(value: 20, onChanged: values.add)),
      );
      final rect = tester.getRect(find.byType(CapacityIndicator));
      final drag = await tester.startGesture(
        rect.centerLeft + const Offset(10, 0),
      );
      await drag.moveTo(rect.centerRight - const Offset(10, 0));
      await tester.pump();
      expect(values, [5, 5, 95]);
      await drag.cancel();
      expect(values, [5, 5, 95]);
      final committed = await tester.startGesture(rect.center);
      await committed.moveTo(rect.centerRight + const Offset(40, 0));
      expect(values, [5, 5, 95, 50, 50, 100]);
      await committed.up();
      expect(values, [5, 5, 95, 50, 50, 100]);
    },
  );

  testWidgets(
    'accepted controlled rebuilds keep pan updates and equal values flowing',
    (tester) async {
      for (final rating in [false, true]) {
        final proposals = <double>[];
        double value = 0;
        await tester.pumpWidget(
          host(
            StatefulBuilder(
              builder: (context, rebuild) {
                void change(double next) {
                  proposals.add(next);
                  rebuild(() => value = next);
                }

                return rating
                    ? RatingIndicator(value: value, onChanged: change)
                    : CapacityIndicator(
                        value: value,
                        discrete: true,
                        onChanged: change,
                      );
              },
            ),
          ),
        );
        final gesture = find.descendant(
          of: find.byType(rating ? RatingIndicator : CapacityIndicator),
          matching: find.byType(GestureDetector),
        );
        final rect = tester.getRect(gesture);
        Offset point(double x) =>
            Offset(rect.left + rect.width * x, rect.center.dy);
        final drag = await tester.startGesture(point(.2));
        await drag.moveTo(point(.6));
        await tester.pump();
        await drag.moveTo(point(.8));
        await tester.pump();
        await drag.moveTo(point(.8) + const Offset(0, 30));
        await tester.pump();
        expect(proposals, rating ? [1, 1, 3, 4, 4] : [20, 20, 60, 80, 80]);
        await drag.cancel();
        expect(value, rating ? 4 : 80);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'rating preserves fractional fill and supports RTL keys and semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      double value = 2.4;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => RatingIndicator(
              value: value,
              semanticLabel: 'Rating',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
          rtl: true,
        ),
      );
      expect(find.byIcon(CupertinoIcons.star_fill), findsNWidgets(3));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, 3);
      final node = tester.getSemantics(find.bySemanticsLabel('Rating'));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase),
        isTrue,
      );
      tester.binding.performSemanticsAction(
        ui.SemanticsActionEvent(
          type: SemanticsAction.increase,
          nodeId: node.id,
          viewId: tester.view.viewId,
        ),
      );
      await tester.pump();
      expect(value, 4);
      final rect = tester.getRect(
        find.descendant(
          of: find.byType(RatingIndicator),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.tapAt(rect.centerRight - const Offset(1, 0));
      await tester.pump();
      expect(value, closeTo(.0625, .0001));
      semantics.dispose();
    },
  );

  testWidgets(
    'read-only indicators expose values without slider actions or tab stops',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CapacityIndicator(value: 72, semanticLabel: 'Storage'),
              RatingIndicator(value: 3, semanticLabel: 'Rating'),
              // ignore: deprecated_member_use_from_same_package
              RelevanceIndicator(value: 14, semanticLabel: 'Relevance'),
            ],
          ),
        ),
      );
      for (final label in ['Storage', 'Rating', 'Relevance']) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();
        expect(data.hasAction(SemanticsAction.increase), isFalse);
        expect(data.flagsCollection.isSlider, isFalse);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'capacity painter invalidates values, explicit colours, direction and live contrast',
    (tester) async {
      Future<CustomPainter> paint(
        double value,
        Color color, {
        bool contrast = false,
        bool rtl = false,
      }) async {
        await tester.pumpWidget(
          host(
            CapacityIndicatorCell(value: value, color: color),
            contrast: contrast,
            rtl: rtl,
          ),
        );
        return tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(CapacityIndicatorCell),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!;
      }

      final initial = await paint(20, CupertinoColors.systemRed);
      final value = await paint(80, CupertinoColors.systemRed);
      expect(value.shouldRepaint(initial), isTrue);
      final color = await paint(80, CupertinoColors.systemBlue);
      expect(color.shouldRepaint(value), isTrue);
      final contrast = await paint(
        80,
        CupertinoColors.systemBlue,
        contrast: true,
      );
      expect(contrast.shouldRepaint(color), isTrue);
      final rtl = await paint(
        80,
        CupertinoColors.systemBlue,
        contrast: true,
        rtl: true,
      );
      expect(rtl.shouldRepaint(contrast), isTrue);
    },
  );

  testWidgets(
    'long label, trailing content, legacy relevance and rating fit narrow RTL at 2x',
    (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Label(
                  icon: MacosIcon(CupertinoIcons.doc),
                  text: Text('A long document title that must wrap'),
                  child: Text('PDF'),
                ),
                RatingIndicator(value: 3, iconSize: 30),
                // ignore: deprecated_member_use_from_same_package
                RelevanceIndicator(value: 14),
                CapacityIndicator(value: 60, discrete: true),
              ],
            ),
          ),
          rtl: true,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Escape and read-only transition cancel ongoing edits', (
    tester,
  ) async {
    final values = <double>[];
    late StateSetter rebuild;
    bool editable = true;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (_, setState) {
            rebuild = setState;
            return RatingIndicator(
              value: 2,
              onChanged: editable ? values.add : null,
            );
          },
        ),
      ),
    );
    final rect = tester.getRect(
      find.descendant(
        of: find.byType(RatingIndicator),
        matching: find.byType(GestureDetector),
      ),
    );
    final drag = await tester.startGesture(rect.centerLeft);
    await drag.moveTo(rect.centerRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await drag.moveTo(rect.center);
    await drag.up();
    expect(values, [0, 0, 5]);
    values.clear();
    final disabled = await tester.startGesture(rect.centerLeft);
    await disabled.moveTo(rect.centerRight);
    rebuild(() => editable = false);
    await tester.pump();
    await disabled.up();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    expect(values, [0, 0, 5]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'continuous capacity retains fractional pointer precision and keyboard step',
    (tester) async {
      final values = <double>[];
      await tester.pumpWidget(
        host(CapacityIndicator(value: 20.4, onChanged: values.add)),
      );
      final rect = tester.getRect(find.byType(CapacityIndicator));
      await tester.tapAt(Offset(rect.left + 60.5, rect.center.dy));
      expect(values, [30.25, 30.25]);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      expect(values.last, closeTo(21.4, .001));
    },
  );

  testWidgets(
    'fixed rating symbols and hit region remain aligned under tight constraints',
    (tester) async {
      final values = <double>[];
      await tester.pumpWidget(
        host(RatingIndicator(value: 0, onChanged: values.add)),
      );
      await tester.tap(find.byIcon(CupertinoIcons.star).last);
      expect(values, [4.5, 4.5]);
      values.clear();
      final rect = tester.getRect(find.byType(RatingIndicator));
      await tester.tapAt(rect.centerRight - const Offset(1, 0));
      expect(values, isEmpty);
    },
  );

  testWidgets(
    'live appearance changes repaint dynamic cells and legacy bar colours',
    (tester) async {
      Widget scene(Brightness brightness) => MacosApp(
        theme: MacosThemeData.light(),
        darkTheme: MacosThemeData.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: const Center(
          child: SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CapacityIndicatorCell(value: 50, color: CupertinoColors.label),
                RatingIndicator(value: 3, iconColor: CupertinoColors.label),
                // ignore: deprecated_member_use_from_same_package
                RelevanceIndicator(value: 14),
              ],
            ),
          ),
        ),
      );
      CustomPainter cell() => tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(CapacityIndicatorCell),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!;
      Color bar() => tester
          .widget<Container>(
            find
                .descendant(
                  // ignore: deprecated_member_use_from_same_package
                  of: find.byType(RelevanceIndicator),
                  matching: find.byType(Container),
                )
                .first,
          )
          .color!;
      await tester.pumpWidget(scene(Brightness.dark));
      final darkCell = cell();
      final darkBar = bar();
      await tester.pumpWidget(scene(Brightness.light));
      await tester.pumpAndSettle();
      expect(cell().shouldRepaint(darkCell), isTrue);
      expect(bar(), isNot(darkBar));
      expect(bar().computeLuminance(), lessThan(.1));
      expect(
        tester
            .widget<Icon>(find.byIcon(CupertinoIcons.star_fill).first)
            .color!
            .computeLuminance(),
        lessThan(.1),
      );
    },
  );

  testWidgets(
    'fractional discrete steps fill exactly the proposed number of cells',
    (tester) async {
      double value = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, setState) => CapacityIndicator(
              value: value,
              splits: 7,
              discrete: true,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      for (var i = 1; i <= 7; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(
          tester
              .widgetList<CapacityIndicatorCell>(
                find.byType(CapacityIndicatorCell),
              )
              .where((cell) => cell.value == 100)
              .length,
          i,
        );
      }
    },
  );

  test('invalid capacity split count is rejected', () {
    expect(() => CapacityIndicator(value: 10, splits: 0), throwsAssertionError);
  });
}
