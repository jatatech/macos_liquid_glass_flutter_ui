# Shared Liquid Glass surfaces

`MacosGlassSurface` shares rendering, semantic effects, accessibility/appearance
policy and native ownership. `MacosGlassCommandSurface` adds floating command
layout and equivalent Flutter controls for approximation/opaque fallback.
Native mode uses actual AppKit NSGlassEffectView on supported macOS.
Import `package:macos_ui/macos_ui.dart`. See [support](support.md) for tested scope
and [the consumer skill](../skills/flutter-macos-golden-gate/SKILL.md) for integration.

## Public composition and migration

The public-import [gallery](../example/lib/liquid_glass.dart) compiles both layers:

```dart
MacosGlassSurface(
  child: Padding(
    padding: const EdgeInsets.all(MacosChromeData.contentInset),
    child: Text('Collection summary'),
  ),
)
```

A shared surface decorates its bounded Flutter child with an approximation by
default, including on macOS when no native content descriptor is supplied. This
is **not** native hosting of arbitrary Flutter widgets. `nativeCommands` opts
into the existing AppKit command host (one to four concise commands) and replaces
the entire Flutter child when native is active. Supply equivalent Flutter controls
as `child` for fallback; the gallery navigation strip demonstrates this. The
AppKit descriptor supports labels, callbacks and enabled/disabled states; it does
not offer arbitrary native Flutter-child clipping, stacking or hosting. See the
single-window/translation/occlusion contract below. Width must be bounded; content
must have finite height. Shared surfaces do not position themselves.

```dart
MacosGlassCommandSurface(
  commands: [MacosGlassCommand(label: 'Next', onPressed: nextDocument)],
  child: documentList,
)
```

The command component positions a bounded surface at the bottom of a content
region; reserve bottom document padding. `forceOpaque` explicitly selects opaque
in both APIs. `nativeOccluded` coordinates custom overlays; `focusNode` is a
caller-owned native group entry node. `onRenderingChanged` reports transitions
from an initially assumed opaque state. Native content is removed from Flutter
hits/focus/semantics while AppKit is active; native labels and disabled state
come from AppKit. Rendering and geometry observers live in the shared surface;
the command wrapper adds no bridge or second rendering policy.

**Migration:** `MacosGlassRendering` adds `approximation`. Update exhaustive
switches. Existing command constructor arguments remain valid. Automatic rendering
on non-macOS now selects the Flutter approximation instead of opaque; retain
`forceOpaque: true` where a consumer needs the former appearance. No upstream
constructor or pinned historical API inventory hash changes. The shared surface
and effect policy are additive. No new dependency or window delegate is introduced.

| Environment/content | Automatic actual path |
|---|---|
| macOS 26+ with permitted, visible native command host and working plugin | native |
| macOS older OS, unavailable preferences/plugin or failed/unsupported native command composition | opaque |
| Arbitrary Flutter child without native descriptor, available macOS preferences allowing transparency | approximation |
| Other platforms / web, no native preference transport | approximation; absence of transport is not a transparency preference |
| Explicit opaque, available Reduce Transparency/Increase Contrast, or Flutter highContrast | opaque |

Only the local macOS 27.2 arm64 native runtime is exercised. The portable widget
implementation and target-policy tests do **not** certify Windows/Linux/iOS/
Android/web runtime support. These hosts are not configured/run in the gallery;
macos_window_utils and appkit_ui_element_colors remain native-only dependencies.
Package/gallery `dart:io` guards were replaced by `kIsWeb`/target-platform guards;
this audit does not establish dependencies' cross-platform runtime compatibility.
Other macOS, Intel, oldest-runtime and universal/release validation remain open.

The approximation uses semantic light/dark tint, edge and restrained highlight
with an 18-point sigma backdrop blur, clipped to each surface's rounded bounds.
Nested Flutter surfaces skip their inner blur instead of stacking filters.
Decoration is static; there is no decorative animation under reduced motion.
Native interactive feedback is disabled under reduced motion. Flutter's contrast
and motion flags apply everywhere; where a platform has no transparency signal,
consumers can use `forceOpaque`. Documents use readable opaque canvases. This is
an approximation, with no Apple fidelity or performance-equivalence claim.

The surface accepts optional caller-owned `focusNode` and `nativeOccluded` parameters.
No existing constructor argument was removed. **Migration:** automatic
Command-Option-1…4 bindings are removed because they collided with application
shortcuts. Tab/Shift-Tab now enter/traverse/exit the native group, skipping disabled
commands; Return/Space activate once; Escape exits backward to Flutter. Application
shortcuts remain application-owned. Consumers may use their existing Flutter
Shortcuts/Actions to request the supplied focus node or call command callbacks;
the package installs no global command shortcut. The gallery offers explicit
Focus commands entry. A failed/malformed/missing-plugin focus response removes
native hits and restores the opaque controls. Caller nodes are not disposed.

