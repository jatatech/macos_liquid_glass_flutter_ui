import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shell_gallery/consumer_evaluation.dart';

Future<void> page(WidgetTester t, String name) async {
  await t.tap(find.text(name));
  await t.pumpAndSettle();
}

Future<void> start(WidgetTester t) async {
  t.view.physicalSize = const Size(1000, 800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.pumpWidget(const ConsumerEvaluation());
  await t.pumpAndSettle();
}

Future<void> toolbarFind(WidgetTester t) async {
  if (find.text('Find documents').hitTestable().evaluate().isEmpty) {
    await t.tap(find.byType(ToolbarOverflowButton));
    await t.pumpAndSettle();
  }
  await t.tap(find.text('Find documents').hitTestable());
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'T1 controlled recursive leaves and equivalent toolbar overflow',
    (t) async {
      await start(t);
      await page(t, 'Preferences');
      expect(t.widget<SidebarItems>(find.byType(SidebarItems)).currentIndex, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pumpAndSettle();
      expect(t.widget<SidebarItems>(find.byType(SidebarItems)).currentIndex, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(t.widget<SidebarItems>(find.byType(SidebarItems)).currentIndex, 2);
      t.view.physicalSize = const Size(480, 700);
      await t.pumpAndSettle();
      await t.tap(find.byType(ToolbarOverflowButton));
      await t.pumpAndSettle();
      expect(find.text('Find documents').hitTestable(), findsOneWidget);
      await toolbarFind(t);
      await t.pumpAndSettle();
      expect(find.text('Search notebook records'), findsOneWidget);
      expect(
        t
            .widget<MacosSearchField>(find.byType(MacosSearchField))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.tap(find.byType(ToolbarOverflowButton));
      await t.pumpAndSettle();
      await t.tap(find.text('Export unavailable').hitTestable());
      await t.pumpAndSettle();
      expect(find.text('Session saves: 0'), findsOneWidget);
      expect(find.text('Export unavailable').hitTestable(), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      await t.tap(
        find
            .byWidgetPredicate(
              (w) => w is MacosIconButton && w.semanticLabel == 'Save session',
            )
            .hitTestable(),
      );
      await t.pumpAndSettle();
      expect(find.text('Session saves: 1'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );

  testWidgets('T2 retained settings, disabled semantics and ownership', (
    t,
  ) async {
    await start(t);
    final semantics = t.ensureSemantics();
    await page(t, 'Preferences');
    final name = t
        .widget<MacosTextField>(find.byType(MacosTextField))
        .controller!;
    await t.enterText(find.byType(MacosTextField), 'Evening survey');
    await t.tap(find.bySemanticsLabel('Sync notebook'));
    await t.pumpAndSettle();
    final managed = t.getSemantics(find.byType(MacosCheckbox).at(1));
    expect(managed.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
    await t.tap(find.byType(MacosCheckbox).at(1));
    await t.pumpAndSettle();
    await page(t, 'Find records');
    await page(t, 'Preferences');
    expect(name.text, 'Evening survey');
    expect(
      t.widget<MacosCheckbox>(find.byType(MacosCheckbox).first).value,
      isFalse,
    );
    expect(
      t.widget<MacosCheckbox>(find.byType(MacosCheckbox).at(1)).value,
      isTrue,
    );
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    semantics.dispose();
    await t.pump();
  });

  testWidgets('T3 distinct search callbacks, submission and composing value', (
    t,
  ) async {
    await start(t);
    await toolbarFind(t);
    await t.pumpAndSettle();
    final field = t.widget<MacosSearchField>(find.byType(MacosSearchField));
    await t.enterText(find.byType(EditableText), 'Al');
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(field.controller!.text, 'Alpine notes');
    expect(find.text('Edits: 1; item: 1; result: 1'), findsOneWidget);
    expect(find.text('Submitted: '), findsOneWidget);
    await t.enterText(find.byType(EditableText), 'Unlisted');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    expect(find.text('Submitted: Unlisted'), findsOneWidget);
    const composing = TextEditingValue(
      text: 'Al',
      selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 0, end: 2),
    );
    await t.tap(find.byType(EditableText));
    await t.pump();
    t.testTextInput.updateEditingValue(composing);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pump();
    expect(field.controller!.value, composing);
    expect(find.text('Edits: 3; item: 1; result: 1'), findsOneWidget);
    field.controller!.value = composing.copyWith(composing: TextRange.empty);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(field.controller!.text, 'Al');
    expect(find.text('Edits: 3; item: 1; result: 1'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('T4 shared surface, equivalent commands and live opaque policy', (
    t,
  ) async {
    await start(t);
    await page(t, 'Glass preview');
    expect(
      find.text('Actual commands: approximation; next: 0'),
      findsOneWidget,
    );
    expect(find.byType(MacosGlassSurface), findsOneWidget);
    await t.tap(find.text('Next record'));
    await t.pumpAndSettle();
    expect(
      find.text('Actual commands: approximation; next: 1'),
      findsOneWidget,
    );
    await t.tap(find.text('Archive unavailable'));
    await t.pumpAndSettle();
    expect(find.textContaining('next: 1'), findsOneWidget);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpAndSettle();
    expect(find.text('Actual commands: opaque; next: 1'), findsOneWidget);
    t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await t.pumpAndSettle();
    expect(
      find.text('Actual commands: approximation; next: 1'),
      findsOneWidget,
    );
    await page(t, 'Preferences');
    await t.tap(find.byType(MacosCheckbox).last);
    await t.pumpAndSettle();
    await page(t, 'Glass preview');
    expect(
      t.widget<MacosGlassSurface>(find.byType(MacosGlassSurface)).forceOpaque,
      isTrue,
    );
    expect(find.textContaining('opaque; next: 1'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });

  testWidgets('T4 missing macOS transport retains functional opaque controls', (
    t,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    var next = 0;
    var mode = MacosGlassRendering.opaque;
    await t.pumpWidget(
      MacosApp(
        home: Center(
          child: SizedBox(
            width: 400,
            height: 300,
            child: NotebookCommands(
              onNext: () => next++,
              onRenderingChanged: (value) => mode = value,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(mode, MacosGlassRendering.opaque);
    await t.tap(find.text('Next record'));
    await t.pumpAndSettle();
    expect(next, 1);
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  // Wire harness adapted from glass_command_surface_test.dart; MIT/NOTICE at repo root.
  testWidgets(
    'T4/6 simulated native descriptor, action and occlusion lifecycle',
    (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      const glass = MethodChannel('dev.groovinchip.macos_ui/glass');
      const preferences = MethodChannel(
        'dev.groovinchip.macos_ui/accessibility',
      );
      final messenger = t.binding.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(glass, (call) async {
        calls.add(call);
        return call.method == 'remove' ? null : true;
      });
      messenger.setMockMethodCallHandler(preferences, (_) async => null);
      Future<void> incoming(String name, ByteData data) async {
        final done = Completer<void>();
        messenger.handlePlatformMessage(name, data, (_) => done.complete());
        await t.runAsync(() => done.future);
        await t.pumpAndSettle();
      }

      var next = 0;
      var covered = false;
      var mode = MacosGlassRendering.opaque;
      late StateSetter rebuild;
      await t.pumpWidget(
        MacosApp(
          home: StatefulBuilder(
            builder: (context, update) {
              rebuild = update;
              return Center(
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: NotebookCommands(
                    onNext: () => next++,
                    nativeOccluded: covered,
                    onRenderingChanged: (value) => mode = value,
                  ),
                ),
              );
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      await incoming(
        preferences.name,
        const StandardMethodCodec().encodeSuccessEnvelope({
          'reduceTransparency': false,
          'increaseContrast': false,
          'reduceMotion': false,
        }),
      );
      expect(mode, MacosGlassRendering.native);
      expect(find.text('Next record'), findsNothing);
      expect(find.text('Readable notebook document'), findsOneWidget);
      final spec =
          calls.lastWhere((call) => call.method == 'update').arguments as Map;
      expect(spec['commands'], [
        {'label': 'Next record', 'enabled': true},
        {'label': 'Archive unavailable', 'enabled': false},
      ]);
      for (final index in [0, 1]) {
        await incoming(
          glass.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('action', {'id': spec['id'], 'index': index}),
          ),
        );
      }
      expect(next, 1);
      rebuild(() => covered = true);
      await t.pumpAndSettle();
      expect(mode, MacosGlassRendering.opaque);
      expect(find.text('Next record'), findsOneWidget);
      rebuild(() => covered = false);
      await t.pumpAndSettle();
      expect(mode, MacosGlassRendering.native);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      expect(calls.last.method, 'remove');
      await incoming(
        glass.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('action', {'id': spec['id'], 'index': 0}),
        ),
      );
      expect(next, 1);
      messenger.setMockMethodCallHandler(glass, null);
      messenger.setMockMethodCallHandler(preferences, null);
      debugDefaultTargetPlatformOverride = null;
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'T5 public table repair; continuous duplicate fractional proposals survive cancel',
    (t) async {
      await start(t);
      await page(t, 'Repaired records');
      await t.tap(find.text('Coastal survey'));
      await t.pumpAndSettle();
      expect(find.text('Record: coast'), findsOneWidget);
      for (final rating in [true, false]) {
        final type = rating ? RatingIndicator : CapacityIndicator;
        final gesture = find.descendant(
          of: find.byType(type),
          matching: find.byType(GestureDetector),
        );
        final rect = t.getRect(gesture);
        Offset at(double x) =>
            Offset(rect.left + rect.width * x, rect.center.dy);
        final drag = await t.startGesture(at(.25));
        await drag.moveTo(at(.625));
        await t.pump();
        await drag.moveTo(at(.625) + const Offset(0, 25));
        await t.pump();
        final value = rating
            ? t.widget<RatingIndicator>(find.byType(type)).value
            : t.widget<CapacityIndicator>(find.byType(type)).value;
        expect(value, rating ? 3.125 : 62.5);
        final proposals = t
            .widget<Text>(find.textContaining(rating ? 'Rating:' : 'Capacity:'))
            .data!;
        expect(
          proposals,
          contains(
            rating ? '[1.25, 1.25, 3.125, 3.125]' : '[25.0, 25.0, 62.5, 62.5]',
          ),
        );
        await drag.cancel();
        await t.pump();
        expect(
          t
              .widget<Text>(
                find.textContaining(rating ? 'Rating:' : 'Capacity:'),
              )
              .data,
          proposals,
        );
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );

  testWidgets('T6 hidden retained commands lose focus, hits and semantics', (
    t,
  ) async {
    await start(t);
    final semantics = t.ensureSemantics();
    await page(t, 'Glass preview');
    await t.tap(find.text('Next record'));
    await t.pumpAndSettle();
    await t.tap(find.text('Hide commands'));
    await t.pumpAndSettle();
    expect(find.text('Next record'), findsNothing);
    expect(find.text('Next record', skipOffstage: false), findsOneWidget);
    expect(find.bySemanticsLabel('Next record'), findsNothing);
    expect(
      t
          .widget<MacosGlassCommandSurface>(
            find.byType(MacosGlassCommandSurface, skipOffstage: false),
          )
          .focusNode!
          .hasFocus,
      isFalse,
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pumpAndSettle();
    expect(find.textContaining('next: 1'), findsOneWidget);
    await t.tap(find.text('Show commands'));
    await t.pumpAndSettle();
    await t.tap(find.text('Next record'));
    await t.pumpAndSettle();
    expect(find.textContaining('next: 2'), findsOneWidget);
    semantics.dispose();
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });

  testWidgets('T6 overlay occlusion, Escape cancellation and disposal', (
    t,
  ) async {
    await start(t);
    await page(t, 'Glass preview');
    final opener = Focus.of(t.element(find.text('Preview overlay')));
    opener.requestFocus();
    await t.pump();
    await t.tap(find.text('Preview overlay'));
    await t.pumpAndSettle();
    expect(
      t
          .widget<MacosGlassCommandSurface>(
            find.byType(MacosGlassCommandSurface),
          )
          .nativeOccluded,
      isTrue,
    );
    expect(
      t
          .widget<MacosGlassSurface>(find.byType(MacosGlassSurface))
          .nativeOccluded,
      isTrue,
    );
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('Cancel preview'), findsNothing);
    expect(opener.hasFocus, isTrue);
    expect(
      t
          .widget<MacosGlassSurface>(find.byType(MacosGlassSurface))
          .nativeOccluded,
      isFalse,
    );
    await t.tap(find.text('Preview overlay'));
    await t.pumpAndSettle();
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
    expect(find.text('Cancel preview'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('T1-6 constrained layout and 200 percent text', (t) async {
    await start(t);
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    for (final brightness in [Brightness.light, Brightness.dark]) {
      t.platformDispatcher.platformBrightnessTestValue = brightness;
      await t.pumpAndSettle();
      for (final name in [
        'Find records',
        'Preferences',
        'Glass preview',
        'Repaired records',
      ]) {
        await page(t, name);
        t.view.physicalSize = const Size(480, 700);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: name);
        t.view.physicalSize = const Size(1000, 800);
        await t.pumpAndSettle();
      }
    }
    t.platformDispatcher.clearPlatformBrightnessTestValue();
    await t.pumpWidget(const SizedBox.shrink());
    await t.pumpAndSettle();
  });
}
