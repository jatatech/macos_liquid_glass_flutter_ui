# Support and known limitations

Version **0.9.0-dev.1**, 2026-11-09. Usable pre-release with provisional support;
not a full accessibility, runtime or performance certification.

## Declared and observed scope

| Area | Scope |
|---|---|
| SDK declarations | Flutter >=3.35.0; Dart >=3.9.2 <4.0.0. Both must hold in the chosen bundle; minimum execution remains unverified. |
| Main verification environment | Flutter 3.44.4/ad70ec4617, Dart 3.12.2, macOS 27.2/26B123 arm64, Xcode 27.2/27B52, SDK 27.2. |
| Automated baseline | 353 library tests and 28 gallery/consumer tests passed at the implementation baseline; formatting/analysis clean. Public export verification is summarised below. |
| Alternate SDK | Isolated Flutter 3.41.6/Dart 3.11.4 has scoped component/consumer checks; this is neither minimum nor latest-stable certification. |
| Native runtime | Visible glass over changing content, pointer/keyboard actions, modal restoration, shell teardown/recreation, resize and fullscreen have bounded observations on the recorded arm64 host. |
| Builds | Debug and invocation-local arm64 Profile have successful baseline builds. Intel/universal and Release coverage remains open. |
| Deployment | macOS 12.0 build floor; native NSGlassEffectView requires 26+, interactive feedback guarded at 27. Older runtime execution is unverified. |
| Other platforms | Flutter approximation/policy simulations exist. Windows/Linux/mobile/web builds and runtimes are not certified; native dependencies may limit portability. |

Floating native hosting supports one registrar/window and one to four concise commands.
The separate [native window toolbar](native-window-toolbar.md) supports up to
20 typed items, controlled search, native groups, pane coordination and staged
Gregorian dates. It retains one toolbar owner and has no Flutter approximation mode.
It replaces equivalent Flutter controls; it does not host arbitrary Flutter
children. Translation/visibility/custom overlay limits are part of the
[glass contract](liquid-glass.md). Dense content remains opaque and readable.

## Outstanding acceptance

- Full VoiceOver traversal and actual IME composition across Flutter/native flows.
- Actual live Reduce Transparency, Increase Contrast, Reduce Motion, system
  appearance/accent notifications. Gallery previews do not pass these criteria.
- Complete traffic-light/minimise/close/restore/focus and surface lifecycle checks.
- macOS 26 native glass and oldest intended fallback-runtime execution.
- Executable minimum/current stable SDK checks with separately resolved locks.
- Release, Intel/universal and any intended other-platform build/runtime checks.
- Controlled representative frame/GPU/resource profiling. Existing mixed-session
  CPU/hitch observations are not a smoothness pass or an attributed component defect.

The native observations were automated app-region/accessibility-tree checks, not
a full user acceptance session. These are explicit evidence gaps; a passing widget
test does not close them.
Report issues with package commit, versions, environment, reproduction and expected/
actual result. Separate actual native observations from mock transport evidence.

## Known issues

- Rapid keyboard dropdown interaction can trigger the pinned Flutter framework's
  `_dropdownRoute == null` assertion. An independent framework-only reproduction
  exists; this has not been attributed to glass. Ordinary settled input passes
  the control. The issue remains unresolved; assertions have not been suppressed.
- Default universal Release/Profile builds have encountered framework unpack/lipo
  failures. Arm64 Debug/Profile success does not establish universal or Release
  delivery. Retry with a specific diagnosis or relevant toolchain change.
- SwiftPM reports a FlutterFramework manifest advisory with the recorded SDK;
  the recorded Debug build succeeds. This advisory remains disclosed.

The native update backlog is repaired with delayed-response regressions for
coalescing, hide/occlusion, invalidation and disposal. Those tests establish wire
ordering, not a guarantee against transport stalls: an already dispatched native
call must finish before a pending hide/removal can be sent.

## Current checkpoint verification

The initial public tree passed 353 library and 28 gallery tests, analysis,
formatting and a macOS Debug build before publication. The current checkpoint
adds native window-toolbar/search/pane/date and localization improvements, plus
Fieldnotes with bundled photography. Current export checks are recorded below;
these do not close outstanding operator or alternative-environment acceptance.

On 9 November 2026, the independently exported current checkpoint passed clean
analysis, **396 library tests and 42 example tests**, non-mutating formatting of
200 Dart files, and a macOS arm64 Debug build of `lib/showcase.dart` using the
main verification environment above. The two new showcase tests cover search
empty/recovery, filtered viewer navigation/Back, favourites and a constrained
200% text layout. Native Fieldnotes browsing/search, selection-following
inspection, photo navigation, favourite changes and light/dark appearance were
observed and recorded. Full operator/environment acceptance remains open.
The existing SwiftPM manifest advisory and always-run build-script warning remain;
the exported Debug build succeeds with those advisories.
