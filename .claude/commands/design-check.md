---
description: Run a visual and accessibility audit on the current app using XcodeBuildMCP
---

Run the `design-check` skill against the current app. Build and launch on the simulator, then systematically screenshot every screen in both light and dark mode, inspect the UI hierarchy for accessibility labels, and verify spacing/typography/color against the design system rules in `.claude/rules/design-system.md`.

Output a structured report with a score out of 10 and categorized issues (critical, warnings, passed).

If issues are found, suggest specific code fixes.
