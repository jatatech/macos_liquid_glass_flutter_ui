# Value controls

`MacosSwitch`, `MacosCheckbox`, `MacosRadioButton` and
`MacosSegmentedControl` render opaque Flutter controls alongside [native glass surfaces](liquid-glass.md). Native
window utilities, traffic lights and the accessibility preference bridge retain
their existing ownership. These controls add no native glass or channels.

## Usage and state ownership

Import `package:macos_ui/macos_ui.dart`. The gallery's Value controls page uses
this public import for document sync in all three switch sizes, mixed attachment
selection, enabled/disabled storage choices and preview-detail choices. Principal child-view switching uses `MacosTabView`;
see [task recipes](composition-recipes.md). The existing controller-backed
`MacosSegmentedControl` is not a native momentary-action or multi-select API.

```dart
MacosSwitch(
  value: syncDocuments,
  semanticLabel: 'Sync documents',
  onChanged: (value) => setState(() => syncDocuments = value),
)
MacosCheckbox(
  value: includeAttachments, // bool?; null displays mixed
  semanticLabel: 'Include attachments',
  onChanged: (value) => setState(() => includeAttachments = value),
)
MacosSegmentedControl(
  controller: detailController, // MacosTabController(length: 3)
  tabs: const [
    MacosTab(label: 'Summary'),
    MacosTab(label: 'Standard'),
    MacosTab(label: 'Detailed'),
  ],
)
```

Switch and checkbox callbacks request values; they do not change the consumer's
value. Mixed/unchecked checkboxes request true; checked requests false. The bool
callback does not request a mixed value. A null callback disables switches,
checkboxes and radios, preserving their accessible names/states while removing
tap actions and keyboard focus. Supply contextual/localised `semanticLabel`s;
these controls do not infer adjacent text as their name.

Radios keep the existing `value`, `groupValue` and `onChanged` constructor. Tab
and Enter/Space work standalone. For a keyboard group, use Flutter's public
`RadioGroup<T>` from `package:flutter/widgets.dart` (or Cupertino), with matching
`groupValue` and update callback:

```dart
RadioGroup<String>(
  groupValue: storage,
  onChanged: selectStorage,
  child: Column(children: [
    MacosRadioButton<String>(
      value: 'local', groupValue: storage,
      semanticLabel: 'On this Mac', onChanged: selectStorage,
    ),
    MacosRadioButton<String>(
      value: 'cloud', groupValue: storage,
      semanticLabel: 'In cloud storage', onChanged: selectStorage,
    ),
  ]),
)
```

The explicit Flutter group boundary prevents unrelated radio sets from sharing
navigation. Group arrows use its registry callback, skip disabled choices and
wrap in reading order; Tab uses Flutter's group traversal policy. Each value in
a group must be unique. Without a `RadioGroup`, no group membership is inferred
from callback identity or nearby controls. Space/Enter or pointer/AX activation
uses the individual radio callback only when its value differs from `groupValue`.

Segments listen to their controller, including external changes; replacing a
controller removes the old listener. The consumer owns/disposes the controller.
Its length must match the nonempty tab list. Tab enters the selected segment;
Left/Right move focus and selection with RTL direction, wrap at the ends, and
Home/End select the endpoints. Enter/Space on an already selected segment does
not notify again. The existing API has no disabled segment/group parameter;
this work does not invent one. An ancestor input/focus/semantics exclusion can
hide an entire control, as with other widgets.

Enter, numpad Enter and Space show held feedback and activate once on release;
repeat events do not repeat changes. Losing focus or disabling cancels a held
key. Primary click focuses and activates; pointer cancellation and secondary
click do not change values. The switch retains its render-object recognizers,
`dragStartBehavior` and RTL-aware drag threshold. Drag release requests one value
only when the midpoint differs from the controlled value. Cancel/disable cannot
commit it, even when Flutter reports an accepted drag cancellation as drag-end.
A declined drag request returns the knob to the controlled value.

## Styling and compatibility

Public constructors, exports, callback types, control sizes, diagnostics and the
public knob painter remain. No new public package API or consumer skill is added.
MIT attribution and the pinned historical inventory remain intact. The new
interaction, surface and radio-client helpers are internal. No consumer-skill
references exist to migrate. Gallery compilation verifies the public examples'
constructors, including Flutter `RadioGroup` on the recorded SDK.

Behaviour/visual migrations:

- Checkbox `activeColor`, `disabledColor` and `offBorderColor` now render; the
  upstream implementation ignored them. Its off/mixed/checked state uses an
  opaque semantic canvas/selection and contrasting glyph instead of duplicated
  accent-gradient tables. Explicit size and colour overrides remain supported.
- A selected radio no longer fires a redundant change callback. Disabled radios
  retain a dim selection border, so selection is still visible. Explicit on/off/
  inner colours and size remain supported.
- Switches expose toggled semantics instead of simultaneous checked and toggled
  flags. Disabled opacity, cancellation, live size relayout and declined drag
  reconciliation now behave consistently with their documented contracts.
- Segments rebuild for external controller changes and expose named selected/
  group semantics. Labels wrap under width constraints and grow with text scale.
  `MacosTab` uses shared semantic surfaces/text/separators; its constructor and
  `copyWith` remain unchanged. Controller length mismatch now asserts explicitly.

All four have actual hover/press feedback and an independent outside focus ring
that remains visible against selected fills without changing layout/hit metrics.
High contrast adds outlines; colours follow live appearance/accent/contrast.
Switch animations settle immediately on live Reduce Motion changes when not
actively dragging. Direct manipulation remains immediate while dragging. Other
value feedback is static, so reduced motion does not delay activation. Existing
accessibility adapter policy augments explicit appearance as before.
