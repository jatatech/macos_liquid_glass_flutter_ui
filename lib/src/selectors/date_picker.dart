import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';
import 'package:macos_liquid_glass_ui/src/buttons/button_interaction.dart';
import 'package:macos_liquid_glass_ui/src/selectors/picker_surface.dart';
import 'package:macos_liquid_glass_ui/src/selectors/caret_painters.dart';
import 'package:macos_liquid_glass_ui/src/selectors/keyboard_shortcut_runner.dart';

/// Defines the possibles [MacosDatePicker] styles.
enum DatePickerStyle {
  /// A text-only date picker.
  textual,

  /// A graphical-only date picker.
  graphical,

  /// A text-and-graphical date picker.
  combined,
}

/// {template onDateChanged}
/// The action to perform when a new date is selected.
/// {endtemplate}
typedef OnDateChanged = void Function(DateTime date);

/// {template macosDatePicker}
/// A [MacosDatePicker] lets the user choose a date.
///
/// There are three types of [MacosDatePicker]s:
/// * `textual`: a text-only date picker where the user must select the day,
///   month, or year and use the caret-control buttons to change the value.
///   This is useful when space in your app is constrained.
/// * `graphical`: a visual date picker where the user can navigate through a
///   calendar-like interface to select a date.
/// * `combined`: provides both `textual` and `graphical` interfaces.
///
/// The [onDateChanged] callback passes through the user's selected date, and
/// must be provided.
/// {endtemplate}
class MacosDatePicker extends StatefulWidget {
  /// {macro macosDatePicker}
  const MacosDatePicker({
    super.key,
    this.style = DatePickerStyle.combined,
    required this.onDateChanged,
    this.initialDate,
    this.enabled = true,
    // Use this to get the weekday abbreviations instead of
    // localizations.narrowWeekdays() in order to match Apple's spec
    this.weekdayAbbreviations = const [
      'Su',
      'Mo',
      'Tu',
      'We',
      'Th',
      'Fr',
      'Sa',
    ],
    this.monthAbbreviations = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
    this.dateFormat,
    this.startWeekOnMonday,
    this.previousMonthLabel = 'Previous month',
    this.nextMonthLabel = 'Next month',
    this.resetDateLabel = 'Reset date',
    this.increaseFieldLabel = 'Increase selected field',
    this.decreaseFieldLabel = 'Decrease selected field',
  });

  /// App-owned translations; defaults retain the legacy English labels.
  final String previousMonthLabel, nextMonthLabel, resetDateLabel;
  final String increaseFieldLabel, decreaseFieldLabel;

  /// Whether the picker accepts input.
  final bool enabled;

  /// The [DatePickerStyle] to use.
  ///
  /// Defaults to [DatePickerStyle.combined].
  final DatePickerStyle style;

  /// {macro onDateChanged}
  final OnDateChanged onDateChanged;

  /// Set an initial date for the picker.
  ///
  /// Defaults to `DateTime.now()`.
  final DateTime? initialDate;

  /// A list of 7 strings, one for each day of the week, starting with Sunday.
  final List<String> weekdayAbbreviations;

  /// A list of 12 strings, one for each month of the year, starting with January.
  final List<String> monthAbbreviations;

  /// Changes the way dates are displayed in the textual interface.
  ///
  /// The following tokens are supported (case-insensitive):
  /// * `D`: day of the month (1-31)
  /// * `DD`: day of the month (01-31)
  /// * `M`: month of the year (1-12)
  /// * `MM`: month of the year (01-12)
  /// * `YYYY`: year (0000-9999)
  /// * Any separator between tokens is preserved (e.g. `/`, `-`, `.`)
  ///
  /// Defaults to `M/D/YYYY`.
  final String? dateFormat;

  /// Allows for changing the order of day headers in the graphical Date Picker
  /// to Mo, Tu, We, Th, Fr, Sa, Su.
  ///
  /// This is useful for internationalization purposes, as many countries begin their weeks on Mondays.
  ///
  /// Null follows MaterialLocalizations.firstDayOfWeekIndex; true forces Monday,
  /// false forces Sunday. The same origin drives both headers and day cells.
  final bool? startWeekOnMonday;

  @override
  State<MacosDatePicker> createState() => _MacosDatePickerState();
}

