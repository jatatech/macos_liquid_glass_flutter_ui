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
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => MacosApp(
  theme: dark ? MacosThemeData.dark() : MacosThemeData.light(),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        highContrast: contrast,
        disableAnimations: motion,
        textScaler: TextScaler.linear(scale),
      ),
      child: Directionality(
        textDirection: direction,
        child: Center(child: SizedBox(width: 320, height: 360, child: child)),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'tiles activate once by keyboard, cancel pointers and ignore secondary click',
    (t) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var clicks = 0;
      var longPresses = 0;
      Widget tile({bool enabled = true}) => host(
        MacosListTile(
          title: const Text('Brief'),
          subtitle: const Text('Ready'),
          focusNode: focus,
          selected: true,
          enabled: enabled,
          onClick: () => clicks++,
          onLongPress: () => longPresses++,
        ),
      );
      final semantics = t.ensureSemantics();

      await t.pumpWidget(tile());
      focus.requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      expect(clicks, 2);
      final position = t.getCenter(find.byType(MacosListTile));
      await t.tapAt(position, buttons: kSecondaryMouseButton);
      expect(clicks, 2);
      final gesture = await t.startGesture(position);
      await t.pump(const Duration(milliseconds: 100));
      await gesture.cancel();
      expect(clicks, 2);
      await t.longPress(find.byType(MacosListTile));
      expect(longPresses, 1);
      expect(clicks, 2);
      expect(
        t.getSemantics(find.byType(MacosListTile)),
        matchesSemantics(
          label: 'Brief\nReady',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          isFocused: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
          hasLongPressAction: true,
        ),
      );
      await t.pumpWidget(tile(enabled: false));
      await t.pump();
      expect(focus.hasFocus, isFalse);
      await t.tap(find.byType(MacosListTile));
      expect(clicks, 2);
      semantics.dispose();
    },
  );

  testWidgets('long-press-only and static tiles retain distinct contracts', (
    t,
  ) async {
    var calls = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      host(
        MacosListTile(
          title: const Text('Details'),
          focusNode: focus,
          onLongPress: () => calls++,
        ),
      ),
    );
    await t.tap(find.text('Details'));
    expect(calls, 0);
    focus.requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, 1);
    await t.longPress(find.text('Details'));
    expect(calls, 2);
    await t.pumpWidget(
      host(
        const MacosListTile(title: Text('Static'), selected: true),
        scale: 2,
        direction: TextDirection.rtl,
      ),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'hidden tabs release focus, input and semantics but retain editing state',
    (t) async {
      final controller = MacosTabController(length: 2);
      final focus = FocusNode();
      final edit = TextEditingController();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      addTearDown(edit.dispose);
      await t.pumpWidget(
        host(
          MacosTabView(
            controller: controller,
            tabs: const [
              MacosTab(label: 'Files'),
              MacosTab(label: 'History'),
            ],
            children: [
              MacosTextField(
                focusNode: focus,
                controller: edit,
                placeholder: 'Name',
              ),
              const Text('Visible history'),
            ],
          ),
        ),
      );
      await t.enterText(find.byType(MacosTextField), 'Retained draft');
      expect(focus.hasFocus, isTrue);
      controller.index = 1;
      await t.pump();
      await t.pump();
      expect(focus.hasFocus, isFalse);
      focus.requestFocus();
      await t.pump();
      expect(focus.hasFocus, isFalse);
      final semantics = t.ensureSemantics();

      expect(find.bySemanticsLabel('Retained draft'), findsNothing);
      controller.index = 0;
      await t.pump();
      expect(edit.text, 'Retained draft');
      expect(focus.hasFocus, isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'tab controller replacement detaches all old listeners and disposes safely',
    (t) async {
      final old = _TrackingController(length: 2);
      final current = _TrackingController(length: 2, initialIndex: 1);
      Widget view(MacosTabController controller, bool dark) => host(
        MacosTabView(
          controller: controller,
          tabs: const [
            MacosTab(label: 'One'),
            MacosTab(label: 'Two'),
          ],
          children: const [Text('First page'), Text('Second page')],
        ),
        dark: dark,
      );
      await t.pumpWidget(view(old, false));
      await t.pumpWidget(view(old, true));
      await t.pumpWidget(view(current, true));
      expect(old.listeners, 0);
      old.index = 1;
      await t.pump();
      expect(current.index, 1);
      await t.pumpWidget(const SizedBox());
      expect(current.listeners, 0);
      old.index = 0;
      expect(t.takeException(), isNull);
      old.dispose();
      current.dispose();
    },
  );

  testWidgets(
    'scaled RTL tab strips scroll keyboard destinations into view at every position',
    (t) async {
      for (final position in MacosTabPosition.values) {
        final controller = MacosTabController(length: 8);
        await t.pumpWidget(
          host(
            MacosTabView(
              controller: controller,
              position: position,
              tabs: List.generate(8, (i) => MacosTab(label: 'Document $i')),
              children: List.generate(8, (i) => Text('Page $i')),
            ),
            scale: 2,
            direction: TextDirection.rtl,
            contrast: true,
            motion: true,
          ),
        );
        await t.tap(find.text('Document 0'));
        await t.sendKeyEvent(LogicalKeyboardKey.end);
        await t.pumpAndSettle();
        expect(controller.index, 7);
        expect(find.text('Document 7').hitTestable(), findsOneWidget);
        await t.sendKeyEvent(
          position == MacosTabPosition.left
              ? LogicalKeyboardKey.arrowUp
              : position == MacosTabPosition.right
              ? LogicalKeyboardKey.arrowDown
              : LogicalKeyboardKey.arrowRight,
        );
        await t.pumpAndSettle();
        expect(controller.index, 6);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        controller.dispose();
      }
    },
  );

  testWidgets('empty tab view is valid', (t) async {
    final controller = MacosTabController(length: 0);
    await t.pumpWidget(
      host(
        MacosTabView(
          controller: controller,
          tabs: const [],
          children: const [],
        ),
      ),
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
    'scrollbar controller replacement, drag, keyboard and shrinking content stay coherent',
    (t) async {
      final first = ScrollController();
      final second = ScrollController();
      final focus = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(focus.dispose);
      Widget view(
        ScrollController controller,
        int count, {
        bool contrast = false,
        bool motion = false,
      }) => host(
        ScrollConfiguration(
          behavior: const MacosScrollBehavior().copyWith(scrollbars: false),
          child: MacosScrollbar(
            controller: controller,
            thumbVisibility: true,
            child: ListView.builder(
              controller: controller,
              itemExtent: 40,
              itemCount: count,
              itemBuilder: (_, i) => i == 0
                  ? Focus(focusNode: focus, child: Text('Row $i'))
                  : Text('Row $i'),
            ),
          ),
        ),
        contrast: contrast,
        motion: motion,
      );
      await t.pumpWidget(view(first, 100));
      await t.pumpAndSettle();
      focus.requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await t.pumpAndSettle();
      expect(first.offset, greaterThan(0));
      await t.pumpWidget(view(second, 100, contrast: true, motion: true));
      await t.pumpAndSettle();
      expect(first.hasClients, isFalse);
      final rect = t.getRect(find.byType(ListView));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset(rect.right - 4, rect.top + 15));
      await mouse.moveTo(Offset(rect.right - 4, rect.top + 15));
      await t.pumpAndSettle();
      await mouse.down(Offset(rect.right - 4, rect.top + 15));
      await mouse.moveBy(const Offset(0, 130));
      await mouse.up();
      await t.pumpAndSettle();
      expect(second.offset, greaterThan(0));
      await mouse.removePointer();
      await t.pumpWidget(view(second, 2));
      await t.pumpAndSettle();
      expect(second.offset, 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'hovering scrollbar updates live theme, contrast and reduced motion',
    (t) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      Widget view(Color color, bool contrast, bool motion) => host(
        MacosScrollbarTheme(
          data: MacosScrollbarThemeData(
            thumbColor: color,
            thicknessWhileHovering: 14,
          ),
          child: ScrollConfiguration(
            behavior: const MacosScrollBehavior().copyWith(scrollbars: false),
            child: MacosScrollbar(
              controller: controller,
              thumbVisibility: true,
              child: ListView(
                controller: controller,
                children: const [SizedBox(height: 2000)],
              ),
            ),
          ),
        ),
        contrast: contrast,
        motion: motion,
      );
      await t.pumpWidget(view(CupertinoColors.systemRed, false, false));
      await t.pumpAndSettle();
      final raw = find.byWidgetPredicate((w) => w is RawScrollbar);
      // Inspect final paint inputs to verify live changes without baseline regeneration.
      ScrollbarPainter painter() {
        // ignore: invalid_use_of_protected_member
        return t.state<RawScrollbarState>(raw).scrollbarPainter;
      }

      final rect = t.getRect(find.byType(ListView));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: rect.center);
      await mouse.moveTo(Offset(rect.right - 4, rect.top + 15));
      await t.pump();
      await t.pump(const Duration(milliseconds: 30));
      await t.pumpWidget(view(CupertinoColors.systemGreen, false, true));
      expect(painter().color, CupertinoColors.systemGreen);
      expect(
        painter().trackColor,
        CupertinoColors.systemGreen.withValues(alpha: .15),
      );
      expect(painter().thickness, 14);
      await t.pumpWidget(view(CupertinoColors.systemGreen, true, true));
      final chrome = MacosChromeData.of(t.element(find.byType(MacosScrollbar)));
      expect(painter().color, chrome.foreground);
      expect(painter().trackColor, chrome.foreground.withValues(alpha: .15));
      await mouse.moveTo(rect.center);
      await t.pump();
      expect(painter().thickness, 6);
      await mouse.removePointer();
    },
  );

  testWidgets(
    'scrollbar visibility and viewport changes preserve an attached position',
    (t) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      Widget view(bool visible, double height) => host(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: height,
            child: ScrollConfiguration(
              behavior: const MacosScrollBehavior().copyWith(scrollbars: false),
              child: MacosScrollbar(
                controller: controller,
                thumbVisibility: visible,
                child: ListView(
                  controller: controller,
                  children: const [SizedBox(height: 2000)],
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpWidget(view(true, 180));
      await t.pumpAndSettle();
      controller.jumpTo(controller.position.maxScrollExtent);
      await t.pumpAndSettle();
      expect(controller.offset, 1820);
      await t.pumpWidget(view(false, 360));
      await t.pumpAndSettle();
      expect(controller.offset, 1640);
      expect(
        t
            .widget<RawScrollbar>(
              find.byWidgetPredicate((w) => w is RawScrollbar),
            )
            .thumbVisibility,
        isFalse,
      );
      await t.pumpWidget(view(true, 360));
      await t.pumpAndSettle();
      expect(controller.positions.length, 1);
      expect(controller.offset, 1640);
      expect(t.takeException(), isNull);
    },
  );

  test('scrollbar merge preserves explicit hover thickness', () {
    expect(
      const MacosScrollbarThemeData(thicknessWhileHovering: 9)
          .merge(const MacosScrollbarThemeData(thicknessWhileHovering: 14))
          .thicknessWhileHovering,
      14,
    );
  });
}

class _TrackingController extends MacosTabController {
  _TrackingController({required super.length, super.initialIndex});
  int listeners = 0;
  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }
}
