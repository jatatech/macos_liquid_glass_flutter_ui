# Foundational buttons

`PushButton`, `MacosIconButton`, `MacosDisclosureButton` and `HelpButton` use
Flutter controls alongside the [native glass capability](liquid-glass.md). Native window ownership, traffic lights and opaque
document content are unchanged. No native glass or new native channel is added.

## Public usage

Import `package:macos_ui/macos_ui.dart`. The gallery's Buttons page compiles all
four controls through this import, with every push control size, secondary and
disabled actions, long labels, icon commands, controlled disclosure and contextual
help. For example, inside a `MacosApp`:

```dart
PushButton(
  controlSize: ControlSize.regular,
  onPressed: saveDocument,
  child: const Text('Save document'),
)
MacosIconButton(
  semanticLabel: 'Add attachment',
  icon: const MacosIcon(CupertinoIcons.add),
  onPressed: addAttachment,
)
MacosDisclosureButton(
  semanticLabel: 'Attachment details',
  isPressed: detailsExpanded,
  onPressed: toggleDetails,
)
HelpButton(
  semanticLabel: 'Attachment help',
  onPressed: showAttachmentHelp,
)
```

Callbacks and disclosure state are consumer-owned. `isPressed` retains its
upstream meaning: true points up and now exposes expanded accessibility state.
It is not the transient held state. A null callback disables a control. Give icon
commands a meaningful `semanticLabel` or an accessible child. Help and disclosure
have fallback names, “Help” and “Show details”; supply labels for localisation and
context. Explicit semantic labels replace child names to avoid duplicate speech.

Tab traverses enabled controls in normal focus order. Enter, numpad Enter and
Space show press feedback while held and activate once on release; repeat events
do not repeat the action. Moving focus or disabling cancels a held key. Primary
pointer press focuses the control, cancellation resets feedback, and secondary
click does not invoke the action. Accessibility tap invokes the same callback.
Disabled controls retain named disabled semantics, but have no tap action or
keyboard focus. Existing ancestor focus/input/semantics exclusions still apply.

## Styling and compatibility

All constructors, defaults, callbacks, exports, control-size extensions and public
State class names remain. MIT attribution and the pinned upstream API inventory
are unchanged. The [consumer skill](../skills/flutter-macos-golden-gate/SKILL.md) is available; no speculative skill/API claim is added.
The shared interaction and opacity helpers are internal and are not exported.

Push buttons retain the upstream accent/secondary/window-state gradient palette
and minimum size metrics. Explicit `color`, `disabledColor`, `padding` and
`borderRadius` now affect rendering; previously these could be ignored or only
influence the foreground calculation. The constructor's default radius remains
4; passing null uses the size-specific radius. Long labels wrap and grow with
text scaling when the parent permits height. The deprecated `pressedOpacity`
and deprecated `PushButtonTheme` remain accepted and inactive, as upstream
documents; this delivery does not reactivate them. Explicit colours are the
supported solid-surface override.

Icon commands retain explicit background/hover/disabled colours, shape, radius,
constraints, padding, alignment and opacity options. Local icon themes continue
supplying background/hover/disabled colours and padding; a theme radius now fills
an omitted widget radius. Widget shape and constraints keep their constructor
precedence. Icons scale down inside the retained compact constraints. Consumers
own custom icon foregrounds and must choose colours suitable for their surfaces.
Help now resolves the nearest `HelpButtonTheme` as well as widget overrides;
its circular 20-point geometry and icon size remain. Disclosure retains its
20-point minimum, fill override and chevron direction. Null cursors safely use
the existing basic cursor.

All four controls expose hover, press, focus and disabled feedback. Focus rings
remain fully opaque outside fading content. `MacosChromeData` adds semantic
`controlHoverOverlay` and `controlPressedOverlay` roles; repeated surface state
literals are avoided. Live high contrast strengthens outlines, removes icon/help
press fading and uses solid high-contrast default push surfaces. Explicit surface
colours remain honoured, including disabled overrides. Help/push foregrounds
choose black or white using the composited background's contrast. Live Reduce
Motion immediately replaces in-flight icon/help fades with target opacity;
push/disclosure feedback is immediate. System appearance/accessibility policy
continues to come from `MacosApp`; no system settings are changed by controls.

Behaviour migration: newly keyboard-reachable buttons may change a consumer's
Tab order. Icon Enter/Space activation now occurs on release, consistently with
the family, rather than on key-down. Styling properties previously ignored now
render. Focus is released when disabled. Consumers should not depend on key
repeat activation, focus in disabled controls, ignored overrides or duplicate
child/explicit semantic labels. No constructor/import migration is needed.
