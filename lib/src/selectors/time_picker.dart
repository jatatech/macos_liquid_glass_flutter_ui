import 'dart:math' as math;
import 'package:flutter/services.dart';

import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/library.dart';
import 'package:macos_liquid_glass_ui/src/buttons/button_interaction.dart';
import 'package:macos_liquid_glass_ui/src/selectors/picker_surface.dart';
import 'package:macos_liquid_glass_ui/src/selectors/caret_painters.dart';
import 'package:macos_liquid_glass_ui/src/selectors/graphical_time_picker_painter.dart';
import 'package:macos_liquid_glass_ui/src/selectors/keyboard_shortcut_runner.dart';

/// Defines the possibles [MacosTimePicker] styles.
enum TimePickerStyle {
  /// A text-only variant of the time picker.
  textual,

  /// A graphical variant of the time picker.
  graphical,

  /// Combines both the [textual] and [graphical] styles.
  combined,
}

/// {template onTimeChanged}
/// The action to perform when a new time is selected.
/// {end-template}
typedef OnTimeChanged = void Function(TimeOfDay time);

/// {template macosTimePicker}
/// A [MacosTimePicker] lets the user choose a time.
///
/// There are three types of [MacosTimePicker]s:
/// * `textual`: a text-only time picker where the user must select the hour,
///   or minute and use the caret-control buttons to change the value.
///   This is useful when space in your app is constrained.
/// * `graphical`: a visual time picker where the user can move the hands of a
///   clock-like interface to select a time.
/// * `combined`: provides both `textual` and `graphical` interfaces.
///
/// The [onTimeChanged] callback passes through the user's selected time, and
/// must be provided.
/// {end-template}
class MacosTimePicker extends StatefulWidget {
  /// {@macro macosTimePicker}
  const MacosTimePicker({
    super.key,
    required this.onTimeChanged,
    this.initialTime,
    this.enabled = true,
    this.style = TimePickerStyle.combined,
  });

  /// Whether the picker accepts input.
  final bool enabled;

  /// Set an initial date for the picker.
  ///
  /// Defaults to `TimeOfDay.now()`.
  final TimeOfDay? initialTime;

  /// The [TimePickerStyle] to use.
  ///
  /// Defaults to [TimePickerStyle.combined].
  final TimePickerStyle style;

  /// {@macro onTimeChanged}
  final OnTimeChanged onTimeChanged;

  @override
  State<MacosTimePicker> createState() => _MacosTimePickerState();
}

class _MacosTimePickerState extends State<MacosTimePicker> {
  late final _initialTime = widget.initialTime ?? TimeOfDay.now();
  late int _selectedHour;
  late int _selectedMinute;
  late DayPeriod _selectedPeriod;
  bool _isHourSelected = false;
  bool _isMinuteSelected = false;
  bool _isPeriodSelected = false;
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _parseInitialTime();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _parseInitialTime() {
    _selectedHour = _initialTime.hour;
    _selectedMinute = _initialTime.minute;
    _selectedPeriod = _initialTime.period;
  }

  TimeOfDay _formatAsTimeOfDay() {
    return TimeOfDay(hour: _selectedHour, minute: _selectedMinute);
  }

  void _incrementElement() {
    if (!widget.enabled ||
        !(_isHourSelected || _isMinuteSelected || _isPeriodSelected)) {
      return;
    }
    if (_isHourSelected) {
      if (_selectedHour + 1 >= 24) {
        setState(() {
          _selectedHour = 0;
          _selectedPeriod = DayPeriod.am;
        });
      } else {
        if (_selectedHour + 1 >= 12) {
          setState(() {
            _selectedHour++;
            _selectedPeriod = DayPeriod.pm;
          });
        } else {
          setState(() => _selectedHour++);
        }
      }
    } else if (_isMinuteSelected) {
      if (_selectedMinute + 1 > 59) {
        setState(() => _selectedMinute = 0);
      } else {
        setState(() => _selectedMinute++);
      }
    } else {
      if (_selectedPeriod == DayPeriod.am) {
        setState(() {
          _selectedHour = _selectedHour + 12;
          _selectedPeriod = DayPeriod.pm;
        });
      } else {
        setState(() {
          _selectedHour = _selectedHour - 12;
          _selectedPeriod = DayPeriod.am;
        });
      }
    }
    widget.onTimeChanged.call(_formatAsTimeOfDay());
  }

