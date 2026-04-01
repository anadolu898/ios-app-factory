# iOS App Factory

Autonomous iOS app portfolio. Build, test, submit, and market apps at scale.
See `MASTER_PLAYBOOK.md` for strategy, thresholds, and tooling decisions.

## Architecture

- **iOS 17+** minimum, iOS 18+ preferred. SwiftUI only — no UIKit unless unavoidable.
- **MVVM** with `@Observable` macro. Never use `ObservableObject`, `@Published`, or `@StateObject`.
- **SwiftData** for persistence (not Core Data). Use `@Query` for fetches, `@Model` for entities.
- **async/await** for all async work. No Combine unless wrapping legacy APIs.
- **Value types** over reference types. Prefer structs for models and enums for state.
- **No force unwraps** (`!`) except in `#Preview` blocks.
- **StoreKit 2 + RevenueCat** for subscriptions. **Sentry** for crash reporting.
- Bundle IDs: `com.rightbehind.appname`. Each app lives in `apps/AppName/`.

## Code Rules

- Swift strict concurrency enabled.
- All user-facing strings: `String(localized:)` — no raw strings in UI.
- Accessibility labels on every interactive element. Support Dynamic Type.
- Every view file must have a `#Preview` block at the bottom.
- Asset Catalog colors only — never `Color(red:green:blue:)` for theme colors.
- Dark Mode must work on every screen. Test before committing.
- File organization: `App/`, `Models/`, `ViewModels/`, `Views/Screens/`, `Views/Components/`, `Services/`, `Extensions/`, `Resources/`.
- See `.claude/rules/design-system.md` for color, typography, spacing, and component standards.
- See `.claude/rules/swiftui-conventions.md` for naming, imports, and previews.

## PRD-Driven Development

Every app starts with a Product Requirements Document — not a vague prompt.

```
apps/AppName/
├── docs/
│   ├── PRD.md              # Source of truth: problem, features (P0-P2), success metrics, acceptance criteria
│   ├── ARCHITECTURE.md     # Technical design decisions
│   ├── specs/              # Feature specifications (reference PRD sections)
│   └── tasks/              # Task breakdowns (one task = one session)
```

- **PRD first.** Define problem, success metrics, features with priority (P0 = must ship, P1 = should ship, P2 = nice to have), acceptance criteria, and explicit out-of-scope items.
- **Specs from PRD.** Each feature gets a spec file referencing PRD sections. Specs include user stories, acceptance criteria, and technical approach.
- **Tasks from specs.** Break specs into task files. Each task should be completable in a single session. Track progress with subtasks and a changes log.
- Use `ultrathink` for architecture decisions, complex debugging, and migration strategies. Use standard thinking for implementation.

## Workflow: Plan > Test > Build > Verify > Review > Ship

1. **Plan first.** Use `/writing-plans` or `/executing-plans` skills. Write PRD and specs before code. For new apps, run Phase 0 market research via Appeeky.
2. **Write tests first.** Use `/test-driven-development` skill. Red-green-refactor. Characterization tests before refactoring existing code.
3. **Build iteratively.** Write code, build via XcodeBuildMCP, run on simulator, fix, repeat.
4. **Verify autonomously.** Use `ios-simulator-skill` to interact with the running app — navigate by accessibility labels, tap elements, type text, take screenshots. Don't rely on pixel coordinates. Use the visual feedback loop: build → screenshot → evaluate → fix → repeat.
5. **Review before merging.** Use `/requesting-code-review` and `/receiving-code-review` skills. Use `/simplify` to check for unnecessary complexity.
6. **Quality gate before submission.** Run `/quality-gate` — zero warnings, tests pass on iPhone 16 Pro + SE + iPad, Dark Mode, VoiceOver, paywall flow.
7. **Ship and monitor.** ASO metadata via Appeeky, submit via App Store Connect, track with RevenueCat.

## Skills Reference (`.claude/skills/`)

Use these skills automatically when their domain is relevant:

**Development:**
- `swiftui-pro` — State, navigation, data, performance, accessibility best practices
- `swiftui`, `swiftui-expert`, `swiftui-patterns` — Advanced patterns, architecture, composition
- `swiftdata` — Schema design, queries, repository pattern, migrations
- `swift` — Language-level best practices, concurrency, protocols
- `testing` — TDD workflows, characterization tests, snapshot tests, mocks
- `ios-simulator-skill` — Semantic simulator interaction (navigate by text/type/ID, not coordinates)
- `design` — Animation patterns, liquid glass, visual design
- `performance` — Profiling, optimization, launch time, memory
- `security` — Secure storage, network security, data protection
- `foundation`, `core-ml`, `mapkit`, `apple-intelligence` — Framework-specific guidance

**Quality & Review:**
- `design-check` — Visual and accessibility audit via XcodeBuildMCP
- `release-review` — Pre-submission review checklist

**ASO & Growth:**
- `aso-audit`, `keyword-research`, `metadata-optimization` — App Store Optimization
- `competitor-analysis`, `competitor-tracking` — Market intelligence
- `app-launch`, `growth`, `press-and-pr` — Launch and growth strategy
- `monetization`, `subscription-lifecycle`, `monetization-strategy` — Revenue optimization
- `screenshot-optimization`, `app-icon-optimization` — Visual assets
- `review-management`, `rating-prompt-strategy` — Ratings and reviews
- `apple-search-ads`, `ua-campaign` — Paid acquisition

**Superpowers (`.claude/skills/superpowers/` — global):**
- `writing-plans`, `executing-plans` — Structured planning before coding
- `test-driven-development` — TDD workflow enforcement
- `systematic-debugging` — Root cause analysis, not guessing
- `requesting-code-review`, `receiving-code-review` — PR review process
- `brainstorming` — Ideation and exploration
- `subagent-driven-development`, `dispatching-parallel-agents` — Parallel work
- `verification-before-completion` — Verify before marking done
- `finishing-a-development-branch` — Clean branch completion

## Git

- Conventional commits: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`
- Feature branches: `app-name/feature-description`
- No direct pushes to main. Branches + PRs only.

## Thresholds

- Kill: MRR < $50 after 90 days
- Scale: MRR > $500 + 10% MoM growth
- Max CPI: $2.00 target, kill keyword at $5.00
- Trial conversion: > 15%
- App Store rating: > 4.3
