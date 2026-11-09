# Native window toolbar — additive consumer integration

`MacosNativeToolbar` and `MacosNativeToolbarCommand` are exported by
`package:macos_ui/macos_ui.dart`. This is a separate single-registrar-window API;
the one-to-four text-descriptor floating host remains unchanged. It installs an
actual AppKit NSToolbar, with native SF Symbol command groups in NSGlassEffectView
on macOS 26+. By default the unified titlebar background is system-owned;
that default alone does not prove a visibly translucent broad titlebar. This is neither Flutter blur
nor arbitrary Flutter-child hosting. Documents remain Flutter-rendered.

Commands have stable IDs, labels, SF Symbol names, ordered integer groups and
nullable callbacks for disabled state. Group 0 is leading; group 1 begins trailing
commands, separated by flexible spaces and a compressible context title. Later
groups follow. AppKit provides native overflow menus with explicit disabled state.
`title` is context; optional `windowTitle` supplies the window/AX title. Up to 20
commands are accepted. Use concise accessible labels and valid system symbols.

See the compiling public-import [standalone gallery example](../example/lib/native_toolbar_example.dart).
Run it with `cd example && flutter run -d macos -t lib/native_toolbar_example.dart`.
The required MacosWindowUtilsConfig disables full-size content, transparent
legacy titlebar, and the legacy fullscreen toolbar-removal delegate. Native
chrome occupies the window frame rather than overlaying Flutter pixels.

`glassTitlebar: true` additionally opts into a full-width native NSGlassEffectView
background under a transparent, full-size titlebar. Initialise macos_window_utils
first and retain its native parent/controller: the toolbar constrains the existing
Flutter view to the window contentLayoutGuide, preserving the content origin and
viewport size. It does not replace the dependency’s content controller. Do not
add another parent controller before macos_window_utils initialisation (that
library expects the original FlutterViewController). A bare Flutter content view
without that native parent retains the ordinary system frame. Accessibility/older
OS policy supplies an opaque native background. Updates reuse the background;
opt-out/disposal restores content autoresizing and window appearance flags. One owner
per engine is supported. An app can put that owner above its Navigator and inject
page command presentations; pass `interactive: false` while a modal page covers
the command source. This avoids competing library/editor toolbar owners. Do not install this in two Flutter routes or use it as a
multi-window API. App-owned settings windows remain app-owned.

Reduce Transparency and Increase Contrast select opaque native controls; Reduce
Motion disables interactive glass feedback. NSWorkspace changes rebuild the
native groups. Other OS versions retain opaque AppKit controls. Non-macOS or
missing transport retains the required Flutter `fallback`. The full native system
preference matrix, older OS, VoiceOver and alternative hardware remain unverified.
This API does not offer a Flutter glass approximation. Use existing APIs where
floating or approximate surfaces are actually required.

Native buttons restore Flutter focus after commands. AppKit owns Tab traversal;
Escape is scoped to the key registrar window and a current owning Flutter route,
not text editors, attached native sheets or native menu tracking. Menu tracking is
observed through AppKit notifications and event-loop/highlight state; accessibility
menu opening in the available automation did not enter that tracking loop, so a
physical menu-Escape check remains outstanding. `onEscape` belongs to the consumer.
Flutter modal routes disable native commands/escape until dismissal. Native
modeless inspectors should not be presented as modal routes. `visible: false`
hides this toolbar for an app-owned editor. Custom overlay ownership and any
application menu routing remain consumer responsibilities.

Updates serialize with latest-state coalescing, disposal removes after an in-flight
update, and missing-plugin disposal is safe. Native callbacks use current enabled
commands and visible/current-route state. Native views and observers stay separate
from the existing bounded floating-glass implementation and window delegates.

If an update becomes unavailable after a successful mount, the same update queue
removes the last native toolbar before showing Flutter fallback. Native removal
retains its external-owner guards and restores owned window framing. A subsequent
valid update can mount again with the caller's current search query. Missing
transport removal remains best effort; an unreachable plugin cannot acknowledge
teardown. Initial unavailable mounts keep the supplied fallback as before.

No existing constructor changed. Consumers opting in must remove their duplicate
Flutter toolbar and follow the configuration above. The historical pinned upstream
API inventory remains historical; these two declarations are additive. Native runtime observations are bounded to the recorded macOS arm64 environment;
outstanding acceptance remains open. See [support](support.md).



## Temporary window ownership

