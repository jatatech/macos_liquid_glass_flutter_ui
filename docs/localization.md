# Localization and directional shell

Use `package:macos_ui/macos_ui.dart`. The app supplies supported locales and
Material/Widgets/Cupertino localization delegates to `MacosApp`, translates its
commands and content, and chooses calendar/bounds. See the compiling
[German/Arabic/Hebrew example](../example/lib/localization_example.dart). Run it
with `cd example && flutter run -d macos -t lib/localization_example.dart` when
the gallery is stopped; change its `locale` argument to exercise another locale.
These example translations illustrate wiring, not a complete translation catalogue.

## Direction and ownership

`MacosWindow.sidebar` is leading and `endSidebar` is trailing. Content, titlebar
region and divider positions mirror with the inherited `Directionality`; pane
widths, snap/close behavior, borrowed scroll controllers and visibility remain
owned by the existing shell. Drag toward the content grows each pane in either
direction. `MacosPaneLayout` gains `textDirection` (default LTR for direct
construction); widths are logical and `content` is a physical viewport rectangle.
Live direction updates notify listeners even when widths are unchanged.

`MacosScaffold.children` runs from leading to trailing. Existing
`ResizableSide.left/right/top` remain **physical**: choose the inward physical
edge when constructing an app-owned pane (left for a trailing pane in LTR,
right in RTL). The shell's Sidebar resizers adapt automatically. No image, logo,
physical-direction control or numeric glyph is globally transformed.

Sidebar indentation, leading icons/disclosure spacing and closed chevrons follow
direction. Right expands/enters and Left collapses/returns to parent in LTR;
Left expands/enters and Right collapses/returns in RTL. Up/Down/Home/End, Tab,
selection callbacks and immediate hidden-child focus/semantics exclusion retain
their contracts. Existing Back uses Cupertino's directional icon and already
mirrors; do not select Forward to mirror it a second time. Segments retain their
existing directional behavior.

The native toolbar remains AppKit-owned. Flutter `Directionality` does not set
macOS application language or AppKit toolbar direction. The application must
configure its native bundle localization as well as Flutter locales; mixed native
and Flutter language selection is not synchronized by this API. Native symbols
should express intent (`chevron.backward` for Back, a physical arrow only for an
actual direction). The [support and verification scope](../docs/support.md)
records the separate native boundary; an opaque RTL floating-glass fallback is
not proof of native toolbar mirroring.

## Legacy Gregorian date adapter policy

This is an explicit opt-in adapter policy, not new automatic translated defaults.
Existing `MacosDatePicker` callers keep English month/weekday and action labels,
M/D/YYYY textual order and Western digits in textual fields. The graphical grid's
day digits/full-date semantics already use `MaterialLocalizations`. Apps opting
into other locales supply these arguments together:

| Input | Policy |
|---|---|
| `weekdayAbbreviations` | Seven translated strings indexed Sunday through Saturday, independent of display order |
| `monthAbbreviations` | Twelve translated Gregorian month strings indexed January through December |
| `dateFormat` | Existing numeric D/DD, M/MM, YYYY tokens and separator; explicit token sequence renders LTR even within an RTL shell, without reversing digits |
| `startWeekOnMonday` | null uses locale `firstDayOfWeekIndex` (including Saturday); true forces Monday; false forces Sunday. One origin positions headers and day cells |
| `previousMonthLabel`, `nextMonthLabel`, `resetDateLabel` | Translated graphical action/semantics labels; English defaults unchanged |
| `increaseFieldLabel`, `decreaseFieldLabel` | Translated textual stepper labels; English defaults unchanged |

The five labels are additive. Explicit strings, date format and week-start always
win. `false` now truly forces Sunday even with a Monday/Saturday-first delegate;
previously it was ignored in that case. Null's existing delegate-driven behavior
is preserved. No locale catalogue, alternate calendar, localized textual numeral
engine or arbitrary date pattern engine is promised. The app must select another
picker for those requirements. Provide actual delegates: setting a locale alone
does not translate English strings or install a localization implementation.

`initialDate` is still a seed, not a controlled setter; a new key reseeds. Browsing
months still selects day 1 and calls `onDateChanged`; reset returns the original
seed's civil day; selecting even the same day still calls back. Textual stepping
retains clamping/callback timing. No new commit or cancellation behavior is added.
Callbacks return the selected local Gregorian civil day with time fields zero,
not an instant converted from the seed. App persistence/cancellation stays app-owned.

The staged date adapter `MacosDateSelection` remains a staged Gregorian UTC component transport.
Its native locale formats native labels only; its labelled Flutter fallback
uses caller month/weekday/week-start overrides and legacy English controls. It
does not automatically apply the native locale identifier or offer this complete
legacy adapter. Use an app-owned localized fallback for fully translated tasks.
Native and fallback calendar/bounds/draft/exit contracts are unchanged.

Apple recommends adapting ordered navigation while preserving physical direction,
images and numeral order ([Right to left](https://developer.apple.com/design/human-interface-guidelines/right-to-left)),
and choosing textual or graphical date input by task, with language-dependent
values/order ([Pickers](https://developer.apple.com/design/human-interface-guidelines/pickers)).
The adapter/default compatibility policy above is this library's engineering
judgment. Widget coverage and AppKit surrogates do not certify physical input,
VoiceOver, fonts, native RTL or other runtimes; [support and verification scope](../docs/support.md)
remain open.