  void _decrementElement() {
    if (!widget.enabled ||
        !(_isHourSelected || _isMinuteSelected || _isPeriodSelected)) {
      return;
    }
    if (_isHourSelected) {
      if (_selectedHour - 1 < 0) {
        setState(() {
          _selectedHour = 23;
          _selectedPeriod = DayPeriod.pm;
        });
      } else {
        if (_selectedHour - 1 < 12) {
          setState(() {
            _selectedHour--;
            _selectedPeriod = DayPeriod.am;
          });
        } else {
          setState(() => _selectedHour--);
        }
      }
    } else if (_isMinuteSelected) {
      if (_selectedMinute - 1 < 0) {
        setState(() => _selectedMinute = 59);
      } else {
        setState(() => _selectedMinute--);
      }
    } else {
      if (_selectedPeriod == DayPeriod.pm) {
        setState(() {
          _selectedHour = _selectedHour - 12;
          _selectedPeriod = DayPeriod.am;
        });
      } else {
        setState(() {
          _selectedHour = _selectedHour + 12;
          _selectedPeriod = DayPeriod.pm;
        });
      }
    }
    widget.onTimeChanged.call(_formatAsTimeOfDay());
  }

  Widget _buildTextualTimePicker(
    MacosTimePickerThemeData timePickerTheme,
    MaterialLocalizations localizations,
  ) {
    return KeyboardShortcutRunner(
      onUpArrowKeypress: _incrementElement,
      onDownArrowKeypress: _decrementElement,
      focusNode: _focusNode,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PhysicalModel(
            color: timePickerTheme.shadowColor!,
            elevation: 1,
            child: ColoredBox(
              color: timePickerTheme.backgroundColor!,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TimePickerFieldElement(
                      isSelected: _isHourSelected,
                      element: localizations.formatHour(
                        TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                      ),
                      onSelected: () {
                        setState(() {
                          _isHourSelected = true;
                          _isMinuteSelected = false;
                          _isPeriodSelected = false;
                        });
                      },
                    ),
                    const Text(':'),
                    TimePickerFieldElement(
                      isSelected: _isMinuteSelected,
                      element: localizations.formatMinute(
                        TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                      ),
                      onSelected: () {
                        setState(() {
                          _isMinuteSelected = true;
                          _isHourSelected = false;
                          _isPeriodSelected = false;
                        });
                      },
                    ),
                    const Text(' '),
                    TimePickerFieldElement(
                      isSelected: _isPeriodSelected,
                      element: _selectedPeriod == DayPeriod.am ? 'AM' : 'PM',
                      onSelected: () {
                        setState(() {
                          _isPeriodSelected = true;
                          _isHourSelected = false;
                          _isMinuteSelected = false;
                        });
                      },
                    ),
                  ],
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
                      !_isHourSelected &&
                      !_isMinuteSelected &&
                      !_isPeriodSelected,
                  child: ButtonInteraction(
                    label: 'Increase selected field',
                    onPressed: _incrementElement,
                    onHeldChanged: (_) {},
                    builder: (context, states) => PickerControlSurface(
                      states: states,
                      child: PhysicalModel(
                        color: timePickerTheme.shadowColor!,
                        elevation: 1,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5.0),
                        ),
                        child: CustomPaint(
                          painter: UpCaretPainter(
                            color: timePickerTheme.caretColor!,
                            backgroundColor:
                                timePickerTheme.caretControlsBackgroundColor!,
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
                  color: timePickerTheme.caretControlsSeparatorColor!,
                ),
              ),
              SizedBox(
                height: 14.0 * MediaQuery.textScalerOf(context).scale(1),
                width: 18.0,
                child: IgnorePointer(
                  ignoring:
                      !_isHourSelected &&
                      !_isMinuteSelected &&
                      !_isPeriodSelected,
                  child: ButtonInteraction(
                    label: 'Decrease selected field',
                    onPressed: _decrementElement,
                    onHeldChanged: (_) {},
                    builder: (context, states) => PickerControlSurface(
                      states: states,
                      child: PhysicalModel(
                        color: timePickerTheme.shadowColor!,
                        elevation: 1,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(5.0),
                        ),
                        child: CustomPaint(
                          painter: DownCaretPainter(
                            color: timePickerTheme.caretColor!,
                            backgroundColor:
                                timePickerTheme.caretControlsBackgroundColor!,
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

  Widget _buildGraphicalTimePicker(MacosTimePickerThemeData timePickerTheme) {
    const clockHeight = 116.0;
    const clockWidth = 115.0;
    final clock = SizedBox(
      height: clockHeight,
      width: clockWidth,
      child: CustomPaint(
        painter: GraphicalTimePickerPainter(
          clockHeight: clockHeight,
          time: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            _selectedHour,
            _selectedMinute,
            0,
          ),
          dayPeriod: _selectedPeriod == DayPeriod.am ? 'AM' : 'PM',
          theme: timePickerTheme,
        ),
      ),
    );
    void change(int minutes) {
      if (!widget.enabled) return;
      final total =
          (_selectedHour * 60 + _selectedMinute + minutes) % (24 * 60);
      setState(() {
        _selectedHour = total ~/ 60;
        _selectedMinute = total % 60;
        _selectedPeriod = _selectedHour < 12 ? DayPeriod.am : DayPeriod.pm;
      });
      widget.onTimeChanged(_formatAsTimeOfDay());
    }

    void choose(Offset point) {
      if (!widget.enabled) return;
      final delta = point - const Offset(clockWidth / 2, clockHeight / 2);
      final fraction =
          (math.atan2(delta.dx, -delta.dy) / (2 * math.pi) + 1) % 1;
      final hours = delta.distance < clockWidth * 0.32;
      final selected =
          (fraction * (hours ? 12 : 60)).round() % (hours ? 12 : 60);
      final total = hours
          ? (selected + (_selectedPeriod == DayPeriod.pm ? 12 : 0)) * 60 +
                _selectedMinute
          : _selectedHour * 60 + selected;
      if (total != _selectedHour * 60 + _selectedMinute) {
        change(total - (_selectedHour * 60 + _selectedMinute));
      }
    }

    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          change(1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          change(-1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) => Semantics(
          label: 'Time',
          increasedValue: MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(
              hour: ((_selectedHour * 60 + _selectedMinute + 1) % 1440) ~/ 60,
              minute: (_selectedMinute + 1) % 60,
            ),
          ),
          decreasedValue: MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(
              hour: ((_selectedHour * 60 + _selectedMinute - 1) % 1440) ~/ 60,
              minute: (_selectedMinute - 1) % 60,
            ),
          ),
          value: MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(_formatAsTimeOfDay()),
          onIncrease: () => change(1),
          onDecrease: () => change(-1),
          child: GestureDetector(
            onTapUp: (details) {
              Focus.of(context).requestFocus();
              choose(details.localPosition);
            },
            onPanUpdate: (details) => choose(details.localPosition),
            child: PickerControlSurface(
              states: {if (Focus.of(context).hasFocus) WidgetState.focused},
              shape: BoxShape.circle,
              child: clock,
            ),
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
    final timePickerTheme = MacosTimePickerTheme.of(context);
    final localizations = MaterialLocalizations.of(context);

    switch (widget.style) {
      case TimePickerStyle.textual:
        return _buildTextualTimePicker(timePickerTheme, localizations);
      case TimePickerStyle.graphical:
        return _buildGraphicalTimePicker(timePickerTheme);
      case TimePickerStyle.combined:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextualTimePicker(timePickerTheme, localizations),
            const SizedBox(height: 16),
            _buildGraphicalTimePicker(timePickerTheme),
          ],
        );
    }
  }
}

class TimePickerFieldElement extends StatelessWidget {
  const TimePickerFieldElement({
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
    final timePickerTheme = MacosTimePickerTheme.of(context);
    Color backgroundColor = isSelected
        ? timePickerTheme.selectedElementColor!
        : MacosColors.transparent;
    Color textColor = isSelected
        ? timePickerTheme.selectedElementTextColor!
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
