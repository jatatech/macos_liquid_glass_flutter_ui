import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shell_gallery/dense_content.dart';

void main() {
  testWidgets(
    'document columns sort and inspect stable selection across tabs',
    (t) async {
      await t.pumpWidget(
        const MacosApp(
          home: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: DocumentBrowser(),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Design brief 1'));
      await t.pumpAndSettle();
      expect(find.text('Alex Morgan · 2026-11-01 · 120 KB'), findsOneWidget);
      await t.tap(find.text('Title'));
      await t.pumpAndSettle();
      var table = t.widget<MacosDataTable>(find.byType(MacosDataTable));
      expect(table.selectedId, 0);
      expect(table.sortColumnIndex, 0);
      expect(table.sortAscending, isTrue);
      await t.tap(find.text('Title ↑'));
      await t.pumpAndSettle();
      table = t.widget<MacosDataTable>(find.byType(MacosDataTable));
      expect(table.sortAscending, isFalse);
      expect(table.selectedId, 0);
      await t.ensureVisible(find.text('Modified'));
      await t.tap(find.text('Modified'));
      await t.pumpAndSettle();
      table = t.widget<MacosDataTable>(find.byType(MacosDataTable));
      expect(table.sortColumnIndex, 2);
      expect(table.rows.first.cells[2], '2026-11-01');
      expect(table.rows.last.cells[2], '2026-11-07');
      await t.ensureVisible(find.text('Design brief 1'));
      await t.tap(find.text('Design brief 1'), buttons: kSecondaryMouseButton);
      await t.pumpAndSettle();
      expect(
        find.text('Design brief 1 — Alex Morgan · 2026-11-01 · 120 KB'),
        findsOneWidget,
      );
      expect(
        t.widget<MacosDataTable>(find.byType(MacosDataTable)).selectedId,
        0,
      );
      await t.tap(find.text('Archive'));
      await t.pumpAndSettle();
      await t.tap(find.text('Design brief 1'));
      await t.pumpAndSettle();
      expect(
        find.text('Design brief 1 — Archived · read only'),
        findsOneWidget,
      );
      await t.tap(find.text('Working files'));
      await t.pumpAndSettle();
      table = t.widget<MacosDataTable>(find.byType(MacosDataTable));
      expect(table.selectedId, 0);
      expect(table.sortColumnIndex, 2);
      expect(t.takeException(), isNull);
    },
  );
}
