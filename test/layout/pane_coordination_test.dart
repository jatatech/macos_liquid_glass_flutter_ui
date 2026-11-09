import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets(
    'pane geometry follows pointer resize, scroll and independent visibility',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final panes = MacosPaneLayoutController();
      final focus = FocusNode();
      late BuildContext scopeContext;
      ScrollController? navigation;
      var clicks = 0;
      final semantics = t.ensureSemantics();
      await t.pumpWidget(
        MacosApp(
          home: MacosWindow(
            paneLayoutController: panes,
            disableWallpaperTinting: true,
            sidebar: Sidebar(
              minWidth: 180,
              startWidth: 200,
              maxWidth: 280,
              topOffset: 0,
              windowBreakpoint: 600,
              builder: (context, controller) {
                navigation = controller;
                return ListView(
                  controller: controller,
                  children: [
                    MacosTextField(
                      focusNode: focus,
                      placeholder: 'Navigation filter',
                    ),
                    for (var i = 0; i < 60; i++)
                      MacosListTile(
                        title: Text('Destination $i'),
                        onClick: () => clicks++,
                      ),
                  ],
                );
              },
            ),
            endSidebar: Sidebar(
              minWidth: 200,
              startWidth: 240,
              topOffset: 0,
              windowBreakpoint: 900,
              shownByDefault: true,
              builder: (_, controller) => ListView(
                controller: controller,
                children: const [Text('Independent inspector')],
              ),
            ),
            child: Builder(
              builder: (context) {
                scopeContext = context;
                return MacosScaffold(
                  children: [
                    ContentArea(
                      builder: (_, controller) => ListView(
                        controller: controller,
                        children: const [Text('Document content')],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(panes.value!.leadingWidth, 200);
      expect(panes.value!.trailingWidth, 240);
      expect(panes.value!.content, const Rect.fromLTWH(200, 0, 760, 700));
      expect(t.getTopLeft(find.text('Document content')).dx, 200);
      // Every visible pane has one explicit scrollbar, with no automatic duplicate.
      expect(
        find.descendant(
          of: find.byType(ListView).first,
          matching: find.byType(MacosScrollbar),
        ),
        findsNothing,
      );
      final first = navigation!;
      final row = find.widgetWithText(MacosListTile, 'Destination 0');
      await t.tap(find.text('Destination 0'));
      await t.tapAt(t.getTopRight(row) + const Offset(-10, 10));
      expect(clicks, 2);
      final secondary = await t.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: 2,
      );
      await secondary.down(t.getCenter(row));
      await secondary.up();
      expect(clicks, 2);
      final pointer = t.getCenter(find.byType(ListView).first);
      t.binding.handlePointerEvent(
        PointerScrollEvent(
          position: pointer,
          scrollDelta: const Offset(0, 250),
        ),
      );
      await t.pumpAndSettle();
      expect(first.offset, greaterThan(0));
      final beforeThumbDrag = first.offset;
      await t.dragFrom(
        const Offset(193, 100),
        const Offset(0, 80),
        kind: PointerDeviceKind.mouse,
      );
      await t.pumpAndSettle();
      expect(first.offset, greaterThan(beforeThumbDrag));
      focus.requestFocus();
      await t.pumpAndSettle();
      final offset = first.offset;
      MacosWindowScope.of(scopeContext).toggleSidebar();
      await t.pumpAndSettle();
      expect(panes.value!.leadingWidth, 0);
      expect(panes.value!.trailingWidth, 240);
      expect(focus.hasFocus, false);
      expect(find.text('Destination 0'), findsNothing);
      expect(find.bySemanticsLabel('Navigation filter'), findsNothing);
      expect(find.text('Independent inspector'), findsOneWidget);
      MacosWindowScope.of(scopeContext).toggleSidebar();
      await t.pumpAndSettle();
      expect(navigation, same(first));
      expect(first.offset, offset);
      // Resize with the physical divider coordinates after scrolling/reopening.
      await t.dragFrom(const Offset(200, 300), const Offset(45, 0));
      await t.pumpAndSettle();
      expect(panes.value!.leadingWidth, 245);
      expect(t.getTopLeft(find.text('Document content')).dx, 245);
      await t.binding.setSurfaceSize(const Size(500, 700));
      await t.pumpAndSettle();
      expect(panes.value!.leadingWidth, 0);
      expect(panes.value!.trailingWidth, 0);
      expect(panes.value!.content.width, 500);
      await t.binding.setSurfaceSize(const Size(1200, 700));
      await t.pumpAndSettle();
      expect(panes.value!.leadingWidth, 245);
      expect(panes.value!.trailingWidth, 240);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      semantics.dispose();
      focus.dispose();
      panes.dispose();
      expect(t.takeException(), isNull);
    },
  );
}
