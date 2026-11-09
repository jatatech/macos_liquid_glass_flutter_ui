import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';
import 'package:macos_liquid_glass_ui/src/buttons/button_interaction.dart';
import 'package:macos_liquid_glass_ui/src/buttons/value_control.dart';
import 'package:flutter/semantics.dart';

/// A labelled text column. Width is a minimum in logical pixels at 1x text.
@immutable
class MacosTableColumn {
  const MacosTableColumn({
    required this.label,
    required this.width,
    this.sortable = false,
  }) : assert(width > 0 && width < double.infinity);

  final String label;
  final double width;
  final bool sortable;
}

/// A flat row with stable, unique identity and one plain-text cell per column.
@immutable
class MacosTableRow {
  const MacosTableRow({
    required this.id,
    required this.cells,
    this.enabled = true,
  });

  final Object id;
  final List<String> cells;
  final bool enabled;
}

/// Bounded, single-selection text table. Sorting/data loading belong to the owner.
///
/// Supply finite width/height, 0–200 rows and matching cells (empty rows are valid).
/// Rows are lazy; columns share explicit widths and scroll horizontally together.
/// This is not an editable grid, multiselection model or hierarchical outline.
/// See docs/data-table.md for sizing, keyboard and ownership contracts.
class MacosDataTable extends StatefulWidget {
  MacosDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.onSelectionChanged,
    this.selectedId,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.onActivate,
    this.onSecondaryTap,
    this.empty = const Text('No documents'),
  }) : assert(columns.isNotEmpty),
       assert(rows.length <= 200),
       assert(rows.map((row) => row.id).toSet().length == rows.length),
       assert(rows.every((row) => row.cells.length == columns.length)),
       assert(
         sortColumnIndex == null ||
             (sortColumnIndex >= 0 && sortColumnIndex < columns.length),
       );

  final List<MacosTableColumn> columns;
  final List<MacosTableRow> rows;
  final Object? selectedId;
  final ValueChanged<Object> onSelectionChanged;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final ValueChanged<Object>? onActivate;
  final void Function(Object id, TapDownDetails details)? onSecondaryTap;

  /// Caller-owned empty state. For loading/error, replace the entire table.
  final Widget empty;

  @override
  State<MacosDataTable> createState() => _MacosDataTableState();
}

