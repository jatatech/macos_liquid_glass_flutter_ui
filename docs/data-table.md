# Dense text tables

Import `package:macos_liquid_glass_ui/macos_liquid_glass_ui.dart`. The additive `MacosDataTable`,
`MacosTableColumn` and `MacosTableRow` exports implement a bounded, flat text table.
The public-import [document browser](../example/lib/dense_content.dart) compares
120 working / 24 archived documents by title, author, modified date and size,
sorts title/date, retains each tab's state, and displays selected metadata below.
Primary selection and Enter inspect; secondary click previews metadata without
changing selection. Shared native glass/portable approximation remains on the
Liquid Glass page; dense table cells stay opaque.

## Decision and limits

Flutter `Table` offers aligned intrinsic/fixed columns but eagerly lays out rows
and supplies neither a selection model nor a scrolling/focus contract. A sliver
list supplies lazy fixed-extent rows, but needs shared column widths and a header.
`MacosListTile` remains a useful independent list action; composing many separately
focused tiles would add one Tab stop per mounted row and keep table navigation in
every consumer. `SidebarItems` expresses navigation hierarchy, not metadata cells.

Use Flutter `ListView.builder` under a fixed header, sharing explicit column
widths within one horizontal `SingleChildScrollView`. One body focus target owns
row keys; sortable headings have ordinary button focus. Both scroll controllers
and body focus node belong to the table State, survive rebuilds and dispose on
removal. There is no external controller parameter and no native code/dependency.
This is the smallest contract needed for the document flow, not an editable grid,
multiselection system, arbitrary cell-widget layout or general data framework.

Supported scope: 0–200 in-memory rows, nonempty columns, one plain-text cell per
column, finite positive column widths, unique stable non-null row IDs. Debug
assertions catch invalid data. Pass immutable snapshots/rebuild after changes;
do not mutate supplied lists while mounted. Consumers handle paging/filtering
outside the table. Larger datasets, column resizing/reordering, editing, pinned
columns, range selection and row hierarchies require a separately justified
extension. Lazy mounting is not a throughput/performance certification.

Supply finite width and height, enough for a header, a row and the horizontal
scrollbar (at least `80 * max(1, textScale) + 16` logical pixels). Column widths
are minimum logical widths at 1x text, multiplied by the effective 14-point text
scale (never shrunk below 1x). Spare width goes to the first column. Narrow views
scroll horizontally; header and rows stay aligned, including RTL. Scrollbars are
persistent/draggable. Standard scroll gestures and Flutter horizontal scroll
keyboard actions remain available. The header stays visible on vertical scroll.
Cells use one line/ellipsis; full labelled values stay in each row's semantics and
the gallery's wrapping inspection text. Date/size formatting, alignment conventions
beyond leading text, and localisation belong to the consumer.

## Controlled identity, selection and sorting

```dart
MacosDataTable(
  columns: const [
    MacosTableColumn(label: 'Title', width: 240, sortable: true),
    MacosTableColumn(label: 'Modified', width: 160, sortable: true),
  ],
  rows: const [
    MacosTableRow(id: 'brief', cells: ['Design brief', '2026-11-08']),
  ],
  selectedId: selectedDocumentId,
  onSelectionChanged: (id) => setState(() => selectedDocumentId = id),
  sortColumnIndex: sortColumn,
  sortAscending: ascending,
  onSort: (column, up) => setState(() {
    sortColumn = column;
    ascending = up;
    // Rebuild rows in the proposed order, with unchanged IDs.
  }),
)
```

This is a State.build fragment; the complete compiling owner is in the gallery.
Selection/sort callbacks propose changes only; the owner must accept and rebuild.
Sorting never mutates supplied data. Initial sort of a new column proposes
ascending; the current column toggles direction. A sort callback alone does not
mark a column sortable. The gallery breaks equal values by stable ID.

Up/Down select adjacent enabled rows; Home/End select enabled endpoints;
Page Up/Down move by the visible row count, skipping disabled rows. Accepted
external or keyboard selection is revealed vertically after layout, including
reordering and text scaling, without stealing keyboard focus. Scrolling uses jumps
without decorative motion. Enter/Space activate the enabled selected row once on
key down via optional `onActivate`; key repeats do not activate. Command/Control/
Option modified keys are left to the application. Tab/Shift-Tab enter/leave the
body instead of traversing every row. Pointer selection requests body focus.
Secondary pointer invokes only optional `onSecondaryTap(id, details)` on secondary
down; it does not select or activate. Primary cancellation does not commit.

A missing selected ID renders no selected row and emits no unsolicited callback.
The next navigation key starts at the relevant enabled endpoint; the owner decides
whether to clear its stale ID. Disabled rows retain readable metadata/disabled
semantics and can remain externally selected; pointer, keys, semantic activation
and secondary actions cannot activate them. Row semantics combine every column
label/value and selection/enabled state. Headings expose header/sort direction and
button actions when sortable. These are labelled rows, not a certified platform
accessibility grid; full VoiceOver acceptance remains open.

The default empty child is static text; `empty` belongs to the caller. For loading
or error, replace the whole table with labelled progress/error/retry content and
keep model state in the owner. Removal disposes the table's view/controller state;
no hidden interactive rows remain. See the inspector/gallery primitives for
progress and retry controls. No asynchronous data fetching or error inference is
built into this table.

## Appearance, outline disposition and compatibility

Live semantic canvas/foreground/selection/hover/pressed/focus/separator roles follow
MacosTheme and high contrast. Selected text uses a contrasting foreground.
Disabled rows suppress interaction feedback. There is no transparency or animation
to override accessibility preferences. No inherited widget behaviour or constructor
changes; migration from the example's former tile list is opt-in for consumers.
List and Sidebar APIs remain valid. Historical inventory hashes are untouched;
the [consumer skill](../skills/flutter-macos-golden-gate/SKILL.md) covers current usage.

The Documents page has flat files and category tabs. It does not need expandable
rows with aligned metadata. Existing `SidebarItems`/`SidebarItem.disclosureItems` suffice
for category navigation; this is navigation hierarchy only. A future requirement
to expand folders/projects **inside the same sortable multicolumn data viewport**,
with stable parent/child IDs, disclosure, hierarchical selection and lazy children,
would justify a separate data-outline design. No complete outline API is claimed.

[support and verification scope](../docs/support.md) records verification and native smoke.
Minimum/current intended Flutter and native-glass/fallback macOS compatibility
remain subject to [compatibility policy](architecture/compatibility-policy.md).
This additive slice does not narrow declared bounds or close LG release gates.
