# iOS App Factory — Claude Code Instructions

## Project Overview
This is an autonomous iOS app portfolio factory. We build, test, submit, and market iOS apps at scale.
Master playbook: `MASTER_PLAYBOOK.md` — read it for strategy, thresholds, and tooling decisions.

## Repository Structure
```
/apps/                  # Each app gets its own directory (e.g., apps/AquaLog/)
/templates/             # Reusable SwiftUI templates, paywall screens, onboarding flows
/scripts/               # Automation scripts (quality gate, screenshot gen, ASO)
/portfolio/             # Portfolio tracking data
/MASTER_PLAYBOOK.md     # Strategy & operations reference
/.agents/skills/        # Agent skills (SwiftUI, ASO, marketing, design)
/.claude/rules/         # Design system tokens, SwiftUI conventions
/.claude/commands/      # Slash commands: /project:design-check, /project:quality-gate
/.claude/agents/        # Specialized subagents: ui-reviewer, accessibility-auditor
```

## Development Conventions

### SwiftUI Apps
- **Target**: iOS 17+ minimum, iOS 18+ preferred
- **Architecture**: MVVM with SwiftUI + SwiftData (not Core Data for new apps)
- **UI Framework**: SwiftUI only, no UIKit unless absolutely required
- **Design**: Follow Apple HIG, support Dark Mode, Dynamic Type
- **Persistence**: SwiftData for local storage
- **Subscriptions**: StoreKit 2 + RevenueCat SDK
- **Widgets**: WidgetKit with TimelineProvider
- **Analytics**: Sentry for crashes, RevenueCat for revenue

### Code Style
- Swift strict concurrency enabled
- Use `@Observable` macro (not ObservableObject) for iOS 17+
- Prefer `async/await` over Combine
- No force unwraps (`!`) except in previews
- All user-facing strings must be localizable (`String(localized:)`)
- Accessibility labels on all interactive elements
- See `.claude/rules/swiftui-conventions.md` for file organization and naming

### SwiftUI Skills (auto-invoked during development)
- **swiftui-pro**: Core rules — state, navigation, data, performance, accessibility
- **swiftui-expert**: Advanced patterns — animations, Charts, Widgets, App Intents, SwiftData
- **swiftui-patterns**: Architecture — MVVM, view composition, refactoring, performance audit

### Design System
- See `.claude/rules/design-system.md` for color, typography, spacing, and component standards
- IMPORTANT: Use Asset Catalog colors, not hardcoded values
- IMPORTANT: Every screen must work in Dark Mode

### Git Workflow
- Each app has its own directory under `apps/`
- Feature branches: `app-name/feature-description`
- Commits: conventional commits (`feat:`, `fix:`, `chore:`, etc.)
- No direct pushes to main — use branches + PRs

### Quality Gate (MUST PASS before any marketing)
Before marking an app ready for submission, verify ALL items in `scripts/quality-gate.sh`.
Key thresholds:
- Zero build warnings
- All tests pass on iPhone 16 Pro, iPhone SE, iPad simulators
- App size < 50MB
- Launch time < 2 seconds
- Dark Mode works on every screen
- Paywall purchase + restore works
- VoiceOver labels on all interactive elements

### App Naming Convention
- Directory: PascalCase (e.g., `AquaLog/`)
- Bundle ID: `com.anadolu898.appname` (lowercase)
- Xcode project inside app directory

## MCP Servers Available
- **GitHub**: Code management, PRs, issues
- **Context7**: Live documentation lookup — use for ANY SwiftUI/StoreKit/WidgetKit API questions
- **XcodeBuildMCP**: Build, run, test, screenshot, UI snapshot, LLDB debug on simulator
- **Xcode MCP** (`xcrun mcpbridge`): SwiftUI preview rendering, Apple docs search, code snippets (Xcode 26.3+)
- **iOS Simulator MCP**: Granular UI interaction — tap coordinates, swipe gestures, text input, video recording
- **Appeeky**: ASO keyword research, competitor analysis, App Store intelligence
- **RevenueCat**: Subscription management, entitlements, offerings, analytics
- **App Store Connect** (via Appeeky): Metadata, versions, reviews, localization

## Design & Quality Tools
- **`/project:design-check`**: Screenshot every screen, audit visual quality + accessibility
- **`/project:quality-gate`**: Full pre-submission checklist (build, test, design, performance)
- **UI Reviewer agent** (`.claude/agents/ui-reviewer.md`): Specialized visual quality review
- **Accessibility Auditor agent** (`.claude/agents/accessibility-auditor.md`): WCAG 2.1 AA compliance
- **Visual feedback loop**: Build → screenshot → evaluate → fix → re-screenshot (autonomous)

## Phase Workflow
When building a new app, follow these phases in order:
1. Market Research (Phase 0) — keyword + competitor analysis via Appeeky
2. Design (Phase 1) — screens, icon, color palette per `.claude/rules/design-system.md`
3. Development (Phase 2) — iterative build + test loop with SwiftUI skills auto-invoked
4. Quality Gate (Phase 3) — run `/project:quality-gate` (replaces manual `scripts/quality-gate.sh`)
5. Submission (Phase 4) — screenshots, ASO metadata, submit via App Store Connect
6. Launch Marketing (Phase 5) — Apple Search Ads + organic
7. Ongoing Ops (Phase 6) — automated monitoring

### Visual Feedback Loop (Phase 2-3)
During development, use the autonomous design iteration cycle:
1. Write/modify SwiftUI code
2. Build and run on simulator (`build_run_sim`)
3. Screenshot the result (`screenshot`)
4. Evaluate against design system rules
5. Fix issues in code
6. Repeat until quality bar met
This loop replaces manual visual review — Claude can iterate autonomously.

## Important Thresholds
- Kill app: MRR < $50 after 90 days
- Scale app: MRR > $500 + 10% MoM growth
- Max CPI: $2.00 target, kill keyword at $5.00
- Trial conversion target: > 15%
- App Store rating target: > 4.3
