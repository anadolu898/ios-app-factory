# Design System Rules

These rules apply to ALL apps in the portfolio. Individual apps may extend but not override these.

## Color Architecture

Every app MUST define colors in an Asset Catalog, not in code:
- `AccentColor` — primary brand color, used for interactive elements
- `BackgroundPrimary` — main background (adapts to light/dark)
- `BackgroundSecondary` — card/section backgrounds
- `TextPrimary` — main text color
- `TextSecondary` — captions, metadata
- `Success`, `Warning`, `Error` — semantic feedback colors

In code, reference via: `Color("AccentColor")` or preferably `Color.accentColor`

NEVER use `Color(red:green:blue:)` for theme colors — always asset catalog.
NEVER use pure black (`#000000`) backgrounds — use system `.background` or a very dark gray.

## Typography

- Use SF Pro (system font) as the default. Only deviate with strong brand justification.
- Use semantic text styles: `.largeTitle`, `.title`, `.headline`, `.body`, `.caption`
- Support Dynamic Type — never hardcode font sizes without `.minimumScaleFactor()`
- Maximum 3 font weights per screen (regular, medium/semibold, bold)

## Spacing & Layout

- Standard edge padding: 16pt (use `.padding()` or `.padding(.horizontal, 16)`)
- Section spacing: 24pt
- Related item spacing: 8-12pt
- Card corner radius: 12-16pt (consistent within an app)
- Touch targets: minimum 44x44pt

## Component Standards

### Buttons
- Primary: filled with AccentColor, white text, 12pt corner radius, 50pt height
- Secondary: bordered with AccentColor, AccentColor text
- Destructive: filled with Error color
- All buttons must have `.accessibilityLabel()` if icon-only

### Cards
- Background: `.regularMaterial` or `BackgroundSecondary`
- Corner radius: 16pt
- Shadow: `color: .black.opacity(0.05), radius: 8, y: 4`
- Padding: 16pt internal

### Lists
- Use system `List` style for settings-like screens
- Use custom `LazyVStack` in `ScrollView` for card-based layouts
- Section headers: `.font(.headline)`, `.foregroundStyle(.secondary)`

### Empty States
- Centered vertically
- System image (SF Symbol) at 48pt
- Title: `.font(.title3).bold()`
- Description: `.font(.body).foregroundStyle(.secondary)`
- Optional CTA button

## Dark Mode

- EVERY screen must look correct in Dark Mode
- Test by switching appearance in simulator
- Use `.regularMaterial` / `.ultraThinMaterial` instead of custom semi-transparent colors
- Shadows are less visible in Dark Mode — consider adding subtle borders as alternative

## Accessibility

- ALL interactive elements: `.accessibilityLabel()`
- Decorative images: `.accessibilityHidden(true)`
- Groups of related content: `.accessibilityElement(children: .combine)`
- Custom actions: `.accessibilityAction(named:) { }`
- Respect `.accessibilityReduceMotion` — provide non-animated alternatives
- Respect `.accessibilityReduceTransparency` — use opaque backgrounds

## App Icon

- 1024x1024 single asset (Xcode generates all sizes)
- Legible at 29pt (small complication)
- No text (except single letters/symbols)
- Simple, distinctive silhouette
- Follow category conventions (health = greens/blues, productivity = bold colors)
