# Compose a macOS task with current APIs

Start with the person's task and content, then choose controls. This guide is a
library-specific interpretation of Apple guidance, not HIG or support certification.
Import `package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart` and public Flutter libraries; inspect the
resolved constructors, not just the pinned upstream inventory.

## Task contract before layout

Record destination/collection, selected object(s), query scope, title subject,
commands and affected pane, commit model, supported inputs and target OS versions.
For example: “Find a project document, open it, return to the filtered collection;
inspect metadata while reading, saving a draft explicitly.” Collection navigation,
object selection and inspector visibility are separate application state.

Apple's [search guidance](https://developer.apple.com/design/human-interface-guidelines/search-fields)
recommends trailing toolbar search for common cross-column/detail searches and
sidebar search for filtering navigation there. Choose scope first; do not put a
collection-only filter in the sidebar of destinations. The typed native toolbar can host explicitly labelled controlled search; its
semantic roles order items; opt-in shared pane geometry bounds title width without promising divider alignment. Use an inline Flutter field for
a local list filter when that placement better explains scope. See the
[native search contract](native-window-toolbar.md#typed-items-and-controlled-native-search).

## Collection → detail → Back

Run [native_toolbar_example.dart](../example/lib/native_toolbar_example.dart) as a
standalone entrypoint from `example/` with
`flutter run -d macos -t lib/native_toolbar_example.dart`. It uses only public
imports and the documented [native host configuration](native-window-toolbar.md).
Do not rebuild a running application during verification.

The collection is a Flutter `MacosListTile` list with a controlled native title
filter and equivalent labelled Flutter fallback. Its query and stable selected index live above the detail switch; ContentArea retains its borrowed controller. Selecting a row does not open it; Open is disabled when
the selection is absent from results. Back returns to the collection retaining
query and selection. Previous/Next move through the current filtered result order;
they are disabled at the endpoints. They are not navigation history. A larger app
should retain a destination/query/selection/scroll snapshot per history entry and
restore it on Back; do not push every selection or query keystroke as a destination.

The title names the collection or current document. One `MacosNativeToolbar` owner
remains mounted while Flutter content switches. Native commands, Flutter fallback,
`PlatformMenuBar` items and `CallbackShortcuts` reuse the same nullable callbacks.
The app owns menu placement and shortcut choice (this fixture uses ⌥⌘1/2/3 to
avoid text cursor keys); it must also route focused editor commands and
modal availability. Native AppKit item overflow does not create application menus.
Apple recommends [menu access to toolbar commands](https://developer.apple.com/design/human-interface-guidelines/toolbars).

Retain the application's standard Edit menu too. The standalone example includes
app-owned Dart/native menu bootstrap files that restore the XIB responder-chain
commands after Flutter menu replacement completes; see the
[editing ownership contract](native-window-toolbar.md#typed-items-and-controlled-native-search).
Flutter focused intents alone do not establish editing support for native fields.

The fixture is synchronous, session-only data. An asynchronous app additionally
needs loading progress, an empty-collection action, filtered-empty clear/recovery,
retry without losing query/selection, and an explicit stale/deleted selection
policy. Do not show an unconfirmed save as complete. A missing native plugin leaves
labelled Flutter commands; older macOS uses opaque AppKit controls. Actual native
focus, overflow, IME and menu tracking require native runtime acceptance.

For larger collections, reuse the bounded flat `MacosDataTable` in
[dense_content.dart](../example/lib/dense_content.dart), with stable application
row IDs and controlled selection. It is not a hierarchical outline or large grid.
Its Working files/Archive `MacosTabView` illustrates principal content switching.
Apple's macOS [segmented-control guidance](https://developer.apple.com/design/human-interface-guidelines/segmented-controls)
distinguishes tab views for main content from related toolbar/inspector choices.
Existing `MacosSegmentedControl` uses `MacosTabController`; retain that contract
for related exclusive choices. Its name does not promise AppKit hosting,
momentary actions or native multi-selection. The separate `MacosNativeToolbarGroup`
provides native momentary or controlled exclusive toolbar options; it does not
change the Flutter segmented-control contract.

## Compact editor and ongoing inspector

Reuse [DocumentInspector](../example/lib/document_inspector.dart), reached through
the gallery's Document inspector page or the document browser's Inspect command.
It owns session draft/saved values and Save/Revert, with read-only archive state.
The browser fixture retains the explicitly inspected subject until Inspect is used
again; it does not automatically track a new selection. Wire selection to the
inspector when the task requires it, retaining drafts by subject.
A production editor should keep drafts keyed by document ID outside disposable
pane widgets; persist through an app service, report failures without losing the
draft, and decide cancellation/unsaved-work behavior explicitly.

An inspector follows selection and should remain nonmodal for repeated adjustments
while viewing content; a pinned Info window retains a fixed subject. Apple's
[panels](https://developer.apple.com/design/human-interface-guidelines/panels) and
[sheets](https://developer.apple.com/design/human-interface-guidelines/sheets)
guidance motivates this distinction. `MacosWindow.endSidebar` and existing builders
or `ResizablePane` can provide app-composed ongoing space. The existing inline
inspector fixture is not a native panel or coordinated split-view implementation.
At compact widths, reveal/hide an app-owned inspector while retaining its draft;
keep a reachable reveal command. Hidden controls must lose hits, focus and semantics.
Borrow builder scroll controllers; dispose only controllers the app creates.

For a brief local attribute/date edit, use an existing `ToolbarPopup` anchored to
its Flutter trigger where appropriate, with `MacosDatePicker` or form controls.
For a native command, retain an opaque `MacosNativeToolbarAnchor` on a typed command
and use the [bounded date adapter](native-window-toolbar.md#stable-anchors-and-contextual-dates).
The picker is Flutter-rendered, not `NSDatePicker`; verify locale/date-entry limits
in the [selector guide](sliders-progress-selectors.md). Avoid a blocking sheet for
continuous metadata inspection. Use `showMacosSheet` for a focused bounded task
with explicit completion/cancellation; it is a Flutter modal route, not an AppKit
attached sheet. Preserve draft edits and restore trigger focus when dismissing
an anchored temporary task. The staged native adapter returns a draft on automatic closure; apply only explicit
Jump. If the native item is overflowed/unavailable, reveal the labelled
`MacosDateSelectionFallback` before opening it; no guessed coordinates.

## Current capability ledger

| Role | Implemented API / ownership | Evidence and boundary |
|---|---|---|
| Window commands/title | `MacosNativeToolbar`, `MacosNativeToolbarCommand`; one retained owner per registrar engine | Native lifecycle harness and Flutter transport tests; typed command/search descriptors and leading/content/trailing roles available; no multiwindow, customization or exact pane-divider alignment. Native momentary/exclusive groups and opt-in shared pane geometry are available. Integer shorthand groups retain ordering. |
| Navigation/content/inspection | `MacosWindow`, `Sidebar`, `MacosScaffold`, `ContentArea`, `ResizablePane` | `MacosPaneLayoutController` opt-in coordinates shell geometry, one backing/scroll ownership and native title width; existing builders/toggles are retained. App owns destinations, selection and draft. |
| Search / content switching | `MacosSearchField` or `MacosTextField`; `MacosTabView`/`MacosTabController` | Flutter editing/tests, app-owned query/scope; `MacosNativeToolbarSearch` retains native editing/composition, with caller-owned query/controller and equivalent Flutter fallback. |
| Temporary tasks | `MacosNativeToolbarAnchor`, controller `presentDate`, `MacosDateSelectionFallback`; existing `ToolbarPopup`, `showMacosSheet`, `MacosDatePicker` | Bounded Gregorian staged native date task and labelled Flutter fallback; one result/draft retention. AppKit harness uses a key eligibility surrogate, not physical focus proof. |
| Functional native glass | `MacosNativeToolbar` or bounded `MacosGlassSurface`/`MacosGlassCommandSurface` descriptors | Actual AppKit Liquid Glass on permitted macOS 26+; floating host replaces child, never hosts arbitrary Flutter children. See [glass contract](liquid-glass.md). |
| Document/content material | Semantic Flutter canvas and readable opaque document/form content | Keep content readable. Classic `NSVisualEffectView` from utilities is a different material from Liquid Glass. |
| Approximation / fallback | Shared surface's explicitly labelled Flutter approximation; opaque accessibility/compatibility paths | Policy/widget evidence; native window toolbar itself has no approximation mode. Respect Reduce Transparency/Contrast/Motion. |
| Background continuity | No public content-extension API | Native glass is not a promise to sample Flutter pixels. HIG-06 concluded that the present shell does not justify extension; see the [support and verification scope](../docs/support.md). |

`windowTitle` (or its `title` default) is temporary and restored on disposal where
ownership still matches. Hiding or changing `glassTitlebar` is not disposal.
Keep window-utils' existing parent/controller/delegate; do not add a duplicate
bridge or second toolbar owner for an editor route. Use `interactive: false` when
a modal covers its source; native settings-window/menu routing remains app-owned.

## Review the task as well as compilation

Review roles and scope: does selection affect the intended detail/inspector, does
the title identify that subject, does Back restore context, and are Previous/Next
clearly result traversal? Check one native owner, current callback/disabled parity,
keyboard-only completion, clear/no-results/retry paths, cancellation and unsaved
work, large/localized text, narrow/wide layout, hidden-pane recovery and selected
contrast. Do not invent private constructors to fill capability gaps.

Compile public-import examples and exercise affected interactions. Separately
record exact source/binary/OS/SDK for native title/overflow/focus/VoiceOver/IME,
active/inactive windows, fullscreen and live accessibility preferences. Flutter
previews and AppKit surrogate tests are bounded evidence. The [support policy](architecture/compatibility-policy.md)
and [support and verification scope](../docs/support.md) retain minimum/current SDK, macOS 26,
oldest fallback and other architecture/runtime gaps; none is passed by this recipe.


## Coordinated native-toolbar shell

The standalone example now shares a `MacosPaneLayoutController` between its retained
native toolbar and MacosWindow. Navigation and inspector use Sidebar's borrowed
controllers; opaque document content uses ContentArea and one explicit scrollbar.
Its selected-object inspector follows selection independently of detail navigation
and retains session drafts by object. The older DocumentInspector recipe above
still illustrates a pinned subject. Pane hide/resize/compact states retain query,
selection and drafts. Previous/Next are momentary actions, Row spacing is a
controlled exclusive toolbar choice, and Back remains a separate navigation
command. See the [complete coordination/action contract](native-window-toolbar.md#coordinated-panes-and-grouped-actions)
for native/opaque ownership, topOffset, hidden focus and application-menu duties.