Mount snapshots the existing toolbar, toolbar style, title visibility, window title,
full-size-content bit, transparency, opacity and background. Disposal restores the
original toolbar and the properties that still equal this host's last writes.
Both `windowTitle` and its `title` default are temporary: an app-supplied value does
**not** intentionally persist after disposal. A later external title/property write
is preserved. Equal-value writes cannot identify a new owner; coordinate ownership
explicitly rather than relying on same-value assignments as a handoff signal.
If another native owner replaces `window.toolbar`, updates return unavailable and
teardown leaves that owner's window properties/toolbar alone, removing only this
host's background and constraints. A future mount snapshots the then-current state.
Only `.fullSizeContentView` is restored; fullscreen and unrelated style bits remain
AppKit/app-owned. The window delegate and window-utils parent are never replaced.

`glassTitlebar: false` opts out of the full-width background while retaining the
installed toolbar and temporary window title/style. `visible: false` only hides
that toolbar; neither is disposal. Dispose the sole widget owner to restore the
previous toolbar. Keep that owner above routes rather than mounting competing
owners. [support and verification scope](../docs/support.md)
distinguishes AppKit lifecycle checks from Flutter rendering/operator acceptance.

## Task scope, menus and missing symbols

The [task recipes and capability ledger](composition-recipes.md) distinguish
collection navigation, selected-object inspection and native hosting. Integer
command groups are ordered leading/trailing groups, not semantic pane placements.
Opt-in typed search/role placement is available as described below. Native momentary/exclusive groups and opt-in pane coordination are described below. Stable native anchors/contextual dates are described below. There is no
background-extension descriptor. Keep one owner across
route/content changes, with app-owned command state and menus.

The standalone example now shares each nullable callback across toolbar, Flutter
fallback, application `PlatformMenuBar` and shortcuts. Back returns to the retained
collection query/selection; Previous/Next browse filtered results. This is not a
history stack. Platform menu routing, editing shortcuts, modal availability and
persistence remain application responsibilities.

An unavailable SF Symbol now uses the standard `questionmark.square` symbol rather
than an empty image. The original command's ID, accessible label, tooltip, disabled
state and overflow text remain intact, within the same 36-point button. Supply a
valid, meaningful symbol on all intended runtimes; a recovery glyph is not a
replacement for choosing an appropriate icon. [support and verification scope](../docs/support.md)
records zero-size failure before the repair and symbol/overflow/width checks after.

## Typed items and controlled native search

Existing constructors, integer groups and command callbacks retain their layout
and behavior when `items` is null. Opt in with `items` and leave `commands` empty.
At most 20 items with distinct, nonempty IDs are accepted. The public barrel exports
`MacosNativeToolbarItem`, `MacosNativeToolbarCommandItem`,
`MacosNativeToolbarSearch`, `MacosNativeToolbarPlacement` and
`MacosNativeToolbarController`; no private imports or second host are required.

`MacosNativeToolbarCommandItem(command: command, placement: ...)` reuses the
existing command callback, disabled state, symbol recovery and overflow menu.
Typed items are ordered by `leading`, `content`, then `trailing`, preserving list
order within each role. Flexible spaces separate roles; the noninteractive context
title precedes content items. These are semantic roles within the current toolbar,
not pane alignment or hard-coded sidebar/inspector widths. The centered title is
still permitted. Opt-in pane coordination is described below. Previous/Next may use a momentary
group; they remain distinct from history.

`MacosNativeToolbarSearch(id: ..., label: ..., controller: ...)` hosts standard
`NSSearchToolbarItem`/`NSSearchField` (macOS 11+, within our deployment floor 12).
AppKit owns collapse/expansion, standard clear control, focus and search overflow
presentation; no extra glass wrapper is applied. The label is the placeholder and
accessibility label. Search defaults to trailing. Choose a label that explains
scope; the example filters project document titles and disables search in detail.
Suggestions, scope menus, tokens, submission and persistence are app-owned or
unsupported here. This descriptor controls a query, not a full native editing value.

The caller owns/disposes the `TextEditingController`. Native committed edits,
including clear, set its text before `onChanged`; programmatic controller changes
never call `onChanged`. Keep application query/results in sync from that callback
and from any programmatic changes. The fallback must use the same controller and
callback. Native selection/marked text stay in AppKit, not Flutter's controller.
An echo of the same query never resets the native editor. Stable ID/type/order
retains the item, editor and selection through unrelated command/title changes.
Native edit revisions reject older queued query snapshots. Explicit programmatic
query replacement can change selection; during marked text it is deferred until
composition commits or editing ends, without a callback echo. A newer native edit
wins over a query update queued before that edit. Do not repeatedly assign text
from build or use the controller's composing range to drive native IME state.

