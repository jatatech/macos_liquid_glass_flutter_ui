import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:shell_gallery/native_toolbar_example.dart';

void main() {
  testWidgets('collection filter, selection and Back retain context', (
    t,
  ) async {
    await t.pumpWidget(const MacosApp(home: NativeToolbarExample()));
    await t.pumpAndSettle();
    await t.enterText(find.byType(MacosTextField), 'not found');
    await t.pumpAndSettle();
    expect(
      find.text('No matching documents. Clear the filter.'),
      findsOneWidget,
    );
    expect(
      t
          .widget<PushButton>(
            find.widgetWithText(PushButton, 'Open selected document'),
          )
          .onPressed,
      isNull,
    );
    await t.enterText(find.byType(MacosTextField), 'e');
    await t.pumpAndSettle();
    await t.tap(find.text('Design brief'));
    await t.pumpAndSettle();
    await t.tap(find.text('Open selected document'));
    await t.pumpAndSettle();
    expect(
      t.widget<MacosNativeToolbar>(find.byType(MacosNativeToolbar)).title,
      'Design brief',
    );
    expect(
      t
          .widget<PushButton>(
            find.widgetWithText(PushButton, 'Previous document'),
          )
          .onPressed,
      isNull,
    );
    await t.tap(find.text('Next document'));
    await t.pumpAndSettle();
    expect(
      t.widget<MacosNativeToolbar>(find.byType(MacosNativeToolbar)).title,
      'Site survey',
    );
    // A shortcut invokes the same next proposal once, then disables at the end.
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.digit3);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await t.pumpAndSettle();
    expect(
      t.widget<MacosNativeToolbar>(find.byType(MacosNativeToolbar)).title,
      'Meeting notes',
    );
    expect(
      t
          .widget<PushButton>(find.widgetWithText(PushButton, 'Next document'))
          .onPressed,
      isNull,
    );
    await t.tap(find.text('Back to collection'));
    await t.pumpAndSettle();
    expect(
      t.widget<MacosTextField>(find.byType(MacosTextField)).controller!.text,
      'e',
    );
    expect(
      t
          .widget<MacosListTile>(
            find.widgetWithText(MacosListTile, 'Meeting notes'),
          )
          .selected,
      isTrue,
    );
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'native menu callbacks and disabled state match the toolbar',
    (t) async {
      const channel = MethodChannel('dev.groovinchip.macos_ui/window_toolbar');
      final calls = <MethodCall>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return true;
      });
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await t.pumpWidget(const MacosApp(home: NativeToolbarExample()));
      await t.pumpAndSettle();
      void checkParity() {
        final items = t
            .widget<MacosNativeToolbar>(find.byType(MacosNativeToolbar))
            .items!;
        final commands = [
          (items.first as MacosNativeToolbarCommandItem).command,
          ...items.whereType<MacosNativeToolbarGroup>().first.commands,
          ...items
              .whereType<MacosNativeToolbarCommandItem>()
              .where((i) => i.anchor == null)
              .skip(1)
              .map((i) => i.command),
          ...items.whereType<MacosNativeToolbarGroup>().last.commands,
          ...items
              .whereType<MacosNativeToolbarCommandItem>()
              .where((i) => i.anchor != null)
              .map((i) => i.command),
        ];
        final menus = t
            .widget<PlatformMenuBar>(find.byType(PlatformMenuBar))
            .menus;
        final navigation = (menus[1] as PlatformMenu).menus;
        expect(navigation.length, commands.length + 1);
        for (var i = 0; i < commands.length; i++) {
          expect(navigation[i + 1].label, commands[i].label);
          expect(navigation[i + 1].onSelected, same(commands[i].onPressed));
        }
        final encoded = (calls.last.arguments as Map)['items'] as List;
        final groups = encoded.where((i) => i['type'] == 'group').toList();
        expect(groups[0]['mode'], 'momentary');
        expect(groups[1]['mode'], 'exclusive');
        expect(groups[0]['commands'], [
          for (final c in commands.skip(1).take(2))
            {
              'id': c.id,
              'label': c.label,
              'symbol': c.symbol,
              'enabled': c.onPressed != null,
            },
        ]);
      }

      checkParity();
      await t.tap(find.text('Design brief'));
      await t.pumpAndSettle();
      await t.tap(find.text('Open selected document'));
      await t.pumpAndSettle();
      checkParity();
      final menu = t.widget<PlatformMenuBar>(find.byType(PlatformMenuBar));
      (menu.menus[1] as PlatformMenu).menus[3].onSelected!();
      await t.pumpAndSettle();
      expect(
        t.widget<MacosNativeToolbar>(find.byType(MacosNativeToolbar)).title,
        'Site survey',
      );
      checkParity();
      // Deliver an actual encoded native callback to the widget's channel handler.
      await t.binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('groupAction', {'id': 'browse', 'command': 'next'}),
        ),
        (_) {},
      );
      await t.pumpAndSettle();
      expect(
        t.widget<MacosNativeToolbar>(find.byType(MacosNativeToolbar)).title,
        'Meeting notes',
      );
      checkParity();
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(calls.last.method, 'remove');
      expect(t.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'native typing and clear retain collection selection through detail',
    (t) async {
      const channel = MethodChannel('dev.groovinchip.macos_ui/window_toolbar');
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => true,
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      Future<void> edit(String text, int revision) async {
        await t.binding.defaultBinaryMessenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('searchChanged', {
              'id': 'document-search',
              'query': text,
              'revision': revision,
            }),
          ),
          (_) {},
        );
        await t.pumpAndSettle();
      }

      await t.pumpWidget(const MacosApp(home: NativeToolbarExample()));
      await t.pumpAndSettle();
      await edit('not found', 1);
      expect(
        find.text('No matching documents. Clear the filter.'),
        findsOneWidget,
      );
      await edit('', 2);
      await t.tap(find.text('Site survey'));
      await t.pumpAndSettle();
      await t.tap(find.text('Open selected document'));
      await t.pumpAndSettle();
      await edit('hidden edit', 3);
      final toolbar = t.widget<MacosNativeToolbar>(
        find.byType(MacosNativeToolbar),
      );
      expect(
        toolbar.items!
            .whereType<MacosNativeToolbarSearch>()
            .single
            .controller
            .text,
        '',
      );
      toolbar.items!
          .whereType<MacosNativeToolbarCommandItem>()
          .first
          .command
          .onPressed!();
      await t.pumpAndSettle();
      expect(
        t
            .widget<MacosListTile>(
              find.widgetWithText(MacosListTile, 'Site survey'),
            )
            .selected,
        true,
      );
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('fallback commands wrap at compact width and large text', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(480, 600));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      const MacosApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(480, 600),
            textScaler: TextScaler.linear(2),
          ),
          child: NativeToolbarExample(),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Meeting notes'));
    await t.pumpAndSettle();
    await t.tap(find.text('Open selected document'));
    await t.pumpAndSettle();
    await t.tap(find.text('Back to collection'));
    await t.pumpAndSettle();
    expect(find.byType(MacosTextField), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'independent inspector retains object drafts and query across pane changes',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(const MacosApp(home: NativeToolbarExample()));
      await t.pumpAndSettle();
      final tile = find.widgetWithText(MacosListTile, 'Design brief');
      await t.tap(tile);
      await t.pumpAndSettle();
      await t.tap(find.text('Toggle inspector'));
      await t.pumpAndSettle();
      final draft = find.byWidgetPredicate(
        (w) =>
            w is MacosTextField &&
            w.placeholder == 'Notes for selected document',
      );
      await t.enterText(draft, 'Keep this session draft');
      await t.pumpAndSettle();
      await t.tap(find.text('Toggle navigation'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<MacosWindow>(find.byType(MacosWindow))
            .paneLayoutController!
            .value!
            .leadingWidth,
        0,
      );
      expect(draft, findsOneWidget);
      await t.tap(find.widgetWithText(MacosListTile, 'Site survey'));
      await t.pumpAndSettle();
      expect(t.widget<MacosTextField>(draft).controller!.text, '');
      await t.tap(tile);
      await t.pumpAndSettle();
      expect(
        t.widget<MacosTextField>(draft).controller!.text,
        'Keep this session draft',
      );
      await t.tap(find.text('Compact rows'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<MacosNativeToolbar>(find.byType(MacosNativeToolbar))
            .items!
            .whereType<MacosNativeToolbarGroup>()
            .last
            .selectedId,
        'compact',
      );
      await t.binding.setSurfaceSize(const Size(500, 800));
      await t.pumpAndSettle();
      expect(draft, findsNothing);
      await t.binding.setSurfaceSize(const Size(1200, 800));
      await t.pumpAndSettle();
      expect(
        t.widget<MacosTextField>(draft).controller!.text,
        'Keep this session draft',
      );
      await t.tap(find.text('Toggle inspector'));
      await t.pumpAndSettle();
      expect(draft, findsNothing);
      await t.tap(find.text('Toggle inspector'));
      await t.pumpAndSettle();
      expect(
        t.widget<MacosTextField>(draft).controller!.text,
        'Keep this session draft',
      );
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'contextual date fallback stages, cancels and commits without losing query',
    (t) async {
      await t.pumpWidget(const MacosApp(home: NativeToolbarExample()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(MacosTextField), 'e');
      await t.tap(find.text('Jump to project date'));
      await t.pumpAndSettle();
      expect(
        find.text('Jump to project date — Flutter anchored chooser'),
        findsOneWidget,
      );
      t
          .widget<MacosDatePicker>(find.byType(MacosDatePicker))
          .onDateChanged(DateTime.utc(2026, 11, 9));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(
        t.widget<MacosTextField>(find.byType(MacosTextField)).controller!.text,
        'e',
      );
      await t.tap(find.text('Jump to project date (Flutter chooser)'));
      await t.pumpAndSettle();
      expect(
        t.widget<MacosDatePicker>(find.byType(MacosDatePicker)).initialDate,
        DateTime.utc(2026, 11, 8),
      );
      t
          .widget<MacosDatePicker>(find.byType(MacosDatePicker))
          .onDateChanged(DateTime.utc(2026, 11, 9));
      await t.pumpAndSettle();
      await t.tap(find.text('Jump'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<MacosListTile>(
              find.widgetWithText(MacosListTile, 'Meeting notes'),
            )
            .selected,
        isTrue,
      );
      expect(find.text('Jumped to 2026-11-9.'), findsOneWidget);
      expect(
        t.widget<MacosTextField>(find.byType(MacosTextField)).controller!.text,
        'e',
      );
    },
  );
}
