---
name: flutter-macos-golden-gate
description: Build or repair macOS Flutter consumers of this repository's local macos_ui fork, including its shell, controls and native Liquid Glass surfaces. Use for this library's API selection, composition, migration and fallback diagnosis; not generic Flutter, iOS glass or unrelated glass packages.
---

# Flutter macOS Golden Gate

Use the consumer's actual dependency source. This is `macos_ui` 0.9.0-dev.1,
a fork with its own pre-1.0 sequence; registry upstream releases lack its additions.
Inspect pubspec/lock/package configuration and resolved public source. Do not
substitute a registry dependency for this Git or local path dependency.

Read the relevant part of [the versioned API dictionary](references/api-v1.md)
for names, constructor requirements, callbacks and component selection. It links
to actual public source and owning guides; it is a selected dictionary, not every
optional styling parameter. Check the constructor before adding other arguments.

Use `package:macos_ui/macos_ui.dart` plus Flutter public imports. Preserve
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
[verification guidance](../../CONTRIBUTING.md) retain unresolved gates; do not infer
minimum/current stable, cross-platform, fidelity or performance certification.
