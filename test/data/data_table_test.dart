import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

const columns = [
  MacosTableColumn(label: 'Title', width: 220, sortable: true),
  MacosTableColumn(label: 'Modified', width: 160, sortable: true),
];
List<MacosTableRow> rows([int count = 100]) => List.generate(
  count,
  (i) => MacosTableRow(
    id: 'id-$i',
    cells: ['Document $i', 'Nov ${i + 1}'],
    enabled: i != 1,
  ),
);

Widget host(
  Widget child, {
  bool dark = false,
  bool contrast = false,
  bool motion = false,
  double scale = 1,
  bool rtl = false,
}) => MacosApp(
  theme: MacosThemeData.light(),
  darkTheme: MacosThemeData.dark(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(scale),
      highContrast: contrast,
      disableAnimations: motion,
    ),
    child: Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Center(child: SizedBox(width: 340, height: 220, child: child)),
    ),
  ),
);

void main() {
  testWidgets(
    'controlled proposals, secondary click and pointer cancellation',
    (t) async {
      final proposals = <Object>[];
      final secondary = <Object>[];
      await t.pumpWidget(
        host(
          MacosDataTable(
            columns: columns,
            rows: rows(),
            onSelectionChanged: proposals.add,
            onSecondaryTap: (id, _) => secondary.add(id),
          ),
        ),
      );
      await t.tap(find.text('Document 0'));
      await t.pump();
      expect(proposals, ['id-0']);
      expect(
        t.widget<MacosDataTable>(find.byType(MacosDataTable)).selectedId,
        isNull,
      );
      await t.tap(find.text('Document 2'), buttons: kSecondaryMouseButton);
      await t.pump();
      expect(secondary, ['id-2']);
      expect(proposals, ['id-0']);
      await t.tap(find.text('Document 1'));
      final gesture = await t.startGesture(
        t.getCenter(find.text('Document 2')),
      );
      await gesture.cancel();
      await t.pump();
      expect(proposals, ['id-0']);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('keyboard skips disabled, pages and reveals selected identity', (
    t,
  ) async {
    Object? selected;
    final activated = <Object>[];
    late StateSetter update;
    await t.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MacosDataTable(
              columns: columns,
              rows: rows(),
              selectedId: selected,
              onSelectionChanged: (id) => update(() => selected = id),
              onActivate: activated.add,
            );
          },
        ),
      ),
    );
    await t.tap(find.text('Document 0'));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pump();
    expect(selected, 'id-2');
    await t.sendKeyEvent(LogicalKeyboardKey.end);
    await t.pumpAndSettle();
    expect(selected, 'id-99');
    expect(find.text('Document 99').hitTestable(), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, ['id-99']);
    await t.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await t.pumpAndSettle();
    expect(selected, 'id-95');
    await t.sendKeyEvent(LogicalKeyboardKey.home);
    await t.pumpAndSettle();
    expect(selected, 'id-0');
    expect(find.text('Document 0').hitTestable(), findsOneWidget);
    update(() => selected = 'id-70');
    await t.pumpAndSettle();
    expect(find.text('Document 70').hitTestable(), findsOneWidget);
  });

  testWidgets('sort is controlled; reorder, removal, empty and disposal', (
    t,
  ) async {
    var data = rows();
    Object? selected = 'id-2';
    int? sorted;
    bool ascending = true;
    final sorts = <String>[];
    late StateSetter update;
    await t.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MacosDataTable(
              columns: columns,
              rows: data,
              selectedId: selected,
              sortColumnIndex: sorted,
              sortAscending: ascending,
              onSort: (column, up) {
                sorts.add('$column:$up');
                update(() {
                  sorted = column;
                  ascending = up;
                  data = data.reversed.toList();
                });
              },
              onSelectionChanged: (id) => update(() => selected = id),
              empty: const Text('Add a document'),
            );
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Title'));
    await t.pumpAndSettle();
    expect(sorts, ['0:true']);
    expect(selected, 'id-2');
    expect(find.text('Document 2').hitTestable(), findsOneWidget);
    await t.tap(find.text('Title ↑'));
    await t.pumpAndSettle();
    expect(sorts.last, '0:false');
    update(() => data = data.where((r) => r.id != selected).toList());
    await t.pumpAndSettle();
    expect(find.text('Document 2'), findsNothing);
    // No unsolicited selection callback when the owner removes its selected ID.
    expect(selected, 'id-2');
    await t.tap(find.text('Document 3'));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.pumpAndSettle();
    expect(selected, 'id-0');
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pump();
    expect(selected, 'id-3');
    update(() => data = []);
    await t.pumpAndSettle();
    expect(find.text('Add a document'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.end);
    await t.pump();
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'column widths shrink again when only layout constraints change',
    (t) async {
      var width = 700.0;
      late StateSetter update;
      final table = MacosDataTable(
        columns: columns,
        rows: rows(),
        onSelectionChanged: (_) {},
      );
      await t.pumpWidget(
        MacosApp(
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SizedBox(width: width, height: 220, child: table);
              },
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final scroll = t
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      expect(scroll.position.maxScrollExtent, 0);
      update(() => width = 340);
      await t.pumpAndSettle();
      expect(scroll.position.maxScrollExtent, 40);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('header and row semantics include full labelled data and state', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(
      host(
        MacosDataTable(
          columns: columns,
          rows: rows(),
          selectedId: 'id-0',
          sortColumnIndex: 0,
          onSelectionChanged: (_) {},
          onSort: (_, _) {},
        ),
      ),
    );
    expect(
      t.getSemantics(find.bySemanticsLabel('Title, ascending')),
      matchesSemantics(
        label: 'Title, ascending',
        isButton: true,
        isHeader: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    final first = find.bySemanticsLabel('Title: Document 0, Modified: Nov 1');
    expect(
      t.getSemantics(first),
      matchesSemantics(
        label: 'Title: Document 0, Modified: Nov 1',
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    expect(
      t.getSemantics(
        find.bySemanticsLabel('Title: Document 1, Modified: Nov 2'),
      ),
      matchesSemantics(
        label: 'Title: Document 1, Modified: Nov 2',
        hasSelectedState: true,
        hasEnabledState: true,
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets(
    'live appearance, contrast, motion, RTL, scaling and owned controllers',
    (t) async {
      Widget table() => MacosDataTable(
        columns: columns,
        rows: rows(),
        selectedId: 'id-80',
        onSelectionChanged: (_) {},
      );
      await t.pumpWidget(host(table()));
      await t.pumpAndSettle();
      final list = t.widget<ListView>(find.byType(ListView));
      final vertical = list.controller!;
      final horizontal = t
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      final light = DefaultTextStyle.of(
        t.element(find.text('Document 80')),
      ).style.color;
      expect(vertical.offset, greaterThan(0));
      await t.pumpWidget(
        host(
          table(),
          dark: true,
          contrast: true,
          motion: true,
          scale: 2,
          rtl: true,
        ),
      );
      await t.pumpAndSettle();
      expect(
        t.widget<ListView>(find.byType(ListView)).controller,
        same(vertical),
      );
      expect(t.widget<ListView>(find.byType(ListView)).itemExtent, 80);
      expect(t.takeException(), isNull);
      // Selection foreground switches from white on blue to black on high contrast white.
      final textContext = t.element(find.text('Document 80'));
      expect(light, const Color(0xFFFFFFFF));
      expect(
        DefaultTextStyle.of(textContext).style.color,
        const Color(0xFF000000),
      );
      await t.drag(find.byType(SingleChildScrollView), const Offset(300, 0));
      await t.pumpAndSettle();
      expect(horizontal.offset, greaterThan(0));
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(vertical.hasClients, isFalse);
      expect(horizontal.hasClients, isFalse);
      expect(() => vertical.addListener(() {}), throwsFlutterError);
      expect(t.takeException(), isNull);
    },
  );
}
