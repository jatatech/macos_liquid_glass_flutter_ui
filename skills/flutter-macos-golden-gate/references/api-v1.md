# API dictionary v1 — local consumer baseline

Package identity: `macos_ui` 0.9.0-dev.1. Inspect the actual resolved source
for the API revision used by your application. Registry upstream releases differ.
All entries below are exported by [the public barrel](../../../lib/macos_ui.dart).
Links into `lib/src` are for inspecting definitions, **never consumer imports**.
Selected argument lists below name required parameters and useful defaults; they
are not full signatures. Follow the source link for parameter types and all options.

## Shell, theme and navigation

| API / source | Constructor and behaviour to retain |
|---|---|
| [MacosApp](../../../lib/src/macos_app.dart) | No required arguments; `home`, `theme`, `darkTheme`, `themeMode`, `shortcuts`, `actions` are optional; `title=''`, `debugShowCheckedModeBanner=true`. Owns the live accessibility adapter. |
| [MacosTheme / MacosThemeData](../../../lib/src/theme/macos_theme.dart) | `MacosTheme(data: ..., child: ...)` requires both; use `MacosTheme.of(context)`, `MacosThemeData.light()` / `.dark()` and existing component themes. |
| [MacosChromeData](../../../lib/src/theme/chrome.dart) | `MacosChromeData.of(context)` resolves semantic surfaces, foregrounds, focus/selection/state roles; use `contentInset`, `gap`, sidebar metric constants instead of repeated styling literals. |
| [MacosAccessibility](../../../lib/src/platform/accessibility.dart) | `MacosAccessibility.of(context)` provides `available`, `reduceTransparency`, `increaseContrast`, `reduceMotion`; unavailable native preferences do not certify preferences are off. |
| [MacosWindow](../../../lib/src/layout/window.dart) | Optional `child`, `sidebar`, `endSidebar`, `titleBar`; `disableWallpaperTinting=false`. Wallpaper material is not native Liquid Glass. |
| [MacosScaffold](../../../lib/src/layout/scaffold.dart) | `children=const <Widget>[]`, optional **`toolBar`** (capital B); content goes in children, not an invented body parameter. |
| [ContentArea](../../../lib/src/layout/content_area.dart) | Required nullable `ScrollableWidgetBuilder? builder`; `minWidth=300`. Builder receives `(BuildContext, ScrollController)`. Borrow controller, do not dispose it. |
| [Sidebar](../../../lib/src/layout/sidebar/sidebar.dart) | Required `builder`, `minWidth`; `maxWidth=400`, nullable `startWidth`, `isResizable=true`, `dragClosed=true`, `windowBreakpoint=556`, `shownByDefault=true`. |
| [SidebarItems](../../../lib/src/layout/sidebar/sidebar_items.dart) | Required `List<SidebarItem> items`, `int currentIndex`, `ValueChanged<int> onChanged`; optional `scrollController`, `itemSize=SidebarItemSize.medium`. Controlled flattened **leaf** selection; focus alone does not select. |
| [SidebarItem](../../../lib/src/layout/sidebar/sidebar_item.dart) | Required Widget `label`; optional `leading`, `trailing`, `focusNode`, `semanticLabel`, `disclosureItems`; `expandDisclosureItems=false`, `section=false`. Navigation hierarchy is not a sortable data outline. |
| [ToolBar](../../../lib/src/layout/toolbar/toolbar.dart) | Optional `title`, `leading`, `List<ToolbarItem>? actions`; `automaticallyImplyLeading=true`, `centerTitle=false`, `enableBlur=false`. Blur does not enable NSGlassEffectView. |
| [ToolBarIconButton](../../../lib/src/buttons/toolbar/toolbar_icon_button.dart) | Required `label`, Widget `icon`, **`showLabel`**; optional `VoidCallback? onPressed` (null disables), `tooltipMessage`. |
| [ToolBarPullDownButton](../../../lib/src/buttons/toolbar/toolbar_pulldown_button.dart) | Required `label`, `icon`, `items`; optional `tooltipMessage`. Capitalisation differs from `MacosPulldownButton`. |
| [CustomToolbarItem](../../../lib/src/layout/toolbar/custom_toolbar_item.dart) | Required `WidgetBuilder inToolbarBuilder`; optional `inOverflowedBuilder`, `tooltipMessage`. Supply equivalent overflow controls for custom commands. |
| [ToolbarOverflowButton](../../../lib/src/buttons/toolbar/toolbar_overflow_button.dart) | Required `overflowContentBuilder`; `isDense=false`. Prefer ToolBar's overflow rather than keeping hidden originals interactive. |

