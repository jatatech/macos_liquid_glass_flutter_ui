import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

const _channel = MethodChannel('dev.groovinchip.macos_ui/glass');
const _preferences = 'dev.groovinchip.macos_ui/accessibility';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  Object? response = true;
  Future<Object?> Function(MethodCall)? handler;

  test(
    'glass policy respects unavailable accessibility, contrast, scale, direction and width',
    () {
      bool permits({
        MacosAccessibilityData accessibility = const MacosAccessibilityData(
          available: true,
          reduceTransparency: false,
        ),
        MediaQueryData media = const MediaQueryData(),
        TextDirection direction = TextDirection.ltr,
        double width = 600,
      }) => MacosGlassData.permitsNative(
        accessibility: accessibility,
        media: media,
        direction: direction,
        width: width,
      );
      expect(permits(), true);
      for (final data in [
        const MacosAccessibilityData(),
        const MacosAccessibilityData(available: true),
        const MacosAccessibilityData(
          available: true,
          reduceTransparency: false,
          increaseContrast: true,
        ),
      ]) {
        expect(permits(accessibility: data), false);
      }
      expect(permits(media: const MediaQueryData(highContrast: true)), false);
      expect(
        permits(media: const MediaQueryData(textScaler: TextScaler.linear(2))),
        false,
      );
      expect(permits(direction: TextDirection.rtl), false);
      expect(permits(width: 299), false);
      expect(permits(width: 300), true);
      expect(
        permits(media: const MediaQueryData(disableAnimations: true)),
        true,
      );
    },
  );

  final scenarios = <(String, Future<void> Function(WidgetTester))>[];
  void glassTest(String name, Future<void> Function(WidgetTester) body) {
    scenarios.add((name, body));
  }

  setUp(() {
    calls.clear();
    response = true;
    handler = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(_channel, (call) async {
        calls.add(call);
        if (handler != null) return handler!(call);
        return call.method == 'remove' ? null : response;
      })
      ..setMockMethodCallHandler(
        const MethodChannel(_preferences),
        (_) async => null,
      );
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(_channel, null)
      ..setMockMethodCallHandler(const MethodChannel(_preferences), null);
  });

  Future<void> nativeMessage(
    WidgetTester tester,
    String name,
    Object value, {
    bool method = false,
  }) async {
    final done = Completer<void>();
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      name,
      method
          ? const StandardMethodCodec().encodeMethodCall(value as MethodCall)
          : const StandardMethodCodec().encodeSuccessEnvelope(value),
      (_) => done.complete(),
    );
    await tester.runAsync(() => done.future);
    await tester.pumpAndSettle();
  }

  Future<void> prefs(
    WidgetTester tester, {
    bool opaque = false,
    bool contrast = false,
    bool motion = false,
  }) => nativeMessage(tester, _preferences, {
    'reduceTransparency': opaque,
    'increaseContrast': contrast,
    'reduceMotion': motion,
  });

  Widget surface({
    VoidCallback? action,
    bool opaque = false,
    ValueChanged<MacosGlassRendering>? mode,
    TextDirection direction = TextDirection.ltr,
    double width = 600,
  }) => MacosApp(
    themeMode: ThemeMode.dark,
    home: Directionality(
      textDirection: direction,
      child: Center(
        child: SizedBox(
          width: width,
          height: 400,
          child: MacosGlassCommandSurface(
            forceOpaque: opaque,
            onRenderingChanged: mode,
            commands: [
              MacosGlassCommand(label: 'Next', onPressed: action),
              const MacosGlassCommand(label: 'Unavailable'),
            ],
            child: const Text('Document content'),
          ),
        ),
      ),
    ),
  );

  Widget queuedSurface({
    double width = 400,
    bool opaque = false,
    bool occluded = false,
    bool hidden = false,
  }) => MacosApp(
    home: Center(
      child: SizedBox(
        width: width,
        child: Offstage(
          offstage: hidden,
          child: MacosGlassSurface(
            forceOpaque: opaque,
            nativeOccluded: occluded,
            nativeCommands: [
              MacosGlassCommand(label: 'Next', onPressed: () {}),
            ],
            child: const Text('Fallback commands'),
          ),
        ),
      ),
    ),
  );

  glassTest('native ownership, actions and stale callback disposal', (
    tester,
  ) async {
    var count = 0;
    final modes = <MacosGlassRendering>[];
    await tester.pumpWidget(surface(action: () => count++, mode: modes.add));
    await tester.pumpAndSettle();
    expect(
      find.text('Next'),
      findsOneWidget,
    ); // Safe initial preference snapshot.
    await prefs(tester);
    expect(
      find.text('Next'),
      findsNothing,
    ); // No duplicate Flutter semantics/focus.
    final spec = calls.last.arguments as Map;
    expect(spec['show'], true);
    expect(spec['dark'], true);
    expect(spec['commands'], [
      {'label': 'Next', 'enabled': true},
      {'label': 'Unavailable', 'enabled': false},
    ]);
    final id = spec['id'];
    for (final index in [0, 1, -1, 100]) {
      await nativeMessage(
        tester,
        _channel.name,
        MethodCall('action', {'id': id, 'index': index}),
        method: true,
      );
    }
    expect(count, 1);
    expect(modes, [MacosGlassRendering.native]);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(calls.last.method, 'remove');
    expect(calls.last.arguments, {'id': id});
    await nativeMessage(
      tester,
      _channel.name,
      MethodCall('action', {'id': id, 'index': 0}),
      method: true,
    );
    expect(count, 1);
  });

  glassTest(
    'live preferences remove and restore glass with explicit dark appearance',
    (tester) async {
      await tester.pumpWidget(surface(action: () {}));
      await tester.pumpAndSettle();
      await prefs(tester);
      expect(find.text('Next'), findsNothing);
      await prefs(tester, opaque: true, contrast: true, motion: true);
      expect(find.text('Next'), findsOneWidget);
      expect((calls.last.arguments as Map)['show'], false);
      await prefs(tester, motion: true);
      expect(find.text('Next'), findsNothing);
      expect((calls.last.arguments as Map)['reduceMotion'], true);
      expect((calls.last.arguments as Map)['dark'], true);
      await tester.pumpWidget(surface(action: () {}, opaque: true));
      await tester.pumpAndSettle();
      expect((calls.last.arguments as Map)['show'], false);
      expect(find.text('Next'), findsOneWidget);
      await tester.pumpWidget(surface(action: () {}));
      await tester.pumpAndSettle();
      expect((calls.last.arguments as Map)['show'], true);
    },
  );

  for (final failure in [
    null,
    'malformed',
    false,
    MissingPluginException(),
    PlatformException(code: 'unavailable'),
  ]) {
    glassTest(
      'unsupported/malformed native response $failure preserves commands',
      (tester) async {
        handler = (call) async {
          if (failure is Exception) throw failure;
          return failure;
        };
        var count = 0;
        await tester.pumpWidget(surface(action: () => count++));
        await tester.pumpAndSettle();
        await prefs(tester);
        expect(find.text('Next'), findsOneWidget);
        await tester.tap(find.text('Next'));
        expect(count, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  for (final hiding in ['opaque', 'occluded', 'offstage']) {
    glassTest('delayed resize coalesces before $hiding and restores latest', (
      tester,
    ) async {
      await tester.pumpWidget(queuedSurface(width: 400));
      await tester.pumpAndSettle();
      await prefs(tester);
      calls.clear();
      final blocked = Completer<Object?>();
      handler = (call) async {
        if (call.method == 'update' &&
            (call.arguments as Map)['width'] == 410) {
          return blocked.future;
        }
        return (call.arguments as Map)['show'] == true;
      };
      for (final width in [410.0, 420.0, 430.0, 440.0]) {
        await tester.pumpWidget(queuedSurface(width: width));
        await tester.pump();
      }
      await tester.pumpWidget(
        queuedSurface(
          width: 440,
          opaque: hiding == 'opaque',
          occluded: hiding == 'occluded',
          hidden: hiding == 'offstage',
        ),
      );
      await tester.pump();
      expect(calls.map((call) => (call.arguments as Map)['width']), [410]);
      blocked.complete(true);
      await tester.pumpAndSettle();
      expect(calls.map((call) => (call.arguments as Map)['show']), [
        true,
        false,
      ]);
      expect(
        find.text('Fallback commands'),
        hiding == 'offstage' ? findsNothing : findsOneWidget,
      );
      await tester.pumpWidget(queuedSurface(width: 440));
      await tester.pumpAndSettle();
      expect((calls.last.arguments as Map)['width'], 440);
      expect((calls.last.arguments as Map)['show'], true);
      expect(find.text('Fallback commands'), findsNothing);
    });
  }

  glassTest(
    'delayed updates converge to latest geometry without a frame backlog',
    (tester) async {
      await tester.pumpWidget(queuedSurface(width: 400));
      await tester.pumpAndSettle();
      await prefs(tester);
      calls.clear();
      final first = Completer<Object?>();
      final second = Completer<Object?>();
      handler = (call) async {
        final width = (call.arguments as Map)['width'];
        if (width == 410) return first.future;
        if (width == 440) return second.future;
        return true;
      };
      for (final width in [410.0, 420.0, 430.0, 440.0]) {
        await tester.pumpWidget(queuedSurface(width: width));
        await tester.pump();
      }
      expect(calls.length, 1);
      first.complete(
        false,
      ); // Stale capability failure cannot poison latest state.
      await tester.pump();
      await tester.pump();
      expect(calls.map((call) => (call.arguments as Map)['width']), [410, 440]);
      for (final width in [450.0, 460.0, 470.0]) {
        await tester.pumpWidget(queuedSurface(width: width));
        await tester.pump();
      }
      expect(calls.length, 2);
      second.complete(true);
      await tester.pumpAndSettle();
      expect(calls.map((call) => (call.arguments as Map)['width']), [
        410,
        440,
        470,
      ]);
      expect(find.text('Fallback commands'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  glassTest(
    'invalidation retries identical geometry despite a stale failed reply',
    (tester) async {
      await tester.pumpWidget(queuedSurface());
      await tester.pumpAndSettle();
      await prefs(tester);
      calls.clear();
      final blocked = Completer<Object?>();
      var delayed = false;
      handler = (call) async {
        if (call.method == 'update' && !delayed) {
          delayed = true;
          return blocked.future;
        }
        return true;
      };
      await tester.pumpWidget(queuedSurface(width: 410));
      await tester.pump();
      expect(
        calls.length,
        1,
        reason: calls.map((c) => '${c.method}: ${c.arguments}').join('\n'),
      );
      final spec = Map.of(calls.single.arguments as Map);
      await nativeMessage(
        tester,
        _channel.name,
        MethodCall('invalidated', {'id': spec['id']}),
        method: true,
      );
      expect(calls.length, 1);
      blocked.complete(false);
      await tester.pumpAndSettle();
      expect(calls.length, 2);
      expect(calls.last.arguments, spec);
      expect(find.text('Fallback commands'), findsNothing);
    },
  );

  glassTest(
    'queued teardown removes a native creation that completes after disposal',
    (tester) async {
      final pending = Completer<Object?>();
      handler = (call) async {
        if ((call.arguments as Map)['show'] == true) {
          return await pending.future;
        }
        return false;
      };
      await tester.pumpWidget(surface(action: () {}));
      await tester.pumpAndSettle();
      // Do not settle: the create deliberately remains in flight.
      final done = Completer<void>();
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        _preferences,
        const StandardMethodCodec().encodeSuccessEnvelope({
          'reduceTransparency': false,
          'increaseContrast': false,
          'reduceMotion': false,
        }),
        (_) => done.complete(),
      );
      await tester.runAsync(() => done.future);
      await tester.pump();
      await tester.pump();
      expect((calls.last.arguments as Map)['show'], true);
      final id = (calls.last.arguments as Map)['id'];
      final dispatched = calls.length;
      for (final width in [410.0, 420.0, 430.0]) {
        await tester.pumpWidget(surface(action: () {}, width: width));
        await tester.pump();
      }
      await tester.pumpWidget(surface(action: () {}, opaque: true));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(
        calls.length,
        dispatched,
        reason: calls.map((c) => '${c.method}: ${c.arguments}').join('\n'),
      ); // Remove waits for the native creation.
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(calls.last.method, 'remove');
      expect(calls.last.arguments, {'id': id});
      expect(calls.length, dispatched + 1);
      expect(tester.takeException(), isNull);
    },
  );

  glassTest('opaque fallback wraps, supports keyboard, RTL and large text', (
    tester,
  ) async {
    var count = 0;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      surface(action: () => count++, direction: TextDirection.rtl, width: 220),
    );
    await tester.pumpAndSettle();
    await prefs(tester);
    expect(calls.where((c) => (c.arguments as Map)['show'] == true), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(count, 1);
    expect(tester.takeException(), isNull);
  });

  glassTest(
    'resizing refreshes logical geometry and route coverage hides native controls',
    (tester) async {
      final nav = GlobalKey<NavigatorState>();
      double width = 600;
      late StateSetter change;
      await tester.pumpWidget(
        MacosApp(
          navigatorKey: nav,
          home: StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return Center(
                child: SizedBox(
                  width: width,
                  height: 400,
                  child: MacosGlassCommandSurface(
                    commands: [
                      MacosGlassCommand(label: 'Next', onPressed: () {}),
                    ],
                    child: const Text('content'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await prefs(tester);
      final before = Map.of(calls.last.arguments as Map);
      change(() => width = 350);
      await tester.pumpAndSettle();
      expect(
        (calls.last.arguments as Map)['width'],
        lessThan(before['width'] as num),
      );
      unawaited(
        nav.currentState!.push(
          CupertinoPageRoute<void>(builder: (_) => const Text('Other route')),
        ),
      );
      await tester.pumpAndSettle();
      expect((calls.last.arguments as Map)['show'], false);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect((calls.last.arguments as Map)['show'], true);
    },
  );
  glassTest('visibility, clipping, overlay ordering and native focus bridge', (
    tester,
  ) async {
    late StateSetter change;
    var offstage = false;
    var opacity = 1.0;
    var occluded = false;
    var blocked = false;
    var ticking = true;
    var moved = false;
    var clipped = false;
    var transformed = false;
    final beforeFocus = FocusNode(debugLabel: 'Before glass');
    final afterFocus = FocusNode(debugLabel: 'After glass');
    await tester.pumpWidget(
      MacosApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            change = setState;
            return Column(
              children: [
                Focus(focusNode: beforeFocus, child: const Text('Before')),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        left: moved ? 40 : 0,
                        top: 0,
                        width: 600,
                        height: 400,
                        child: Offstage(
                          offstage: offstage,
                          child: Opacity(
                            opacity: opacity,
                            child: TickerMode(
                              enabled: ticking,
                              child: ClipRect(
                                clipper: clipped ? _TopClip() : null,
                                child: Transform.scale(
                                  scale: transformed ? 0.9 : 1,
                                  child: MacosGlassCommandSurface(
                                    nativeOccluded: occluded,
                                    commands: [
                                      MacosGlassCommand(
                                        label: 'Next',
                                        onPressed: () {},
                                      ),
                                    ],
                                    child: const MacosTooltip(
                                      message: 'Document hint',
                                      child: Text('Document'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (blocked)
                        const Positioned.fill(
                          child: ColoredBox(color: Color(0xff000000)),
                        ),
                    ],
                  ),
                ),
                Focus(focusNode: afterFocus, child: const Text('After')),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await prefs(tester);
    bool visible() =>
        (calls.lastWhere((c) => c.method == 'update').arguments
            as Map)['show'] ==
        true;
    expect(visible(), true);
    final initial = Map.of(calls.last.arguments as Map);
    final group = tester
        .widgetList<Focus>(find.byType(Focus))
        .firstWhere(
          (focus) => focus.focusNode?.debugLabel == 'Native glass commands',
        )
        .focusNode!;
    group.requestFocus();
    await tester.pumpAndSettle();
    expect(calls.last.method, 'focus');
    expect((calls.last.arguments as Map)['backward'], false);
    await nativeMessage(
      tester,
      _channel.name,
      MethodCall('exitFocus', {'id': initial['id'], 'backward': false}),
      method: true,
    );
    expect(afterFocus.hasFocus, true);
    group.requestFocus();
    await tester.pumpAndSettle();
    await nativeMessage(
      tester,
      _channel.name,
      MethodCall('exitFocus', {'id': initial['id'], 'backward': true}),
      method: true,
    );
    expect(beforeFocus.hasFocus, true);
    for (final changeVisibility in <VoidCallback>[
      () => offstage = true,
      () => offstage = false,
      () => opacity = 0,
      () => opacity = 1,
      () => occluded = true,
      () => occluded = false,
      () => blocked = true,
      () => blocked = false,
      () => ticking = false,
      () => ticking = true,
      () => clipped = true,
      () => clipped = false,
      () => transformed = true,
      () => transformed = false,
    ].indexed) {
      change(changeVisibility.$2);
      await tester.pumpAndSettle();
      expect(visible(), changeVisibility.$1.isOdd);
    }
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.text('Document')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Document hint'), findsOneWidget);
    expect(visible(), false);
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(visible(), true);
    change(() => moved = true);
    await tester.pumpAndSettle();
    expect(visible(), true);
    expect((calls.last.arguments as Map)['x'], (initial['x'] as num) + 40);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    beforeFocus.dispose();
    afterFocus.dispose();
  });
  glassTest(
    'failed focus entry removes native hits and invalidation permits retry',
    (tester) async {
      await tester.pumpWidget(surface(action: () {}));
      await tester.pumpAndSettle();
      await prefs(tester);
      final id = (calls.last.arguments as Map)['id'];
      handler = (call) async =>
          call.method == 'focus' ? 'invalid focus response' : true;
      final group = tester
          .widgetList<Focus>(find.byType(Focus))
          .firstWhere(
            (focus) => focus.focusNode?.debugLabel == 'Native glass commands',
          )
          .focusNode!;
      group.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
      expect((calls.last.arguments as Map)['show'], false);
      handler = null;
      await nativeMessage(
        tester,
        _channel.name,
        MethodCall('invalidated', {'id': id}),
        method: true,
      );
      expect(find.text('Next'), findsNothing);
      expect((calls.last.arguments as Map)['show'], true);
    },
  );
  testWidgets('glass transport, repeated ownership and live policy lifecycle', (
    tester,
  ) async {
    // Keep repeated subscriptions to the app-wide broadcast in one fake-clock
    // lifetime. Each scenario still unmounts the app and verifies its assertions.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      for (final (name, body) in scenarios) {
        calls.clear();
        response = true;
        handler = null;
        debugPrint('Glass scenario: $name');
        await body(tester);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _TopClip extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, 100);
  @override
  bool shouldReclip(_TopClip oldClipper) => false;
}
