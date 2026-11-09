import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show ThemeMode, WidgetState;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

const channelName = 'dev.groovinchip.macos_ui/accessibility';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'live native preferences combine with Flutter and explicit dark theme',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel(channelName),
          null,
        ),
      );
      late BuildContext context;
      await tester.pumpWidget(
        MacosApp(
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      Future<void> emit(Object? value) async {
        final delivered = Completer<void>();
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          channelName,
          const StandardMethodCodec().encodeSuccessEnvelope(value),
          (_) => delivered.complete(),
        );
        await tester.runAsync(() => delivered.future);
        await tester.pump();
      }

      expect(calls, ['listen']);
      expect(MacosAccessibility.of(context).reduceTransparency, isTrue);
      await emit({
        'reduceTransparency': false,
        'reduceMotion': false,
        'increaseContrast': false,
      });
      expect(MacosAccessibility.of(context).available, isTrue);
      expect(MediaQuery.disableAnimationsOf(context), isFalse);
      final before = MacosChromeData.of(context).separator;
      await emit({
        'reduceTransparency': true,
        'reduceMotion': true,
        'increaseContrast': true,
      });
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
      expect(MediaQuery.highContrastOf(context), isTrue);
      expect(MacosChromeData.of(context).separator, isNot(before));
      expect(MacosTheme.of(context).brightness, Brightness.dark);
      await emit({
        'reduceTransparency': false,
        'reduceMotion': false,
        'increaseContrast': false,
      });
      expect(MediaQuery.disableAnimationsOf(context), isFalse);
      expect(MediaQuery.highContrastOf(context), isFalse);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(
            disableAnimations: true,
            highContrast: true,
          );
      await tester.pump();
      await emit({
        'reduceTransparency': false,
        'reduceMotion': false,
        'increaseContrast': false,
      });
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
      expect(MediaQuery.highContrastOf(context), isTrue);
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      await emit({'reduceMotion': 'malformed'});
      expect(MacosAccessibility.of(context).available, isFalse);
      expect(MacosAccessibility.of(context).reduceTransparency, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(calls, ['listen', 'cancel']);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  for (final failure in <Exception>[
    MissingPluginException(),
    PlatformException(code: 'unavailable'),
  ]) {
    testWidgets('native adapter failure $failure retains opaque fallback', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (_) async => throw failure,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel(channelName),
          null,
        ),
      );
      late BuildContext context;
      await tester.pumpWidget(
        MacosApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      expect(MacosAccessibility.of(context).available, isFalse);
      expect(MacosAccessibility.of(context).reduceTransparency, isTrue);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
  testWidgets(
    'chrome resolves state priority, inactive selection and live Flutter contrast',
    (tester) async {
      late MacosChromeData chrome;
      Future<void> build({bool contrast = false, bool active = true}) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(highContrast: contrast),
            child: MacosTheme(
              data: MacosThemeData.light(isMainWindow: active),
              child: Builder(
                builder: (context) {
                  chrome = MacosChromeData.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      }

      await build();
      expect(chrome.canvas.a, 1);
      expect(chrome.backgroundFor({WidgetState.hovered}), chrome.hover);
      expect(
        chrome.backgroundFor({WidgetState.selected, WidgetState.hovered}),
        chrome.selection,
      );
      expect(
        chrome.backgroundFor({WidgetState.pressed, WidgetState.selected}),
        chrome.pressed,
      );
      expect(
        chrome.backgroundFor({WidgetState.disabled, WidgetState.pressed}),
        chrome.toolbar,
      );
      await build(contrast: true, active: false);
      expect(chrome.focusWidth, 3);
      expect(chrome.selection, chrome.foreground);
    },
  );

  testWidgets(
    'icon commands support keyboard, focus, hover, disabled and right click',
    (tester) async {
      var count = 0;
      await tester.pumpWidget(
        MacosApp(
          home: Center(
            child: MacosIconButton(
              semanticLabel: 'Command',
              icon: const Text('Run'),
              onPressed: () => count++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(count, 1);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(MacosIconButton)),
      );
      await tester.pump();
      final secondary = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: 2,
      );
      await secondary.down(tester.getCenter(find.byType(MacosIconButton)));
      await secondary.up();
      expect(count, 1);
      await mouse.removePointer();
      await tester.pumpWidget(
        const MacosApp(
          home: Center(
            child: MacosIconButton(semanticLabel: 'Command', icon: Text('Run')),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(count, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
