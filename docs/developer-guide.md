# Getting started

Import `package:macos_ui/macos_ui.dart` plus Flutter public widget libraries.
The package does not re-export Flutter widgets. Use actual exported constructors;
private `src/` imports are for implementation, never consumer code.
The optional [consumer skill](../skills/flutter-macos-golden-gate/SKILL.md) and
[selected API dictionary](../skills/flutter-macos-golden-gate/references/api-v1.md)
help choose verified APIs. [Support](support.md) describes provisional coverage.

## Install and configure a macOS host

Use a Git dependency in your Flutter application:

```yaml
dependencies:
  flutter:
    sdk: flutter
  macos_ui:
    git:
      url: https://github.com/jatatech/macos_liquid_glass_flutter_ui.git
      ref: main
```

Run `flutter pub get` and keep your app lockfile. Pin a reviewed commit SHA
instead of `main` when you need a fixed source revision. A local path dependency
is also supported if you keep a checkout available at that path.
This local fork is version 0.9.0-dev.1; it has its own pre-1.0 sequence after
upstream adoption, and registry upstream versions do not contain these additions. Retain app lockfiles; when changing SDK, resolve again in an
isolated copy rather than treating an SDK-specific lockfile as minimum support.
See [provisional SDK support](architecture/compatibility-policy.md).

Use a generated Flutter macOS host and retain its plugin registration:
[MainFlutterWindow.swift](../example/macos/Runner/MainFlutterWindow.swift) calls
`RegisterGeneratedPlugins(registry: flutterViewController)`. Preserve Flutter's
AppDelegate integration. Configure the app target's macOS deployment target to
at least 12.0 to match the plugin's CocoaPods and SwiftPM declarations; this
build floor does not certify runtime support. Compiling native glass requires an
SDK with `NSGlassEffectView` (macOS 26+) and the compiler required by that SDK;
the recorded successful host uses Xcode/SDK 27.2. Runtime availability guards
select fallback on older systems; older-runtime verification remains open.

Apply `const MacosWindowUtilsConfig().apply()` once at macOS startup before
`runApp`, as in the runnable example below. It initializes Flutter bindings and
`WindowManipulator`, configures titlebar/toolbar/full-size content and owns the
existing window delegate path. Do not add a competing delegate or call this on
portable hosts without the platform guard. The utility's windowBackground
visual-effect material is distinct from the package's native Liquid Glass.
The gallery sets a 480×400 minimum window; it is an app choice, not a package
requirement or a promise that every component fits at that width.

## Run a complete application

For the photo-library app shown in the README, follow [Fieldnotes](examples.md).
It includes bundled photography and uses a native window toolbar, controlled
search, coordinated panes and a floating viewer command surface.

## Runnable consumer example

[developer_example.dart](../example/lib/developer_example.dart) is a complete
public-import example, rather than a collection of fragments. From `example/`:

```sh
flutter run -d macos -t lib/developer_example.dart
```

It composes `MacosApp` → `MacosWindow`/`Sidebar` → `MacosScaffold`/`ToolBar` →
`ContentArea`. Documents uses a bounded `MacosDataTable` with stable row IDs and
controlled selection; Settings uses controlled checkboxes and a retained opaque
preference. Its shared `MacosGlassSurface` provides equivalent AppKit descriptors
and Flutter fallback controls. Selection/settings live in the app State, with no
filesystem persistence. The builder's borrowed scroll controller belongs to
`ContentArea`; consumers must not dispose it. The example's widget test verifies
selection, retained settings, navigation and disposal; it does not run AppKit.
This minimal example is not an additional native visual acceptance capture.

For real visible glass over changing covers, use the primary gallery:
[main.dart](../example/lib/main.dart), [liquid_glass.dart](../example/lib/liquid_glass.dart).
For a floating command wrapper, use `MacosGlassCommandSurface` as that page does:
it delegates rendering to the same shared surface, accepts one to four commands
and requires a bounded width/height. Reserve document bottom padding so commands
do not cover content. For working document filter/sort/inspect/session Save-Revert,
see [dense_content.dart](../example/lib/dense_content.dart) and
[document_inspector.dart](../example/lib/document_inspector.dart). For export
settings/progress/validation, see the Sliders and selectors/Text and search pages
in `main.dart`. [Gallery instructions](../example/README.md) identify each flow.

## Choose public APIs

For a native window toolbar, search, groups and pane coordination, use
[MacosNativeToolbar](native-window-toolbar.md). Retain one owner above navigation,
share the pane controller with MacosWindow, and provide equivalent fallback
controls. App menus and native Edit routing remain app-owned.


