# Lists, tabs and scrollbars

Dense document content uses readable opaque Flutter surfaces alongside [native glass](liquid-glass.md) under ADRs 0004/0005. Existing
native window ownership and dependencies are unchanged.

## Public use and behaviour

Import `package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart`. `MacosListTile` keeps its existing
constructor arguments and adds `selected` (false), `enabled` (true) and optional
caller-owned `focusNode`. Selection is controlled: a click invokes `onClick`,
and the consumer rebuilds `selected`. Enter/Space activate once on key release;
secondary click does not invoke the primary action. Long press invokes only
`onLongPress`; a tile with only that callback also supports Enter/Space and an
accessibility long-press action. Pointer cancellation does not commit. Callback-
free tiles remain static content and do not acquire button semantics or focus.
Disable an interactive tile with `enabled: false` to retain its callbacks while
removing interaction/focus. Disabling a focused tile releases focus.

Tiles provide hover, pressed and focus feedback, controlled selected semantics,
and disabled semantics for interactive rows. Titles/subtitles grow with text
scaling and respect directionality. Semantic foreground/secondary/selection
roles replace the former literal subtitle greys. A selection uses contrasting
text and inherited icon colours. Explicit child Text styles and icon colours
remain authoritative; consumers must choose legible explicit colours. Existing
leading spacing and content typography are retained. List selection models,
Up/Down row navigation and context menus remain application responsibilities;
this widget does not invent a table, outline or multi-selection abstraction.

`MacosTabView`, `MacosTab`, `MacosTabController` and
`MacosSegmentedControl` retain their public constructors. Controllers remain
caller-owned and must match the number of tabs/pages. Replacing the controller
detaches the old listener; dependency changes do not duplicate listeners.
An empty view is valid. Child state, including editing and scroll position,
remains mounted across tab changes. Hidden pages lose focus, pointer input,
semantics and tickers immediately; revealing a page does not force focus back.
Use stable keys when reordering stateful pages. `MacosTab.copyWith` now preserves
its key.

The selected tab is the group's Tab traversal stop. Enter/Space choose it;
Home/End select endpoints. Top/bottom tabs use Left/Right with RTL mapping.
Side tabs retain rotated labels and use physical Up/Down accounting for rotation
and RTL. Keyboard and external controller selection reveal the selected segment
without forcing external selection to take keyboard focus. Tab labels scroll
inside available bounds rather than overflowing into the window. Content uses
semantic opaque canvas/separator roles. Existing `position` and `padding` remain
supported. The strip now occupies its own layout space instead of overlapping
the content border; allow a bounded content height for scrollable pages and
review layouts that depended on the old overlay geometry.

`MacosScrollbar` retains its constructor, explicit style overrides and Flutter
`RawScrollbar` controller/drag/visibility/orientation/notification contracts.
Use the same `ScrollController` on it and its scrollable, and dispose that
controller in the owning State. A persistent thumb requires an unambiguous
attached controller; it must not be shared between simultaneously visible
scroll positions. Keyboard scrolling follows Flutter Scrollable/ScrollAction:
place focus inside the scrollable or supply a matching PrimaryScrollController.
The scrollbar does not capture document editing/navigation keys globally.

Partial local scrollbar themes now fill unspecified fields from the MacosTheme
and component defaults, instead of asserting. Theme merge now retains
`thicknessWhileHovering`. Hover track colour updates with the live theme; live
reduced motion immediately settles hover thickness/track animation and removes
fade duration. Increased contrast uses an opaque semantic foreground thumb,
overriding a custom thumb colour for accessibility; disabling that preference
restores the custom colour. Other explicit thickness/radius/visibility settings
remain honoured. Controller replacement, shrinking content, dragging, wheel and
keyboard scrolling continue through the existing Flutter implementation.

## Gallery and compatibility

The public-import [document browser](../example/lib/dense_content.dart) has 120
working documents and 24 archived documents, independent per-tab selection and
scroll position, an inspection summary, pointer selection, keyboard row focus
and page scrolling, and persistent draggable scrollbars. It uses a bounded
scrollable viewport and scaled row extents; full document names remain in text
semantics even when narrow visual labels use ellipsis. It is representative
component coverage, not a production file manager or performance benchmark.

No imports, exports, dependencies or native APIs are changed. The three list
properties are additive; the [consumer skill](../skills/flutter-macos-golden-gate/SKILL.md) covers current usage. The immutable
upstream inventory remains historical. Existing clients should review the
intentional behaviour corrections: interactive list rows enter keyboard
traversal; hidden tab pages cannot retain focus; tab strips reserve layout space;
partial scrollbar themes inherit defaults; high contrast overrides thumb colour.
The gallery compiles through public package imports. No private consumer imports
or proposed APIs are taught.
