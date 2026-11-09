# Migrating from upstream macos_ui

## Package identity migration — 9 November 2026

Replace the dependency key `macos_ui` with `macos_liquid_glass_ui`, retaining
this repository's Git source or your local checkout path. Replace imports of
`package:macos_ui/macos_ui.dart` with
`package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart`. The old barrel is not
shipped. Run `flutter pub get` in every consumer to regenerate its lockfile,
package configuration and native plugin registration, then fully rebuild macOS
apps (hot reload cannot migrate a native module). Do not hand-edit generated
registrants or lockfiles. Remove stale build/Pods artifacts if a host still
references the old module, then resolve again.

CocoaPods uses `macos_liquid_glass_ui`; SwiftPM uses package/target
`macos_liquid_glass_ui` and product `macos-liquid-glass-ui`. Privacy resources
move with the target. The native `MacOSUiPlugin` registration class,
`dev.groovinchip.macos_ui` method/event channels and toolbar identifier prefix
remain intentional implementation contracts. Do not register both packages in
one engine: they share those channels. Existing widget names, constructors,
callbacks and upstream MIT provenance remain unchanged. Registry publication
remains disabled; this is a source dependency migration at `0.9.0-dev.1`.


This fork adopts upstream revision `dec19cf6960721f80165ead6c9c19594030b292f`
with its MIT notices. Use `package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart` and the existing
`MacosApp`, `MacosTheme`, `MacosWindow`, `MacosScaffold`, `Sidebar`, `ToolBar`
APIs. Depend on this Git source; upstream registry releases differ.

Version `0.9.0-dev.1` starts this fork's own pre-1.0 sequence after earlier local
snapshots inherited upstream 2.2.3. It is not a downgrade to an upstream registry
release. Resolve consumer locks again after changing source/version. No public
API changes accompany this initial public packaging. CocoaPods version spelling
is `0.9.0.dev.1`; native identifiers remain compatible.

The table describes intentional behavior corrections and additive APIs. Check
owning contracts and actual exported source for the parameters you use.

| Area | Retained contract / necessary migration | Owning rationale and regression evidence |
|---|---|---|
| Theme and hidden panes | Exact interpolation endpoints now retain original theme values. Hidden panes retain mounted state but immediately lose focus, input and semantics; do not rely on hidden focus. | [support and verification scope](../docs/support.md); `test/theme/`, `test/layout/window_test.dart` |
| Navigation and overflow | Existing leaf-index selection retained/extended recursively; focus movement alone does not select. Overflow originals no longer remain keyboard/AX targets; custom items still need equivalent overflow builders. | [Navigation](shell-navigation.md); `test/layout/` |
| Buttons and value controls | Values remain consumer-controlled; cancelled presses do not activate. Radios no longer re-notify an already selected value, a concrete selection-contract correction. Switch drag remains midpoint proposal on accepted end; cancellation/disable cannot commit. Explicit checkbox colours now work. | [Buttons](foundational-buttons.md), [choices](value-controls.md); `test/buttons/` |
| Text and search | Caller controllers/focus nodes remain owned by caller; preserve composing text. Clear/empty-query `onChanged` now fires once; remove app workarounds that duplicate it. Result selection still does not call `onChanged`; it invokes selection callbacks. `onSubmitted` is additive. | [Fields](text-fields.md); `test/fields/` |
| Slider/progress/selectors | Slider proposals remain controlled and use actual min/max; see endpoint-count `splits` and keyboard precision. Colour well's previously missing callback now runs once per changed colour. Picker `initialDate`/`initialTime` remain seeds, not controlled properties. Null callbacks/disabled controls reject input. | [Selectors](sliders-progress-selectors.md); `test/indicators/`, `test/selectors/` |
| Lists/tabs/scrollbars | List `selected` is controlled; tab pages stay mounted but hidden pages lose interaction/semantics/tickers. Tab strip now reserves layout space; review consumers relying on overlap. Scrollbars retain Flutter controller/drag contracts and require an unambiguous attached controller. | [Lists/tabs](lists-tabs-scrollbars.md); `test/layout/` |
| Menus/sheets/dialogs | Flutter transient surfaces retain result/cancellation ownership and now bound focus/dismissal/anchors. A Flutter sheet is not an AppKit attached document sheet. Custom overlays must coordinate native glass coverage. | [Transient surfaces](transient-surfaces.md); `test/transients/`, `test/layout/` |
| Capacity/rating | **The fork preserves pinned pan down/start/every update, duplicate proposals, fractional pointer values and positive-fraction rating fill.** There is no release-only preview contract or rollback of already-sent proposals. Consumers of intermediate local snapshots must restore live updates; implement draft/Save/Revert in app state if needed. Keyboard/read-only, paint/live-colour and symbol-aligned hit-region repairs remain. | [Precise contract](indicators-content.md), [verification scope](support.md); `test/indicators/inspector_indicators_test.dart` |
| ContentArea | Constructor usage retained; now StatefulWidget with retained/disposed controller and valid null builder. Treat it as Widget if code depended on StatelessWidget implementation type; never dispose its borrowed controller. | [Content](indicators-content.md); `test/layout/` |
| Shared/native glass | Additive shared surface/commands; native child replacement is explicit. Earlier local versions removed colliding global Command-Option-1…4 bindings. Use app-owned shortcuts or caller-owned focus node. The shared surface adds `MacosGlassRendering.approximation`: update exhaustive switches. Portable automatic mode changed opaque → approximation; use `forceOpaque` when needed. | [Glass migration/ownership](liquid-glass.md); `test/layout/glass*`, [verification scope](support.md) |
| Flat table | Additive `MacosDataTable`/row/column APIs; app owns sorting, stable IDs and selection. No upstream replacement, editable grid, multiselect or data outline claim. | [Table](data-table.md); `test/data/data_table_test.dart` |

