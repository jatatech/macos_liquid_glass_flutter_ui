import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import '../fields/field_interactions_test.dart' show host;

const choices = [
  MacosPopupMenuItem(value: 'a', child: Text('Alpha')),
  MacosPopupMenuItem(value: 'b', enabled: false, child: Text('Blocked')),
  MacosPopupMenuItem(value: 'c', child: Text('Charlie')),
];
Finder get popup => find.byType(MacosPopupButton<String>);

void main() {
  testWidgets(
    'semantic date activation moves keyboard focus to selected field',
    (t) async {
      final handle = t.ensureSemantics();
      final dates = <DateTime>[];
      await t.pumpWidget(
        host(
          MacosDatePicker(
            initialDate: DateTime(2024, 1, 31),
            style: DatePickerStyle.textual,
            onDateChanged: dates.add,
          ),
        ),
      );
      final node = t.getSemantics(find.text('31'));
      t.binding.rootPipelineOwner.visitChildren((owner) {
        owner.semanticsOwner?.performAction(node.id, SemanticsAction.tap);
      });
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pump();
      expect(dates, [DateTime(2024, 1, 30)]);
      await t.pumpWidget(const SizedBox());
      handle.dispose();
    },
  );

  testWidgets('popup scales in RTL and invalidates changed controlled values', (
    t,
  ) async {
    var value = 'a';
    var calls = 0;
    late StateSetter rebuild;
    await t.pumpWidget(
      host(
        StatefulBuilder(
          builder: (_, set) {
            rebuild = set;
            return MacosPopupButton<String>(
              items: choices,
              value: value,
              menuMaxHeight: 150,
              onChanged: (_) => calls++,
            );
          },
        ),
        direction: TextDirection.rtl,
        scale: 2,
        contrast: true,
      ),
    );
    await t.tap(popup);
    await t.pumpAndSettle();
    expect(find.text('Charlie'), findsOneWidget);
    rebuild(() => value = 'c');
    await t.pumpAndSettle();
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.text('Blocked'), findsNothing);
    expect(calls, 0);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'progress circle retains Cupertino-only use and zero-radius safety',
    (t) async {
      await t.pumpWidget(
        const CupertinoApp(
          home: Column(
            children: [ProgressCircle(value: 40), ProgressCircle(radius: 0)],
          ),
        ),
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'discrete slider uses actual range, RTL keys and semantic bounds',
    (t) async {
      final values = <double>[];
      var value = 15.0;
      late StateSetter rebuild;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              rebuild = set;
              return MacosSlider(
                min: 10,
                max: 20,
                splits: 3,
                discrete: true,
                value: value,
                semanticLabel: 'Volume',
                onChanged: (v) {
                  values.add(v);
                  set(() => value = v);
                },
              );
            },
          ),
          direction: TextDirection.rtl,
        ),
      );
      final semantics = t.ensureSemantics();
      await t.tap(find.byType(MacosSlider));
      await t.pump();
      values.clear();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await t.pump();
      expect(value, 20);
      expect(values, [20]);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(values, [20]);
      var node = t.getSemantics(find.byType(MacosSlider));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase),
        isFalse,
      );
      t.binding.rootPipelineOwner.visitChildren((owner) {
        owner.semanticsOwner?.performAction(node.id, SemanticsAction.decrease);
      });
      await t.pump();
      expect(values, [20, 15]);
      rebuild(() => value = 10);
      await t.pump();
      node = t.getSemantics(find.byType(MacosSlider));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.decrease),
        isFalse,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pump();
      expect(value, 20);
      semantics.dispose();
    },
  );

  testWidgets(
    'slider cancellation stops updates; disabled and secondary click are inert',
    (t) async {
      final values = <double>[];
      var enabled = true;
      late StateSetter rebuild;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              rebuild = set;
              return MacosSlider(
                value: 0.5,
                onChanged: enabled ? values.add : null,
              );
            },
          ),
        ),
      );
      final rect = t.getRect(find.byType(MacosSlider));
      final mouse = await t.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: 2,
      );
      await mouse.down(rect.center);
      await mouse.up();
      expect(values, isEmpty);
      final drag = await t.startGesture(rect.center);
      await drag.moveBy(const Offset(45, 0));
      await t.pump();
      expect(values, isNotEmpty);
      await drag.cancel();
      final count = values.length;
      rebuild(() => enabled = false);
      await t.pump();
      await t.tap(find.byType(MacosSlider));
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      expect(values.length, count);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'progress percentages and live motion changes including in-flight',
    (t) async {
      final semantics = t.ensureSemantics();
      Widget tree(bool motion) => host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressBar(value: 25, semanticLabel: 'Download'),
            ProgressCircle(value: 75, semanticLabel: 'Indexing'),
            ProgressCircle(semanticLabel: 'Connecting'),
          ],
        ),
        motion: motion,
      );
      await t.pumpWidget(tree(false));
      expect(t.getSemantics(find.bySemanticsLabel('Download')).value, '25.00%');
      expect(t.getSemantics(find.bySemanticsLabel('Indexing')).value, '75.00%');
      expect(t.getSemantics(find.bySemanticsLabel('Connecting')).value, '');
      expect(
        t
            .widget<CupertinoActivityIndicator>(
              find.byType(CupertinoActivityIndicator),
            )
            .animating,
        isTrue,
      );
      await t.pump(const Duration(milliseconds: 120));
      await t.pumpWidget(tree(true));
      await t.pumpAndSettle();
      expect(
        t
            .widget<CupertinoActivityIndicator>(
              find.byType(CupertinoActivityIndicator),
            )
            .animating,
        isFalse,
      );
      expect(t.binding.transientCallbackCount, 0);
      await t.pumpWidget(tree(false));
      await t.pump(const Duration(milliseconds: 120));
      expect(t.binding.transientCallbackCount, greaterThan(0));
      await t.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );

  testWidgets('progress repaint includes colours at fixed values and RTL', (
    t,
  ) async {
    Widget tree(Color color, TextDirection direction) => host(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressCircle(value: 50, innerColor: color, borderColor: color),
          ProgressBar(value: 50, trackColor: color, backgroundColor: color),
        ],
      ),
      direction: direction,
    );
    await t.pumpWidget(tree(CupertinoColors.systemRed, TextDirection.ltr));
    List<CustomPainter> painters() => t
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<CustomPainter>()
        .toList();
    final before = painters();
    await t.pumpWidget(tree(CupertinoColors.systemGreen, TextDirection.rtl));
    final after = painters();
    expect(after.length, 2);
    for (var i = 0; i < 2; i++) {
      expect(after[i].shouldRepaint(before[i]), isTrue);
    }
  });

  testWidgets(
    'popup chooses once on Enter, skips disabled and restores external focus',
    (t) async {
      final focus = FocusNode();
      final calls = <String?>[];
      await t.pumpWidget(
        host(
          MacosPopupButton<String>(
            items: choices,
            value: 'a',
            focusNode: focus,
            onChanged: calls.add,
          ),
        ),
      );
      focus.requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(calls, ['c']);
      expect(focus.hasFocus, isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(calls, ['c']);
      expect(focus.hasFocus, isTrue);
      await t.pumpWidget(const SizedBox());
      focus.dispose();
    },
  );

  testWidgets('popup closes on disable, hide, disposal and focus replacement', (
    t,
  ) async {
    var enabled = true;
    var hidden = false;
    final one = FocusNode();
    final two = FocusNode();
    var focus = one;
    var calls = 0;
    late StateSetter rebuild;
    await t.pumpWidget(
      host(
        StatefulBuilder(
          builder: (_, set) {
            rebuild = set;
            return ExcludeFocus(
              excluding: hidden,
              child: MacosPopupButton<String>(
                items: choices,
                value: 'a',
                focusNode: focus,
                onChanged: enabled ? (_) => calls++ : null,
              ),
            );
          },
        ),
      ),
    );
    for (final mode in ['disable', 'hide', 'dispose']) {
      await t.tap(popup);
      await t.pumpAndSettle();
      if (mode == 'dispose') {
        await t.pumpWidget(const SizedBox());
      } else {
        rebuild(() {
          if (mode == 'hide') {
            hidden = true;
          } else {
            enabled = false;
            focus = two;
          }
        });
        await t.pumpAndSettle();
        expect(find.text('Charlie'), findsNothing);
        rebuild(() {
          enabled = true;
          hidden = false;
        });
        await t.pumpAndSettle();
      }
      expect(t.takeException(), isNull);
    }
    expect(calls, 0);
    one.dispose();
    two.dispose();
  });

  testWidgets(
    'rapid popup open and Escape remains bounded with no framework assertion',
    (t) async {
      final focus = FocusNode();
      await t.pumpWidget(
        host(
          MacosPopupButton<String>(
            items: choices,
            value: 'a',
            focusNode: focus,
            onChanged: (_) {},
          ),
        ),
      );
      focus.requestFocus();
      await t.pump();
      for (var i = 0; i < 8; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.space);
        await t.pump(const Duration(milliseconds: 16));
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pump(const Duration(milliseconds: 16));
      }
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      focus.dispose();
    },
  );

  testWidgets(
    'date field clamps month/year, keyboard focus and Monday offset',
    (t) async {
      final dates = <DateTime>[];
      await t.pumpWidget(
        host(
          MacosDatePicker(
            initialDate: DateTime(2024, 1, 31),
            onDateChanged: dates.add,
            style: DatePickerStyle.textual,
          ),
        ),
      );
      await t.tap(find.text('1'));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      expect(dates, [DateTime(2024, 2, 29)]);
      await t.tap(find.text('2024'));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      expect(dates.last, DateTime(2025, 2, 28));
      await t.pumpWidget(
        host(
          MacosDatePicker(
            key: const ValueKey('Sunday'),
            initialDate: DateTime(2026, 11, 1),
            startWeekOnMonday: true,
            onDateChanged: dates.add,
          ),
        ),
      );
      expect(find.text('30'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'time field wraps, graphical input changes selection, no timer after disposal',
    (t) async {
      final times = <TimeOfDay>[];
      await t.pumpWidget(
        host(
          MacosTimePicker(
            initialTime: const TimeOfDay(hour: 23, minute: 59),
            style: TimePickerStyle.textual,
            onTimeChanged: times.add,
          ),
        ),
      );
      await t.tap(find.text('59'));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      expect(times, [const TimeOfDay(hour: 23, minute: 0)]);
      await t.pumpWidget(
        host(
          MacosTimePicker(
            key: const ValueKey('graph'),
            initialTime: const TimeOfDay(hour: 10, minute: 0),
            style: TimePickerStyle.graphical,
            onTimeChanged: times.add,
          ),
        ),
      );
      final rect = t.getRect(find.byType(MacosTimePicker));
      await t.tapAt(rect.center + const Offset(50, 0));
      await t.pump();
      expect(times.last, const TimeOfDay(hour: 10, minute: 15));
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      expect(times.last, const TimeOfDay(hour: 10, minute: 16));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 5));
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'disabled pickers block semantics input, scaled RTL stays within bounds',
    (t) async {
      var count = 0;
      await t.pumpWidget(
        host(
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MacosDatePicker(
                  enabled: false,
                  initialDate: DateTime(2026, 11, 8),
                  onDateChanged: (_) => count++,
                ),
                MacosTimePicker(enabled: false, onTimeChanged: (_) => count++),
                MacosSlider(value: 0.5, onChanged: null),
                MacosColorWell(enabled: false, onColorSelected: (_) => count++),
              ],
            ),
          ),
          scale: 2,
          direction: TextDirection.rtl,
          contrast: true,
        ),
      );
      await t.tap(find.text('8').first, warnIfMissed: false);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      expect(count, 0);
      expect(t.takeException(), isNull);
    },
  );
}
