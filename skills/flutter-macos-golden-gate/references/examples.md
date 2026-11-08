# Runnable public examples

Use the files in this checkout as maintained examples; links below resolve relative
to this repository-local skill. They are not embedded copies requiring a second
implementation to maintain. If moving the skill elsewhere, retain its repository
references or resolve the equivalent files in the actual dependency source.

## Minimal shell, settings, table and shared native/fallback surface

[developer_example.dart](../../../example/lib/developer_example.dart) is a complete
entrypoint with public Flutter imports and `package:macos_ui/macos_ui.dart`.
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

This test runs Flutter controls, not AppKit. Passing it does not establish native,
minimum/current SDK or other-platform support. See [support](../../../docs/support.md).

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
Native observations and their limits are summarised in [support](../../../docs/support.md);
no new native runtime claim follows from recompiling.

Before adapting copied code, retain [MIT notices/provenance](../../../NOTICE.md)
and read [migration](../../../docs/migration.md) for the behaviour you change.
Do not replace macOS controls with unrelated Material/iOS UI, make ordinary users
select a renderer, invent constructors or expose private imports to solve a compile
error. Inspect the actual public source and use the appropriate existing control.

## Independently generated consumer tasks

[Complete consumer](../../../example/lib/consumer_evaluation.dart) is another complete
entrypoint (`flutter run -d macos -t lib/consumer_evaluation.dart` from example/).
It combines controlled hierarchical navigation, toolbar search entry/overflow,
retained session settings, a repaired public table/indicators and bounded shared
native/fallback commands. A custom preview overlay coordinates nativeOccluded,
blocks underlying semantics and restores its requesting Flutter control's focus.
The retained hidden command panel excludes focus, hits, semantics and tickers.

The [interaction tests](../../../example/test/consumer_evaluation_test.dart) cover
these flows. Native transport simulation verifies descriptors, actions and
occlusion routing; it does not create AppKit views or extend runtime acceptance.
