import 'package:flutter/cupertino.dart' hide OverlayVisibilityMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

Widget host(
  Widget child, {
  bool contrast = false,
  bool motion = false,
  bool dark = false,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MacosApp(
  theme: MacosThemeData.light(),
  darkTheme: MacosThemeData.dark(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(800, 600),
      highContrast: contrast,
      disableAnimations: motion,
      textScaler: TextScaler.linear(scale),
    ),
    child: Directionality(
      textDirection: direction,
      child: Center(child: SizedBox(width: 220, child: child)),
    ),
  ),
);
Finder get clear => find.byWidgetPredicate(
  (w) => w is MacosIconButton && w.semanticLabel == 'Clear text',
);
const options = [
  SearchResultItem('Alpha'),
  SearchResultItem('Beta'),
  SearchResultItem('Gamma'),
];

void main() {
  testWidgets(
    'clear is named, keyboard reachable, exactly once and read-only safe',
    (t) async {
      final c = TextEditingController(text: 'Draft');
      final calls = <String>[];
      await t.pumpWidget(
        host(
          MacosTextField(
            controller: c,
            onChanged: calls.add,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
      );
      await t.tap(clear, buttons: kSecondaryMouseButton);
      await t.pump();
      expect(c.text, 'Draft');
      expect(calls, isEmpty);
      await t.tap(clear);
      await t.pump();
      expect(c.text, '');
      expect(calls, ['']);
      expect(clear, findsNothing);
      c.text = 'Keep';
      await t.pumpWidget(
        host(
          MacosTextField(
            controller: c,
            readOnly: true,
            onChanged: calls.add,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
      );
      await t.tap(clear);
      await t.pump();
      expect(c.text, 'Keep');
      expect(calls, ['']);
      await t.pumpWidget(
        host(
          MacosTextField(
            controller: c,
            onChanged: calls.add,
            clearButtonMode: OverlayVisibilityMode.editing,
          ),
        ),
      );
      await t.tap(find.byType(EditableText));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pump();
      expect(c.text, '');
      expect(calls, ['', '']);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'focus replacement and external ownership, nullable disabled styles',
    (t) async {
      final a = FocusNode();
      final b = FocusNode();
      final c = TextEditingController();
      await t.pumpWidget(host(MacosTextField(focusNode: a, controller: c)));
      a.requestFocus();
      await t.pump();
      expect(a.hasFocus, true);
      await t.pumpWidget(host(MacosTextField(focusNode: b, controller: c)));
      b.requestFocus();
      await t.pump();
      expect(b.hasFocus, true);
      await t.pumpWidget(
        host(
          MacosTextField(
            focusNode: b,
            controller: c,
            enabled: false,
            placeholderStyle: null,
          ),
        ),
      );
      await t.pump();
      expect(b.hasFocus, false);
      b.requestFocus();
      await t.pump();
      expect(b.hasFocus, false);
      await t.pumpWidget(host(MacosTextField(focusNode: b, controller: c)));
      expect(b.canRequestFocus, true);
      await t.pumpWidget(const SizedBox());
      a.requestFocus();
      b.requestFocus();
      c.text = 'still owned';
      a.dispose();
      b.dispose();
      c.dispose();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'controller transitions preserve composing and selection without callbacks',
    (t) async {
      final c = TextEditingController.fromValue(
        const TextEditingValue(
          text: 'かな',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        ),
      );
      final calls = <String>[];
      await t.pumpWidget(
        host(MacosTextField(controller: c, onChanged: calls.add)),
      );
      await t.pumpWidget(host(MacosTextField(onChanged: calls.add)));
      final editable = t.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.value, c.value);
      expect(calls, isEmpty);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('text input composing, selection, submission and formatters', (
    t,
  ) async {
    final c = TextEditingController();
    final changes = <String>[];
    final submissions = <String>[];
    await t.pumpWidget(
      host(
        MacosTextField(
          controller: c,
          onChanged: changes.add,
          onSubmitted: submissions.add,
        ),
      ),
    );
    await t.showKeyboard(find.byType(EditableText));
    const value = TextEditingValue(
      text: 'にほん',
      selection: TextSelection(baseOffset: 1, extentOffset: 3),
      composing: TextRange(start: 0, end: 3),
    );
    t.testTextInput.updateEditingValue(value);
    await t.pump();
    expect(c.value, value);
    expect(changes, ['にほん']);
    t.testTextInput.updateEditingValue(
      value.copyWith(composing: TextRange.empty),
    );
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(submissions, ['にほん']);
    await t.pumpWidget(
      host(
        MacosTextField(
          controller: c,
          maxLength: 2,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
    );
    await t.enterText(find.byType(EditableText), 'abc1234');
    expect(c.text, '12');
    await t.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'copy cut paste and select-all retain Flutter editing actions',
    (t) async {
      Future<void> command(LogicalKeyboardKey key) async {
        await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await t.sendKeyEvent(key);
        await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await t.pump();
      }

      String? clipboard;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          if (call.method == 'Clipboard.hasStrings') {
            return {'value': clipboard?.isNotEmpty ?? false};
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final c = TextEditingController(text: 'Report');
      await t.pumpWidget(host(MacosTextField(controller: c)));
      await t.showKeyboard(find.byType(EditableText));
      await command(LogicalKeyboardKey.keyA);
      await t.pump();
      expect(c.selection, const TextSelection(baseOffset: 0, extentOffset: 6));
      await command(LogicalKeyboardKey.keyC);
      expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, 'Report');
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
      await command(LogicalKeyboardKey.keyX);
      await t.pump();
      expect(c.text, '');
      await command(LogicalKeyboardKey.keyV);
      await t.pump();
      expect(c.text, 'Report');
      await t.pumpWidget(host(MacosTextField(controller: c, readOnly: true)));
      await t.showKeyboard(find.byType(EditableText));
      await command(LogicalKeyboardKey.keyA);
      await command(LogicalKeyboardKey.keyX);
      expect(c.text, 'Report');
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'search empty and clear changes, keys choose exactly once, Escape dismisses',
    (t) async {
      final c = TextEditingController();
      final changes = <String>[];
      final chosen = <String>[];
      final submitted = <String>[];
      await t.pumpWidget(
        host(
          MacosSearchField(
            controller: c,
            results: options,
            onChanged: changes.add,
            onResultSelected: (r) => chosen.add(r.searchKey),
            onSubmitted: submitted.add,
          ),
        ),
      );
      await t.enterText(find.byType(EditableText), 'Al');
      await t.pump();
      expect(find.text('Alpha'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(chosen, ['Alpha']);
      expect(c.text, 'Alpha');
      expect(submitted, isEmpty);
      expect(find.byType(ListView), findsNothing);
      await t.tap(clear);
      await t.pump();
      expect(changes, ['Al', '']);
      expect(find.byType(ListView), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(find.byType(ListView), findsNothing);
      expect(c.text, '');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pump();
      expect(submitted, ['']);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'search listens to replacement/results, disposes focused overlay safely',
    (t) async {
      final a = TextEditingController();
      final b = TextEditingController(text: 'Bet');
      final f = FocusNode();
      final g = FocusNode();
      await t.pumpWidget(
        host(MacosSearchField(controller: a, focusNode: f, results: options)),
      );
      f.requestFocus();
      await t.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      await t.pumpWidget(
        host(MacosSearchField(controller: b, focusNode: g, results: options)),
      );
      g.requestFocus();
      await t.pumpAndSettle();
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      await t.pumpWidget(
        host(
          MacosSearchField(
            controller: b,
            focusNode: g,
            results: const [SearchResultItem('Better')],
          ),
        ),
      );
      await t.pump();
      expect(find.text('Better'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
      await t.pumpWidget(
        host(
          MacosSearchField(
            controller: b,
            focusNode: g,
            results: options,
            enabled: false,
          ),
        ),
      );
      await t.pump();
      expect(find.byType(ListView), findsNothing);
      await t.pumpWidget(const SizedBox());
      a.text = 'alive';
      b.text = 'alive';
      a.dispose();
      b.dispose();
      f.dispose();
      g.dispose();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('search composing keys ignored and no-result widget updated', (
    t,
  ) async {
    final c = TextEditingController();
    await t.pumpWidget(
      host(
        MacosSearchField(
          controller: c,
          results: options,
          emptyWidget: const Text('No matches'),
        ),
      ),
    );
    await t.showKeyboard(find.byType(EditableText));
    t.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'かな',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pump();
    expect(c.value.composing, const TextRange(start: 0, end: 2));
    expect(find.text('No matches'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.dispose();
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'live appearance contrast motion hover and constrained RTL scale',
    (t) async {
      final f = FocusNode();
      final field = MacosTextField(
        focusNode: f,
        placeholder: 'A long placeholder with a useful description',
      );
      await t.pumpWidget(host(field));
      f.requestFocus();
      await t.pump(const Duration(milliseconds: 30));
      await t.pumpWidget(
        host(
          field,
          dark: true,
          contrast: true,
          motion: true,
          scale: 2,
          direction: TextDirection.rtl,
        ),
      );
      await t.pump();
      final container = t.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).last,
      );
      expect(container.duration, Duration.zero);
      final border = (container.decoration! as BoxDecoration).border! as Border;
      expect(border.top.width, 3);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(t.getCenter(find.byType(MacosTextField)));
      await t.pump();
      await mouse.removePointer();
      expect(t.takeException(), isNull);
      await t.pumpWidget(
        host(
          const MacosSearchField(results: options),
          scale: 2,
          direction: TextDirection.rtl,
        ),
      );
      await t.tap(find.byType(EditableText));
      await t.pump();
      expect(find.text('Alpha'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      f.dispose();
    },
  );
  testWidgets('named values and hidden fields exclude focus and semantics', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    final c = TextEditingController(text: 'Named report');
    final f = FocusNode();
    final field = Semantics(
      label: 'Document name',
      child: MacosTextField(controller: c, focusNode: f),
    );
    await t.pumpWidget(
      host(
        ExcludeFocus(
          excluding: false,
          child: Offstage(offstage: false, child: field),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Document name'), findsOneWidget);
    expect(
      t.getSemantics(find.byType(EditableText)).getSemanticsData().value,
      'Named report',
    );
    f.requestFocus();
    await t.pump();
    await t.pumpWidget(host(ExcludeFocus(child: Offstage(child: field))));
    await t.pump();
    expect(f.hasFocus, false);
    expect(find.bySemanticsLabel('Document name'), findsNothing);
    await t.pumpWidget(const SizedBox());
    c.dispose();
    f.dispose();
    semantics.dispose();
  });

  testWidgets(
    'custom focused decoration and directional borders survive focus',
    (t) async {
      final f = FocusNode();
      const custom = BoxDecoration(
        color: Color(0xFF102030),
        border: BorderDirectional(start: BorderSide(color: Color(0xFF123456))),
      );
      await t.pumpWidget(
        host(
          MacosTextField(
            focusNode: f,
            decoration: custom,
            focusedDecoration: custom,
          ),
        ),
      );
      f.requestFocus();
      await t.pumpAndSettle();
      expect(
        t
            .widget<AnimatedContainer>(find.byType(AnimatedContainer).last)
            .decoration,
        custom,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      f.dispose();
    },
  );
}
