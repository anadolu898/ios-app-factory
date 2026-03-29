---
name: design-check
description: When the user says "design check", "check the UI", "verify screens", or when completing Phase 3 quality gate. Runs a structured visual and accessibility audit using XcodeBuildMCP screenshots and UI snapshots. Auto-invoke after major UI changes during Phase 2.
metadata:
  version: 1.0.0
---

# Design Check — Visual & Accessibility Audit

You are a meticulous iOS design reviewer. Your job is to screenshot every screen, inspect the UI hierarchy, and verify compliance with Apple HIG and the project's design system.

## Workflow

### Step 1: Build & Launch
1. Build the app on simulator via `build_run_sim`
2. Wait for app to launch fully

### Step 2: Screenshot Every Screen
For each screen in the app:
1. Navigate to the screen (use `snapshot_ui` to find tap targets, then tap via UI automation or navigate programmatically)
2. Take a `screenshot` — examine for:
   - Visual hierarchy: Is it clear what's primary, secondary, tertiary?
   - Spacing consistency: Even padding, aligned elements
   - Typography: Readable sizes, proper weight hierarchy
   - Color: Sufficient contrast, consistent palette
   - Dark Mode: Switch appearance and re-screenshot
3. Take a `snapshot_ui` — examine for:
   - Accessibility labels on ALL interactive elements
   - Proper element roles (button, link, heading)
   - Logical reading order
   - No unlabeled images or icons

### Step 3: Device Size Check
Repeat key screens on:
1. iPhone 17 Pro (default) — full-size experience
2. iPhone SE (small screen) — ensure nothing clips or overflows
3. iPad (if supported) — check adaptive layout

### Step 4: Interaction Check
Test these flows:
1. **Onboarding**: Complete the full flow — smooth transitions? Clear CTAs?
2. **Paywall**: Trigger paywall — clear pricing? Restore button visible?
3. **Empty states**: Does the app handle zero data gracefully?
4. **Error states**: Force an error (airplane mode) — helpful message?
5. **Keyboard handling**: Open any text input — does the view adjust?

### Step 5: Report

Generate a structured report:

```
## Design Check Report — [App Name]

### Overall Score: X/10

### Screen-by-Screen
| Screen | Light Mode | Dark Mode | Accessibility | Issues |
|--------|-----------|-----------|---------------|--------|
| Home   | OK/Issues | OK/Issues | OK/Issues     | ...    |
| ...    |           |           |               |        |

### Critical Issues (must fix)
1. [Issue description + which screen + suggested fix]

### Warnings (should fix)
1. [Issue description]

### Passed Checks
- [x] All interactive elements have accessibility labels
- [x] Dark Mode renders correctly on all screens
- [x] Typography hierarchy is clear
- [x] Spacing is consistent
- [x] Empty states are designed
- [x] Paywall displays correctly
```

## Apple HIG Quick Reference

### Spacing
- Standard padding: 16pt from edges
- Between sections: 20-24pt
- Between related items: 8-12pt
- Touch targets: minimum 44x44pt

### Typography Hierarchy
- Large Title: 34pt bold (screen titles in navigation)
- Title: 28pt bold (section headers)
- Headline: 17pt semibold (list headers)
- Body: 17pt regular (main content)
- Callout: 16pt (secondary content)
- Caption: 12pt (timestamps, metadata)

### Color
- Use semantic colors: `.primary`, `.secondary`, `.background`
- Accent color for interactive elements
- Destructive actions in `.red`
- Minimum contrast ratio: 4.5:1 (text), 3:1 (large text)

### Navigation
- Use system navigation patterns (tab bar, navigation bar)
- Back button always accessible
- Swipe-to-go-back enabled (default with NavigationStack)

## Related Skills

- For SwiftUI code fixes: `swiftui-pro`, `swiftui-expert`
- For pre-submission quality: see `scripts/quality-gate.sh`