| Need | Public entry points and owning guide |
|---|---|
| Application, theme, semantic styling and preferences | `MacosApp`, `MacosTheme`, `MacosThemeData`, `MacosChromeData`, `MacosAccessibility`; [foundations](shell-foundations.md) |
| Window, panes, hierarchy and commands | `MacosWindow`, `MacosScaffold`, `ContentArea`, `ResizablePane`, `Sidebar`, `SidebarItems`, `SidebarItem`, `ToolBar`; [navigation](shell-navigation.md) |
| Shared glass / floating command glass | `MacosGlassSurface`, `MacosGlassCommandSurface`, `MacosGlassCommand`, `MacosGlassRendering`, `MacosGlassData`; [composition](liquid-glass.md) |
| Buttons | `PushButton`, `MacosIconButton`, `MacosDisclosureButton`, `HelpButton`; [buttons](foundational-buttons.md) |
| Controlled choices | `MacosSwitch`, `MacosCheckbox`, `MacosRadioButton`, `MacosSegmentedControl`; [value controls](value-controls.md) |
| Editing/search | `MacosTextField`, `MacosSearchField`, `SearchResultItem`; [fields](text-fields.md) |
| Range, progress and native colour panel | `MacosSlider`, `ProgressBar`, `ProgressCircle`, `MacosColorWell`, `MacosDatePicker`, `MacosTimePicker`; [selectors](sliders-progress-selectors.md) |
| Lists, tabs and scrolling | `MacosListTile`, `MacosTabView`, `MacosTabController`, `MacosScrollbar`; [content](lists-tabs-scrollbars.md) |
| Flat document data | `MacosDataTable`, `MacosTableColumn`, `MacosTableRow`; [table limits](data-table.md) |
| Ratings, capacity and labels | `RatingIndicator`, `CapacityIndicator`, `Label`; [indicators](indicators-content.md) |
| Menus, sheets, alerts and hints | `MacosPulldownButton`, `MacosPopupButton`, `MacosSheet`, `MacosAlertDialog`, `MacosTooltip`; [transient surfaces](transient-surfaces.md) |

These are entry points, not a replacement signature dictionary. Check the linked
guide/source for required parameters. `Label` is the actual name, not
`MacosLabel`; the legacy `RelevanceIndicator` remains deprecated. The table is a
0–200-row flat text view, not an editable grid or data outline. Flutter's
`TimeOfDay` comes from `package:flutter/material.dart`; `ThemeMode` also remains
a Flutter API. Native utility APIs are existing public dependency re-exports.

## Compose glass and accessible content

`MacosGlassSurface.child` is always Flutter content. Without `nativeCommands`, it
can receive the Flutter approximation, including on macOS with available permitted
preferences. Native descriptors replace the entire child when AppKit is active;
they never host arbitrary Flutter widgets. Supply equivalent labelled actions
in both representations. `onRenderingChanged` distinguishes native,
approximation and opaque; do not use renderer diagnostics as an ordinary user
setup step. `forceOpaque` is available for explicit compatibility needs.

Native hosting is bounded and translation-only, with limited supported clipping.
Custom `OverlayEntry` visuals must set `nativeOccluded: true` until removed.
Package-owned menus/dialogs/tooltips coordinate coverage; arbitrary overlay
ordering cannot be inferred from pointer probes. Do not assume AppKit siblings
inherit Flutter clipping or transforms. The integration is single-registrar;
there is no multi-window promise. See [complete ownership contract](liquid-glass.md).

Reduce Transparency/Increase Contrast select opaque; Reduce Motion suppresses
decorative motion. Explicit light/dark cannot suppress accessibility policy.
Use semantic colours/metrics from `MacosTheme`/`MacosChromeData`, meaningful control
labels, readable opaque documents, finite table sizes and sufficient wrapping at
large text. Keep hidden mounted controls out of focus, hits and semantics.
Caller-supplied controllers/focus nodes remain caller-owned; dispose app-owned
resources and custom overlays when removing their owner. Do not dispose borrowed
builder controllers. Native failures/missing plugins retain safe Flutter controls.

Local gallery contrast/motion/text previews and target-platform widget tests are
policy evidence; they are not actual live OS preference, VoiceOver, IME or
cross-platform acceptance. Native glass requires macOS 26+ and working transport;
older macOS/plugin failure uses opaque. Portable hosts can choose the labelled
approximation, but their builds/runtimes remain unverified. No native fidelity or
performance equivalence is claimed. [Migration](migration.md),
[support evidence](architecture/compatibility-policy.md) and the
[contributor checks](../CONTRIBUTING.md) describe the remaining gates.
