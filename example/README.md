# Production gallery

Library version **0.9.0-dev.1**, gallery app `0.9.0+1`. See
[support and known limitations](../docs/support.md) for tested scope and open acceptance.

Start with the [developer guide](../docs/developer-guide.md) for local installation
and macOS plugin/host setup. The compact public-import consumer is
[developer_example.dart](lib/developer_example.dart): run
`flutter run -d macos -t lib/developer_example.dart` here. Its document selection,
settings and shared-surface fallback compile in an executable widget test; the
main gallery below owns actual native glass evidence.

Run `flutter pub get` and `flutter run -d macos` here after resolving the root package. Uses only the local package's public import. See the root README and [support policy](../docs/architecture/compatibility-policy.md) for current behaviour and limitations.

The macOS host is a fresh Flutter template with a 12.0 deployment target and 480×400 minimum window size. Window configuration uses `MacosWindowUtilsConfig`; production native glass is provided by the package.

The gallery uses `MacosChromeData` for opaque shell surfaces/metrics and shows live
`MacosAccessibility` settings on the shell page. Tab reaches icon commands;
Enter/Space activate them. macOS View menu commands retain ⌥⌘S and ⌥⌘L.
The colour page displays semantic shell roles. See
[foundations and remaining native acceptance](../docs/shell-foundations.md).

Navigation includes a nested Foundations/Appearance navigation tree with arrow/Home/End
navigation and safe collapse. Resize near 560 points to exercise command overflow;
the sidebar auto-hides at its inherited 556-point breakpoint. ⌥⌘1 shows the
application shell. View includes the native fullscreen command and disabled
Export Selection. Overflow menus support arrows, Enter/Space and Escape, wrapping
and scrolling. See [contracts and exact verification](../docs/shell-navigation.md).


The Buttons page demonstrates PushButton in every ControlSize, secondary/disabled
and long-label actions, named MacosIconButton commands, controlled
MacosDisclosureButton details and contextual HelpButton actions. Tab/Enter/Space,
hover/press, appearance and live accessibility changes use the production controls.
See [button contracts and compatibility](../docs/foundational-buttons.md).

Value controls demonstrates controlled sync switches in mini/small/regular sizes,
mixed attachments, enabled/disabled radios inside Flutter RadioGroup and a
controller-backed document-view segmented control. Labels wrap at 200% text;
arrow navigation is group/direction aware. See
[value ownership, keyboard and compatibility](../docs/value-controls.md).

Text and search demonstrates document-name validation/save, a selectable read-only
reference, a disabled managed folder and document suggestions with keyboard/clear/
submission feedback. See [field contracts](../docs/text-fields.md).

Sliders and selectors demonstrates controlled volume/quality, popup choice,
native highlight colour, date/time scheduling, disabled controls and named
progress. See [contracts and compatibility](../docs/sliders-progress-selectors.md).

Documents demonstrates 120 working files and 24 archived documents with controlled
row selection, per-tab inspection summaries/scroll positions, keyboard focus and
page scrolling, persistent draggable scrollbars and scaled dense rows. See
[list/tab/scrollbar contracts](../docs/lists-tabs-scrollbars.md).

**Menus and dialogs** demonstrates a document review sheet, archive confirmation,
anchored details and tooltip using public imports. Escape cancels, commands return
results, and the status reports changes. These are opaque Flutter surfaces.

The **Liquid Glass** page (also **Open Liquid Glass** on Application shell)
compiles both `MacosGlassSurface` navigation and `MacosGlassCommandSurface`
actions over scrolling covers or dense Notes. The shared layer automatically
chooses actual native glass, Flutter approximation or opaque fallback. Gallery
renderer diagnostics are for verification. Compare opaque, switch appearance with
⌥⌘L, use Focus commands then Tab/Return, and test local contrast/motion/text
scaling or modal coverage. App shortcuts remain app-owned; there are no automatic
command-number shortcuts. Other platform runtimes remain unverified. See
[composition, migration and release gates](../docs/liquid-glass.md).

The **Document inspector** page adds controlled editorial rating/offline allocation,
read-only capacity/relevance and long document labels. It includes local read-only,
contrast, reduced-effects, 2x text and RTL previews. See
[contracts and migration](../docs/indicators-content.md). The existing Liquid Glass
page and its native/portable/opaque distinctions remain available.

Documents now uses the public `MacosDataTable` for aligned title/author/modified/size
columns, title/date sorting, single selection and metadata inspection, with retained
Working files/Archive state. See [table contract](../docs/data-table.md).

Integrated entry points: **Documents** → filter by title/author → select a row
(or Up/Down/Home/End, Enter) → **Inspect selected document**. Empty filters show
zero results; clear the field to recover. Working files and Archive retain their
own filter/sort/selection; secondary click previews metadata without selecting.
The inspector command requires a selection and opens a named document. Its
archive variant is read only, even with the local edit preview enabled.

In an open inspector, edit rating/allocation, then **Save metadata** or **Revert
metadata**. Live status explains unsaved/saved/reverted state; no filesystem or
network operation occurs. The draft belongs to that mounted inspector session;
closing/replacing it or leaving the page discards it. Local contrast, effects,
2× text and RTL controls remain available. Existing Text and search supplies
name validation/error recovery; Sliders and selectors supplies progress; Liquid
Glass supplies actual native navigation/commands, modal occlusion and opaque
comparison. These reuse existing flows rather than duplicating component demos.

All gallery sources import `package:macos_ui/macos_ui.dart`; executable entry is
`lib/main.dart`. `lib/dense_content.dart` contains controlled table/sort callbacks;
`lib/document_inspector.dart` contains draft commit/revert. Minimal public usage:

```dart
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

Widget documentTable(Object? selected, ValueChanged<Object> choose) =>
    MacosDataTable(
      columns: const [MacosTableColumn(label: 'Title', width: 240)],
      rows: const [MacosTableRow(id: 'brief', cells: ['Design brief'])],
      selectedId: selected,
      onSelectionChanged: choose,
    );
```

The template gallery SDK floor now matches the root Dart declaration; actual
resolution may require a newer SDK through dependencies. This is not minimum
version certification. See [support and verification scope](../docs/support.md).
