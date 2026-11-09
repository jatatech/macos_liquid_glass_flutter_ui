# Resolved colors and selection foregrounds

`MacosDynamicColor.resolve(color, context)` uses the current `MacosTheme`
brightness, `MediaQuery.highContrast` and `CupertinoUserInterfaceLevel`. Resolve
inside a dependent build when these traits can change; a saved resolved color is
a snapshot. Plain colors are returned unchanged; `maybeResolve(null, context)`
returns null.

The exported `ResolvedMacosDynamicColor` remains a `CupertinoDynamicColor` with
its original variants and constructor. All channels, color space, serialization,
luminance and color-copy operations now use its `resolvedColor`. Re-resolving the
snapshot uses the new context and retained variants. Cupertino's type- and
variant-sensitive equality/hash contract is retained, including the effective
ARGB value; do not equate a wrapper to a concrete Color merely because it paints
the same pixels. Use `toARGB32()` only when an explicitly quantized 32-bit value
is required, and `withValues` to preserve fractional alpha/color-space precision.

Sidebar selection/hover/press and highlighted/pressed toolbar overflow labels use
the higher-contrast black or white foreground against the actual state fill.
Sidebar disclosure, leading/trailing icons and trailing text share that state.
Both `MacosIcon` and Flutter `Icon` inherit defaults; explicit child colors/styles
and nested consumer icon themes remain authoritative. Arbitrary custom painting
and images must supply their own legible state treatment. Focus borders, selected
semantics, selection callbacks and pointer cancellation retain their contracts.
SidebarItem has no disabled-row API; overflow rows with no action/submenu remain
disabled, with no tap action advertised by dormant release handlers.

Translucent selection fills are evaluated over the semantic opaque sidebar or
toolbar canvas. Keep that owning surface behind them. If a consumer supplies a
different custom backdrop, it owns the foreground/backdrop pairing; use explicit
child styling or an opaque selection fill. This is Flutter chrome, not a claim
that native glass or arbitrary Flutter pixels are sampled by the contrast helper.

The target for inherited ordinary small text is at least 4.5:1 in the covered
states. This implements the legibility aim in Apple's
[Accessibility guidance](https://developer.apple.com/design/human-interface-guidelines/accessibility)
and adaptive-color guidance in [Color](https://developer.apple.com/design/human-interface-guidelines/color).
The black/white comparison is the library's engineering choice, not a prescribed
Apple implementation. Explicit consumer overrides can intentionally change contrast.

`MacosThemeData.lerp` now interpolates `canvasColor` from the two canvas endpoints;
it no longer substitutes primary/accent colors. No animation scheduling or Reduce
Motion policy changed. Exact source, regression/synthetic-gallery evidence and
native acceptance limits are in [support and verification scope](../docs/support.md).
