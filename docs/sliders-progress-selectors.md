# Sliders, progress and selectors

These controls use semantic Flutter surfaces. The colour well opens a
package-owned AppKit colour panel. Existing macos_window_utils window ownership
remains unchanged.

## Public usage

Import `package:macos_ui/macos_ui.dart`; time values additionally use
`package:flutter/material.dart`'s `TimeOfDay` (as before). The gallery's
**Sliders and selectors** page compiles a complete export-settings flow using
only public imports. The contracts below describe current behavior.

`MacosSlider(value: volume, min: 0, max: 100, onChanged: updateVolume,
semanticLabel: 'Export volume')` is controlled: callers rebuild its value.
A null `onChanged` now disables input/focus and exposes disabled semantics.
Discrete `splits` counts endpoints, so min 10 / max 20 / splits 3 yields
10, 15, 20. Continuous arrow/semantic steps are 1% of the range. Up/Down
increase/decrease; Left/Right follow text direction; Home/End select bounds.
No callback occurs for an unchanged effective value. Drag updates are live;
cancellation keeps values already delivered, ends the gesture and sends no
extra value. A tap commits on release. Secondary clicks do not change values.
Track, tick and thumb colours preserve caller overrides and dynamic resolution;
hover/press, visible focus and contrast outlines use semantic chrome roles.

`ProgressBar(value: 35, semanticLabel: 'Export')` and
`ProgressCircle(value: 35, semanticLabel: 'Indexing')` use **0–100** values
and expose percentage semantics. The bar is determinate only; the old nullable
bar documentation was inaccurate. `ProgressCircle(semanticLabel: 'Connecting')`
is indeterminate and exposes no invented numeric value. Its spinner becomes
static under live reduced motion, including an in-flight preference change,
and resumes when allowed. Circle/bar painters invalidate on colour-only changes;
the bar follows RTL direction. Explicit colours remain effective. A circle can
still be used in a CupertinoApp without a MacosTheme; radius zero is safe.

`MacosPopupButton<T>` retains its items, selectedItemBuilder, controlled value,
callbacks, themes, sizing, autofocus and external focus-node contract. Enter/
Space opens it; arrow navigation skips disabled rows; Enter/Space chooses once;
Escape or outside click dismisses without a value callback. Focus returns to
the trigger after dismissal/selection. A disabled or changed items/value snapshot
invalidates an open route. Hiding through ExcludeFocus/TickerMode or disposing
removes the owned popup. Trigger focus nodes supplied by callers are never
disposed. Item focus nodes, scroll controller and curved animation are disposed.
Menus use opaque surfaces, bounded scrolling and grow with text scaling; explicit text styles and popup colours are
preserved. Hover/press/focus outlines use chrome roles; disabled rows dim.
Reduced motion removes popup fading live. The bounded rapid-open/Escape test
uses eight 16ms key cycles without the historical framework assertion on the
pinned SDK; this is not a universal framework fix or a general framework claim.

`MacosColorWell(onColorSelected: updateColour, color: colour,
semanticLabel: 'Highlight colour')` adds optional controlled `color`, `enabled`
and `semanticLabel`. Omitting color retains its own last selection. Tab and
Enter/Space, primary pointer and accessibility activation open the panel.
Only an active well receives colour changes. A changed colour notifies once;
opening, closing/cancelling, duplicates, malformed data and unavailable native
channels do not notify. `onColorSelected` now actually runs (the adopted widget
never called it). Missing plugins/platform errors safely leave the well usable.
When disabled, hidden by ExcludeFocus/TickerMode or disposed, it cancels its
session. Arbitrary Offstage-only embedding does not signal visibility; consumers
must exclude focus or remove/disable such controls, as the shell does.

`MacosDatePicker` and `MacosTimePicker` retain internally owned selections seeded
by `initialDate` / `initialTime`. Those properties remain **initial values**, not
controlled setters; use a new widget key to reseed. Both add `enabled: false`.
Text fields can be selected by pointer, Tab or accessibility activation, then
adjusted using Up/Down or named steppers. Field/stepper/day controls have hover,
pressed, focus and selected feedback with live contrast. Disabled subtrees drop
focus, hit testing and actionable semantics. Text fields reflow at constrained
widths/scales. Caller picker themes remain in use. Date month/year changes clamp
the day (January 31 → February 29 in 2024); Monday-first Sunday-start months
retain all days. Invalid date-format token patterns fall back to M/D/YYYY.
Calendar days have full-date semantic names; selected-date text honours its
theme role. Calendar previous/next/reset retain the adopted callback behaviour.

The graphical time picker is now interactive: inner clock clicks/drags select
hours in the current AM/PM period; outer clock clicks/drags select minutes.
Arrow keys and semantic increment/decrement adjust one minute, wrapping midnight.
Textual minutes wrap within the hour as in the adopted control. Each effective
graphical change notifies once. The clock depicts the selection with seconds at
zero; it no longer starts an unowned wall-clock timer, drifts independently of
the selected value or animates seconds. This also removes motion under reduced
motion. It is a time selector, not a clock display.

## Native ownership

The colour panel is application-wide (`NSColorPanel.shared`), not per-window.
Its Flutter session serialises listen/open/cancel and routes events exclusively
to the active well. It uses the guarded EventChannel wire protocol so missing
plugin activation is caught locally rather than reported globally by Flutter's
receiveBroadcastStream convenience method. Invalid payloads are ignored; error
and end-of-stream release the current session. No subscription exists before
activation. No timers or polling are added.

Swift uses public AppKit APIs and main-thread operations. Mode/colour arguments
are validated and every method completes its Flutter result. The provider owns
its target/action and one close observer while open, and detaches them on close,
cancel and disposal. It does not repeatedly register colour notifications.
Colours convert through sRGB and preserve alpha; the shared panel is not released
when closed. There is no public target getter on NSColorPanel, so ownership is
tracked explicitly. Consumers must coordinate other uses of the shared panel;
simultaneous external panel owners/multiple windows are not a supported contract.
No new API raises the existing macOS 12 deployment floor.

## Compatibility and migration

All existing imports and named constructor arguments remain valid. Additions:
nullable slider callback (its getter type is now `ValueChanged<double>?`), colour
well color/enabled/semanticLabel and picker enabled. Code reading the slider's
callback as non-null must guard it or assert its own enabled invariant. The slider
is now stateful; consumers should not depend on its former StatelessWidget base.
Default colour properties remain unchanged. No package exports, dependencies,
lockfiles or native window integration APIs change.

Behaviour corrections may affect clients relying on the broken 0–1 discrete
range, duplicate values, tap-down commits, missing colour callbacks, numerical
progress strings without units, unbounded popup focus lifetime, invalid month
rollover, inert graphical time input or moving clock hands. Callers should let
controlled state own slider/popup/colour values and treat initial date/time as
seeds. Explicit picker/popup styles remain supported; accessibility adds an
independent visible focus/contrast boundary.
