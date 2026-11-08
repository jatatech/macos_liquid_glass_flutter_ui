import 'package:flutter/services.dart';

abstract final class MacosGlassBridge {
  static const channel = MethodChannel('dev.groovinchip.macos_ui/glass');
  static int nextId = 1;
  static final owners = <int, void Function(MethodCall)>{};
  static bool _installed = false;
  static void install() {
    if (_installed) return;
    _installed = true;
    channel.setMethodCallHandler((call) async {
      final args = call.arguments;
      if (args is Map && args['id'] is int) owners[args['id']]?.call(call);
    });
  }
}