Native clear retains field focus. Escape/editing shortcuts remain AppKit-owned
while editing, so Escape is not a Back command there. Tab/click enters search.
An optional caller-owned `MacosNativeToolbarController.focusSearch(id)` starts
standard native search interaction; it returns false for missing, disabled, hidden,
covered, unavailable or non-key-window search. The app should request its fallback
field's FocusNode on false. The compiling example routes Find from ⌘F and its app
menu this way. It owns command/shortcut availability and the native Edit menu;
the package does not capture global editing shortcuts or synthesize app menus.

The example's `ExampleMenuChannel` forwards to Flutter's unchanged
`DefaultPlatformMenuDelegate` channel, then requests restoration only after
`Menu.setMenus` completes. Its app-owned `ExampleEditMenu.swift` copies the XIB's
standard responder-chain Edit menu, so native search/date editors and Flutter text
fields keep standard editing commands after asynchronous rebuilds. Generic text
Find is omitted when the app already supplies its own ⌘F. Existing external Edit
menus and explicit menu clearing are preserved. These are example bootstrap files,
not exported package APIs or a second toolbar bridge; consumers retain their own
menu composition and native responder routing. Copying just the Dart toolbar
widget does not install an application Edit menu.

`visible: false`, `interactive: false` and covered Flutter routes release native
search focus and block edits. Removing an ID/type disposes its delegate/target;
disposal restores the prior toolbar using the guarded ownership contract. Moving/removing
the search item intentionally may end editing; retain identity and placement across
ordinary query/result updates. One owner per registrar engine remains the limit.

Typed updates use `updateTyped` on the existing channel so an older native plugin
fails safely to the supplied labelled Flutter fallback. Malformed descriptors are
rejected before window mutation. Missing plugin/transport also keeps fallback;
older macOS uses standard AppKit search and existing opaque command policy.
No deployment bound, window-utils parent, delegate or glass policy changed.
[support and verification scope](../docs/support.md) is bounded: synthetic
marked text is not physical IME or VoiceOver acceptance; the remaining acceptance criteria remain open.

