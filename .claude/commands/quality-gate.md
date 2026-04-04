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

9. **ASO audit** (submission-ready builds): Run `.agents/skills/aso-audit` — verify title ≤30 chars, subtitle ≤30 chars, keyword field ≤100 chars (no spaces, comma-separated), no keyword stuffing in description, description has a hook in the first 255 chars (visible without "More").
10. **Metadata validation** (submission-ready builds): Run `.agents/skills/metadata-optimization` — verify description leads with strongest benefit, first 255 chars are keyword-rich and conversion-optimized, all 10 screenshot slots planned/filled.
11. **Screenshot check** (submission-ready builds): Run `.agents/skills/screenshot-optimization` — verify first screenshot is a hook (not a feature tour), captions are readable at glance, screenshots follow category visual conventions.
12. **Icon validation** (submission-ready builds): Run `.agents/skills/app-icon-optimization` — verify icon is legible at 29pt (smallest size shown on device), no text that becomes unreadable at small sizes, follows category color conventions.
13. **Keyword readiness** (submission-ready builds): Run `.agents/skills/keyword-research` — confirm the final keyword field is optimized: high-volume terms the app can realistically rank for, no duplication of words already in title/subtitle.
14. **Onboarding funnel check** (when onboarding screens exist): Run `.agents/skills/onboarding-optimization` — verify activation event is reachable within first 3 interactions from app open, no permissions requested before value delivered, sign-up gate is after activation.
15. **Monetization flow check** (when paywall exists): Run `.agents/skills/monetization-strategy` — verify paywall has all required Apple-compliant elements: benefit-driven headline, 3–5 benefit bullets, social proof, annual pricing highlighted, restore purchases button visible, close button visible and accessible.

**ASO checks (9–15) are required for submission-ready builds.** Skip them for internal development builds, but run them before every App Store submission.

Output a pass/fail report. ALL items must pass before proceeding to Phase 4 (submission).

If any items fail, provide specific fix instructions and offer to fix them.