Read [shell foundations](../../../docs/shell-foundations.md) for semantic roles
and [navigation](../../../docs/shell-navigation.md) for recursive indices, keys,
resizing and overflow. Early milestone introductions describe historical opaque
work; [current glass guide](../../../docs/liquid-glass.md) supersedes that direction.

## Native and fallback surfaces

| API / source | Selected constructor contract |
|---|---|
| [MacosGlassCommand](../../../lib/src/glass/command_surface.dart) | `const MacosGlassCommand({required String label, VoidCallback? onPressed})`; null callback disables. |
| [MacosGlassSurface](../../../lib/src/glass/surface.dart) | Required Widget `child`; `List<MacosGlassCommand> nativeCommands=const []`, `forceOpaque=false`, `nativeOccluded=false`, optional caller `FocusNode? focusNode`, `ValueChanged<MacosGlassRendering>? onRenderingChanged`. Shared rendering/lifecycle/policy owner. |
| [MacosGlassCommandSurface](../../../lib/src/glass/command_surface.dart) | Required Widget `child` (document region), `commands` (1–4); same opaque/occlusion/focus/report options. Positions commands at bottom and delegates surface rendering. Bounded width **and** height, reserve document bottom padding. |
| [MacosGlassRendering](../../../lib/src/enums/glass_rendering.dart) | Actual modes: `native`, `approximation`, `opaque`. Exhaustive switches must handle all three. Initial assumed opaque need not emit a callback. |
| [MacosGlassData](../../../lib/src/theme/glass.dart) | Semantic effect tokens/command metrics; renderer selection belongs to the surface, not a parallel consumer bridge. |

Read [composition/support](composition-support.md) before composing native commands.

## Controls and content

