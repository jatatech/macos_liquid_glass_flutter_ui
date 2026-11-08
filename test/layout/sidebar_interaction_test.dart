import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets(
    'flat sidebar shows focus, activates with keys and ignores secondary click',
    (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var selection = 0;
      await tester.pumpWidget(
        MacosApp(
          home: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 230,
              child: SidebarItems(
                currentIndex: selection,
                onChanged: (value) => setState(() => selection = value),
                items: [
                  const SidebarItem(label: Text('One')),
                  SidebarItem(label: const Text('Two'), focusNode: node),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selection, 1);
      expect(node.hasFocus, isTrue);
      final focusedDecoration = tester
          .widgetList<Container>(find.byType(Container))
          .any((container) {
            final decoration = container.decoration;
            return decoration is ShapeDecoration &&
                decoration.shape.dimensions.horizontal > 0;
          });
      expect(focusedDecoration, isTrue);
      final secondary = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: 2,
      );
      await secondary.down(tester.getCenter(find.text('One')));
      await secondary.up();
      expect(selection, 1);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    },
  );
}
