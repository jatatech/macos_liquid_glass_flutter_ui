import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

void main() {
  for (final direction in TextDirection.values) {
    final rtl = direction == TextDirection.rtl;
    testWidgets('$direction panes, dividers, resize and live direction', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(1000, 650));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final panes = MacosPaneLayoutController();
      addTearDown(panes.dispose);
      late BuildContext scope;
      Widget shell(TextDirection value) => MacosApp(
        home: Directionality(
          textDirection: value,
          child: MacosWindow(
            paneLayoutController: panes,
            disableWallpaperTinting: true,
            sidebar: Sidebar(
              minWidth: 150,
              startWidth: 200,
              maxWidth: 300,
              topOffset: 0,
              windowBreakpoint: 0,
              builder: (_, c) => ListView(
                controller: c,
                children: const [Text('المكتبة 123')],
              ),
            ),
            endSidebar: Sidebar(
              minWidth: 150,
              startWidth: 180,
              maxWidth: 280,
              topOffset: 0,
              windowBreakpoint: 0,
              shownByDefault: true,
              builder: (_, c) => ListView(
                controller: c,
                children: const [Text('מאפיינים 456')],
              ),
            ),
            child: Builder(
              builder: (context) {
                scope = context;
                return const SizedBox.expand(key: Key('document'));
              },
            ),
          ),
        ),
      );
      await t.pumpWidget(shell(direction));
      await t.pumpAndSettle();
      expect(
        t.getRect(find.byKey(const Key('document'))),
        Rect.fromLTWH(rtl ? 180 : 200, 0, 620, 650),
      );
      expect(
        panes.value!.content,
        t.getRect(find.byKey(const Key('document'))),
      );
      expect(
        t.getCenter(find.text('المكتبة 123')).dx,
        rtl ? greaterThan(800) : lessThan(200),
      );
      final leadingEdge = rtl ? 800.0 : 200.0;
      await t.dragFrom(Offset(leadingEdge, 350), Offset(rtl ? -40 : 40, 0));
      await t.pumpAndSettle();
      expect(panes.value!.leadingWidth, closeTo(240, 1));
      final trailingEdge = rtl ? 180.0 : 820.0;
      await t.dragFrom(Offset(trailingEdge, 350), Offset(rtl ? 30 : -30, 0));
      await t.pumpAndSettle();
      expect(panes.value!.trailingWidth, closeTo(210, 1));
      await t.pumpWidget(shell(rtl ? TextDirection.ltr : TextDirection.rtl));
      await t.pumpAndSettle();
      expect(panes.value!.content.left, rtl ? 240 : 210);
      MacosWindowScope.of(scope).toggleEndSidebar();
      await t.pump(const Duration(milliseconds: 350));
      await t.pumpAndSettle();
      expect(find.text('מאפיינים 456'), findsNothing);
      expect(panes.value!.trailingWidth, 0);
    });

    testWidgets('$direction disclosure, keys, focus, mixed text and Back', (
      t,
    ) async {
      final parent = FocusNode(), leaf = FocusNode();
      addTearDown(parent.dispose);
      addTearDown(leaf.dispose);
      var selection = -1, back = 0;
      final semantics = t.ensureSemantics();
      await t.pumpWidget(
        MacosApp(
          home: Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Center(
                child: SizedBox(
                  width: 230,
                  child: Column(
                    children: [
                      MacosBackButton(
                        onPressed: () => back++,
                        semanticLabel: 'Zurück',
                      ),
                      Expanded(
                        child: SidebarItems(
                          currentIndex: 0,
                          onChanged: (v) => selection = v,
                          items: [
                            SidebarItem(
                              label: const Text('المكتبة 123'),
                              focusNode: parent,
                              disclosureItems: [
                                SidebarItem(
                                  label: const Text(
                                    'מאפיינים ABC 456 — Dokumenteigenschaften',
                                  ),
                                  focusNode: leaf,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.byIcon(
          rtl ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
        ),
        findsOneWidget,
      );
      expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
      // Cupertino's Back already mirrors itself; choosing Forward in RTL would
      // mirror twice. Inspect the rendered transform, not only IconData.
      final backTransform = find.descendant(
        of: find.byIcon(CupertinoIcons.back),
        matching: find.byType(Transform),
      );
      expect(backTransform, rtl ? findsOneWidget : findsNothing);
      if (rtl) {
        expect(t.widget<Transform>(backTransform).transform.entry(0, 0), -1);
      }

      parent.requestFocus();
      await t.pump();
      final expand = rtl
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowRight;
      final collapse = rtl
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowLeft;
      await t.sendKeyEvent(expand);
      await t.pumpAndSettle();
      await t.sendKeyEvent(expand);
      await t.pumpAndSettle();
      expect(leaf.hasFocus, isTrue);
      final parentRect = t.getRect(find.byKey(const ValueKey('0')));
      final leafRect = t.getRect(find.byKey(const ValueKey('0/0')));
      expect(
        rtl
            ? parentRect.right - leafRect.right
            : leafRect.left - parentRect.left,
        MacosChromeData.gap,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(selection, 0);
      await t.sendKeyEvent(collapse);
      await t.pumpAndSettle();
      expect(parent.hasFocus, isTrue);
      await t.sendKeyEvent(collapse);
      await t.pump();
      expect(leaf.canRequestFocus, isFalse);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(leaf.hasFocus, isFalse);
      await t.tap(find.byType(MacosBackButton));
      await t.pumpAndSettle();
      expect(back, 1);
      expect(t.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('$direction scaffold order retains physical resizer meaning', (
      t,
    ) async {
      await t.pumpWidget(
        MacosApp(
          home: Directionality(
            textDirection: direction,
            child: MacosScaffold(
              children: [
                ResizablePane.noScrollBar(
                  minSize: 120,
                  startSize: 150,
                  maxSize: 250,
                  resizableSide: rtl ? ResizableSide.left : ResizableSide.right,
                  child: const Text('Pane'),
                ),
                ContentArea(builder: (_, _) => const Text('Content')),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final pane = find.byType(ResizablePane);
      expect(t.getTopLeft(pane).dx, rtl ? 650 : 0);
      final edge = rtl ? t.getTopLeft(pane).dx : t.getTopRight(pane).dx;
      await t.dragFrom(
        Offset(edge + (rtl ? 2 : -2), 300),
        Offset(rtl ? -30 : 30, 0),
      );
      await t.pumpAndSettle();
      expect(t.getSize(pane).width, closeTo(180, 1));
    });
  }
}
