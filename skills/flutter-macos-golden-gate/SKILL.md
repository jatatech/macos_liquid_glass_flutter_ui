---
name: flutter-macos-golden-gate
description: Build or repair macOS Flutter consumers of this repository's macos_liquid_glass_ui fork, including its shell, controls and native Liquid Glass surfaces. Use for this library's API selection, composition, migration and fallback diagnosis; not generic Flutter, iOS glass or unrelated glass packages.
---

# Flutter macOS Golden Gate

Use the consumer's actual dependency source. This repository is a fork named
`macos_liquid_glass_ui`, now pre-release **0.9.0-dev.1**; the former **2.2.3** metadata
was inherited upstream identity. This fork uses its own pre-1.0 sequence; registry
upstream releases do not include its additions. Inspect the consumer's
pubspec/lock/package configuration and the resolved `lib/macos_liquid_glass_ui.dart` before generating code. Compare this dictionary with the resolved public source revision.
Do not substitute a registry dependency for the user's local checkout.

Before selecting widgets, read [task/composition recipes](../../docs/composition-recipes.md).
Write the consumer's task contract: navigation destination versus object selection,
search scope, title/command subject, persistence and presentation lifetime. Review
roles and ownership as well as compilation. Retain query/selection on Back;
previous/next traverses results rather than replacing navigation history. The
capability ledger records implemented typed search, pane coordination, groups and
bounded native anchors/staged dates, with native/fallback and operator limits.
Use MacosTabView for principal content switching; controller-backed segments are
related choices, not momentary native actions. Use one retained native toolbar
owner and app-owned PlatformMenuBar routing with shared callbacks/enabled state.

Read the relevant part of [the versioned API dictionary](references/api-v1.md)
for names, constructor requirements, callbacks and component selection. It links
to actual public source and owning guides; it is a selected dictionary, not every
optional styling parameter. Check the constructor before adding other arguments.

Use `package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart` plus Flutter public imports. Preserve
`MacosApp`, `MacosTheme`, `MacosWindow`, `MacosScaffold`, `Sidebar` and `ToolBar`.
`Label` and `MacosDataTable` are real names; `MacosLabel`, `MacosTable` and an
invented native-menu API are not. Do not import private `src/` paths, substitute
Material/iOS application shells, or redesign inherited controls to match an
inventory. Flutter `ThemeMode` and `TimeOfDay` need Flutter imports.

For host setup or a runnable starting point, read [examples](references/examples.md).
Reuse the complete public-import consumer or production gallery rather than
assembling unverified constructors. Preserve MIT attribution when adapting source;
[NOTICE](../../NOTICE.md) records pinned upstream provenance.

For any glass, focus or overlay task, read [composition and support](references/composition-support.md).
Actual native Liquid Glass is the core macOS capability. The command wrapper
**delegates to `MacosGlassSurface`**; Flutter approximation and opaque paths remain
explicitly distinct. Descriptors replace child; they do not host arbitrary Flutter
widgets. Retain readable opaque documents and accessibility/compatibility fallback.
Do not add a window delegate, global command shortcuts or a multi-window promise.

Keep values and persistence application-owned. Retain callback frequency, precision,
selection, cancellation and keyboard/pointer contracts from the owning guide.
Capacity/rating propose on down/start/every pan update, including equal/fractional
values; release adds no commit and cancellation does not roll back proposals.
A null indicator callback is read only. Caller controllers/focus nodes stay
caller-owned; a `ContentArea` builder's scroll controller is borrowed.

Verify changed consumer code with its available SDK: non-mutating format, analysis
and meaningful focused compile/interaction tests. Check keyboard, disabled/hidden
focus and semantics, text scaling and constrained layout for the changed flow.
For native claims, use actual supported runtime evidence; widget simulation is
not native acceptance. Report exact versions/scope and unavailable environments.
[Support policy](../../docs/architecture/compatibility-policy.md) and
[release checklist](../../CONTRIBUTING.md) retain unresolved gates; do not infer
minimum/current stable, cross-platform, fidelity or performance certification.

## Actual native window toolbars

For a top-frame toolbar with icons, groups and overflow, use the additive
`MacosNativeToolbar` API after reading [its contract](../../docs/native-window-toolbar.md)
and public-import example. The floating four-command surface is not a full
window toolbar. Follow the documented window configuration and single-owner scope.
For a full-width native glass titlebar, use the additive `glassTitlebar: true`
mode after window-utils initialisation; preserve that dependency’s native parent
controller. Native command pills alone do not establish titlebar translucency.

## Resolved selection colors

Read [semantic colors](../../docs/semantic-colors.md) when styling selection or
translucent chrome. Resolve dynamic colors from the current build context; retain
live brightness/contrast/elevation dependencies. Do not rebuild RGB to work around
the former serialization defect. Sidebar text, disclosure and both `Icon` and
`MacosIcon` inherit contrasting state defaults; explicit colors and custom drawing
remain the consumer's responsibility. Transparent selection assumes the semantic
canvas underlay. Native material contrast still requires actual runtime evidence.

For native search use the public `MacosNativeToolbarSearch` descriptor and semantic
`MacosNativeToolbarCommandItem` roles under the existing single owner. Read the
[native search contract](../../docs/native-window-toolbar.md#typed-items-and-controlled-native-search)
for controller ownership, IME/query boundaries, fallback and app-owned Find/menu
routing. Roles order items; optional shared pane geometry bounds native title width, without exact divider alignment. Use the compiling standalone
example; physical IME/VoiceOver and older-runtime acceptance remain open.


For coordinated panes use `MacosPaneLayoutController` with both MacosWindow and its
retained native toolbar, Sidebar.topOffset zero and borrowed pane controllers.
Read the [coordination/group contract](../../docs/native-window-toolbar.md#coordinated-panes-and-grouped-actions)
before opting in: one opaque Flutter sidebar backing, immediate visibility changes,
automatic scrollbar suppression and a 300-point content floor. Content scrollers
need their own explicit thumb; never wrap Sidebar's builder in another scrollbar.
Native toolbar groups use `MacosNativeToolbarGroup`: momentary has null selectedId;
exclusive requires an app-controlled selectedId. Reuse option callbacks across
fallback/menu/shortcuts and preserve repeats, disabled state and cancellation.
This does not change MacosSegmentedControl or promise a native floating sidebar.
