import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

void main() => runApp(const LocalizationExample());

/// Bounded app-owned Gregorian locale adapter; production apps supply their own
/// translations, supported locales, calendar policy and command/menu strings.
class LocalizationExample extends StatelessWidget {
  const LocalizationExample({super.key, this.locale = const Locale('de')});
  final Locale locale;

  @override
  Widget build(BuildContext context) => MacosApp(
    locale: locale,
    supportedLocales: const [Locale('de'), Locale('ar'), Locale('he')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Builder(
      builder: (context) {
        final ar = locale.languageCode == 'ar';
        final he = locale.languageCode == 'he';
        final title = ar
            ? 'المكتبة 123'
            : he
            ? 'ספרייה 123'
            : 'Dokumenteigenschaften 123';
        final previous = ar
            ? 'الشهر السابق'
            : he
            ? 'החודש הקודם'
            : 'Voriger Monat';
        final next = ar
            ? 'الشهر التالي'
            : he
            ? 'החודש הבא'
            : 'Nächster Monat';
        final reset = ar
            ? 'إعادة تعيين التاريخ'
            : he
            ? 'איפוס תאריך'
            : 'Datum zurücksetzen';
        final increase = ar
            ? 'زيادة'
            : he
            ? 'הגדלה'
            : 'Erhöhen';
        final decrease = ar
            ? 'تقليل'
            : he
            ? 'הקטנה'
            : 'Verringern';
        final months = ar
            ? const [
                'يناير',
                'فبراير',
                'مارس',
                'أبريل',
                'مايو',
                'يونيو',
                'يوليو',
                'أغسطس',
                'سبتمبر',
                'أكتوبر',
                'نوفمبر',
                'ديسمبر',
              ]
            : he
            ? const [
                'ינו׳',
                'פבר׳',
                'מרץ',
                'אפר׳',
                'מאי',
                'יוני',
                'יולי',
                'אוג׳',
                'ספט׳',
                'אוק׳',
                'נוב׳',
                'דצמ׳',
              ]
            : const [
                'Jan',
                'Feb',
                'Mär',
                'Apr',
                'Mai',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Okt',
                'Nov',
                'Dez',
              ];
        final weekdays = ar
            ? const ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س']
            : he
            ? const ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳']
            : const ['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'];
        return MacosWindow(
          disableWallpaperTinting: true,
          sidebar: Sidebar(
            minWidth: 180,
            topOffset: 0,
            builder: (_, controller) => SidebarItems(
              scrollController: controller,
              currentIndex: 0,
              onChanged: (_) {},
              items: [
                SidebarItem(
                  label: Text(title),
                  disclosureItems: [
                    SidebarItem(label: Text('$title / ABC 456')),
                  ],
                ),
              ],
            ),
          ),
          child: MacosScaffold(
            children: [
              ContentArea(
                builder: (_, controller) => ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(MacosChromeData.contentInset),
                  children: [
                    Text(title),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: MacosDatePicker(
                        initialDate: DateTime(2024, 2, 29),
                        onDateChanged: (_) {},
                        weekdayAbbreviations: weekdays,
                        monthAbbreviations: months,
                        dateFormat: ar || he ? 'DD/MM/YYYY' : 'DD.MM.YYYY',
                        // Null uses the locale's first weekday, including Saturday.
                        previousMonthLabel: previous,
                        nextMonthLabel: next,
                        resetDateLabel: reset,
                        increaseFieldLabel: increase,
                        decreaseFieldLabel: decrease,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
