import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:macos_ui/macos_ui.dart';

/// Civil Gregorian days, independent of UTC offsets. Native presentation uses a
/// Gregorian calendar in UTC with localized labels. No instant/time is selected.
/// Other calendars require an app-owned presentation; this adapter never guesses.
class MacosDateSelection {
  MacosDateSelection({
    required DateTime initialDate,
    required DateTime minimumDate,
    required DateTime maximumDate,
    required this.title,
    required this.commitLabel,
    required this.cancelLabel,
    this.locale = 'en_US',
  }) : initialDate = day(initialDate),
       minimumDate = day(minimumDate),
       maximumDate = day(maximumDate) {
    if (this.minimumDate.year < 1 ||
        this.maximumDate.year > 9999 ||
        this.maximumDate.isBefore(this.minimumDate) ||
        !contains(this.initialDate)) {
      throw ArgumentError('Expected ordered civil dates in years 1–9999');
    }
  }
  final DateTime initialDate, minimumDate, maximumDate;
  final String title, commitLabel, cancelLabel, locale;
  static DateTime day(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  bool contains(DateTime value) =>
      !day(value).isBefore(minimumDate) && !day(value).isAfter(maximumDate);

  /// Transport contains calendar components, never epoch milliseconds.
  Map<String, Object> toMap() => {
    'date': [initialDate.year, initialDate.month, initialDate.day],
    'minimum': [minimumDate.year, minimumDate.month, minimumDate.day],
    'maximum': [maximumDate.year, maximumDate.month, maximumDate.day],
    'title': title,
    'commitLabel': commitLabel,
    'cancelLabel': cancelLabel,
    'locale': locale,
    'calendar': 'gregorian',
  };
}

enum MacosDateSelectionExit {
  committed,
  cancelled,
  dismissed,
  invalidated,
  superseded,
  disposed,
  unavailable,
}

/// Only [MacosDateSelectionExit.committed] applies a staged task. Other exits
/// include the last draft so automatic closure need not lose genuine edits.
/// Explicit Cancel can discard it according to the application's task contract.
class MacosDateSelectionResult {
  const MacosDateSelectionResult(this.exit, this.date);
  final MacosDateSelectionExit exit;
  final DateTime date;
}

/// A supported, explicitly Flutter anchored date chooser. This uses the existing
/// ToolbarPopup route/focus/anchor contract, never an AppKit sheet or popover.
/// Keep mounted while open. The caller owns bounds and commit versus draft policy.
/// Legacy MacosDatePicker remains a seed-value widget; each opening gets a new one.
class MacosDateSelectionFallback extends StatefulWidget {
  const MacosDateSelectionFallback({
    super.key,
    required this.selection,
    required this.onResult,
    this.enabled = true,
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
    this.weekdayAbbreviations = const [
      'Su',
      'Mo',
      'Tu',
      'We',
      'Th',
      'Fr',
      'Sa',
    ],
    this.startWeekOnMonday = false,
  });
  final MacosDateSelection selection;
  final ValueChanged<MacosDateSelectionResult> onResult;
  final bool enabled;
  final List<String> monthAbbreviations, weekdayAbbreviations;
  final bool startWeekOnMonday;
  @override
  State<MacosDateSelectionFallback> createState() =>
      MacosDateSelectionFallbackState();
}

class MacosDateSelectionFallbackState
    extends State<MacosDateSelectionFallback> {
  static MacosDateSelectionFallbackState? _current;
  final _focus = FocusNode(skipTraversal: true, canRequestFocus: false);
  FocusNode? _previousFocus;
  ModalRoute<dynamic>? _sourceRoute;
  final _popup = GlobalKey<ToolbarPopupState<void>>();
  bool _active = false, _closing = false;
  late DateTime _draft;
  MacosDateSelectionExit _exit = MacosDateSelectionExit.dismissed;
  late ValueChanged<MacosDateSelectionResult> _result;
  void _finish(MacosDateSelectionExit exit) {
    if (!_active || _closing) return;
    _closing = true;
    _exit = exit;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _active) _popup.currentState?.removeToolbarPopupRoute();
      });
    } else {
      _popup.currentState?.removeToolbarPopupRoute();
    }
  }

  /// Open only after the fallback is visible and laid out. Duplicate opens are ignored.
  Future<void> open() async {
    if (!mounted || !widget.enabled || _active) return;
    _current?._finish(MacosDateSelectionExit.superseded);
    _current = this;
    _active = true;
    _closing = false;
    _previousFocus = FocusManager.instance.primaryFocus;
    _sourceRoute = ModalRoute.of(context);
    _draft = widget.selection.initialDate;
    _exit = MacosDateSelectionExit.dismissed;
    _result = widget.onResult;
    await _popup.currentState!.openPopup();
    if (!_active) return;
    _active = false;
    if (identical(_current, this)) _current = null;
    if (mounted && widget.enabled && (_sourceRoute?.isCurrent ?? true)) {
      final invoker = _focus.traversalDescendants
          .where((n) => n.canRequestFocus && !n.skipTraversal)
          .firstOrNull;
      (invoker ?? _previousFocus)?.requestFocus();
    } else if (_sourceRoute?.isCurrent == true &&
        _previousFocus?.context != null &&
        _previousFocus!.canRequestFocus) {
      _previousFocus!.requestFocus();
    }
    _result(MacosDateSelectionResult(_exit, _draft));
  }

  @override
  void didUpdateWidget(MacosDateSelectionFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_active &&
        (!widget.enabled || oldWidget.selection != widget.selection)) {
      _finish(MacosDateSelectionExit.invalidated);
    }
  }

  @override
  void dispose() {
    if (identical(_current, this)) _current = null;
    if (_active) {
      _active = false;
      // Avoid calling app setState during widget teardown.
      final result = _result;
      final date = _draft;
      final previous = _previousFocus;
      final route = _sourceRoute;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route?.isCurrent == true &&
            previous?.context != null &&
            previous!.canRequestFocus) {
          previous.requestFocus();
        }
        result(MacosDateSelectionResult(MacosDateSelectionExit.disposed, date));
      });
    }
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolbarPopup<void>(
    key: _popup,
    position: ToolbarPopupPosition.below,
    child: Focus(
      focusNode: _focus,
      child: PushButton(
        controlSize: ControlSize.regular,
        onPressed: widget.enabled ? open : null,
        child: Text('${widget.selection.title} (Flutter chooser)'),
      ),
    ),
    content: (context) => StatefulBuilder(
      builder: (context, update) => SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(MacosChromeData.contentInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${widget.selection.title} — Flutter anchored chooser'),
                MacosDatePicker(
                  initialDate: _draft,
                  style: DatePickerStyle.combined,
                  monthAbbreviations: widget.monthAbbreviations,
                  weekdayAbbreviations: widget.weekdayAbbreviations,
                  startWeekOnMonday: widget.startWeekOnMonday,
                  onDateChanged: (date) {
                    if (!_closing) {
                      update(() => _draft = MacosDateSelection.day(date));
                    }
                  },
                ),
                if (!widget.selection.contains(_draft))
                  const Text('Choose a date within the task bounds.'),
                Wrap(
                  spacing: MacosChromeData.gap,
                  children: [
                    PushButton(
                      controlSize: ControlSize.regular,
                      onPressed: () =>
                          _finish(MacosDateSelectionExit.cancelled),
                      child: Text(widget.selection.cancelLabel),
                    ),
                    PushButton(
                      controlSize: ControlSize.regular,
                      onPressed: widget.selection.contains(_draft)
                          ? () => _finish(MacosDateSelectionExit.committed)
                          : null,
                      child: Text(widget.selection.commitLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
