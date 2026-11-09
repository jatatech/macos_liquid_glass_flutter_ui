# Indicators and document content

The exported capacity/rating/label/content APIs retain controlled state and
readable opaque content. See the [inspector example](../example/lib/document_inspector.dart).

## Controlled editing and read-only display

Capacity accepts 0–100 inclusive. Continuous pointer input retains fractional
percentages; keyboard and semantic adjustments step by one percentage point.
Discrete keyboard/semantic input steps by `100 / splits`; pointer input stays
fractional in both modes. Positive `splits` counts cells, with zero
and 100 included as endpoints. Supplied display values need not be quantised;
complete discrete cells are filled up to the value, without partial cells.

Rating accepts 0–`amount` inclusive. Pointer proposals preserve fractions; any
positive fraction fills the next symbol, matching pinned upstream behaviour.
Keyboard/semantic input proposes whole-symbol steps. Symbols retain their requested size when space permits;
they shrink within constrained layouts rather than overflowing. Their actual hit
region stays aligned with the symbols even when a parent imposes a larger width.

Both components are controlled: rebuild with `onChanged`'s proposed value to
retain the change. A null callback means **read only**, rather than an unavailable
command: the value retains full readability, has no adjustment actions or slider
role and leaves the tab order. To represent an unavailable editor, explain that
state in the accompanying content and pass null. There is no new enabled flag.
`CapacityIndicatorCell` is a decorative paint primitive; its owning indicator
supplies the accessible value. Relevance remains a deprecated, read-only legacy
comparison; its semantics now report `value of amount` and its layout fits narrow
constraints and follows reading direction. It is not a recommended new control.

Pointer down, pan start and every pan update immediately propose values, including
repeated equal values, as in upstream. Both horizontal and vertical pans work.
Release adds no final callback. Cancellation does not undo already delivered
proposals. Escape, loss of focus and becoming read only suppress subsequent drag
updates; secondary input does not edit. Controlled rebuilds during a drag keep
updates flowing; there is no hidden preview diverging from the supplied value.

Continuous/fractional pointer proposals match upstream. Consumers of earlier
release-only or quantised local snapshots should restore live updates and keep
application-level draft/Save/Revert when needed.
The bounded rating hit area follows actual symbols under constraints, repairing
the demonstrated mismatch between stretched hit region and painted symbols;
RTL coordinates follow reading direction. Read-only/keyboard/semantic and paint
repairs remain. No new public constructor or opt-in is needed.

Tab/Shift-Tab reach editable indicators. Up/Down increase/decrease, horizontal
arrows follow reading direction, and Home/End choose the endpoints. Modified
Command/Control/Option shortcuts remain available to the application. Semantic
increase/decrease actions use the same range/steps and disappear at endpoints.
Zero rating is available by Home/decrease or the leading edge of the pointer
region. No automatic state persistence or decorative animation is added.

```dart
import 'package:flutter/cupertino.dart';
import 'package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart';

class RatingEditor extends StatefulWidget {
  const RatingEditor({super.key});
  @override
  State<RatingEditor> createState() => _RatingEditorState();
}
class _RatingEditorState extends State<RatingEditor> {
  double rating = 3;
  @override
  Widget build(BuildContext context) => RatingIndicator(
    value: rating,
    semanticLabel: 'Editorial rating',
    onChanged: (value) => setState(() => rating = value),
  );
}
```

The compiling gallery includes this pattern plus both capacity modes, relevance,
a long document label and locally adjustable contrast, reduced effects, text
scaling, reading direction and read-only state. Local previews do not change
system preferences. Dense content stays opaque. Existing shared native glass,
portable approximation and opaque policies remain in the Liquid Glass page.

## Appearance and supporting primitives

Semantic chrome focus/hover/pressed overlays preserve explicit fill/icon colours.
Capacity resolves live dynamic colours and contrast; contrast increases the cell
outline weight and uses the semantic foreground. Every painter input (including
value, colours, contrast and direction) invalidates paint. Read-only values are
not faded. No effects or animation require suppression when transparency/motion
preferences change. Dynamic appearance and accent are resolved during build.

`Label` now lets text wrap within bounded widths and uses directional icon spacing.
The existing `MacosIcon` and `MacosImageIcon` contracts are retained; no icon system
was replaced. Callers still choose meaningful semantic labels and suppress
redundant decorative icon announcements where appropriate.

`ContentArea` now retains one owned scroll controller for the lifetime of its
state and disposes it on removal. The nullable builder renders an empty area,
as its original constructor documentation promised. Rebuilding with a new builder
preserves the same controller and scroll offset where a scrollable remains.
Do not dispose the builder's borrowed controller or attach multiple independent
scroll positions unless their Flutter semantics support it. Constructor usage is
unchanged; its superclass changes from StatelessWidget to StatefulWidget, so code
that depended on that implementation type must treat it as a Widget instead.
