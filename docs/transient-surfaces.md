# Menus and transient surfaces

Import `package:macos_ui/macos_ui.dart`. These Navigator-hosted Flutter surfaces
provide opaque menus, dialogs, sheets and tooltips. `MacosSheet` is not an AppKit
window-attached sheet. `ToolbarPopup` provides anchored content; there is no
standalone native popover, context-menu or native menu-bar API. Existing utilities
own window integration. See [glass overlay coordination](liquid-glass.md) when
composing custom overlays with native controls.

## Commands and anchored content

`MacosPulldownButton(title: 'Document actions', items: [...])` accepts the existing
`MacosPulldownMenuItem` / divider entries. Null or empty items disable the trigger;
`enabled: false` disables an item. An enabled item with no callback still dismisses
its menu, retaining the upstream contract. Caller focus nodes remain caller-owned,
and can be replaced without dangling listeners. `autofocus`, title/icon,
disabledTitle, directional alignment and menuAlignment remain supported.

Enter/Space activates on key release once; Down also opens the trigger. Up/Down
wrap through enabled entries, Home/End reach the ends, and Tab traverses within
the modal route. Focus scrolls long menus into view. Primary click activates;
secondary click, canceled pointer presses and repeated key-down events do not
invoke commands. Escape or an outside click dismisses without invoking a command.
Normal dismissal returns focus to the trigger. Restoration checks that the source
route is current so a command opening a dialog cannot steal focus behind it.

Menus reuse the toolbar command traversal implementation. Rows grow with scaled
or wrapped text; itemHeight is a minimum, rather than clipping a line into a
fixed height. Placement uses the measured child and stays within the viewport in
LTR/RTL. Default surfaces, state overlays and outlines use semantic chrome roles.
Explicit text styling and theme backgrounds/highlights/icon colours are retained;
partial themes have fallbacks. Pulldown colour alpha is made opaque for readable
content. Contrast uses semantic selection/focus roles. The caret repaints on live
colour changes. Menus open/close without a fade, avoiding interactive invisible
route tails and respecting Reduce Motion without another animation owner.

`ToolBarPullDownButton` continues using the same trigger and existing overflow
submenu. Its label is exposed independently of tooltips. Overflow submenus open
with the physical forward arrow (Right in LTR, Left in RTL), click or Enter/Space;
the reverse arrow and Escape return to the parent menu. Choosing a leaf closes
that submenu before its callback and leaves its parent menu available. The old
extra pop after the callback could accidentally close a newly opened dialog;
it has been removed. Focus-ring geometry stays stable when a submenu takes focus.

`ToolbarPopup<T>` retains its public `GlobalKey<ToolbarPopupState<T>>`, `openPopup`,
`isOpen`, `removeToolbarPopupRoute`, placement, position and offsets. Supply an
accessible trigger and a bounded content builder. `ToolbarOverflowMenu` is useful
for traversable content/commands, as shown in the gallery. Duplicate openings are
ignored. Escape/outside click dismiss; removal targets the owned route, even if
another modal is above it. The popup never pops an unrelated route. Caller content
continues to own its data and any application-level duplicate-operation guards.

Open pulldowns/toolbars retain immutable anchor/theme snapshots. Trigger movement
or size changes during scrolling/layout, Offstage/zero-opacity ancestors, native
window metrics changes, removal and relevant live theme/media changes dismiss
rather than leaving a stale anchor. The anchor watcher observes frames the app
already requests; it does not schedule animation frames or poll on a timer.
Selection popups also gain geometry invalidation while retaining their established
selection contract. Disable/hide owned controls with focus exclusion or remove
them; arbitrary external overlays are not a general visibility notification API.

## Alerts and sheets

Call `showMacosAlertDialog<T>` / `showMacosSheet<T>` with a builder, then close
through that builder's context: `Navigator.of(dialogContext).pop(result)`.
The gallery demonstrates typed confirmation/cancellation and a review sheet with
an editable note. Using the route's context matters with nested Navigators;
`useRootNavigator` retains its default `true` and can be set to `false`.

The shared route captures local inherited themes, labels its scope, uses safe
areas, initially takes focus without adding an empty Tab stop, and closes the
Tab traversal loop. Pop restores the Navigator's prior eligible focus. Escape is
an explicit cancel even when `barrierDismissible` is false; `PopScope` can veto
that cancellation. Only an enabled dismissible barrier responds to outside click.
Programmatic pop results, routeSettings, barrierLabel and selected Navigator are
preserved. Explicit barrierColor now preserves its alpha instead of being
silently replaced with 0.6; only the default scrim uses 0.6.

Alerts scroll long content and stack actions at larger text scales. A nullable
horizontalActions now treats null as the documented horizontal default, with
scaled-text adaptation. Sheets scroll long content, align near the top and bound
default insets in small windows. Both use opaque semantic surfaces and live
contrast outlines; explicit sheet backgroundColor remains effective. Modal
transitions use a short fade instead of the inherited duplicated bounce spring.
Live Reduce Motion removes visual fading and inset animation. Reversing or
covered modal content excludes focus, hit testing and semantics immediately;
the fading visual cannot be activated twice.

## Tooltips

`MacosTooltip` retains message, child, excludeFromSemantics and useMousePosition.
Hover and long-press show a non-interactive overlay; it never takes focus or
consumes keyboard shortcuts. Pointer exit, clicks, scrolling, keyboard input
(including Escape), anchor invalidation, live theme/media changes and disposal
remove it. Theme/message changes dismiss the snapshot; the next hover captures
the latest style. Partial tooltip themes fill defaults. Increased contrast uses
an opaque outlined surface, and reduced motion removes fading. Explicit styles
remain effective under standard contrast. `excludeFromSemantics` suppresses both
the trigger label and tooltip announcement; the visual overlay never duplicates
the semantic label. Timers, pointer/mouse/keyboard and
metrics listeners, overlay entries and animation controllers are disposed.
