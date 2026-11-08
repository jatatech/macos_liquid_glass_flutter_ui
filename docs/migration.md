# Migrating from upstream macos_ui

This fork adopts upstream revision `dec19cf6960721f80165ead6c9c19594030b292f`
with its MIT notices. Keep `package:macos_ui/macos_ui.dart` and the existing
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
