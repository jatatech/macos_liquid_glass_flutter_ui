import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  for (final end in [false, true]) {
    testWidgets(
      '${end ? 'end' : 'main'} hidden pane excludes focus, hits and semantics',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        final semantics = tester.ensureSemantics();
        late MacosWindowScope scope;
        var taps = 0;
        final sidebar = Sidebar(
          minWidth: 180,
          shownByDefault: true,
          builder: (context, _) => Focus(
            focusNode: focus,
            child: GestureDetector(
              onTap: () => taps++,
              child: Semantics(
                label: 'Pane action',
                child: const Text('Pane action'),
              ),
            ),
          ),
        );
        await tester.pumpWidget(
          MacosApp(
            home: MacosWindow(
              disableWallpaperTinting: true,
              sidebar: end ? null : sidebar,
              endSidebar: end ? sidebar : null,
              child: Builder(
                builder: (context) {
                  scope = MacosWindowScope.of(context);
                  return const MacosScaffold(children: []);
                },
              ),
            ),
          ),
        );
        focus.requestFocus();
        await tester.pump();
        expect(focus.hasFocus, isTrue);
        final point = tester.getCenter(find.text('Pane action'));
        end ? scope.toggleEndSidebar() : scope.toggleSidebar();
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isFalse);
        expect(find.text('Pane action'), findsNothing);
        expect(find.bySemanticsLabel('Pane action'), findsNothing);
        await tester.tapAt(point);
        expect(taps, 0);
        focus.requestFocus();
        await tester.pump();
        expect(focus.hasFocus, isFalse);
        end ? scope.toggleEndSidebar() : scope.toggleSidebar();
        await tester.pumpAndSettle();
        expect(find.text('Pane action'), findsOneWidget);
        await tester.tap(find.text('Pane action'));
        expect(taps, 1);
        semantics.dispose();
      },
    );
  }
  testWidgets('live reduced motion removes pane transitions', (tester) async {
    final reduced = ValueNotifier(false);
    addTearDown(reduced.dispose);
    await tester.pumpWidget(
      MacosApp(
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: reduced,
          builder: (context, value, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: value),
            child: child!,
          ),
        ),
        home: MacosWindow(
          disableWallpaperTinting: true,
          sidebar: Sidebar(
            minWidth: 180,
            builder: (_, _) => const Text('Navigation'),
          ),
          child: const MacosScaffold(children: []),
        ),
      ),
    );
    expect(
      tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .any((widget) => widget.duration > Duration.zero),
      isTrue,
    );
    reduced.value = true;
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
    reduced.value = false;
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .any((widget) => widget.duration > Duration.zero),
      isTrue,
    );
    // The utility schedules a zero-delay native bounds update after rebuild.
    await tester.pump(Duration.zero);
  });
}
