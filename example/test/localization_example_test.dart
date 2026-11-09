import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:shell_gallery/localization_example.dart';

void main() {
  for (final language in ['de', 'ar', 'he']) {
    testWidgets(
      '$language locale adapter at narrow width and 200 percent text',
      (t) async {
        await t.binding.setSurfaceSize(const Size(480, 650));
        addTearDown(() => t.binding.setSurfaceSize(null));
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(LocalizationExample(locale: Locale(language)));
        await t.pumpAndSettle();
        final context = t.element(find.byType(MacosDatePicker));
        expect(
          Directionality.of(context),
          language == 'de' ? TextDirection.ltr : TextDirection.rtl,
        );
        final locale = MaterialLocalizations.of(context);
        final picker = t.widget<MacosDatePicker>(find.byType(MacosDatePicker));
        final first = picker.weekdayAbbreviations[locale.firstDayOfWeekIndex];
        final last =
            picker.weekdayAbbreviations[(locale.firstDayOfWeekIndex + 6) % 7];
        expect(
          t.getCenter(find.text(first)).dx,
          language == 'de'
              ? lessThan(t.getCenter(find.text(last)).dx)
              : greaterThan(t.getCenter(find.text(last)).dx),
        );
        expect(find.text('2024'), findsOneWidget);
        expect(
          find.text('${picker.monthAbbreviations[1]} 2024'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
