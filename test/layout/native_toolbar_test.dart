import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

void main() {
  const channel = MethodChannel('dev.groovinchip.macos_ui/window_toolbar');
  for (final failure in ['rejected', 'unavailable', 'missing']) {
    testWidgets(
      'accepted toolbar tears down before $failure fallback and recovers',
      (t) async {
        final query = TextEditingController(text: 'retained');
        final routing = MacosNativeToolbarController();
        final removal = Completer<void>();
        final calls = <String>[];
        final edits = <String>[];
        var fail = false;
        t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
          call,
        ) async {
          calls.add(call.method);
          if (call.method == 'remove') {
            await removal.future;
            return null;
          }
          if (call.method == 'updateTyped' && fail) {
            if (failure == 'rejected') {
              throw PlatformException(code: 'bad_arguments');
            }
            if (failure == 'missing') throw MissingPluginException();
            return false;
          }
          return true;
        });
        addTearDown(() {
          t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
          query.dispose();
        });
        Widget shell() => MacosApp(
          home: MacosNativeToolbar(
            title: 'Documents',
            controller: routing,
            items: [
              MacosNativeToolbarSearch(
                id: 'find',
                label: 'Find documents',
                controller: query,
                onChanged: edits.add,
              ),
            ],
            fallback: MacosTextField(
              controller: query,
              placeholder: 'Fallback search',
              onChanged: edits.add,
            ),
            child: const SizedBox(),
          ),
        );
        await t.pumpWidget(shell());
        await t.pumpAndSettle();
        expect(find.byType(MacosTextField), findsNothing);
        expect(await routing.focusSearch('find'), isTrue);
        calls.clear();
        fail = true;
        await t.pumpWidget(shell());
        await t.pump();
        expect(calls, ['updateTyped', 'remove']);
        expect(
          find.byType(MacosTextField),
          findsNothing,
          reason: 'Fallback must wait until native removal completes',
        );
        removal.complete();
        await t.pumpAndSettle();
        expect(find.byType(MacosTextField), findsOneWidget);
        expect(await routing.focusSearch('find'), isFalse);
        await t.enterText(find.byType(MacosTextField), 'fallback edit');
        await t.pumpAndSettle();
        expect(query.text, 'fallback edit');
        expect(edits, ['fallback edit']);
        fail = false;
        await t.pumpWidget(shell());
        await t.pumpAndSettle();
        expect(find.byType(MacosTextField), findsNothing);
        expect(query.text, 'fallback edit');
        expect(await routing.focusSearch('find'), isTrue);
        expect(edits, ['fallback edit']);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
        expect(calls.last, 'remove');
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );
  }
  testWidgets(
    'queued recovery and disposal wait for failure teardown',
    (t) async {
      final calls = <String>[];
      final removal = Completer<void>();
      var reject = false;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'remove') {
          await removal.future;
          return null;
        }
        if (reject) throw PlatformException(code: 'bad_arguments');
        return true;
      });
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      Widget shell(String title) => Directionality(
        textDirection: TextDirection.ltr,
        child: MacosNativeToolbar(
          title: title,
          fallback: const Text('Fallback'),
          child: const SizedBox(),
        ),
      );
      await t.pumpWidget(shell('Accepted'));
      await t.pumpAndSettle();
      calls.clear();
      reject = true;
      await t.pumpWidget(shell('Rejected'));
      await t.pump();
      expect(calls, ['update', 'remove']);
      reject = false;
      await t.pumpWidget(shell('Queued recovery'));
      await t.pumpWidget(const SizedBox());
      expect(calls, ['update', 'remove']);
      removal.complete();
      await t.pumpAndSettle();
      expect(
        calls.where((c) => c == 'update').length,
        1,
        reason: 'A queued update cannot remount after disposal',
      );
      expect(calls.last, 'remove');
      expect(t.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  testWidgets('portable toolbar keeps fallback and never contacts native', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return true;
    });
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MacosNativeToolbar(
          title: 'Library',
          commands: [],
          fallback: Text('Commands'),
          child: Text('Photos'),
        ),
      ),
    );
    expect(find.text('Commands'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(calls, isEmpty);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });
  testWidgets(
    'native toolbar serializes updates and removes after an in-flight update',
    (tester) async {
      final calls = <MethodCall>[];
      final first = Completer<bool>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (calls.length == 1) return first.future;
        return true;
      });
      Widget shell(String title) => Directionality(
        textDirection: TextDirection.ltr,
        child: MacosNativeToolbar(
          title: title,
          glassTitlebar: title == 'Photo two',
          commands: const [],
          fallback: const Text('Fallback'),
          child: const Text('Content'),
        ),
      );
      await tester.pumpWidget(shell('Library'));
      await tester.pumpWidget(shell('Photo one'));
      await tester.pumpWidget(shell('Photo two'));
      expect(calls.length, 1);
      first.complete(true);
      await tester.pump();
      await tester.pump();
      expect(calls.map((c) => c.method), ['update', 'update']);
      expect((calls.last.arguments as Map)['title'], 'Photo two');
      expect((calls.first.arguments as Map)['glassTitlebar'], false);
      expect((calls.last.arguments as Map)['glassTitlebar'], true);
      expect(find.text('Fallback'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(calls.last.method, 'remove');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  testWidgets(
    'disposal waits for a pending native update before removing',
    (tester) async {
      final calls = <String>[];
      final pending = Completer<bool>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'update') return pending.future;
        return null;
      });
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MacosNativeToolbar(
            title: 'Pending',
            commands: [],
            fallback: Text('Fallback'),
            child: SizedBox(),
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      expect(calls, ['update']);
      pending.complete(true);
      await tester.pump();
      expect(calls, ['update', 'remove']);
      expect(tester.takeException(), isNull);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  testWidgets(
    'missing toolbar transport keeps fallback on mount and disposal',
    (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MacosNativeToolbar(
            title: 'Library',
            commands: [],
            fallback: Text('Fallback'),
            child: Text('Photos'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fallback'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  testWidgets(
    'covered Flutter routes disable native commands and Escape ownership',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return true;
      });
      await tester.pumpWidget(
        MacosApp(
          home: MacosNativeToolbar(
            title: 'Library',
            commands: [
              MacosNativeToolbarCommand(
                id: 'next',
                label: 'Next',
                symbol: 'chevron.right',
                onPressed: () {},
              ),
            ],
            fallback: const Text('Fallback'),
            child: const Text('Photos'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.push(
        PageRouteBuilder<void>(pageBuilder: (_, _, _) => const SizedBox()),
      );
      await tester.pumpAndSettle();
      final covered =
          calls.where((c) => c.method == 'update').last.arguments as Map;
      expect(covered['interactive'], false);
      expect((covered['commands'] as List).single['enabled'], false);
      navigator.pop();
      await tester.pumpAndSettle();
      final restored =
          calls.where((c) => c.method == 'update').last.arguments as Map;
      expect(restored['interactive'], true);
      expect((restored['commands'] as List).single['enabled'], true);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  testWidgets(
    'typed search routes current edits and releases controllers',
    (t) async {
      final calls = <MethodCall>[];
      final query = TextEditingController(text: 'initial');
      final replacement = TextEditingController(text: 'replacement');
      final routing = MacosNativeToolbarController();
      final edits = <String>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return true;
      });
      Widget shell({
        bool enabled = true,
        bool visible = true,
        TextEditingController? controller,
      }) => Directionality(
        textDirection: TextDirection.ltr,
        child: MacosNativeToolbar(
          title: 'Documents',
          visible: visible,
          controller: routing,
          items: [
            MacosNativeToolbarSearch(
              id: 'find',
              label: 'Find documents',
              controller: controller ?? query,
              enabled: enabled,
              onChanged: edits.add,
            ),
          ],
          fallback: const Text('Fallback'),
          child: const SizedBox(),
        ),
      );
      Future<void> edit(Object? arguments) async {
        await t.binding.defaultBinaryMessenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('searchChanged', arguments),
          ),
          (_) {},
        );
        await t.pump();
      }

      await t.pumpWidget(shell());
      await t.pumpAndSettle();
      final item = ((calls.last.arguments as Map)['items'] as List).single;
      expect(item['placement'], 'trailing');
      expect(item['query'], 'initial');
      expect(await routing.focusSearch('find'), true);
      expect(await routing.focusSearch('missing'), false);
      await edit({'id': 'find', 'query': 'typed', 'revision': 2});
      expect(query.text, 'typed');
      expect(edits, ['typed']);
      await edit({'id': 'find', 'query': 'stale', 'revision': 1});
      await edit({'id': 'unknown', 'query': 'bad', 'revision': 4});
      await edit({'id': 'find', 'query': 42, 'revision': 4});
      expect(query.text, 'typed');
      query.text = 'programmatic';
      await t.pumpAndSettle();
      final changed = ((calls.last.arguments as Map)['items'] as List).single;
      expect(changed['query'], 'programmatic');
      expect(changed['revision'], 2);
      expect(edits, ['typed']);
      await t.pumpWidget(shell(enabled: false));
      await edit({'id': 'find', 'query': 'disabled', 'revision': 3});
      expect(query.text, 'programmatic');
      expect(await routing.focusSearch('find'), false);
      await t.pumpWidget(shell(visible: false));
      await edit({'id': 'find', 'query': 'hidden', 'revision': 4});
      expect(query.text, 'programmatic');
      await t.pumpWidget(shell(controller: replacement));
      await t.pumpAndSettle();
      final count = calls.length;
      query.text = 'detached';
      await t.pump();
      expect(calls.length, count);
      await edit({'id': 'find', 'query': '', 'revision': 5});
      expect(replacement.text, '');
      expect(edits, ['typed', '']);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      final disposedCount = calls.length;
      replacement.text = 'disposed owner';
      await t.pump();
      expect(calls.length, disposedCount);
      expect(await routing.focusSearch('find'), false);
      query.dispose();
      replacement.dispose();
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  testWidgets(
    'older typed transport fails safely to labelled fallback',
    (t) async {
      final controller = TextEditingController();
      final routing = MacosNativeToolbarController();
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'updateTyped') {
          throw PlatformException(code: 'bad_arguments');
        }
        return null;
      });
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MacosNativeToolbar(
            title: 'Documents',
            controller: routing,
            items: [
              MacosNativeToolbarSearch(
                id: 'find',
                label: 'Find documents',
                controller: controller,
              ),
            ],
            fallback: const Text('Find documents fallback'),
            child: const SizedBox(),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Find documents fallback'), findsOneWidget);
      expect(await routing.focusSearch('find'), false);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      controller.dispose();
      expect(t.takeException(), isNull);
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  testWidgets(
    'group proposals stay controlled and use current availability',
    (t) async {
      var proposals = 0;
      final pane = MacosPaneLayoutController();
      final calls = <MethodCall>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return true;
      });
      Widget shell({
        bool enabled = true,
        bool visible = true,
        bool interactive = true,
      }) => Directionality(
        textDirection: TextDirection.ltr,
        child: MacosNativeToolbar(
          title: 'Groups',
          visible: visible,
          interactive: interactive,
          paneLayoutController: pane,
          items: [
            MacosNativeToolbarGroup(
              id: 'view',
              label: 'View',
              mode: MacosNativeToolbarGroupMode.exclusive,
              selectedId: 'list',
              commands: [
                MacosNativeToolbarCommand(
                  id: 'list',
                  label: 'List',
                  symbol: 'list.bullet',
                  onPressed: enabled ? () => proposals++ : null,
                ),
              ],
            ),
          ],
          fallback: const Text('Group fallback'),
          child: const SizedBox(),
        ),
      );
      Future<void> propose(Object args) async {
        await t.binding.defaultBinaryMessenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('groupAction', args),
          ),
          (_) {},
        );
        await t.pump();
      }

      await t.pumpWidget(shell());
      await t.pumpAndSettle();
      pane.value = const MacosPaneLayout(
        size: Size(1000, 600),
        leadingWidth: 200,
        trailingWidth: 240,
      );
      await t.pumpAndSettle();
      expect((calls.last.arguments as Map)['paneLayout'], {
        'width': 1000.0,
        'height': 600.0,
        'leading': 200.0,
        'trailing': 240.0,
      });
      expect(
        ((calls.last.arguments as Map)['items'] as List).single['selected'],
        'list',
      );
      await propose({'id': 'view', 'command': 'list'});
      await propose({'id': 'view', 'command': 'list'});
      expect(proposals, 2);
      await propose({'id': 'view', 'command': 'unknown'});
      await propose({'id': 'unknown', 'command': 'list'});
      await propose(42);
      expect(proposals, 2);
      await t.pumpWidget(shell(enabled: false));
      await propose({'id': 'view', 'command': 'list'});
      await t.pumpWidget(shell(visible: false));
      await propose({'id': 'view', 'command': 'list'});
      await t.pumpWidget(shell(interactive: false));
      await propose({'id': 'view', 'command': 'list'});
      expect(proposals, 2);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      final count = calls.length;
      pane.value = null;
      await t.pump();
      expect(calls.length, count);
      pane.dispose();
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