Apple sources: [native search item](https://developer.apple.com/documentation/appkit/nssearchtoolbaritem)
for adaptive search behavior/availability and
[search scope](https://developer.apple.com/design/human-interface-guidelines/search-fields),
[toolbar roles](https://developer.apple.com/design/human-interface-guidelines/toolbars)
for design guidance. The Dart role/revision model is library design judgment,
not an Apple-mandated API or a pane geometry guarantee.


## Coordinated panes and grouped actions

Share one caller-owned `MacosPaneLayoutController` with `MacosWindow` and its
retained `MacosNativeToolbar`. The shell publishes `MacosPaneLayout` after layout:
Flutter viewport `size`, visible logical `leadingWidth`/`trailingWidth`,
`textDirection` and computed physical `content` rectangle. Hidden widths
are zero. This is a one-window feed, not a width setter or native-language setter. Do not share one controller
between shells. Dispose after both users unmount. `MacosWindowScope` still owns
pane toggles; `Sidebar` builders still borrow their existing scroll controllers.
`ContentArea` and `ResizablePane` remain the content/supplementary layout APIs.

Coordination is opt-in; the default shell behavior remains unchanged. In this mode:

- The leading pane has one opaque Flutter backing rather than the legacy utility
  `TransparentMacOSSidebar`. Explicit decoration is composed on that backing.
  Use `disableWallpaperTinting: true` to choose opaque content/inspector backing,
  as in the example. Native Liquid Glass belongs to the retained toolbar/titlebar;
  this does not make the Flutter navigation pane a native floating glass sidebar.
- Automatic framework scrollbars are suppressed within the shell. Each Sidebar
  still wraps exactly one borrowed-controller scroller; do not add another thumb.
  Wrap ContentArea's scroller explicitly if it needs a thumb. ResizablePane's
  existing constructors choose its thumb ownership. No second native sidebar
  backdrop or scroll channel is installed by coordination.
- Visibility/width changes apply without sliding, so reported regions match the
  displayed frame. Hidden panes retain state and scroll offset but lose focus,
  hits and semantics; showing does not steal focus. The shell retains its existing
  300-point content floor by suppressing trailing, then leading panes if needed;
  application breakpoints should provide useful task-specific sizes above this.
- Set `Sidebar.topOffset: 0` when native chrome has already reserved the viewport.
  The native owner keeps the window-utils parent and `contentLayoutGuide`; it
  caps the context title width at the smaller of 260 points or available content
  width. AppKit retains centered-title placement, margins and overflow. Roles do
  not promise exact alignment with Flutter dividers, an NSSplitViewController or
  arbitrary child hosting. No synthetic spacer subtracts hard-coded pane widths.

The existing native titlebar backing is decorative and explicitly returns no hit
view. Its region stays above the Flutter viewport. No native background-extension
capture is added; that remains a later optional workpiece.

`MacosNativeToolbarGroup` adds standard AppKit `NSToolbarItemGroup` controls on the
existing typed channel/host. Provide `id`, `label`, one to eight `commands`, `mode`
and optional `placement` (default content). Command IDs are distinct/nonempty
within the group; toolbar item IDs remain distinct across the toolbar. Groups use
text labels and standard adaptive expanded/collapsed representation; the reused
command's symbol and integer group are not used for segment layout. Standard
native groups receive no extra custom glass wrapper.

`MacosNativeToolbarGroupMode.momentary` has no persistent selection (`selectedId`
must be null). Each completed activation invokes that command's nullable callback
once, including repeats. `exclusive` requires a `selectedId` matching an option.
Activation proposes via that option's callback; the host immediately restores the
supplied selection until the app rebuilds with an accepted value. Programmatic
selection changes do not emit callbacks. Cancellation/outside release emits no
proposal; AppKit owns segment pointer/keyboard tracking and Tab traversal. Native
commands return focus to Flutter after activation. A disabled option has a null
callback; it may remain the current exclusive choice, but cannot propose. Hidden,
covered and noninteractive toolbars block proposals. Mode/option-count changes
recreate only the group; ordinary labels/selection/availability update in place.
Search identity/editor/composition remain governed by the controlled-search contract.

Native overflow uses the same option callbacks, disabled states and exclusive
selection marks. Stale menu targets recheck the current model. The application
must provide equivalent labelled fallback, menu and shortcuts; the example uses
selected Flutter semantics and shares callbacks for native groups, fallback,
PlatformMenuBar and shortcuts. Application menus remain consumer-owned, including
any selected-choice indication. No multi-selection, toolbar customization or
history abstraction is promised. Older native plugins reject unsupported group
descriptors into the supplied fallback. Existing constructors, integer groups,
drag callbacks and precision are unchanged.

[Public example](../example/lib/native_toolbar_example.dart) combines coordinated
navigation, collection/detail, independent selected-object inspector and session
drafts. Its 900/1100-point breakpoints and pane sizes are fixture choices, not
library rules. Pane commands are disabled below their reveal breakpoints; resize
wider to reveal them. The fallback toolbar scrolls within 35% of viewport height
so large text leaves room for content. [support and verification scope](../docs/support.md)
separates Flutter state/pointer tests, AppKit properties/actions and open operator
acceptance. No full native sidebar, physical IME/VoiceOver/fullscreen or support
certification follows from these bounded checks.

Design sources: Apple's [split-view guidance](https://developer.apple.com/design/human-interface-guidelines/split-views)
for pane sizing/hiding and [segmented controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls)
for action versus choice roles. The installed AppKit SDK declares native group
selection/control representation on macOS 10.15+, below the deployment floor 12;
[selection mode](https://developer.apple.com/documentation/appkit/nstoolbaritemgroup/selectionmode-swift.property)
is the standard mechanism. The geometry feed, opaque coordination policy and
controlled proposal/restore contract are library decisions, not Apple requirements.


## Stable anchors and contextual dates

Retain one `MacosNativeToolbarAnchor()` and supply it as `anchor` on exactly one
`MacosNativeToolbarCommandItem`, with stable item ID/placement. Retain the toolbar
controller too. `controller.presentDate(anchor, MacosDateSelection(...))` returns
one `MacosDateSelectionResult`. The opaque anchor exposes neither native views nor
Flutter coordinates. One registrar host/channel remains; no second bridge, arbitrary
Flutter child, multiwindow, customization or detachable popover is introduced.

The anchor command uses a retained standard AppKit button (system material), not a
recreated custom glass wrapper. Unrelated title/query/group/pane updates retain it;
actual removal/rebinding, disabling, hide/coverage, anchor geometry change or window
resize/move invalidates the presentation. Native frame notifications are observed
only while open; no capture, timer or self-driven frame loop. A visible, enabled
item in the owned key window (without an attached sheet) is required. Overflowed
items have no eligible persistent positioning view: return `unavailable`. The
application must reveal and lay out a labelled Flutter fallback, then open it;
never estimate a Flutter coordinate for a native button. The example's app menu
uses the same nullable date command as its toolbar/overflow/fallback.

Native presentation is a transient `NSPopover` with standard graphical and textual
`NSDatePicker` controls for month browsing and precise year entry, and explicit
app-labelled Jump/Cancel actions. AppKit manages standard appearance/accessibility;
no extra glass container is layered around the picker/popover. One native date task
is active at a time. A valid new eligible request supersedes the previous request;
an unavailable or malformed request does not cancel an existing task. Every accepted
request completes exactly once, clearing ownership before closing the popover:

- `committed`: explicit Jump; apply the staged task.
- `cancelled`: explicit Cancel; app may discard the draft.
- `dismissed`: Escape/outside/AppKit automatic closure; retain the returned draft.
- `invalidated`, `superseded`, `disposed`: automatic ownership/layout closure;
  retain the returned draft according to the task contract.
- `unavailable`: no presentation; retain the original seed and offer fallback.

Escape belongs first to native text editing, menus and attached sheets. It closes
the chooser when not owned by those interactions, and never also invokes the
consumer's toolbar `onEscape`. Closing restores the eligible anchor or registrar
content only when its window is key and no sheet/menu/text editor owns focus;
actual focus across activation remains operator acceptance. Disposal, toolbar owner
replacement and in-flight updates follow the existing guarded restoration policy.

`MacosDateSelection` takes app-owned initial/minimum/maximum civil dates, title,
commit/cancel labels and a native locale identifier. It deliberately supports only
a Gregorian date task, no time/instant or alternative calendar. Select another
app-owned picker for another calendar. Date components are normalized to UTC days
without converting the supplied year/month/day, so local/DST offsets cannot shift
the selected day. Native labels use the requested locale and a Gregorian UTC
calendar; min/max constrain native selection. The bounded adapter is staged:
for immediate filtering use app-owned `MacosDatePicker.onDateChanged` rather than
pretending browsing is a committed Jump. Document edits and persistence stay app-owned.

`MacosDateSelectionFallback` is an explicitly labelled **Flutter anchored chooser**
using existing `ToolbarPopup` and a new seed-value `MacosDatePicker` for each opening.
Keep its key/state mounted, pass `selection` and `onResult`; a visible button opens
it, or call `GlobalKey<MacosDateSelectionFallbackState>.currentState?.open()` after
layout. Duplicate openings are ignored; another fallback supersedes the old one.
Do not open the native and Flutter presenters simultaneously. Normal Escape/outside
closure returns a draft without applying; Jump/Cancel are explicit. Disable/change
the task to invalidate; removal returns disposed. Existing ToolbarPopup geometry/
metrics/environment invalidation may report dismissed; it still retains the draft.
Focus returns to the eligible trigger/content with current-route guards. Fallback
month/week labels and week start are caller-supplied; legacy date-format/default
localization limits remain explicit in the [locale adapter policy](localization.md).
The native locale identifier does not translate this Flutter fallback. An out-of-bounds
Flutter draft disables Jump and is returned on automatic closure so the app can
retain/correct it; clamp a future seed explicitly if necessary. No bounds/callback/
initial-value behavior of legacy `MacosDatePicker` is changed.

[support and verification scope](../docs/support.md) separates Flutter route/transport,
AppKit surrogate/property/action and missing physical operator/runtime proof.
Apple [popovers](https://developer.apple.com/design/human-interface-guidelines/popovers)
and [pickers](https://developer.apple.com/design/human-interface-guidelines/pickers)
are design references; [NSPopover](https://developer.apple.com/documentation/appkit/nspopover)
and [NSDatePicker](https://developer.apple.com/documentation/appkit/nsdatepicker)
are framework references. The staged result/opaque-token contract is library design
judgment, not an Apple API or full HIG certification. All APIs used are below the
macOS 12 deployment floor; actual oldest-runtime/native 26 acceptance remains open.

Native/Flutter locale and direction ownership are separate; see [localization](localization.md).

## Collapsed group labels

The supplied group `label` now populates AppKit’s distinct item `title` as well as
the toolbar/overflow label. This repairs blank, AX-unnamed momentary popups at
constrained widths while retaining native automatic expanded/collapsed/overflow
behavior. Labels update in place; no constructor, callback or selection contract
changes. No consumer migration is needed. [support and verification scope](../docs/support.md)
cover normal/fullscreen and long updated labels; physical VoiceOver and other
outstanding acceptance remain open.
