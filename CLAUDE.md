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
- **Context7**: Live documentation lookup for any library/framework
- **XcodeBuildMCP**: Build, run, test on simulator, screenshots, UI inspection
- **Appeeky** (pending): ASO keyword research + competitor analysis
- **RevenueCat** (pending): Subscription management
- **App Store Connect** (pending): Metadata, submission

## Phase Workflow
When building a new app, follow these phases in order:
1. Market Research (Phase 0) — keyword + competitor analysis
2. Design (Phase 1) — screens, icon, color palette
3. Development (Phase 2) — iterative build + test loop
4. Quality Gate (Phase 3) — run `scripts/quality-gate.sh`
5. Submission (Phase 4) — screenshots, ASO metadata, submit
6. Launch Marketing (Phase 5) — Apple Search Ads + organic
7. Ongoing Ops (Phase 6) — automated monitoring

## Important Thresholds
- Kill app: MRR < $50 after 90 days
- Scale app: MRR > $500 + 10% MoM growth
- Max CPI: $2.00 target, kill keyword at $5.00
- Trial conversion target: > 15%
- App Store rating target: > 4.3
