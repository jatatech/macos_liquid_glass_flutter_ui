import 'package:flutter/services.dart';

/// Keep Flutter's standard menu serialization/callback delegate. Restore the
/// app-owned native responder Edit menu only after its replacement completes.
class ExampleMenuChannel extends MethodChannel {
  const ExampleMenuChannel() : super('flutter/menu');

  static const composition = MethodChannel(
    'example.shell_gallery/menu_composition',
  );

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    final result = await super.invokeMethod<T>(method, arguments);
    if (method == 'Menu.setMenus') {
      await composition.invokeMethod<void>('restoreEditMenu');
    }
    return result;
  }
}
