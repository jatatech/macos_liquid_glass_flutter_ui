import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Live AppKit accessibility preferences. An unavailable adapter keeps native
/// macOS glass conservative. Portable surfaces distinguish transport absence
/// from a user preference; Flutter motion and contrast flags still apply.
@immutable
class MacosAccessibilityData {
  const MacosAccessibilityData({
    this.reduceTransparency = true,
    this.reduceMotion = false,
    this.increaseContrast = false,
    this.available = false,
  });

  final bool reduceTransparency;
  final bool reduceMotion;
  final bool increaseContrast;
  final bool available;

  static MacosAccessibilityData _decode(dynamic value) {
    if (value is! Map ||
        value['reduceTransparency'] is! bool ||
        value['reduceMotion'] is! bool ||
        value['increaseContrast'] is! bool) {
      return const MacosAccessibilityData();
    }
    return MacosAccessibilityData(
      reduceTransparency: value['reduceTransparency'] as bool,
      reduceMotion: value['reduceMotion'] as bool,
      increaseContrast: value['increaseContrast'] as bool,
      available: true,
    );
  }
}

/// Owned by [MacosApp]. May also wrap standalone themed widget trees.
/// Cancels its subscription on disposal. Explicit appearance does not override
/// accessibility. No optional effect is enabled by this widget.
class MacosAccessibility extends StatefulWidget {
  const MacosAccessibility({super.key, required this.child});
  final Widget child;

  static MacosAccessibilityData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Preferences>()?.data ??
      const MacosAccessibilityData();

  @override
  State<MacosAccessibility> createState() => _MacosAccessibilityState();
}

class _MacosAccessibilityState extends State<MacosAccessibility> {
  static final _events = _PreferenceEvents();
  StreamSubscription<dynamic>? _subscription;
  MacosAccessibilityData _data = const MacosAccessibilityData();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      _subscription = _events.stream.listen(
        (dynamic value) {
          if (mounted) {
            setState(() => _data = MacosAccessibilityData._decode(value));
          }
        },
        onError: (Object error) {
          if (mounted) setState(() => _data = const MacosAccessibilityData());
        },
      );
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return _Preferences(
      data: _data,
      child: MediaQuery(
        data: media.copyWith(
          disableAnimations: media.disableAnimations || _data.reduceMotion,
          highContrast: media.highContrast || _data.increaseContrast,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Preferences extends InheritedWidget {
  const _Preferences({required this.data, required super.child});
  final MacosAccessibilityData data;
  @override
  bool updateShouldNotify(_Preferences oldWidget) => data != oldWidget.data;
}

// EventChannel wire protocol with guarded activation/deactivation: the framework
// EventChannel reports activation failures globally before stream onError runs.
class _PreferenceEvents {
  static const _name = 'dev.groovinchip.macos_ui/accessibility';
  static const _method = MethodChannel(_name);
  late final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast(
        onListen: () => unawaited(_start()),
        onCancel: () => unawaited(_stop()),
      );
  Stream<dynamic> get stream => _controller.stream;
  Future<void> _pending = Future<void>.value();

  Future<void> _start() {
    return _pending = _pending.then((_) async {
      if (!_controller.hasListener) return;
      ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(_name, (
        message,
      ) async {
        if (!_controller.hasListener) return null;
        try {
          _controller.add(
            message == null
                ? null
                : const StandardMethodCodec().decodeEnvelope(message),
          );
        } catch (_) {
          _controller.add(null);
        }
        return null;
      });
      try {
        await _method.invokeMethod<void>('listen');
      } catch (_) {
        if (_controller.hasListener) _controller.add(null);
      }
    });
  }

  Future<void> _stop() {
    return _pending = _pending.then((_) async {
      ServicesBinding.instance.defaultBinaryMessenger.setMessageHandler(
        _name,
        null,
      );
      try {
        await _method.invokeMethod<void>('cancel');
      } catch (_) {
        // Missing plugins and teardown races retain the conservative fallback.
      }
    });
  }
}
