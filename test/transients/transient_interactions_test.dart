import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

Widget host(
  Widget child, {
  bool dark = false,
  bool contrast = false,
  bool motion = false,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MacosApp(
  theme: dark ? MacosThemeData.dark() : MacosThemeData.light(),
  builder: (context, navigator) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      highContrast: contrast || MediaQuery.highContrastOf(context),
      disableAnimations: motion || MediaQuery.disableAnimationsOf(context),
      textScaler: TextScaler.linear(scale),
    ),
    child: Directionality(
      textDirection: direction,
      child: RepaintBoundary(
        key: const ValueKey('transient-frame'),
        child: navigator!,
      ),
    ),
  ),
  home: child,
);

MacosAlertDialog alert(BuildContext context) => MacosAlertDialog(
  appIcon: const FlutterLogo(),
  title: const Text('Confirm change'),
  message: const Text(
    'A long document message that remains readable and scrollable.',
  ),
  primaryButton: PushButton(
    controlSize: ControlSize.large,
    onPressed: () => Navigator.of(context).pop('saved'),
    child: const Text('Save'),
  ),
  secondaryButton: PushButton(
    controlSize: ControlSize.large,
    onPressed: () => Navigator.of(context).pop(),
    child: const Text('Cancel'),
  ),
);

void main() {
  testWidgets('toolbar submenu action opens a dialog without popping it', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        Builder(
          builder: (context) => Center(
            child: ToolbarOverflowButton(
              overflowContentBuilder: (_) => ToolbarOverflowMenu(
                children: [
                  ToolBarPullDownButton(
                    label: 'Document',
                    icon: CupertinoIcons.doc,
                    items: [
                      MacosPulldownMenuItem(
                        title: const Text('Confirm'),
                        label: 'Confirm',
                        onTap: () => showMacosAlertDialog<void>(
                          context: context,
                          builder: alert,
                        ),
                      ),
                    ],
                  ).build(context, ToolbarItemDisplayMode.overflowed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(find.text('Confirm change'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    expect(
      FocusManager.instance.primaryFocus!.context!
          .findAncestorWidgetOfExactType<MacosAlertDialog>(),
      isNotNull,
    );
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('Confirm change'), findsNothing);
    // Choosing a submenu command returns to its parent menu.
    expect(find.text('Document'), findsOneWidget);
  });

  testWidgets(
    'partial pulldown styles and external focus replacement remain usable',
    (t) async {
      final first = FocusNode();
      final second = FocusNode();
      var node = first;
      var enabled = true;
      late StateSetter change;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return Center(
                child: MacosPulldownButtonTheme(
                  data: const MacosPulldownButtonThemeData(
                    backgroundColor: Color(0xFF123456),
                  ),
                  child: MacosPulldownButton(
                    title: 'Commands',
                    focusNode: node,
                    items: enabled
                        ? [const MacosPulldownMenuItem(title: Text('Action'))]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
      first.requestFocus();
      await t.pump();
      change(() => node = second);
      await t.pumpAndSettle();
      first.dispose();
      second.requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(find.text('Action'), findsOneWidget);
      change(() => enabled = false);
      await t.pumpAndSettle();
      expect(find.text('Action'), findsNothing);
      expect(second.hasFocus, isFalse);
      await t.pumpWidget(const SizedBox());
      second.dispose();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'live modal accessibility removes visual motion and keeps explicit sheet style',
    (t) async {
      await t.pumpWidget(
        host(
          Builder(
            builder: (context) => Center(
              child: PushButton(
                controlSize: ControlSize.large,
                child: const Text('Open'),
                onPressed: () => showMacosSheet<void>(
                  context: context,
                  builder: (_) => const MacosSheet(
                    backgroundColor: Color(0xFF123456),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Live sheet'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pump(const Duration(milliseconds: 16));
      expect(
        find.ancestor(
          of: find.text('Live sheet'),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(
            disableAnimations: true,
            highContrast: true,
          );
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await t.pump();
      expect(
        find.ancestor(
          of: find.text('Live sheet'),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(
        t.widget<MacosSheet>(find.byType(MacosSheet)).backgroundColor,
        const Color(0xFF123456),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
    },
  );

  for (final sheet in [false, true]) {
    testWidgets(
      'modal sheet=$sheet traps focus, Escape cancels and restores trigger',
      (t) async {
        late FocusNode trigger;
        final semantics = t.ensureSemantics();
        await t.pumpWidget(
          host(
            Builder(
              builder: (context) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MacosIconButton(
                      semanticLabel: 'Open modal',
                      icon: const MacosIcon(CupertinoIcons.add),
                      onPressed: () {
                        if (sheet) {
                          showMacosSheet<void>(
                            context: context,
                            builder: (ctx) => MacosSheet(child: alert(ctx)),
                          );
                        } else {
                          showMacosAlertDialog<void>(
                            context: context,
                            builder: alert,
                          );
                        }
                      },
                    ),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {},
                      child: const Text('Background'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        trigger = t
            .widget<Focus>(
              find
                  .descendant(
                    of: find.byType(MacosIconButton),
                    matching: find.byType(Focus),
                  )
                  .first,
            )
            .focusNode!;
        trigger.requestFocus();
        await t.pump();
        await t.sendKeyEvent(LogicalKeyboardKey.enter);
        await t.pumpAndSettle();
        expect(find.text('Confirm change'), findsOneWidget);
        await t.tapAt(const Offset(2, 2));
        await t.pumpAndSettle();
        expect(
          find.text('Confirm change'),
          findsOneWidget,
        ); // non-dismissible barrier
        for (var i = 0; i < 5; i++) {
          await t.sendKeyEvent(LogicalKeyboardKey.tab);
          await t.pumpAndSettle();
          expect(trigger.hasFocus, isFalse);
          final focused = FocusManager.instance.primaryFocus!.context!;
          expect(
            focused.findAncestorWidgetOfExactType<MacosAlertDialog>(),
            isNotNull,
          );
        }
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pump();
        expect(find.text('Confirm change').hitTestable(), findsNothing);
        await t.pumpAndSettle();
        expect(find.text('Confirm change'), findsNothing);
        expect(trigger.hasFocus, isTrue);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'explicit barrier colour, programmatic result and dismissible sheet',
    (t) async {
      String? result;
      await t.pumpWidget(
        host(
          Builder(
            builder: (context) => Center(
              child: PushButton(
                controlSize: ControlSize.large,
                child: const Text('Open'),
                onPressed: () async {
                  result = await showMacosAlertDialog<String>(
                    context: context,
                    barrierColor: const Color(0x12345678),
                    builder: alert,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      expect(
        t.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
        const Color(0x12345678),
      );
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(result, 'saved');
      final context = t.element(find.text('Open'));
      final resultFuture = showMacosSheet<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const MacosSheet(
          child: SizedBox(width: 120, height: 80, child: Text('Sheet content')),
        ),
      );
      await t.pumpAndSettle();
      await t.tapAt(const Offset(2, 2));
      await t.pumpAndSettle();
      await resultFuture;
      expect(find.text('Sheet content'), findsNothing);
    },
  );

  testWidgets(
    'alert and sheet bound long scaled RTL content and live motion/contrast',
    (t) async {
      t.view.physicalSize = const Size(320, 260);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final sheet in [false, true]) {
        await t.pumpWidget(
          host(
            Builder(
              builder: (context) => Center(
                child: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('Open'),
                  onPressed: () {
                    if (sheet) {
                      showMacosSheet<void>(
                        context: context,
                        builder: (_) => MacosSheet(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < 20; i++)
                                Text('Long readable document summary $i'),
                            ],
                          ),
                        ),
                      );
                    } else {
                      showMacosAlertDialog<void>(
                        context: context,
                        builder: alert,
                      );
                    }
                  },
                ),
              ),
            ),
            scale: 2,
            direction: TextDirection.rtl,
          ),
        );
        await t.tap(find.text('Open'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        // App-wide preference changes reach an already open route.
        t.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(
              disableAnimations: true,
              highContrast: true,
            );
        await t.pump();
        expect(t.takeException(), isNull);
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      }
    },
  );

  testWidgets('pulldown keys activate once, skip disabled and restore focus', (
    t,
  ) async {
    var count = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      host(
        Center(
          child: MacosPulldownButton(
            title: 'Commands',
            focusNode: focus,
            items: [
              const MacosPulldownMenuItem(
                title: Text('Disabled'),
                enabled: false,
              ),
              MacosPulldownMenuItem(
                title: const Text('Run'),
                onTap: () => count++,
              ),
              const MacosPulldownMenuDivider(),
              MacosPulldownMenuItem(
                title: const Text('Other'),
                onTap: () => count += 10,
              ),
            ],
          ),
        ),
      ),
    );
    focus.requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pumpAndSettle();
    await t.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(count, 0);
    await t.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(count, 1);
    expect(focus.hasFocus, isTrue);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.end);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pumpAndSettle();
    expect(count, 11);
  });

  testWidgets(
    'pulldown ignores secondary clicks and canceled presses, bounds long menus',
    (t) async {
      final semantics = t.ensureSemantics();
      await t.pumpWidget(
        host(
          Center(
            child: MacosPulldownButton(
              title: 'Commands',
              items: [
                for (var i = 0; i < 60; i++)
                  MacosPulldownMenuItem(
                    title: Text('Long document command $i with wrapping text'),
                    enabled: i != 0,
                  ),
              ],
            ),
          ),
          scale: 2,
          direction: TextDirection.rtl,
        ),
      );
      final position = t.getCenter(find.text('Commands'));
      final mouse = await t.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await mouse.down(position);
      await mouse.up();
      await t.pumpAndSettle();
      expect(find.textContaining('Long document command'), findsNothing);
      final press = await t.startGesture(position);
      await press.cancel();
      await t.pumpAndSettle();
      expect(find.textContaining('Long document command'), findsNothing);
      await t.tap(find.text('Commands'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final disabled = t.getSemantics(
        find.text('Long document command 0 with wrapping text'),
      );
      expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pumpAndSettle();
      expect(
        find.text('Long document command 59 with wrapping text').hitTestable(),
        findsOneWidget,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.textContaining('Long document command'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'pulldown stale anchors dismiss on scroll, hide and live appearance',
    (t) async {
      late StateSetter change;
      var hidden = false;
      var dark = false;
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final commands = [const MacosPulldownMenuItem(title: Text('Action'))];
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return MacosTheme(
                data: dark ? MacosThemeData.dark() : MacosThemeData.light(),
                child: ListView(
                  controller: scroll,
                  children: [
                    Offstage(
                      offstage: hidden,
                      child: MacosPulldownButton(
                        title: 'Commands',
                        items: commands,
                      ),
                    ),
                    const SizedBox(height: 1600),
                  ],
                ),
              );
            },
          ),
        ),
      );
      for (var mode = 0; mode < 3; mode++) {
        await t.tap(find.text('Commands'));
        await t.pumpAndSettle();
        expect(find.text('Action'), findsOneWidget);
        if (mode == 0) scroll.jumpTo(20);
        if (mode == 1) change(() => dark = true);
        if (mode == 2) change(() => hidden = true);
        await t.pumpAndSettle();
        expect(
          find.text('Action'),
          findsNothing,
          reason: 'invalidation mode $mode',
        );
        if (mode == 0) {
          scroll.jumpTo(0);
          await t.pumpAndSettle();
        }
      }
    },
  );

  testWidgets(
    'popup duplicate open, anchor removal and unrelated route safety',
    (t) async {
      final key = GlobalKey<ToolbarPopupState<void>>();
      late StateSetter change;
      var hidden = false;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return Center(
                child: Offstage(
                  offstage: hidden,
                  child: ToolbarPopup<void>(
                    key: key,
                    content: (_) =>
                        const ToolbarOverflowMenu(children: [Text('Details')]),
                    child: PushButton(
                      controlSize: ControlSize.large,
                      child: const Text('Trigger'),
                      onPressed: () => key.currentState!.openPopup(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await t.tap(find.text('Trigger'));
      key.currentState!.openPopup();
      await t.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      final context = t.element(find.text('Trigger'));
      showMacosAlertDialog<void>(context: context, builder: alert);
      await t.pumpAndSettle();
      change(() => hidden = true);
      await t.pumpAndSettle();
      expect(find.text('Details'), findsNothing);
      expect(find.text('Confirm change'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('Confirm change'), findsNothing);
    },
  );

  testWidgets(
    'tooltip partial themes, timers, Escape and stale anchors release overlays',
    (t) async {
      final semantics = t.ensureSemantics();
      final tooltip = GlobalKey();
      late StateSetter change;
      var hidden = false;
      await t.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return Center(
                child: Offstage(
                  offstage: hidden,
                  child: MacosTooltipTheme(
                    data: const MacosTooltipThemeData(
                      waitDuration: Duration(milliseconds: 20),
                    ),
                    child: MacosTooltip(
                      key: tooltip,
                      message: 'Tooltip detail',
                      excludeFromSemantics: true,
                      child: const Text('Hover here'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      // Match inherited tooltip tests' internal visibility hook without adding API.
      // ignore: avoid_dynamic_calls
      (tooltip.currentState as dynamic).ensureTooltipVisible();
      await t.pumpAndSettle();
      expect(find.text('Tooltip detail'), findsOneWidget);
      expect(find.bySemanticsLabel('Tooltip detail'), findsNothing);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(find.text('Tooltip detail'), findsNothing);
      // ignore: avoid_dynamic_calls
      (tooltip.currentState as dynamic).ensureTooltipVisible();
      await t.pumpAndSettle();
      change(() => hidden = true);
      await t.pumpAndSettle();
      expect(find.text('Tooltip detail'), findsNothing);
      change(() => hidden = false);
      await t.pump();
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(t.getCenter(find.text('Hover here')));
      await t.pump(const Duration(milliseconds: 30));
      await t.pumpAndSettle();
      expect(find.text('Tooltip detail'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      expect(t.takeException(), isNull);
      await mouse.removePointer();
      semantics.dispose();
    },
  );
}
