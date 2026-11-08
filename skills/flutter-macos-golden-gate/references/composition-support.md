# Composition, ownership and provisional support

Read [the complete glass contract](../../../docs/liquid-glass.md) when diagnosing
native composition; it owns the detailed visibility rules. Native Liquid Glass
uses public **NSGlassEffectView**, not NSVisualEffectView or captured Flutter
pixels. The production gallery demonstrates a bounded native sibling composition
over changing Flutter covers. Do not generalise that observation to every renderer
or arbitrary Flutter content hosting. Native, approximation and opaque selection
are implemented behaviors, with provisional runtime coverage described below.

| Situation | Expected rendering / consumer action |
|---|---|
| macOS 26+, working plugin/preferences, 1–4 permitted native commands and supported visible geometry | Native command descriptor replaces the **entire** Flutter child. Provide equivalent labelled fallback actions; null callbacks disable. |
| Arbitrary Flutter child, no native descriptor, available macOS preferences permit it | Labelled Flutter approximation, never arbitrary Flutter-child hosting in AppKit. |
| Older macOS, unavailable preference/native transport, failed native composition/focus | Safe opaque Flutter controls. A successful widget test cannot prove AppKit availability. |
| Portable host without native preference transport | Approximation policy is implemented; builds/runtimes are unverified. Missing transport here is not a Reduce Transparency preference. |
| forceOpaque, available Reduce Transparency/Increase Contrast, Flutter highContrast | Opaque. Explicit appearance does not override accessibility. Reduce Motion suppresses decoration/interactive feedback, not necessarily glass. |

For a native host, keep translation-only bounded geometry; supported rectangular
clips do not imply arbitrary clip/transform inheritance by an AppKit sibling.
Native mode also falls back for RTL, too-large labels, narrow regions and hidden
or covered owners. Custom visual `OverlayEntry` content must set
`nativeOccluded: true` until removed; pointer probes cannot prove arbitrary visual
occlusion. Package transients coordinate their own coverage. Avoid nested expensive
filters; the shared Flutter approximation suppresses inner blur automatically.
Documents/dense forms remain readable opaque content.

Tab/Shift-Tab enter/traverse/exit enabled native commands; Return/Space activate,
Escape exits backward. No global Command-Option-1…4 command bindings are installed.
Application shortcuts remain app-owned; optional supplied `focusNode` belongs to
the caller. That node targets native entry; it is not attached to the Flutter
fallback controls. For a custom overlay, retain the requesting Flutter control's
focus and restore it on cancellation; do not assume the native entry node can
restore focus in approximation/opaque mode. Native mode excludes fallback
controls from Flutter hits/focus/semantics.
Caller controllers/nodes/overlays retain caller disposal responsibility. Do not
dispose the ContentArea/Sidebar builder's borrowed scroll controller.

Retain generated plugin registration and existing `macos_window_utils` ownership;
apply `const MacosWindowUtilsConfig().apply()` once at guarded macOS startup, as in
[developer example](../../../example/lib/developer_example.dart). Do not install a
second window delegate, look up a main window as a multi-window solution, or change
system settings to make a demo work. This integration is single-registrar with no
multi-window promise. [Host setup](../../../docs/developer-guide.md) describes
macOS 12 build targets, the SDK containing NSGlassEffectView (macOS 26+) and retained
AppDelegate/plugin registration. Native utility visual-effect materials are separate.

## Diagnose the observed path

| Symptom | Targeted check |
|---|---|
| New API missing or version looks like upstream | Inspect resolved path/barrel/source revision; local fork is now 0.9.0-dev.1. Older local snapshots inherited 2.2.3; registry upstream lacks these additions. |
| Shared surface never native | Check descriptor presence, supported runtime/SDK/plugin/preferences, visible bounded geometry and onRenderingChanged. An ordinary child intentionally uses approximation. Do not hide accessibility fallback. |
| Glass overlays a custom popup | Coordinate nativeOccluded for its full visible lifetime, including non-interactive fade tails; remove overlay on owner disposal. |
| Duplicate focus/action targets | Ensure fallback controls disappear from native mode; do not add another bridge or global shortcut. Check hidden owner, failed focus entry and resource ownership. |
| Search list or text state behaves unexpectedly | Result selection is distinct from onChanged. Keep full editing value/composing region; Escape dismisses suggestions without clearing query. See field guide. |
| Capacity/rating updates more than once | Continuous duplicate/fractional proposals are the restored upstream contract. Do not deduplicate, quantise or wait for release without an explicit app requirement. App Save/Revert belongs in app state. |
| Layout overflow | Bound command/table viewports, allow wrapping at large text, use overflow builders and finite table sizes; do not overlay decorative chrome on document text. |

## What the recorded evidence establishes

[Compatibility policy](../../../docs/architecture/compatibility-policy.md) owns
the matrix; [CONTRIBUTING](../../../CONTRIBUTING.md) owns verification guidance.
Recorded primary: Flutter 3.44.4/ad70ec4617, Dart 3.12.2, engine a10d8ac38d;
macOS 27.2/26B123 arm64, Xcode 27.2/27B52, SDK 27.2. Isolated Flutter
3.41.6/db50e20168 / Dart 3.11.4 has scoped analysis/tests, not native runtime.
Neither installed SDK is evidence of current stable. Resolve current stable at
execution if that check is requested; the dated support record lists 3.47 family.

Declared Flutter >=3.35.0 / Dart >=3.9.2 remains **unverified**. Main resolved Dart
>=3.10.0-0 comes from installed SDK package metadata, not a demonstrated hosted
minimum defect. Do not silently raise bounds or change global toolchains. macOS
12 is a build floor; native glass requires 26+, but only recorded 27.2 arm64 was
exercised. Native source availability guards and target-platform simulations do
not certify old-runtime or other-platform support.

Open release gates: full VoiceOver/IME; actual live native transparency, contrast,
motion, appearance/accent; complete traffic lights/minimise/close/restore; minimum
and current stable SDK resolution/analysis/tests; macOS 26 and oldest intended
fallback runtime; other hosts/Intel/universal/release; controlled frame/GPU/resource
performance. Local AX inspection, MediaQuery previews, Flutter goldens and prior bounded mixed CPU smoke do not close them. No fidelity/performance equivalence or
support certification follows from this skill. Keep native captures separate from
deterministic Flutter goldens. See [support and known limitations](../../../docs/support.md) for remaining
runtime and performance coverage.
