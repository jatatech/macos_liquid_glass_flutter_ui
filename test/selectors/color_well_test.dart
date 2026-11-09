import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import '../fields/field_interactions_test.dart' show host;

const channel = MethodChannel('dev.groovinchip.macos_ui');
const events = MethodChannel('dev.groovinchip.macos_ui/color_panel');
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <String>[];
  setUp(() {
    calls.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, (
      call,
    ) async {
      calls.add(call.method);
      return null;
    });
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, null);
  });
  Future<void> send(WidgetTester t, ByteData? data) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      events.name,
      data,
      (_) {},
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'well opens only on activation, decodes/deduplicates and cancels safely',
    (t) async {
      final colors = <Color>[];
      var enabled = true;
      var hidden = false;
      late StateSetter rebuild;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              rebuild = set;
              return ExcludeFocus(
                excluding: hidden,
                child: MacosColorWell(
                  enabled: enabled,
                  color: CupertinoColors.systemRed,
                  onColorSelected: colors.add,
                ),
              );
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(calls, isEmpty);
      await t.tap(find.byType(MacosColorWell));
      await t.pumpAndSettle();
      expect(calls, ['listen', 'color_panel']);
      await send(
        t,
        const StandardMethodCodec().encodeSuccessEnvelope('invalid'),
      );
      await send(
        t,
        const StandardMethodCodec().encodeSuccessEnvelope({'bad': 3}),
      );
      await send(t, const StandardMethodCodec().encodeSuccessEnvelope('-1'));
      await send(t, ByteData(1));
      expect(colors, isEmpty);
      await send(
        t,
        const StandardMethodCodec().encodeSuccessEnvelope('0xFF00FF00'),
      );
      await send(
        t,
        const StandardMethodCodec().encodeSuccessEnvelope('0xFF00FF00'),
      );
      expect(colors, [const Color(0xFF00FF00)]);
      rebuild(() => enabled = false);
      await t.pumpAndSettle();
      expect(calls.sublist(2), ['close_color_panel', 'cancel']);
      rebuild(() => enabled = true);
      await t.pumpAndSettle();
      await t.tap(find.byType(MacosColorWell));
      await t.pumpAndSettle();
      rebuild(() => hidden = true);
      await t.pumpAndSettle();
      expect(calls.where((s) => s == 'cancel').length, 2);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'only active well receives selection; close and errors do not notify',
    (t) async {
      final first = <Color>[];
      final second = <Color>[];
      await t.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MacosColorWell(onColorSelected: first.add),
              MacosColorWell(onColorSelected: second.add),
            ],
          ),
        ),
      );
      await t.tap(find.byType(MacosColorWell).first);
      await t.pumpAndSettle();
      await t.tap(find.byType(MacosColorWell).last);
      await t.pumpAndSettle();
      expect(calls, ['listen', 'color_panel', 'listen', 'color_panel']);
      await send(
        t,
        const StandardMethodCodec().encodeSuccessEnvelope('4278255360'),
      );
      expect(first, isEmpty);
      expect(second, [const Color(0xFF00FF00)]);
      await send(
        t,
        const StandardMethodCodec().encodeErrorEnvelope(code: 'cancelled'),
      );
      expect(second.length, 1);
      await t.tap(find.byType(MacosColorWell).first);
      await t.pumpAndSettle();
      await send(t, null);
      expect(first, isEmpty);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
  for (final missing in [true, false]) {
    testWidgets('well handles missing=$missing plugin or platform failure', (
      t,
    ) async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(events, (
        call,
      ) async {
        if (missing) throw MissingPluginException();
        throw PlatformException(code: 'unavailable');
      });
      await t.pumpWidget(
        host(
          MacosColorWell(onColorSelected: (_) => fail('No selection expected')),
        ),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    });
  }
}
