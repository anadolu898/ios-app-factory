---
description: Run the full quality gate checklist before app submission
---

Execute the complete quality gate for the current app. This includes:

1. **Build check**: Build without warnings via `build_sim`
2. **Test check**: Run all tests via `test_sim`
3. **Design check**: Run the `/project:design-check` workflow
4. **Size check**: Check the .app bundle size (must be < 50MB)
5. **Performance check**: Launch app and verify load time < 2 seconds
6. **Paywall check**: Navigate to paywall, verify display and restore button
7. **Dark Mode check**: Switch to dark mode, verify all screens
8. **Accessibility check**: Verify VoiceOver labels via `snapshot_ui` on every screen

Output a pass/fail report. ALL items must pass before proceeding to Phase 4 (submission).

If any items fail, provide specific fix instructions and offer to fix them.
