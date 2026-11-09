import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

MacosDateSelection task({DateTime? initial}) => MacosDateSelection(
  initialDate: initial ?? DateTime.utc(2024, 2, 29),
  minimumDate: DateTime.utc(2020),
  maximumDate: DateTime.utc(2030, 12, 31),
  title: 'Project date',
  commitLabel: 'Jump',
  cancelLabel: 'Cancel',
  locale: 'fr_FR',
);

void main() {
  test('civil dates retain local components and reject invalid bounds', () {
    final value = task(initial: DateTime(2024, 2, 29, 23));
    expect(value.toMap()['date'], [2024, 2, 29]);
    expect(value.initialDate.isUtc, isTrue);
    expect(() => task(initial: DateTime.utc(2019)), throwsArgumentError);
    expect(value.contains(DateTime.utc(2031)), isFalse);
  });
  testWidgets(
    'native anchor token remains stable and routes a typed result',
    (t) async {
      const channel = MethodChannel('dev.groovinchip.macos_ui/window_toolbar');
      final calls = <MethodCall>[];
      final pending = Completer<Map<String, Object>>();
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'presentDate') return pending.future;
        return true;
      });
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final anchor = MacosNativeToolbarAnchor();
      final controller = MacosNativeToolbarController();
      Widget shell(String title) => Directionality(
        textDirection: TextDirection.ltr,
        child: MacosNativeToolbar(
          title: title,
          controller: controller,
          items: [
            MacosNativeToolbarCommandItem(
              anchor: anchor,
              command: MacosNativeToolbarCommand(
                id: 'date',
                label: 'Date',
                symbol: 'calendar',
                onPressed: () {},
              ),
            ),
          ],
          fallback: const Text('Fallback'),
          child: const Text('Content'),
        ),
      );
      await t.pumpWidget(shell('First'));
      await t.pump();
      final first = (calls.last.arguments as Map)['items'] as List;
      expect(first.single['type'], 'anchor');
      final result = controller.presentDate(anchor, task());
      await t.pumpWidget(shell('Second'));
      await t.pump();
      final updates = calls.where((c) => c.method == 'updateTyped');
      expect(
        ((updates.last.arguments as Map)['items'] as List).single['anchor'],
        first.single['anchor'],
      );
      final request =
          calls.firstWhere((c) => c.method == 'presentDate').arguments as Map;
      expect(request['anchor'], first.single['anchor']);
      expect(request['date'], [2024, 2, 29]);
      pending.complete({
        'exit': 'invalidated',
        'date': [2025, 12, 15],
      });
      await t.pump();
      expect((await result).exit, MacosDateSelectionExit.invalidated);
      expect((await result).date, DateTime.utc(2025, 12, 15));
      await t.pumpWidget(const SizedBox());
      await t.pump();
      expect(
        (await controller.presentDate(anchor, task())).exit,
        MacosDateSelectionExit.unavailable,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  for (final exit in [
    'Jump',
    'Cancel',
    'Escape',
    'Outside',
    'Remove',
    'Disable',
  ]) {
    testWidgets('Flutter anchored $exit completes once with last draft', (
      t,
    ) async {
      final key = GlobalKey<MacosDateSelectionFallbackState>();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final results = <MacosDateSelectionResult>[];
      final selection = task();
      Widget shell({bool enabled = true, bool show = true}) => MacosApp(
        home: Column(
          children: [
            MacosTextField(focusNode: focus),
            if (show)
              MacosDateSelectionFallback(
                key: key,
                selection: selection,
                enabled: enabled,
                onResult: results.add,
              ),
          ],
        ),
      );
      await t.pumpWidget(shell());
      await t.pumpAndSettle();
      key.currentState!.open();
      await t.pumpAndSettle();
      expect(
        find.text('Project date — Flutter anchored chooser'),
        findsOneWidget,
      );
      t
          .widget<MacosDatePicker>(find.byType(MacosDatePicker))
          .onDateChanged(DateTime.utc(2025, 12, 15));
      await t.pumpAndSettle();
      if (exit == 'Jump' || exit == 'Cancel') {
        await t.tap(find.text(exit));
      } else if (exit == 'Escape') {
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
      } else if (exit == 'Outside') {
        await t.tapAt(const Offset(790, 590));
      } else {
        await t.pumpWidget(
          shell(enabled: exit != 'Disable', show: exit != 'Remove'),
        );
      }
      await t.pumpAndSettle();
      expect(results.length, 1);
      expect(results.single.date, DateTime.utc(2025, 12, 15));
      expect(results.single.exit, switch (exit) {
        'Jump' => MacosDateSelectionExit.committed,
        'Cancel' => MacosDateSelectionExit.cancelled,
        'Remove' => MacosDateSelectionExit.disposed,
        'Disable' => MacosDateSelectionExit.invalidated,
        _ => MacosDateSelectionExit.dismissed,
      });
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(results.length, 1);
    });
  }
  testWidgets(
    'out of bounds draft disables Jump; automatic closure retains it',
    (t) async {
      final key = GlobalKey<MacosDateSelectionFallbackState>();
      final results = <MacosDateSelectionResult>[];
      await t.pumpWidget(
        MacosApp(
          home: MacosDateSelectionFallback(
            key: key,
            selection: task(),
            onResult: results.add,
          ),
        ),
      );
      await t.pumpAndSettle();
      key.currentState!.open();
      await t.pumpAndSettle();
      t
          .widget<MacosDatePicker>(find.byType(MacosDatePicker))
          .onDateChanged(DateTime.utc(2031));
      await t.pump();
      expect(
        t.widget<PushButton>(find.widgetWithText(PushButton, 'Jump')).onPressed,
        isNull,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(results.single.date, DateTime.utc(2031));
      expect(results.single.exit, MacosDateSelectionExit.dismissed);
    },
  );
  testWidgets(
    'fallback supersession, duplicate opens and trigger focus are bounded',
    (t) async {
      final first = GlobalKey<MacosDateSelectionFallbackState>();
      final second = GlobalKey<MacosDateSelectionFallbackState>();
      final results = <MacosDateSelectionResult>[];
      final selection = task();
      await t.pumpWidget(
        MacosApp(
          home: Column(
            children: [
              MacosDateSelectionFallback(
                key: first,
                selection: selection,
                onResult: results.add,
              ),
              MacosDateSelectionFallback(
                key: second,
                selection: selection,
                onResult: results.add,
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      first.currentState!.open();
      first.currentState!.open();
      await t.pumpAndSettle();
      expect(find.byType(MacosDatePicker), findsOneWidget);
      second.currentState!.open();
      await t.pumpAndSettle();
      expect(results.single.exit, MacosDateSelectionExit.superseded);
      expect(find.byType(MacosDatePicker), findsOneWidget);
      await t.tap(find.text('Jump'));
      await t.pumpAndSettle();
      expect(results.length, 2);
      expect(results.last.exit, MacosDateSelectionExit.committed);
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorStateOfType<MacosDateSelectionFallbackState>(),
        second.currentState,
      );
    },
  );
  testWidgets('fallback moving anchor closes and retains draft', (t) async {
    final key = GlobalKey<MacosDateSelectionFallbackState>();
    final results = <MacosDateSelectionResult>[];
    final selection = task();
    Widget shell(double inset) => MacosApp(
      home: Padding(
        padding: EdgeInsets.only(top: inset),
        child: Align(
          alignment: Alignment.topLeft,
          child: MacosDateSelectionFallback(
            key: key,
            selection: selection,
            onResult: results.add,
          ),
        ),
      ),
    );
    await t.pumpWidget(shell(0));
    await t.pumpAndSettle();
    key.currentState!.open();
    await t.pumpAndSettle();
    t
        .widget<MacosDatePicker>(find.byType(MacosDatePicker))
        .onDateChanged(DateTime.utc(2025, 12, 15));
    await t.pumpWidget(shell(40));
    await t.pumpAndSettle();
    expect(results.length, 1);
    expect(results.single.exit, MacosDateSelectionExit.dismissed);
    expect(results.single.date, DateTime.utc(2025, 12, 15));
    expect(find.byType(MacosDatePicker), findsNothing);
  });
}