The sidebar's classic native wrapper is macOS-only; other targets use the semantic
canvas. Portable policy/widget checks do not certify other-platform runtimes.

The native surface queue now retains one in-flight request and one latest pending
state. Superseded geometry/hide work is coalesced, stale replies cannot poison new
requests and final removal waits for an in-flight creation. Public focus/action
and fallback contracts remain. This prevents backlog, not transport stalls.

[Support](support.md) records known issues and outstanding acceptance. The
macOS 12 deployment floor is not runtime certification. Deprecated relevance
remains compatibility-only. Use the [developer guide](developer-guide.md),
[gallery](../example/README.md) and [consumer skill](../skills/flutter-macos-golden-gate/SKILL.md)
for complete public-import examples.

## Native window toolbar, search and panes

These are additive APIs; existing floating glass and shorthand command consumers
keep their constructors and callback contracts. Use
[MacosNativeToolbar](native-window-toolbar.md) for native window chrome.

- Typed `items` must not be mixed with nonempty `commands`. Retain stable IDs and
  semantic placements across rebuilds. Missing native transport uses your Flutter fallback.
- `MacosNativeToolbarSearch` uses a caller-owned query controller. AppKit owns native
  selection and marked text; echoing a query must not reset editing. Supply equivalent
  Flutter fallback controls and app-owned Find/Edit menu routing.
- Share a caller-owned `MacosPaneLayoutController` with `MacosWindow` and the toolbar
  to coordinate panes. Use `Sidebar.topOffset: 0` for the native-reserved viewport;
  borrow each builder's scroll controller once. Defaults stay unchanged without opt-in.
- Native groups support momentary commands or controlled exclusive selection.
  Exclusive groups require a valid `selectedId`; momentary groups require null.
  Each activation proposes once, including repeated choices.
- Retain a `MacosNativeToolbarAnchor` for contextual dates. The staged Gregorian
  adapter returns a draft on automatic closure; apply only explicit commits.
  Reveal the labelled Flutter chooser when the native anchor is unavailable.

Keep one toolbar owner above route changes. Disposing it restores temporary window
properties only while ownership matches; later external writes are preserved.
A rejected update removes the previously accepted native toolbar before Flutter
fallback appears. Valid recovery retains caller-owned query and application state.
The standalone example's native Edit menu bootstrap belongs to that example,
not to a new package-level application-menu API.

## Semantic colors

Resolved dynamic-color wrappers retain their type, variants and equality contract;
all Color operations now use the resolved appearance, including alpha and color
space. Remove RGB-reconstruction workarounds and resolve again after trait changes.
Sidebar selection/hover/press and toolbar overflow now use contrasting foregrounds;
explicit child styles still win. [Color contract](semantic-colors.md).

## Direction and localized dates

`MacosWindow.sidebar` is leading and `endSidebar` trailing. Scaffold children and
sidebar tree keys follow reading direction; `ResizableSide` remains physical.
`MacosPaneLayout.textDirection` defaults to LTR for direct construction.
Five optional date action labels retain English defaults. Explicit week-start false
forces Sunday; null follows delegates. Legacy seed, browse and reset callbacks
remain. Flutter direction does not configure AppKit's application language.
[Locale policy](localization.md).

## Examples and documentation

[Fieldnotes](examples.md) adds an offline photography workspace without changing
package APIs. Its favourites and notes are session state. Existing component
examples and upstream continuous drag/fractional value contracts are retained.
