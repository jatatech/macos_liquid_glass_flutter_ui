import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shell_gallery/main.dart';

void main() {
  testWidgets('glass local policy controls and modal dismissal', (
    tester,
  ) async {
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liquid Glass'));
    await tester.pumpAndSettle();
    for (final name in [
      'Test contrast: false',
      'Test reduced motion: false',
      'Test large text: false',
    ]) {
      await tester.ensureVisible(find.text(name));
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(find.text(name.replaceFirst('false', 'true')), findsOneWidget);
    }
    await tester.ensureVisible(find.text('Test dialog'));
    await tester.tap(find.text('Test dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Glass temporarily covered'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Glass temporarily covered'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Liquid Glass entry, fallback navigation, hide and restore', (
    tester,
  ) async {
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Liquid Glass'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Commands: approximation'), findsOneWidget);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Notes'), findsOneWidget);
    expect(find.textContaining('Survey record').first, findsOneWidget);
    await tester.tap(find.text('Covers'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Covers'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Selected: Autumn field notes'), findsOneWidget);
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    expect(find.byType(MacosGlassCommandSurface), findsNothing);
    await tester.tap(find.text('Show commands'));
    await tester.pumpAndSettle();
    expect(find.byType(MacosGlassCommandSurface), findsOneWidget);
    await tester.tap(find.text('Compare opaque'));
    await tester.pumpAndSettle();
    expect(find.text('Use automatic glass'), findsOneWidget);
    tester.view.physicalSize = const Size(480, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('document workflow reviews, inspects and archives', (t) async {
    await t.pumpWidget(const ShellGallery());
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Menus and dialogs'));
    await t.tap(find.text('Menus and dialogs'));
    await t.pumpAndSettle();
    await t.tap(find.text('Document actions'));
    await t.pumpAndSettle();
    await t.tap(find.text('Review changes…'));
    await t.pumpAndSettle();
    expect(find.text('Review design brief'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(find.text('Document status: Draft'), findsOneWidget);
    await t.tap(find.text('Document actions'));
    await t.pumpAndSettle();
    await t.tap(find.text('Review changes…'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mark ready'));
    await t.pumpAndSettle();
    expect(find.text('Document status: Ready for review'), findsOneWidget);
    await t.tap(find.text('Document details'));
    await t.pumpAndSettle();
    expect(find.textContaining('Working copy · edited today'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    await t.tap(find.text('Document actions'));
    await t.pumpAndSettle();
    await t.tap(find.text('Archive document…'));
    await t.pumpAndSettle();
    await t.tap(find.text('Archive'));
    await t.pumpAndSettle();
    expect(find.text('Document status: Archived'), findsOneWidget);
    t.view.physicalSize = const Size(480, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    t.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Document actions'));
    await t.pumpAndSettle();
    await t.tap(find.text('Document actions'));
    await t.pumpAndSettle();
    await t.tap(find.text('Review changes…'));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
  });

  testWidgets('document browser navigates, scrolls, retains tabs and scales', (
    tester,
  ) async {
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();
    final first = find.text('Design brief 1');
    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(
      find.text('Design brief 1 — Working copy · ready for review'),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.text('Project summary 120 — Working copy · ready for review'),
      findsOneWidget,
    );
    final workingScroll = tester.widget<ListView>(
      find.descendant(
        of: find.byKey(const ValueKey('working-documents')),
        matching: find.byType(ListView),
      ),
    );
    final offset = workingScroll.controller!.offset;
    expect(offset, greaterThan(0));
    await tester.ensureVisible(find.text('Archive'));
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design brief 1'));
    await tester.pumpAndSettle();
    expect(find.text('Design brief 1 — Archived · read only'), findsOneWidget);
    await tester.tap(find.text('Working files'));
    await tester.pumpAndSettle();
    expect(workingScroll.controller!.offset, offset);
    expect(find.text('Project summary 120').hitTestable(), findsOneWidget);
    tester.view.physicalSize = const Size(480, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('export selector gallery controls and constrained scaling', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sliders and selectors'));
    await tester.pumpAndSettle();
    expect(find.text('Export settings'), findsOneWidget);
    await tester.tap(find.byType(MacosSlider).first);
    await tester.pumpAndSettle();
    expect(find.text('Volume: 50 percent'), findsOneWidget);
    await tester.tap(find.byType(MacosPopupButton<String>));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Best quality'), findsOneWidget);
    tester.view.physicalSize = const Size(480, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shell navigates, changes appearance, and hides the sidebar with keyboard',
    (tester) async {
      await tester.pumpWidget(const ShellGallery());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore typography'));
      await tester.pumpAndSettle();
      expect(find.text('Large title'), findsOneWidget);
      final before = MacosTheme.of(
        tester.element(find.text('Large title')),
      ).brightness;
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIcon &&
              widget.icon == CupertinoIcons.circle_lefthalf_fill,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        MacosTheme.of(tester.element(find.text('Large title'))).brightness,
        isNot(before),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(find.text('Application shell'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shell reflows at 480 wide and 200 percent text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Explore typography'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Explore typography'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('first appearance change reverses a dark system appearance', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    final title = find.text('Application shell').last;
    expect(MacosTheme.of(tester.element(title)).brightness, Brightness.dark);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is MacosIcon &&
            widget.icon == CupertinoIcons.circle_lefthalf_fill,
      ),
    );
    await tester.pumpAndSettle();
    expect(MacosTheme.of(tester.element(title)).brightness, Brightness.light);
    // Advance fake time to drain the native utility's zero-delay bounds timer.
    await tester.pump(Duration.zero);
  });
  testWidgets('hierarchy and overflow commands share keyboard shortcuts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(560, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colour roles'));
    await tester.pumpAndSettle();
    expect(find.text('Document canvas'), findsOneWidget);
    final more = find.byWidgetPredicate(
      (w) => w is MacosIconButton && w.semanticLabel == 'More toolbar commands',
    );
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('Export selection'), findsOneWidget);
    await tester.tap(find.text('Show application shell'));
    await tester.pumpAndSettle();
    expect(find.text('Window, navigation and content'), findsOneWidget);
    tester.view.physicalSize = const Size(560, 640);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Typography'));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
    expect(find.text('Window, navigation and content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'button gallery actions, disclosure, disabled controls and scaled layout',
    (tester) async {
      await tester.pumpWidget(const ShellGallery());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buttons'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save regular'));
      await tester.pumpAndSettle();
      expect(find.text('Saved with regular button'), findsOneWidget);
      await tester.tap(find.text('Save unavailable'));
      expect(find.text('Saved with regular button'), findsOneWidget);
      final disclosure = find.byWidgetPredicate(
        (w) => w is MacosDisclosureButton && w.enabled,
      );
      await tester.ensureVisible(disclosure);
      await tester.tap(disclosure);
      await tester.pumpAndSettle();
      expect(
        find.text('Attachments are included when you save this document.'),
        findsOneWidget,
      );
      final help = find.byWidgetPredicate((w) => w is HelpButton && w.enabled);
      await tester.tap(help);
      await tester.pumpAndSettle();
      expect(
        find.text('Choose Add attachment to include a file.'),
        findsOneWidget,
      );
      tester.view.physicalSize = const Size(480, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save document and all attached reference material'),
        -150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('value gallery controls and narrow scaled layout', (
    tester,
  ) async {
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Value controls'));
    await tester.pumpAndSettle();
    final sync = find.byWidgetPredicate(
      (w) => w is MacosSwitch && w.size == ControlSize.mini,
    );
    await tester.tap(sync);
    await tester.pumpAndSettle();
    expect(tester.widget<MacosSwitch>(sync).value, true);
    await tester.tap(
      find.byWidgetPredicate((w) => w is MacosCheckbox && w.onChanged != null),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<MacosCheckbox>(find.byType(MacosCheckbox).first).value,
      true,
    );
    await tester.ensureVisible(find.text('Recent'));
    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();
    expect(find.text('View 2 of 3'), findsOneWidget);
    tester.view.physicalSize = const Size(480, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Shared with me'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('field gallery validates, clears and selects documents', (
    tester,
  ) async {
    await tester.pumpWidget(const ShellGallery());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text and search'));
    await tester.pumpAndSettle();
    final name = find.byType(MacosTextField).first;
    await tester.enterText(name, '');
    await tester.tap(find.text('Save name'));
    await tester.pump();
    expect(find.text('Enter a document name before saving.'), findsOneWidget);
    await tester.enterText(name, 'Annual report');
    await tester.tap(find.text('Save name'));
    await tester.pump();
    expect(find.text('Saved Annual report'), findsOneWidget);
    final search = find.byType(MacosSearchField);
    await tester.ensureVisible(search);
    await tester.enterText(
      find.descendant(of: search, matching: find.byType(EditableText)),
      'Project',
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('Opened Project brief'), findsOneWidget);
    tester.view.physicalSize = const Size(480, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.ensureVisible(search);
    expect(tester.takeException(), isNull);
  });
}