class _MacosDatePickerState extends State<MacosDatePicker> {
  final _today = DateTime.now();
  late final _initialDate = widget.initialDate ?? _today;

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;
  bool _isDaySelected = false;
  bool _isMonthSelected = false;
  bool _isYearSelected = false;
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _parseInitialDate();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Splits each part of the formatted initial date by "/" and stores the
  // results
  void _parseInitialDate() {
    _selectedDay = _initialDate.day;
    _selectedMonth = _initialDate.month;
    _selectedYear = _initialDate.year;
  }

  // Formats the currently selected date as a DateTime object
  DateTime _formatAsDateTime() {
    return DateTime(_selectedYear, _selectedMonth, _selectedDay);
  }

  // Increments the currently selected element - day, month, or year
  void _incrementElement() {
    if (!widget.enabled ||
        !(_isDaySelected || _isMonthSelected || _isYearSelected)) {
      return;
    }
    if (_isDaySelected) {
      int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay + 1 <= daysInMonth) {
        setState(() => _selectedDay = (_selectedDay + 1));
      } else {
        setState(() => _selectedDay = 1);
      }
    }
    if (_isMonthSelected) {
      if (_selectedMonth + 1 <= 12) {
        setState(() => _selectedMonth++);
      } else {
        setState(() => _selectedMonth = 1);
      }
    }
    if (_isYearSelected) {
      setState(() => _selectedYear++);
    }
    _selectedDay = _selectedDay.clamp(
      1,
      DateUtils.getDaysInMonth(_selectedYear, _selectedMonth),
    );
    widget.onDateChanged.call(_formatAsDateTime());
  }

  // Decrements the currently selected element - day, month, or year
  void _decrementElement() {
    if (!widget.enabled ||
        !(_isDaySelected || _isMonthSelected || _isYearSelected)) {
      return;
    }
    if (_isDaySelected) {
      int daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay - 1 >= 1) {
        setState(() => _selectedDay = (_selectedDay - 1));
      } else {
        setState(() => _selectedDay = daysInMonth);
      }
    }
    if (_isMonthSelected) {
      if (_selectedMonth - 1 >= 1) {
        setState(() => _selectedMonth--);
      } else {
        setState(() => _selectedMonth = 12);
      }
    }
    if (_isYearSelected) {
      setState(() => _selectedYear = math.max(1, _selectedYear - 1));
    }
    _selectedDay = _selectedDay.clamp(
      1,
      DateUtils.getDaysInMonth(_selectedYear, _selectedMonth),
    );
    widget.onDateChanged.call(_formatAsDateTime());
  }

  int _firstWeekday(MaterialLocalizations localizations) =>
      widget.startWeekOnMonday == null
      ? localizations.firstDayOfWeekIndex
      : widget.startWeekOnMonday!
      ? 1
      : 0;

  // Creates the day headers - Su, Mo, Tu, We, Th, Fr, Sa
  // or Mo, Tu, We, Th, Fr, Sa, Su depending on the value of [startWeekOnMonday]
  List<Widget> _dayHeaders(
    TextStyle? headerStyle,
    MaterialLocalizations localizations,
  ) {
    final result = <Widget>[];

    final firstDayOfWeekIndex = _firstWeekday(localizations);

    for (int i = firstDayOfWeekIndex; result.length < 7; i = (i + 1) % 7) {
      final weekday = widget.weekdayAbbreviations[i];
      result.add(
        ExcludeSemantics(
          child: Center(child: Text(weekday, style: headerStyle)),
        ),
      );
    }
    return result;
  }

  // Creates textual date presentation based on "dateFormat" property
  List<Widget> _textualDateElements() {
    final validFormat = RegExp(
      r'^(d{1,2}|m{1,2}|y{1,4})[^dmy]+(d{1,2}|m{1,2}|y{1,4})[^dmy]+(d{1,2}|m{1,2}|y{1,4})$',
      caseSensitive: false,
    ).hasMatch(widget.dateFormat ?? '');
    final separator = validFormat
        ? widget.dateFormat!.toLowerCase().replaceAll(RegExp(r'[dmy]'), '')[0]
        : '/';

    final List<String> dateElements = validFormat
        ? widget.dateFormat!.toLowerCase().split(RegExp(r'[^dmy]'))
        : ['m', 'd', 'y'];

    final List<Widget> dateFields = <Widget>[];
    for (var dateElement in dateElements) {
      if (dateElement.startsWith('d')) {
        String value = dateElement == 'dd' && _selectedDay < 10
            // Add a leading zero
            ? '0$_selectedDay'
            : '$_selectedDay';

        dateFields.add(
          DatePickerFieldElement(
            isSelected: _isDaySelected,
            element: value,
            onSelected: () {
              setState(() {
                _isDaySelected = true;
                _isMonthSelected = false;
                _isYearSelected = false;
              });
            },
          ),
        );
      } else if (dateElement.startsWith('m')) {
        String value = dateElement == 'mm' && _selectedMonth < 10
            // Add a leading zero
            ? '0$_selectedMonth'
            : '$_selectedMonth';

        dateFields.add(
          DatePickerFieldElement(
            isSelected: _isMonthSelected,
            element: value,
            onSelected: () {
              setState(() {
                _isMonthSelected = true;
                _isDaySelected = false;
                _isYearSelected = false;
              });
            },
          ),
        );
      } else if (dateElement.startsWith('y')) {
        dateFields.add(
          DatePickerFieldElement(
            isSelected: _isYearSelected,
            element: '$_selectedYear',
            onSelected: () {
              setState(() {
                _isYearSelected = true;
                _isDaySelected = false;
                _isMonthSelected = false;
              });
            },
          ),
        );
      }
      dateFields.add(Text(separator));
    }

    dateFields.removeLast();

    return dateFields;
  }

  Widget _buildTextualPicker(MacosDatePickerThemeData datePickerTheme) {
    return KeyboardShortcutRunner(
      onUpArrowKeypress: _incrementElement,
      onDownArrowKeypress: _decrementElement,
      focusNode: _focusNode,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PhysicalModel(
            color: datePickerTheme.shadowColor!,
            elevation: 1,
            child: ColoredBox(
              color: datePickerTheme.backgroundColor!,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  // Numeric date formats retain their explicit token order in RTL.
                  textDirection: TextDirection.ltr,
                  children: _textualDateElements(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4.0),
          Column(
            children: [
              SizedBox(
                height: 14.0 * MediaQuery.textScalerOf(context).scale(1),
                width: 18.0,
                child: IgnorePointer(
                  ignoring:
                      !_isMonthSelected && !_isDaySelected && !_isYearSelected,
                  child: ButtonInteraction(
                    label: widget.increaseFieldLabel,
                    onPressed: _incrementElement,
                    onHeldChanged: (_) {},
                    builder: (context, states) => PickerControlSurface(
                      states: states,
                      child: PhysicalModel(
                        color: datePickerTheme.shadowColor!,
                        elevation: 1,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5.0),
                        ),
                        child: CustomPaint(
                          painter: UpCaretPainter(
                            color: datePickerTheme.caretColor!,
                            backgroundColor:
                                datePickerTheme.caretControlsBackgroundColor!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 1.0,
                child: ColoredBox(
                  color: datePickerTheme.caretControlsSeparatorColor!,
                ),
              ),
              SizedBox(
                height: 14.0 * MediaQuery.textScalerOf(context).scale(1),
                width: 18.0,
                child: IgnorePointer(
                  ignoring:
                      !_isMonthSelected && !_isDaySelected && !_isYearSelected,
                  child: ButtonInteraction(
                    label: widget.decreaseFieldLabel,
                    onPressed: _decrementElement,
                    onHeldChanged: (_) {},
                    builder: (context, states) => PickerControlSurface(
                      states: states,
                      child: PhysicalModel(
                        color: datePickerTheme.shadowColor!,
                        elevation: 1,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(5.0),
                        ),
                        child: CustomPaint(
                          painter: DownCaretPainter(
                            color: datePickerTheme.caretColor!,
                            backgroundColor:
                                datePickerTheme.caretControlsBackgroundColor!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphicalPicker(
    MacosDatePickerThemeData datePickerTheme,
    List<Widget> dayHeaders,
    List<Widget> dayItems,
  ) {
    return PhysicalModel(
      color: datePickerTheme.shadowColor!,
      child: SizedBox(
        width: 180.0 * MediaQuery.textScalerOf(context).scale(1),
        child: ColoredBox(
          color: datePickerTheme.backgroundColor!,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 2.0,
                  top: 2.0,
                  bottom: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.monthAbbreviations[_selectedMonth - 1]} $_selectedYear',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.08,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MacosIconButton(
                          semanticLabel: widget.previousMonthLabel,
                          icon: MacosIcon(
                            Directionality.of(context) == TextDirection.rtl
                                ? CupertinoIcons.arrowtriangle_right_fill
                                : CupertinoIcons.arrowtriangle_left_fill,
                            size: 10.0,
                            color: datePickerTheme.monthViewControlsColor,
                          ),
                          backgroundColor: MacosColors.transparent,
                          borderRadius: BorderRadius.zero,
                          padding: EdgeInsets.zero,
                          boxConstraints: const BoxConstraints(maxWidth: 12.0),
                          onPressed: () {
                            if (_selectedMonth - 1 < 1) {
                              setState(() {
                                _selectedYear--;
                                _selectedMonth = 12;
                                _selectedDay = 1;
                              });
                            } else {
                              setState(() {
                                _selectedMonth--;
                                _selectedDay = 1;
                              });
                            }
                            _selectedDay = _selectedDay.clamp(
                              1,
                              DateUtils.getDaysInMonth(
                                _selectedYear,
                                _selectedMonth,
                              ),
                            );
                            widget.onDateChanged.call(_formatAsDateTime());
                          },
                        ),
                        const SizedBox(width: 6.0),
                        MacosIconButton(
                          semanticLabel: widget.resetDateLabel,
                          icon: MacosIcon(
                            CupertinoIcons.circle_fill,
                            size: 8.0,
                            color: datePickerTheme.monthViewControlsColor,
                          ),
                          backgroundColor: MacosColors.transparent,
                          borderRadius: BorderRadius.zero,
                          padding: EdgeInsets.zero,
                          boxConstraints: const BoxConstraints(maxWidth: 12.0),
                          onPressed: () {
                            setState(() => _parseInitialDate());
                            _selectedDay = _selectedDay.clamp(
                              1,
                              DateUtils.getDaysInMonth(
                                _selectedYear,
                                _selectedMonth,
                              ),
                            );
                            widget.onDateChanged.call(_formatAsDateTime());
                          },
                        ),
                        const SizedBox(width: 6.0),
                        MacosIconButton(
                          semanticLabel: widget.nextMonthLabel,
                          icon: MacosIcon(
                            Directionality.of(context) == TextDirection.rtl
                                ? CupertinoIcons.arrowtriangle_left_fill
                                : CupertinoIcons.arrowtriangle_right_fill,
                            size: 10.0,
                            color: datePickerTheme.monthViewControlsColor,
                          ),
                          backgroundColor: MacosColors.transparent,
                          borderRadius: BorderRadius.zero,
                          padding: EdgeInsets.zero,
                          boxConstraints: const BoxConstraints(maxWidth: 12.0),
                          onPressed: () {
                            if (_selectedMonth + 1 > 12) {
                              setState(() {
                                _selectedYear++;
                                _selectedMonth = 1;
                                _selectedDay = 1;
                              });
                            } else {
                              setState(() {
                                _selectedMonth++;
                                _selectedDay = 1;
                              });
                            }

                            _selectedDay = _selectedDay.clamp(
                              1,
                              DateUtils.getDaysInMonth(
                                _selectedYear,
                                _selectedMonth,
                              ),
                            );
                            widget.onDateChanged.call(_formatAsDateTime());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6.0, right: 5.0),
                child: Column(
                  children: [
                    GridView.custom(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      gridDelegate: _DayPickerGridDelegate(
                        MediaQuery.textScalerOf(context).scale(1),
                      ),
                      childrenDelegate: SliverChildListDelegate(
                        dayHeaders,
                        addRepaintBoundaries: false,
                      ),
                    ),
                    Divider(
                      color: datePickerTheme.monthViewHeaderDividerColor,
                      height: 0,
                    ),
                    GridView.custom(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      gridDelegate: _DayPickerGridDelegate(
                        MediaQuery.textScalerOf(context).scale(1),
                      ),
                      childrenDelegate: SliverChildListDelegate(
                        dayItems,
                        addRepaintBoundaries: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PickerSurface(
    enabled: widget.enabled,
    child: Builder(builder: _buildPicker),
  );

  Widget _buildPicker(BuildContext context) {
    final datePickerTheme = MacosDatePickerTheme.of(context);
    const dayStyle = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 10.0,
      letterSpacing: 0.12,
    );
    final localizations = MaterialLocalizations.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final dayHeaders = _dayHeaders(
      MacosTheme.of(context).typography.caption1.copyWith(
        color: datePickerTheme.monthViewWeekdayHeaderColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.12,
      ),
      localizations,
    );

    final firstWeekday = DateTime(_selectedYear, _selectedMonth).weekday % 7;
    final fixedDayOffset = (firstWeekday - _firstWeekday(localizations)) % 7;

    // 1-based day of month, e.g. 1-31 for January, and 1-29 for February on
    // a leap year.
    int day = -fixedDayOffset;

    final dayItems = <Widget>[];

    while (day < daysInMonth) {
      day++;
      if (day < 1) {
        dayItems.add(const SizedBox.shrink());
      } else {
        final dayToBuild = DateTime(_selectedYear, _selectedMonth, day);

        final isSelectedDay = DateUtils.isSameDay(
          DateTime(_selectedYear, _selectedMonth, _selectedDay),
          dayToBuild,
        );
        final isToday = DateUtils.isSameDay(_today, dayToBuild);

        BoxDecoration? decoration;
        Widget? dayText;

        if (isToday && isSelectedDay) {
          dayText = Text(
            localizations.formatDecimal(day),
            style: dayStyle.apply(
              color: textLuminance(datePickerTheme.monthViewCurrentDateColor!),
            ),
          );
          decoration = BoxDecoration(
            color: datePickerTheme.monthViewCurrentDateColor,
            borderRadius: const BorderRadius.all(Radius.circular(3.0)),
          );
        } else if (isToday) {
          dayText = Text(
            localizations.formatDecimal(day),
            style: dayStyle.apply(
              color: datePickerTheme.monthViewCurrentDateColor,
            ),
          );
        } else if (isSelectedDay) {
          dayText = Text(
            localizations.formatDecimal(day),
            style: dayStyle.copyWith(
              color: datePickerTheme.monthViewSelectedDateTextColor,
            ),
          );
          decoration = BoxDecoration(
            color: datePickerTheme.monthViewSelectedDateColor,
            borderRadius: const BorderRadius.all(Radius.circular(3.0)),
          );
        }

        Widget dayWidget = ButtonInteraction(
          label: localizations.formatFullDate(dayToBuild),
          selected: isSelectedDay,
          onHeldChanged: (_) {},
          onPressed: () {
            setState(() {
              _isDaySelected = true;
              _selectedDay = dayToBuild.day;
            });
            _selectedDay = _selectedDay.clamp(
              1,
              DateUtils.getDaysInMonth(_selectedYear, _selectedMonth),
            );
            widget.onDateChanged.call(_formatAsDateTime());
          },
          builder: (context, states) => PickerControlSurface(
            states: states,
            child: Container(
              decoration: decoration,
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 2.0),
                  child:
                      dayText ??
                      Text(
                        localizations.formatDecimal(dayToBuild.day),
                        style: dayStyle,
                      ),
                ),
              ),
            ),
          ),
        );

        dayItems.add(dayWidget);
      }
    }

    switch (widget.style) {
      case DatePickerStyle.textual:
        return _buildTextualPicker(datePickerTheme);
      case DatePickerStyle.graphical:
        return _buildGraphicalPicker(datePickerTheme, dayHeaders, dayItems);
      case DatePickerStyle.combined:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextualPicker(datePickerTheme),
            const SizedBox(height: 16),
            _buildGraphicalPicker(datePickerTheme, dayHeaders, dayItems),
          ],
        );
    }
  }
}

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate(this.scale);
  final double scale;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = 24.0 * scale;
    return SliverGridRegularTileLayout(
      childCrossAxisExtent: tileWidth,
      childMainAxisExtent: tileHeight,
      crossAxisCount: columnCount,
      crossAxisStride: tileWidth,
      mainAxisStride: tileHeight,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) =>
      oldDelegate.scale != scale;
}

class DatePickerFieldElement extends StatelessWidget {
  const DatePickerFieldElement({
    super.key,
    required this.element,
    required this.onSelected,
    required this.isSelected,
  });

  final String element;
  final VoidCallback onSelected;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final datePickerTheme = MacosDatePickerTheme.of(context);
    Color backgroundColor = isSelected
        ? datePickerTheme.selectedElementColor!
        : MacosColors.transparent;
    Color textColor = isSelected
        ? datePickerTheme.selectedElementTextColor!
        : MacosTheme.of(context).typography.body.color!;
    return PickerField(
      element: element,
      selected: isSelected,
      onSelected: onSelected,
      background: backgroundColor,
      foreground: textColor,
    );
  }
}
