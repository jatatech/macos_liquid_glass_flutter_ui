import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show DefaultMaterialLocalizations, MaterialLocalizations;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

// Isolates the week-start contract from a particular SDK translation catalogue.
class _SaturdayLocalizations extends DefaultMaterialLocalizations {
  const _SaturdayLocalizations();
  @override
  int get firstDayOfWeekIndex => 6;
}

class _Delegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const _SaturdayLocalizations());
  @override
  bool shouldReload(_Delegate old) => false;
}

void main() {
  for (final direction in TextDirection.values) {
    for (final monday in <bool?>[null, false, true]) {
      testWidgets(
        '$direction week-start $monday header/cells agree at leap boundary',
        (t) async {
          final dates = <DateTime>[];
          final semantics = t.ensureSemantics();
          Widget host(DateTime seed) => MacosApp(
            localizationsDelegates: const [_Delegate()],
            home: Directionality(
              textDirection: direction,
              child: Center(
                child: MacosDatePicker(
                  initialDate: seed,
                  onDateChanged: dates.add,
                  startWeekOnMonday: monday,
                  weekdayAbbreviations: const [
                    'S0',
                    'M1',
                    'T2',
                    'W3',
                    'T4',
                    'F5',
                    'S6',
                  ],
                  monthAbbreviations: List.generate(
                    12,
                    (i) => 'Monat ${i + 1}',
                  ),
                  dateFormat: 'DD.MM.YYYY',
                  previousMonthLabel: 'Voriger Monat',
                  nextMonthLabel: 'Nächster Monat',
                  resetDateLabel: 'Zurücksetzen',
                  increaseFieldLabel: 'Erhöhen',
                  decreaseFieldLabel: 'Verringern',
                ),
              ),
            ),
          );
          await t.pumpWidget(host(DateTime(2024, 2, 29, 23, 59)));
          await t.pumpAndSettle();
          final first = monday == null
              ? 6
              : monday
              ? 1
              : 0;
          // Feb 1 2024 is Thursday (Sunday-index 4).
          final offset = (4 - first) % 7;
          final header = find.text(
            ['S0', 'M1', 'T2', 'W3', 'T4', 'F5', 'S6'][(first + offset) % 7],
          );
          final firstDay = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'Thursday, February 1, 2024',
          );
          expect(t.getCenter(firstDay).dx, closeTo(t.getCenter(header).dx, 1));
          expect(find.text('Monat 2 2024'), findsOneWidget);
          // Explicit format is a numeric sequence, never reversed with RTL layout.
          final fields = find.byType(DatePickerFieldElement);
          expect(
            t.getTopLeft(fields.at(0)).dx,
            lessThan(t.getTopLeft(fields.at(2)).dx),
          );
          expect(t.widget<DatePickerFieldElement>(fields.at(0)).element, '29');
          expect(t.widget<DatePickerFieldElement>(fields.at(1)).element, '02');
          await t.tap(
            find.byWidgetPredicate(
              (w) =>
                  w is MacosIconButton && w.semanticLabel == 'Nächster Monat',
            ),
          );
          await t.pumpAndSettle();
          expect(dates, [DateTime(2024, 3, 1)]); // Browsing remains a callback.
          await t.pumpWidget(host(DateTime(2030, 1, 1)));
          await t.pumpAndSettle();
          expect(
            find.text('Monat 3 2024'),
            findsOneWidget,
          ); // Same state ignores new seed.
          await t.tap(
            find.byWidgetPredicate(
              (w) => w is MacosIconButton && w.semanticLabel == 'Zurücksetzen',
            ),
          );
          await t.pumpAndSettle();
          expect(dates.last, DateTime(2024, 2, 29));
          final day = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == 'Thursday, February 29, 2024',
          );
          await t.tap(day);
          await t.pumpAndSettle();
          expect(dates.last, DateTime(2024, 2, 29));
          expect(
            dates.length,
            3,
          ); // Re-select is still delivered, no deduplication.
          semantics.dispose();
        },
      );
    }
  }
  testWidgets(
    'default English/US and year browsing callbacks remain compatible',
    (t) async {
      final dates = <DateTime>[];
      await t.pumpWidget(
        MacosApp(
          home: Center(
            child: MacosDatePicker(
              initialDate: DateTime(2024, 12, 31),
              onDateChanged: dates.add,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Dec 2024'), findsOneWidget);
      final fields = t
          .widgetList<DatePickerFieldElement>(
            find.byType(DatePickerFieldElement),
          )
          .toList();
      expect(fields.map((f) => f.element), ['12', '31', '2024']);
      await t.tap(
        find.byWidgetPredicate(
          (w) => w is MacosIconButton && w.semanticLabel == 'Next month',
        ),
      );
      await t.pumpAndSettle();
      expect(dates, [DateTime(2025, 1, 1)]);
      final civil = MacosDateSelection(
        initialDate: DateTime(2024, 2, 29, 23),
        minimumDate: DateTime(2023),
        maximumDate: DateTime(2025),
        title: 'Date',
        commitLabel: 'Apply',
        cancelLabel: 'Cancel',
      );
      expect(civil.toMap()['date'], [2024, 2, 29]);
    },
  );
}
