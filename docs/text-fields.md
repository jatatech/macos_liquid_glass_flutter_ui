# Text and search fields

Import `package:macos_ui/macos_ui.dart`. Flutter owns editing, selection,
shortcuts and composition. The Text and search gallery demonstrates document
naming, inline validation, a selectable reference, disabled managed value and search.

## Editing and state contract

`MacosTextField` retains both constructors, controller/restoration, focus,
formatters, selection controls, context menus and submission callbacks. External
controllers and focus nodes remain caller-owned. Replacing a focus node removes
the old listener; switching to an internal controller copies the full editing
value, including selection and composing range. External `canRequestFocus`
settings are preserved. Disabled fields reject pointer, focus and editing actions;
re-enabling does not force focus. Read-only fields support selection/copy but
cannot cut, type, paste or clear. Programmatic controller changes remain allowed.

The default field uses semantic opaque canvas/disabled surfaces, hover borders,
readable text, and an independent accent focus border (foreground in increased
contrast). The default placeholder uses secondary foreground. Explicit text,
placeholder and decoration styles still take precedence. Explicit focused
borders are now honoured instead of being overwritten by a hardcoded blue ring;
custom `BorderDirectional` decorations no longer fail a cast. Base decoration
stays visible during focus. Live reduced motion removes decoration transitions
and cursor opacity fading, including changes during a transition. Flutter cursor
blinking remains managed by EditableText; this is not a promise to stop blinking.

`clearButtonMode` retains its text-presence visibility contract (the name
`editing` means nonempty text, not keyboard focus). The named Clear text button
is now reachable with Tab and activates with Enter/Space or primary click.
Clearing returns focus to the editor and calls `onChanged('')` exactly once only
when text changed. Read-only/disabled clear buttons cannot mutate text. A suffix
continues to take precedence over the built-in clear button. Secondary click does
not clear or select a suggestion; Flutter retains its text context-menu path.

Wrap a field in `Semantics(label: 'Document name', child: ...)` and show a persistent
visible label. Placeholder text is a hint, not a replacement for a field name.
Validation stays application-owned: retain entered text, show an adjacent error
(e.g. a live-region Text), and supply a decoration when useful. There is no new
built-in error API. Use the shell's existing ExcludeFocus/Offstage pane contract
when hiding mounted fields; generic opacity alone does not hide input/semantics.

## Search and compatibility

`MacosSearchField` retains existing parameters and adds optional
`ValueChanged<String>? onSubmitted`. Existing consumers require no source changes.
Search now uses the text keyboard with the Search input action. Enter without
an active result submits via `onSubmitted`; an active result instead invokes its
`onSelected` and the field's `onResultSelected`, once each. Selection replaces the
editing value with the result key and a collapsed end selection; this is an
explicit committed selection, not an in-progress composition. As before,
programmatic/result selection does not invoke `onChanged`. Typing, editing and
clear invoke `onChanged`, including the previously missing empty-query case.
Consumers which separately special-cased empty queries should remove duplicate
notification logic.

Results filter case-insensitively on text. Programmatic text changes and live
results replacements update the visible list without calling `onChanged`.
Up/Down cycle and scroll results; Enter chooses the highlighted result. Escape
hides suggestions without deleting the query. Left/Right, modified arrows and
Command editing shortcuts remain with the editor. Search does not consume
suggestion keys during an active composing region. Selection-only controller
notifications do not reopen dismissed suggestions. Clicking the field or editing
text reopens them. Focus loss/disable/replacement dismisses the overlay; disposal
removes it with the owning OverlayPortal. The portal shares the field's inherited
theme and cannot paint without its anchor. Result rows expose button/selected
semantics; native VoiceOver announcements remain unaccepted.

Result height is now a minimum: rows grow for text scaling. Lists scroll at the
configured visible-result count, are bounded by available viewport height and
open above the field when appropriate. Default surfaces are opaque semantic
colours; `MacosSearchFieldTheme` background/highlight overrides remain respected.
Long default result labels ellipsize; custom children must fit their row.
`maxResultsToShow` and `resultHeight` must be positive (asserted).

Consumer examples and the gallery use only public imports.