Native controls use NSGlassEffectView regular glass with NSButtons and semantic
`NSColor.labelColor` content tint, preserving standard control vibrancy rather
than overriding it.  Explicit Aqua/Dark
Aqua follows Flutter appearance. Interactive feedback on macOS 27+ is disabled
for reduced motion; native Liquid Glass requires macOS 26+. These are public
[NSGlassEffectView APIs](https://developer.apple.com/documentation/appkit/nsglasseffectview),
with semantic foreground colour consistent with Apple's
[AppKit vibrancy guidance](https://developer.apple.com/documentation/appkit/nsvisualeffectview).
This is actual native glass, distinct from classic visual-effect material or
Flutter blur. No shader, captured Flutter frame or duplicate native document view.

## Supported ownership and visibility contract

The adapter weakly references the actual registrar view and inserts glass as its
sibling above Flutter, in that same window. Existing macos_window_utils retains
window configuration/delegates. This uses single-view compatibility registrar
APIs; there is no multi-window support promise.

Translation and size changes are synchronized on frames the application already
requests, without driving an animation/frame loop. Route/metrics listeners remain
owned/disposed. No native view is reused across a different owner. Reparenting
reattaches to the actual Flutter parent. Window notifications are matched against
the current registrar window at notification time, fixing registration-before-
attachment. Close/minimize invalidates native views; deminiaturization notifies
registered owners even when their views have already been removed. No extra
window delegate, main-window lookup or engine lifetime ownership is introduced.

Offstage, partial/zero opacity, TickerMode, hidden/covered routes, IgnorePointer,
excluded semantics, non-translation transforms and oval/path ancestor clips select
the Flutter path. Rectangular clipping and pointer-blocking coverage are probed
at the bar's four inset corners and centre. Native action callbacks are rejected
while that anchor is hidden. Package tooltips suspend glass using counted overlay
ownership, including their non-interactive fade tails; disposal releases the
count. Menus/sheets/dialogs covering the owning route hide its glass.

**Custom OverlayEntry visuals must set `nativeOccluded: true` while present.**
Pointer probes cannot prove arbitrary visual occlusion (especially IgnorePointer
or a small overlay between probes), nor emulate arbitrary Flutter compositing.
Do not place this surface under unsupported clipping/transforms and assume the
native sibling inherits them. Translation-only, bounded regions and explicit
custom-overlay coordination are the supported contract. Arbitrary visual overlay
ordering is not claimed. Opaque fallback controls still obey Flutter's actual
clip, route, pointer, focus and semantics tree.

Dart serializes updates/removal per owner with at most one in-flight update and
one replaceable latest pending specification. Geometry changes coalesce before
dispatch; current hide/occlusion/fallback replaces unsent visible states. An
already dispatched update must finish before the latest state can be applied.
Stale replies cannot activate or fail a newer request, including an identical
specification retried after invalidation. Disposal drops unsent work and removes
the native owner after the in-flight update finishes. Dart ignores stale/malformed
actions and removes callback ownership before teardown. Native channels guard commands, finite geometry,
positive owner IDs, method names, unavailable OS/hierarchy and focus direction;
remove is idempotent. Missing plugin, cancellation and failed capability/focus
entry retain Flutter commands. Explicit invalidation clears capability failure
and schedules a fresh frame so a previously opaque owner can retry. Native
views/observers/closures are owned and disposed; no measured leak-count claim.

## Accessibility and observed acceptance

For native command hosts, unavailable macOS preference source/plugin/OS, Reduce
Transparency, Increase Contrast,
Flutter high contrast, RTL, text above 17 points for nominal 13-point labels and
regions narrower than 300 points select wrapping opaque commands. Explicit
light/dark never suppresses the app's accessibility bridge. Reduced motion retains
glass and disables interactive feedback. Native mode removes duplicate Flutter
controls from focus/hits/semantics; AppKit supplies native button labels/states.

The gallery's **Test contrast**, **Test reduced motion** and **Test large text**
controls inject local MediaQuery policy only. Compare opaque is a local forced
fallback, not a system preference test. They do not change system settings or
claim to exercise the native NSWorkspace notification source. Actual OS preference
changes against glass still require permission/human acceptance. Wire/policy
transitions are covered automatically. Local injected motion also makes document
selection jump rather than animate.

Real native glass has bounded light/dark, scrolling, pointer/keyboard and modal/
fullscreen observations on macOS 27.2 arm64. Full VoiceOver/real IME, actual live
OS preferences, complete lifecycle, other runtimes/architectures and controlled
performance acceptance remain open. [Support and known limitations](support.md)
records the distinction between these observations, widget simulations and
certified support. Multi-window hosting remains unsupported.