class _MacosDataTableState extends State<MacosDataTable> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  final _focus = FocusNode(debugLabel: 'Document table');
  double _extent = 40;
  bool _focused = false;

  @override
  void didUpdateWidget(MacosDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Also covers an in-place data reorder or removal. Reveal after layout.
    _scheduleReveal();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleReveal();
  }

  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_vertical.hasClients) return;
      final index = widget.rows.indexWhere((r) => r.id == widget.selectedId);
      if (index >= 0) _reveal(index);
    });
  }

  void _reveal(int index) {
    final position = _vertical.position;
    final top = index * _extent;
    final bottom = top + _extent;
    final offset = top < position.pixels
        ? top
        : bottom > position.pixels + position.viewportDimension
        ? bottom - position.viewportDimension
        : position.pixels;
    _vertical.jumpTo(offset.clamp(0, position.maxScrollExtent));
  }

  void _choose(MacosTableRow row) {
    if (!row.enabled) return;
    _focus.requestFocus();
    widget.onSelectionChanged(row.id);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        final selected = widget.rows.where(
          (r) => r.id == widget.selectedId && r.enabled,
        );
        if (selected.isNotEmpty) widget.onActivate?.call(selected.first.id);
      }
      return KeyEventResult.handled;
    }
    final direction =
        key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.pageDown ||
            key == LogicalKeyboardKey.home
        ? 1
        : key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.pageUp ||
              key == LogicalKeyboardKey.end
        ? -1
        : 0;
    if (direction == 0) return KeyEventResult.ignored;
    if (event is KeyUpEvent) return KeyEventResult.handled;
    final current = widget.rows.indexWhere((r) => r.id == widget.selectedId);
    final page = _vertical.hasClients
        ? math.max(1, (_vertical.position.viewportDimension / _extent).floor())
        : 1;
    var target = key == LogicalKeyboardKey.home
        ? 0
        : key == LogicalKeyboardKey.end
        ? widget.rows.length - 1
        : current < 0
        ? (direction > 0 ? 0 : widget.rows.length - 1)
        : (current +
                  direction *
                      (key == LogicalKeyboardKey.pageDown ||
                              key == LogicalKeyboardKey.pageUp
                          ? page
                          : 1))
              .clamp(0, math.max(0, widget.rows.length - 1))
              .toInt();
    while (target >= 0 && target < widget.rows.length) {
      if (widget.rows[target].enabled) {
        widget.onSelectionChanged(widget.rows[target].id);
        // The owner's accepted rebuild reveals its actual selected ID.
        break;
      }
      target += direction;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _focus.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    final scale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(14) / 14,
    );
    _extent = 40 * scale;
    Widget cell(String text, double width) => SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MacosChromeData.gap),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
    return ColoredBox(
      color: chrome.canvas,
      child: LayoutBuilder(
        builder: (context, bounds) {
          assert(
            bounds.hasBoundedWidth && bounds.hasBoundedHeight,
            'MacosDataTable needs finite width and height.',
          );
          final widths = widget.columns.map((c) => c.width * scale).toList();
          final width = math.max(
            bounds.maxWidth,
            widths.reduce((a, b) => a + b),
          );
          widths[0] += width - widths.reduce((a, b) => a + b);
          return ScrollConfiguration(
            behavior: const MacosScrollBehavior().copyWith(scrollbars: false),
            child: MacosScrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  height: bounds.maxHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: _extent,
                          child: DefaultTextStyle(
                            style: MacosTheme.of(context).typography.body
                                .copyWith(color: chrome.foreground),
                            child: Row(
                              children: [
                                for (var i = 0; i < widget.columns.length; i++)
                                  Semantics(
                                    header: true,
                                    sortKey: OrdinalSortKey(i.toDouble()),
                                    child: SizedBox(
                                      width: widths[i],
                                      child: !widget.columns[i].sortable
                                          ? cell(
                                              widget.columns[i].label,
                                              widths[i],
                                            )
                                          : ButtonInteraction(
                                              onHeldChanged: (_) {},
                                              onPressed:
                                                  widget.columns[i].sortable &&
                                                      widget.onSort != null
                                                  ? () => widget.onSort!(
                                                      i,
                                                      widget.sortColumnIndex ==
                                                              i
                                                          ? !widget
                                                                .sortAscending
                                                          : true,
                                                    )
                                                  : null,
                                              label:
                                                  '${widget.columns[i].label}${widget.sortColumnIndex == i
                                                      ? widget.sortAscending
                                                            ? ', ascending'
                                                            : ', descending'
                                                      : ''}',
                                              builder: (context, states) =>
                                                  ValueControlSurface(
                                                    states: states,
                                                    child: cell(
                                                      '${widget.columns[i].label}${widget.sortColumnIndex == i
                                                          ? widget.sortAscending
                                                                ? ' ↑'
                                                                : ' ↓'
                                                          : ''}',
                                                      widths[i],
                                                    ),
                                                  ),
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Focus(
                            focusNode: _focus,
                            onFocusChange: (value) =>
                                setState(() => _focused = value),
                            onKeyEvent: _key,
                            child: DecoratedBox(
                              position: DecorationPosition.foreground,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _focused
                                      ? chrome.focusRing
                                      : chrome.separator,
                                  width: _focused ? chrome.focusWidth : 1,
                                ),
                              ),
                              child: widget.rows.isEmpty
                                  ? Center(child: widget.empty)
                                  : MacosScrollbar(
                                      controller: _vertical,
                                      thumbVisibility: true,
                                      notificationPredicate: (n) =>
                                          n.metrics.axis == Axis.vertical,
                                      child: ListView.builder(
                                        controller: _vertical,
                                        itemExtent: _extent,
                                        itemCount: widget.rows.length,
                                        findChildIndexCallback: (key) {
                                          final id =
                                              (key as ValueKey<Object>).value;
                                          final index = widget.rows.indexWhere(
                                            (r) => r.id == id,
                                          );
                                          return index < 0 ? null : index;
                                        },
                                        itemBuilder: (context, index) {
                                          final row = widget.rows[index];
                                          final selected =
                                              row.id == widget.selectedId;
                                          final foreground = selected
                                              ? buttonForeground(
                                                  chrome.selection,
                                                  chrome.canvas,
                                                )
                                              : row.enabled
                                              ? chrome.foreground
                                              : chrome.disabledForeground;
                                          return _TableRowView(
                                            key: ValueKey(row.id),
                                            selected: selected,
                                            enabled: row.enabled,
                                            focused:
                                                _focused &&
                                                selected &&
                                                row.enabled,
                                            label: [
                                              for (
                                                var i = 0;
                                                i < row.cells.length;
                                                i++
                                              )
                                                '${widget.columns[i].label}: ${row.cells[i]}',
                                            ].join(', '),
                                            onTap: () => _choose(row),
                                            onSecondaryTap:
                                                widget.onSecondaryTap == null
                                                ? null
                                                : (details) =>
                                                      widget.onSecondaryTap!(
                                                        row.id,
                                                        details,
                                                      ),
                                            child: DefaultTextStyle(
                                              style: MacosTheme.of(context)
                                                  .typography
                                                  .body
                                                  .copyWith(color: foreground),
                                              child: Row(
                                                children: [
                                                  for (
                                                    var i = 0;
                                                    i < row.cells.length;
                                                    i++
                                                  )
                                                    cell(
                                                      row.cells[i],
                                                      widths[i],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TableRowView extends StatefulWidget {
  const _TableRowView({
    super.key,
    required this.selected,
    required this.enabled,
    required this.focused,
    required this.label,
    required this.onTap,
    required this.onSecondaryTap,
    required this.child,
  });
  final bool selected, enabled, focused;
  final String label;
  final VoidCallback onTap;
  final GestureTapDownCallback? onSecondaryTap;
  final Widget child;

  @override
  State<_TableRowView> createState() => _TableRowViewState();
}

class _TableRowViewState extends State<_TableRowView> {
  bool _hover = false, _pressed = false;
  @override
  Widget build(BuildContext context) {
    final chrome = MacosChromeData.of(context);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: widget.label,
      selected: widget.selected,
      enabled: widget.enabled,
      focusable: widget.enabled,
      focused: widget.focused,
      onTap: widget.enabled ? widget.onTap : null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onTap : null,
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onSecondaryTapDown: widget.enabled ? widget.onSecondaryTap : null,
          child: ValueControlSurface(
            states: {
              if (widget.focused) WidgetState.focused,
              if (widget.enabled && _hover) WidgetState.hovered,
              if (widget.enabled && _pressed) WidgetState.pressed,
            },
            child: ColoredBox(
              color: widget.selected ? chrome.selection : chrome.canvas,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
