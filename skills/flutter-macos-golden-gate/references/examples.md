# Runnable public examples

Use the files in this checkout as maintained examples; links below resolve relative
to this repository-local skill. They are not embedded copies requiring a second
implementation to maintain. If moving the skill elsewhere, retain its repository
references or resolve the equivalent files in the actual dependency source.

## Minimal shell, settings, table and shared native/fallback surface

[developer_example.dart](../../../example/lib/developer_example.dart) is a complete
entrypoint with public Flutter imports and `package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart`.
[Setup](../../../docs/developer-guide.md) supplies the local path dependency and
host configuration. From repository `example/`:

```sh
flutter pub get
flutter run -d macos -t lib/developer_example.dart
```

Read/adapt that file for MacosApp → MacosWindow/Sidebar → MacosScaffold/ToolBar →
ContentArea. Its app State owns document selection and settings. Shared surface
nativeCommands and fallback PushButton call the same action; Settings can retain
forceOpaque. It supplies a finite table viewport and borrows builder scrolling.
Use semantic metrics, meaningful labels and controlled callbacks as it does.
This small session fixture does not persist files or demonstrate a second window.

Compile and exercise selection/navigation/retained opaque setting/disposal with:

```sh
flutter analyze lib/developer_example.dart test/developer_example_test.dart
flutter test test/developer_example_test.dart --reporter expanded
```

This test runs Flutter controls, **not AppKit**. the fork recorded it on 3.44.4 and
isolated 3.41.6; [support and verification scope](../../../docs/support.md) records
this skill's exact verification scope. Never infer minimum/latest/native support.

## Full toolbar, search, command wrapper and document flows

[main.dart](../../../example/lib/main.dart) is the complete production gallery
entrypoint. From `example/`, run `flutter run -d macos`.

| Task | Source and interaction to inspect |
|---|---|
| Toolbar command/search and settings | `main.dart`: ToolBarIconButton/CustomToolbarItem overflow; Text and search for editing/composition/results; Sliders and selectors for export settings/validation. Their callbacks belong to the app. |
| Visible native glass and floating commands | [liquid_glass.dart](../../../example/lib/liquid_glass.dart): shared navigation surface plus MacosGlassCommandSurface over scrolling covers/opaque Notes, matching actions, disabled Archived, Focus commands, local live previews and opaque comparison. Preserve bottom document clearance. |
| Data/filter/sort/inspection | [dense_content.dart](../../../example/lib/dense_content.dart): controlled stable IDs, retained selection and sort, working/archive records; [document_inspector.dart](../../../example/lib/document_inspector.dart): continuous fractional indicators, read-only archive, session Save/Revert. |
| Menus/dialogs | [transient_surfaces.dart](../../../example/lib/transient_surfaces.dart): cancellation, keyboard/focus and bounded placement. Custom overlays additionally coordinate nativeOccluded. |

[Gallery guide](../../../example/README.md) lists flows and shortcuts.
`flutter analyze` and `flutter test test/shell_test.dart --reporter expanded` in
`example/` compile the public gallery and exercise its shell/component flows.
Native captures/conditions live in [support and verification scope](../../../docs/support.md),
separate from widget tests; no new native runtime claim follows from recompiling.

Before adapting copied code, retain [MIT notices/provenance](../../../NOTICE.md)
and read [migration](../../../docs/migration.md) for the behaviour you change.
Do not replace macOS controls with unrelated Material/iOS UI, make ordinary users
select a renderer, invent constructors or expose private imports to solve a compile
error. Inspect the actual public source and use the appropriate existing control.

## Independently generated consumer tasks

[the fork consumer](../../../example/lib/consumer_evaluation.dart) is another complete
entrypoint (`flutter run -d macos -t lib/consumer_evaluation.dart` from example/).
It combines controlled hierarchical navigation, toolbar search entry/overflow,
retained session settings, a repaired public table/indicators and bounded shared
native/fallback commands. A custom preview overlay coordinates nativeOccluded,
blocks underlying semantics and restores its requesting Flutter control's focus.
The retained hidden command panel excludes focus, hits, semantics and tickers.

[support and verification scope](../../../docs/support.md)
and [new interaction tests](../../../example/test/consumer_evaluation_test.dart)
record the evaluation. Native channel simulation verifies descriptor/action and
occlusion routing; it does not create AppKit views or extend runtime acceptance.

## Task composition and menu parity

[Recipes and current limits](../../../docs/composition-recipes.md) map tasks to
real public APIs. [Native toolbar example](../../../example/lib/native_toolbar_example.dart)
is a standalone filtered collection/detail flow: Back retains query/selection,
Previous/Next traverses filtered results, and native/fallback/menu/shortcut actions
share nullable callbacks. It is synchronous session data, not persistent storage.
Do not mount it under the gallery's existing toolbar/menu owner. The existing
DocumentInspector supplies the compact editor Save/Revert example.

the controlled-search contract updates the standalone native toolbar fixture to typed command roles and
controlled `MacosNativeToolbarSearch`, labelled Flutter fallback, Find menu/⌘F,
clear/no-results and retained collection/detail selection. Search is disabled in
detail; explicit Previous/Next actions remain distinct from Back. The source and
its interaction tests compile against public exports. Native property/marked-text
checks are bounded, not physical IME/VoiceOver/fullscreen acceptance.


The [standalone native toolbar example](../../../example/lib/native_toolbar_example.dart)
also compiles the shared pane controller, Sidebar navigation/independent inspector,
ContentArea, native momentary browse and exclusive row-spacing groups. It retains
query, selection and per-object session drafts through pane changes. Breakpoints,
sizes and shortcut assignments are fixture choices. It uses one explicit thumb
per content scroller and borrowed Sidebar controllers, not arbitrary native child
hosting. [Contract](../../../docs/native-window-toolbar.md#coordinated-panes-and-grouped-actions).

The standalone entrypoint also uses app-owned `ExampleMenuChannel` and native
`ExampleEditMenu.swift` bootstrap. They retain the original responder-chain Edit
menu after Flutter menu replacement completes, without shadowing the app's Find.
These are example files, not new public package APIs or another toolbar owner.
Consumers must retain equivalent native editing routing in their own menu setup.
Rejected updates now remove an accepted native toolbar before showing fallback;
keep both presentations bound to the same caller-owned query and task state.
