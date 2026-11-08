# Shell navigation and commands

The shell provides hierarchical navigation and toolbar overflow with semantic
Flutter chrome. Bounded native navigation/commands are also available through
[shared glass surfaces](liquid-glass.md). Existing window utilities retain ownership.

## Navigation contract

Import `package:macos_ui/macos_ui.dart`. Existing public widget types,
constructors, callbacks and exports remain intact. `SidebarItems.currentIndex` counts selectable leaves in
depth-first order, including collapsed leaves. Section headers and disclosure
parents do not consume indices. This retains flat and one-level indexing and
extends it consistently to nested disclosures. A header-only tree is allowed.

Up/Down move focus through visible interactive rows; Home/End reach the first/
last. Right expands a branch, then enters its first interactive child. Left
collapses an expanded branch or returns to its parent. Enter/Space activates a
leaf or toggles a branch; moving focus alone does not change selection. Tab
continues normal traversal. Focused rows scroll into view and show the existing
semantic focus ring. Primary click focuses and activates; secondary click does
not activate. Disclosure rows always show a chevron, including section headers.

Expanded and selected semantics reflect the actual state. Collapsing a focused
subtree returns focus to its parent. Children remain mounted, retaining their
state and nested expansion, but immediately lose input, focus and semantics
while closing. Reduced motion switches directly to the target height, including
when enabled during a transition. Rows/headers grow with text size; explicit
item/list colour and shape overrides remain honoured.

`expandDisclosureItems` seeds local state. Expansion is retained while mounted;
a `PageStorageKey` on `SidebarItems` additionally scopes restoration for that
list. Item positions identify expansion/focus state: recreate the list with a
new key if its hierarchy is replaced and old positional state is unwanted.
Whole panes continue the M3 hidden-pane contract: mounted state is retained,
focus is released on hiding and hidden controls cannot receive input/AX focus.
Reopening a pane does not force focus away from the current visible control.

## Toolbar contract and migration

The named More toolbar commands button is keyboard reachable only when visible.
Overflowed originals retain widget state but lose focus and semantics; the
renderer excludes their paint, pointer hits and semantics at layout time. When
a focused command overflows, focus moves to More toolbar commands. Disabled
menu entries expose disabled semantics, skip keyboard traversal and cannot
activate. Custom commands still need `inOverflowedBuilder` to offer an equivalent
menu command; the existing default remains an empty entry.

Menus use opaque semantic surfaces. Labels wrap/grow and long menus scroll.
Up/Down wrap through enabled commands, Home/End reach the endpoints and scroll
them into view. Enter/Space activate once; key-up does not invoke a second time.
Submenus open on hover, click, Enter/Space or Right; Left/Escape dismiss one menu
level. Outside click dismisses the popup. Dismissal restores the trigger's focus
if it is still mounted and focusable; a hidden/removed trigger is not refocused.
Window metrics changes dismiss popups rather than leaving stale anchors.
Popup bounds stay within the viewport; live reduced motion suppresses fading.

Behaviour corrections: overflow no longer leaks keyboard/AX controls; disabled
pulldown entries retain their disabled state when converted to overflow;
repeated submenu-open requests are idempotent instead of asserting. Submenus
now support explicit keyboard/click dismissal as well as outside click; they do
not close merely because the pointer briefly leaves them. The public `isDense`
option remains accepted; More always uses a compact icon with an accessible
name rather than displaying an empty label. No upstream inventory hash or MIT
notice was rewritten. Consumers need no constructor/import migration.

## Gallery and verification — 2026-11-08

The public-import gallery shows Foundations → Appearance → Colour roles,
application-shell/appearance commands and disabled export. Show application
shell uses ⌥⌘1 both in the View menu and Flutter shortcuts; existing ⌥⌘S/⌥⌘L
commands remain. Toolbar and menu callbacks share the same actions. View now
includes the platform-provided fullscreen command: the previous PlatformMenuBar
replaced the template menu without including it. This is a concrete command
surface correction, not runtime proof that fullscreen works. Sidebar auto-hides
at its existing default 556-point breakpoint; resize wider to use navigation.

Flutter 3.44.4 stable (ad70ec4617), engine a10d8ac38d, Dart 3.12.2;
macOS 27.2 (26B123), Xcode 27.2 (27B52), SDK 27.2. Non-mutating Dart format:
137 unchanged files. Root analysis: no issues. Complete library suite: 220 pass
(213 inherited, seven new shell regressions). Gallery: four pass, including
480-wide/200% text and 560-wide hierarchy/overflow/shortcut integration. Final
macOS debug build succeeds with the existing SwiftPM FlutterFramework advisory.
Dependency locks unchanged; no native source changes, skips, equality weakening
or golden regeneration.

New regressions cover recursive focus/selection/semantics, immediate hidden
subtree safety, live reduced motion, scaled/narrow rows, explicit colour/shape
preservation, secondary click, nested menu keyboard entry/back, dismissal/focus
restoration, resize focus transfer, disabled AX state, and wrapped/scrolling
menus at 320×240 with 200% text. These are deterministic widget checks, not
native screenshots or a VoiceOver traversal.

Native CUA obtained the existing gallery window's AX shell and native close,
fullscreen/zoom and minimize controls, but the next interaction reported that
the Mac was locked and automatic unlock failed. The final build was not launched
or visually inspected. No system preferences were changed. Native titlebar safe
areas, dragging, traffic lights, zoom/fullscreen, live native menu acceptance,
visual comparisons and VoiceOver remain open human/OS checks. Previous M3 native
evidence is historical, not acceptance of this build. Other OS/Intel/multi-window,
universal Release/Profile and performance remain unverified.
