# Contributing

Use the public package import in examples. Keep Flutter widgets, semantic tokens,
platform adaptation and native integration separate. Preserve upstream APIs and
interaction contracts; a behavior change needs a demonstrated issue, regression
coverage and migration notes. Preserve MIT notices and upstream attribution.

## Verify changes

Record Flutter/Dart, macOS and Xcode/SDK versions. From the repository root:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test --reporter expanded
```

Then from `example/`:

```sh
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter build macos --debug
```

Run focused tests while editing; repeat affected checks after material changes.
Do not weaken assertions, skip failures or regenerate goldens merely to pass.
New native changes also need Swift format lint, an actual native build and
appropriate runtime input/lifecycle checks. Use public AppKit APIs, main-thread
view operations, availability guards and explicit observer/view disposal.
Existing window configuration/delegates belong to macos_window_utils.

Check keyboard/pointer/semantics, hidden/disabled focus, text scaling, constrained
layouts and live preferences for affected components. Custom overlays must
coordinate `nativeOccluded`. Keep native observations distinct from Flutter widget
tests and goldens; neither AX inspection nor injected MediaQuery values establishes
VoiceOver or real system-preference acceptance.

Use isolated SDK copies for compatibility checks. Do not infer support from
minimum declarations or a deployment target. Record exact build/runtime scope
and report known failures; [support](docs/support.md) lists outstanding acceptance.
