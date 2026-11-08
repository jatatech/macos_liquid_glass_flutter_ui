import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets(
    'recursive tree arrows, selection, collapse focus and semantics',
    (tester) async {
      final branch = FocusNode();
      final nested = FocusNode();
      final leaf = FocusNode();
      addTearDown(branch.dispose);
      addTearDown(nested.dispose);
      addTearDown(leaf.dispose);
      final semantics = tester.ensureSemantics();

      var selected = 0;
      await tester.pumpWidget(
        MacosApp(
          home: StatefulBuilder(
            builder: (context, setState) => SidebarItems(
              currentIndex: selected,
              onChanged: (value) => setState(() => selected = value),
              items: [
                const SidebarItem(label: Text('First')),
                SidebarItem(
                  label: const Text('Branch'),
                  focusNode: branch,
                  disclosureItems: [
                    SidebarItem(
                      label: const Text('Nested'),
                      focusNode: nested,
                      disclosureItems: [
                        SidebarItem(
                          label: const Text('Leaf'),
                          semanticLabel: 'Leaf destination',
                          focusNode: leaf,
                        ),
                      ],
                    ),
                  ],
                ),
                const SidebarItem(label: Text('Last')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      branch.requestFocus();
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(
          find
              .byWidgetPredicate(
                (w) => w is Semantics && w.properties.expanded == false,
              )
              .first,
        ),
        matchesSemantics(
          label: 'Branch',
          isButton: true,
          isFocusable: true,
          isFocused: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasExpandedState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(nested.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(leaf.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);
      await tester.tap(find.text('Branch'));
      await tester
          .pump(); // Input/AX excluded before the closing animation finishes.
      expect(branch.hasFocus, isTrue);
      expect(leaf.canRequestFocus, isFalse);
      expect(find.semantics.byLabel('Leaf destination'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNot(leaf));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 2);
      await tester.tap(find.text('Branch'));
      await tester.pumpAndSettle();
      expect(find.text('Leaf'), findsOneWidget); // nested expansion retained
      expect(leaf.canRequestFocus, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'live reduced motion finishes disclosure and scaled narrow tree remains readable',
    (tester) async {
      var reduced = false;
      late StateSetter update;
      await tester.pumpWidget(
        MacosApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: reduced,
                  textScaler: const TextScaler.linear(2),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 210,
                    child: SidebarItems(
                      currentIndex: 0,
                      onChanged: (_) {},
                      items: const [
                        SidebarItem(
                          label: Text('Section with a long label'),
                          section: true,
                          disclosureItems: [
                            SidebarItem(label: Text('Child with a long label')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Section with a long label'));
      await tester.pump(const Duration(milliseconds: 20));
      update(() => reduced = true);
      await tester.pump();
      await tester.pump();
      final align = tester
          .widgetList<Align>(find.byType(Align))
          .where((a) => a.heightFactor != null)
          .single;
      expect(align.heightFactor, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'overflow menu keyboard skips disabled, activates once and restores focus',
    (tester) async {
      var activated = 0;
      await tester.pumpWidget(
        MacosApp(
          home: Builder(
            builder: (context) => Center(
              child: ToolbarOverflowButton(
                overflowContentBuilder: (_) => ToolbarOverflowMenu(
                  children: [
                    const ToolbarOverflowMenuItem(label: 'Unavailable'),
                    ToolbarOverflowMenuItem(
                      label: 'Run',
                      onPressed: () => activated++,
                    ),
                    ToolbarOverflowMenuItem(label: 'Other', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final trigger = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, isNot(trigger));
      expect(find.text('Run'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(activated, 1);
      expect(FocusManager.instance.primaryFocus, trigger);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Run'), findsNothing);
      expect(FocusManager.instance.primaryFocus, trigger);
    },
  );

  testWidgets(
    'overflow submenu supports keyboard entry, back and disabled state',
    (tester) async {
      var activated = 0;
      await tester.pumpWidget(
        MacosApp(
          home: Builder(
            builder: (context) => Center(
              child: ToolbarOverflowButton(
                overflowContentBuilder: (_) => ToolbarOverflowMenu(
                  children: [
                    ToolbarOverflowMenuItem(
                      label: 'Group',
                      subMenuItems: [
                        const ToolbarOverflowMenuItem(label: 'Disabled child'),
                        ToolbarOverflowMenuItem(
                          label: 'Child command',
                          onPressed: () => activated++,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Child command'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Child command'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(activated, 1);
    },
  );

  testWidgets(
    'resize excludes hidden toolbar focus and AX and moves focus to overflow',
    (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final semantics = tester.ensureSemantics();

      var width = 700.0;
      late StateSetter update;
      await tester.pumpWidget(
        MacosApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  height: 52,
                  child: ToolBar(
                    title: const Text('Commands'),
                    actions: [
                      CustomToolbarItem(
                        inToolbarBuilder: (_) => SizedBox(
                          width: 200,
                          child: Focus(
                            focusNode: node,
                            child: MacosIconButton(
                              semanticLabel: 'Custom command',
                              icon: const MacosIcon(CupertinoIcons.add),
                              onPressed: () {},
                            ),
                          ),
                        ),
                        inOverflowedBuilder: (_) => ToolbarOverflowMenuItem(
                          label: 'Custom command',
                          onPressed: () {},
                        ),
                      ),
                      const ToolBarIconButton(
                        label: 'Disabled export',
                        icon: MacosIcon(CupertinoIcons.share),
                        showLabel: false,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      update(() => width = 220);
      await tester.pumpAndSettle();
      expect(node.canRequestFocus, isFalse);
      expect(node.hasFocus, isFalse);
      expect(find.semantics.byLabel('Custom command'), findsNothing);
      expect(find.semantics.byLabel('Disabled export'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Custom command'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
  testWidgets(
    'overflow scales, wraps and scrolls long labels with disabled AX state',
    (tester) async {
      tester.view.physicalSize = const Size(320, 240);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MacosApp(
          home: Center(
            child: ToolbarOverflowButton(
              overflowContentBuilder: (_) => ToolbarOverflowMenu(
                children: [
                  const ToolbarOverflowMenuItem(label: 'Unavailable export'),
                  for (var i = 0; i < 8; i++)
                    ToolbarOverflowMenuItem(
                      label: 'A long command label that needs wrapping $i',
                      onPressed: () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MacosIconButton));
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('Unavailable export'), findsOneWidget);
      final disabled = tester.getSemantics(find.text('Unavailable export'));
      expect(
        disabled.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(
        find.text('A long command label that needs wrapping 7').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      semantics.dispose();
    },
  );

  testWidgets(
    'hierarchy keeps explicit surfaces and shape and ignores secondary click',
    (tester) async {
      const shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      );
      await tester.pumpWidget(
        MacosApp(
          home: SidebarItems(
            currentIndex: 0,
            onChanged: (_) {},
            items: const [
              SidebarItem(
                label: Text('Custom branch'),
                unselectedColor: Color(0xFF123456),
                shape: shape,
                disclosureItems: [
                  SidebarItem(
                    label: Text('Custom leaf'),
                    selectedColor: Color(0xFF654321),
                    shape: shape,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pointer = await tester.createGesture(buttons: 2);
      await pointer.down(tester.getCenter(find.text('Custom branch')));
      await pointer.up();
      await tester.pumpAndSettle();
      expect(find.text('Custom leaf'), findsNothing);
      await tester.tap(find.text('Custom branch'));
      await tester.pumpAndSettle();
      final decorations = tester
          .widgetList<Container>(find.byType(Container))
          .map((w) => w.decoration)
          .whereType<ShapeDecoration>();
      expect(
        decorations.any(
          (d) => d.color == const Color(0xFF123456) && d.shape == shape,
        ),
        isTrue,
      );
      expect(
        decorations.any(
          (d) => d.color == const Color(0xFF654321) && d.shape == shape,
        ),
        isTrue,
      );
    },
  );
}