| Need | Entry / selected required arguments and defaults | Owning guide |
|---|---|---|
| Action | [PushButton](../../../lib/src/buttons/push_button.dart): required `child`, `controlSize`; nullable `onPressed` disables. `MacosIconButton`, `MacosDisclosureButton`, `HelpButton` for icon/disclosure/help. | [Buttons](../../../docs/foundational-buttons.md) |
| Boolean or choice | [MacosCheckbox](../../../lib/src/buttons/checkbox.dart): required `bool value`, nullable `ValueChanged<bool>? onChanged`, `size=14`, optional `semanticLabel`. `MacosSwitch`, `MacosRadioButton`, `MacosSegmentedControl` for other controlled choices. Segments use `MacosTabController`, not native momentary/multiple-selection items; use `MacosTabView` for principal child views. | [Value controls](../../../docs/value-controls.md) |
| Text and search | [MacosSearchField](../../../lib/src/fields/search_field.dart): no required args; `maxResultsToShow=5`, `placeholder='Search'`, `enabled=true`; optional controller/focus, `ValueChanged<String>? onChanged/onSubmitted`, `List<SearchResultItem>? results`, `Function(SearchResultItem)? onResultSelected`. `SearchResultItem(String searchKey, {Widget? child, VoidCallback? onSelected})`. Use `MacosTextField` for general editing. | [Fields](../../../docs/text-fields.md): result selection fires item/field selection callbacks once each, **not onChanged**. Preserve IME composing value and caller resource ownership. |
| Range/progress/selectors | `MacosSlider`, `ProgressBar`, `ProgressCircle`, `MacosColorWell`, `MacosDatePicker`, `MacosTimePicker`. Date/time initial values are seeds, not controlled properties. | [Selectors](../../../docs/sliders-progress-selectors.md); inspect constructors for selected control. |
| Flat text records | [MacosDataTable](../../../lib/src/layout/data_table.dart): required `columns`, `rows`, `ValueChanged<Object> onSelectionChanged`; optional `Object? selectedId`, `int? sortColumnIndex`, `sortAscending=true`, `void Function(int,bool)? onSort`, `onActivate`, `onSecondaryTap`. `MacosTableColumn` requires `String label`, `double width`, `sortable=false`; `MacosTableRow` requires `Object id`, `List<String> cells`, `enabled=true`. | [Table](../../../docs/data-table.md): 0–200 rows, stable unique IDs, matching cell counts, finite viewport. App sorts/rebuilds and retains selection; not editable/multiselect/native grid. |
| Capacity | [CapacityIndicator](../../../lib/src/indicators/capacity_indicators.dart): required `double value` (0–100), optional `ValueChanged<double>? onChanged`, `discrete=false`, `splits=10`, `semanticLabel`. | [Indicators](../../../docs/indicators-content.md); pointer fractions retained even discrete, keyboard discrete step `100/splits`. |
| Rating | [RatingIndicator](../../../lib/src/indicators/rating_indicator.dart): required `double value` (0–amount), `amount=5`, `iconSize=16`, optional `ValueChanged<double>? onChanged`, `semanticLabel`. | [Indicators](../../../docs/indicators-content.md); positive fractions fill next symbol; pointer stays fractional, keyboard whole-symbol steps. |
| Labels/list/tab/scroll | `Label`, `MacosListTile`, `MacosTabView`, `MacosTab`, `MacosTabController`, `MacosScrollbar`. | [Indicators/content](../../../docs/indicators-content.md), [lists/tabs/scrollbars](../../../docs/lists-tabs-scrollbars.md): caller tab controller ownership, retained hidden page state with focus/hit/semantics excluded, unambiguous attached scroll controller. |
| Transient UI | `MacosPulldownButton`, `MacosPopupButton`, `MacosSheet`, `MacosAlertDialog`, `MacosTooltip`. Flutter menus/sheets are not invented AppKit menu/document-sheet abstractions. | [Transient surfaces](../../../docs/transient-surfaces.md): results, dismissal and focus restoration. |

Capacity/rating callbacks retain upstream down/start/every-update timing, including
equal proposals and controlled rebuilds; no final release callback or automatic
rollback. RelevanceIndicator is deprecated compatibility-only. Before migrating,
read [intentional repairs and restored defaults](../../../docs/migration.md).
Unexpanded family rows are routing aids, **not constructor or compilation claims**.

Typed native toolbar additions: `MacosNativeToolbar.items` accepts public
`MacosNativeToolbarCommandItem(command: ..., placement: ...)` and
`MacosNativeToolbarSearch(id: ..., label: ..., controller: ..., onChanged: ...)`;
`MacosNativeToolbarPlacement` is leading/content/trailing. `commands` must be empty
when typed items are supplied. Optional `MacosNativeToolbarController.focusSearch`
routes native Find; app focuses fallback on false. Full ownership and editing
limits: [contract](../../../docs/native-window-toolbar.md#typed-items-and-controlled-native-search).


pane coordination exports `MacosPaneLayoutController`/`MacosPaneLayout` for an opt-in one-window
shell geometry feed and `MacosNativeToolbarGroup`/`MacosNativeToolbarGroupMode` for
standard native momentary or controlled exclusive options. Existing Flutter
segments retain their MacosTabController contract. See [coordination/actions](../../../docs/native-window-toolbar.md#coordinated-panes-and-grouped-actions)
and the public-import standalone example for constructor use and fallback/menu
parity. Exclusive selectedId is required; null is required for momentary mode.
