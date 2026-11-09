import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shell_gallery/showcase.dart';

void main() {
  testWidgets('photo search recovers from empty and Back retains the query', (
    t,
  ) async {
    await t.pumpWidget(const FieldnotesApp());
    await t.pumpAndSettle();
    final field = find.byType(MacosTextField).first;
    await t.enterText(field, 'no photograph matches this');
    await t.pumpAndSettle();
    expect(find.text('No photographs found'), findsOneWidget);
    await t.tap(find.text('Clear search'));
    await t.pumpAndSettle();
    expect(find.text('12 photographs · Autumn collection'), findsOneWidget);
    await t.enterText(field, 'lake');
    await t.pumpAndSettle();
    expect(find.text('2 results for “lake”'), findsOneWidget);
    await t.tap(find.text('Open photograph'));
    await t.pumpAndSettle();
    expect(find.byType(MacosGlassCommandSurface), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    expect(
      t.widget<MacosNativeToolbar>(find.byType(MacosNativeToolbar)).title,
      'An afternoon afloat',
    );
    await t.tap(find.text('Back to photographs'));
    await t.pumpAndSettle();
    expect(t.widget<MacosTextField>(field).controller!.text, 'lake');
    expect(find.text('2 results for “lake”'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'favourites update the album and narrow large-text layout stays usable',
    (t) async {
      t.view.physicalSize = const Size(1400, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(const FieldnotesApp());
      await t.pumpAndSettle();
      await t.tap(find.text('Favourites').first);
      await t.pumpAndSettle();
      expect(find.text('4 photographs · Autumn collection'), findsOneWidget);
      await t.tap(find.widgetWithText(PushButton, 'Remove favourite'));
      await t.pumpAndSettle();
      expect(find.text('3 photographs · Autumn collection'), findsOneWidget);
      t.view.physicalSize = const Size(760, 700);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
}
