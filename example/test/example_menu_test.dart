import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell_gallery/example_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native Edit restoration waits for successful menu replacement',
    () async {
      final calls = <String>[];
      final replacement = Completer<void>();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.menu, (call) async {
        calls.add(call.method);
        await replacement.future;
        return null;
      });
      messenger.setMockMethodCallHandler(ExampleMenuChannel.composition, (
        call,
      ) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.menu, null);
        messenger.setMockMethodCallHandler(
          ExampleMenuChannel.composition,
          null,
        );
      });
      final result = const ExampleMenuChannel().invokeMethod<void>(
        'Menu.setMenus',
        {'0': []},
      );
      await Future<void>.delayed(Duration.zero);
      expect(calls, ['Menu.setMenus']);
      replacement.complete();
      await result;
      expect(calls, ['Menu.setMenus', 'restoreEditMenu']);
    },
  );
  test('failed or unrelated menu messages do not restore a menu', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var restores = 0;
    messenger.setMockMethodCallHandler(SystemChannels.menu, (call) async {
      if (call.method == 'Menu.setMenus') {
        throw PlatformException(code: 'failed');
      }
      return true;
    });
    messenger.setMockMethodCallHandler(ExampleMenuChannel.composition, (
      _,
    ) async {
      restores++;
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.menu, null);
      messenger.setMockMethodCallHandler(ExampleMenuChannel.composition, null);
    });
    const channel = ExampleMenuChannel();
    expect(await channel.invokeMethod<bool>('Menu.isPluginAvailable'), isTrue);
    await expectLater(
      channel.invokeMethod<void>('Menu.setMenus'),
      throwsA(isA<PlatformException>()),
    );
    expect(restores, 0);
  });
}
