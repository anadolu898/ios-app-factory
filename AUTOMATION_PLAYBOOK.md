# iOS App Factory — Automation Playbook
## Lessons Learned from AquaLog Build (March 28-29, 2026)

### What Worked Well (Keep Doing)

1. **XcodeGen for project management** — `project.yml` + `xcodegen generate` is far better than manually editing `.xcodeproj`. Every target, dependency, and plist key is declarative. BUT it overwrites widget Info.plist every time — need to re-patch version strings after each generate.

2. **XcodeBuildMCP for build/test/run** — `build_sim`, `test_sim`, `build_run_sim` are reliable. `session_set_defaults` saves time. Screenshot capture works well.

3. **AppIntents as the universal foundation** — One AppIntent powers widgets, Control Center, Siri, Shortcuts, and Action Button. Build intents first, everything else is free.

4. **@Observable + stored properties** — Computed properties 2+ levels deep break SwiftUI reactivity. Always use stored properties updated explicitly in a `recalculate()` method with `withAnimation`.

5. **RevenueCat MCP** for managing subscription products remotely.

6. **Appeeky MCP** for ASO keyword research and competitor analysis — got real volume/difficulty scores.

### What Broke & Had to Be Fixed Manually

1. **Simulator clicking (cliclick)** — Coordinate mapping between iOS points and macOS screen pixels is unreliable. The simulator window position shifts, and the title bar offset varies. Onboarding taps worked but post-onboarding taps failed. **LESSON:** Don't rely on automated clicking for testing. Use `snapshot_ui` to verify state, but accept that manual interaction testing has limits.

2. **Widget Info.plist version mismatch** — XcodeGen regenerates the widget Info.plist every time, resetting `CFBundleShortVersionString` to "1.0" instead of `$(MARKETING_VERSION)`. This causes a build warning and potential App Store rejection. **FIX:** After every `xcodegen generate`, automatically patch the widget Info.plist. Could be a post-generate script.

3. **@AppStorage vs SwiftData dual storage** — Used both for `hasCompletedOnboarding`, causing potential desyncs. **LESSON:** Pick ONE source of truth. @AppStorage is faster for gate checks (no SwiftData load needed).

4. **Old Beverage enum vs NutrientDatabase** — Started with a simple enum, then added a comprehensive database. Had to create a `displayInfo(for:)` bridge. **LESSON:** Start with the data model you'll need at scale. Don't build a simple enum if you know you'll need 23+ items.

5. **AngularGradient on progress ring** — Looked wrong at small fill percentages (<15%). Switched to LinearGradient. **LESSON:** Always test visual components at extreme values (0%, 5%, 50%, 100%).

6. **Worktree CWD sticky** — If the worktree directory gets deleted while the shell CWD is inside it, every subsequent Bash command fails with "Path does not exist". **LESSON:** Always `cd` out of a worktree before deleting it. Or use `git -C` for all commands.

### What Should Be Automated Next

| Task | Current State | Automation Approach |
|------|--------------|-------------------|
| **XcodeGen + plist patching** | Manual after every generate | Post-generate shell script that patches widget plists |
| **Build + test cycle** | Manual `build_sim` + `test_sim` | Single command: `./scripts/build-test.sh` |
| **Screenshot capture** | cliclick unreliable | Use Xcode UI testing (XCUITest) for deterministic screenshots |
| **App Store screenshot generation** | Manual ChatGPT + resize | Script that takes simulator screenshots at each device size |
| **ASO keyword research** | Manual Appeeky queries | Scheduled task that checks keyword rankings weekly |
| **RevenueCat product setup** | Manual via MCP | Script that creates products/offerings/entitlements from aso.json |
| **App Store submission** | Not yet automated | Fastlane or `xcodebuild -exportArchive` + `altool` |
| **Privacy policy/terms** | Manual HTML | Template that fills in app name, email, features |
| **Quality gate** | Manual checklist | `quality-gate.sh` that runs build, tests, checks warnings, app size |

### Phase Timing (Actual vs Planned)

| Phase | Planned | Actual | Notes |
|-------|---------|--------|-------|
| Market Research | 2 hrs | 30 min | Appeeky MCP + web search made this fast |
| Core MVP | 4 hrs | 2 hrs | SwiftUI + SwiftData is fast for CRUD apps |
| Intelligence Engine | 4 hrs | 3 hrs | 5 services, all pure Swift, no API dependencies |
| Polish + Fix bugs | 2 hrs | 4 hrs | Progress ring bug took longest to diagnose |
| Infrastructure (RC, Sentry, Pages) | 1 hr | 1.5 hrs | SPM dependency resolution is slow |
| Screenshots + ASO | 2 hrs | 2 hrs | Simulator clicking was the bottleneck |
| **Total** | **15 hrs** | **13 hrs** | |

### Template for Next App

```
1. Pick category from MASTER_PLAYBOOK.md kill/scale thresholds
2. Run Appeeky ASO research (aso_full_audit, get_keyword_suggestions)
3. Check competitor reviews for pain points
4. Create project.yml with all targets (main, widgets, watch, tests)
5. Build data model first (SwiftData @Model)
6. Build AppIntents second (these power everything)
7. Build services (calculators, managers)
8. Build views last (dashboard, onboarding, settings, paywall)
9. Run quality gate: build, test, zero warnings
10. Generate screenshots, prepare ASO metadata
11. Submit via Xcode/Fastlane
```

### Key Architecture Decisions to Make Upfront

- **Data layer:** SwiftData (local) vs CloudKit (sync) vs Firebase
- **Subscriptions:** RevenueCat (recommended) vs raw StoreKit 2
- **Crash reporting:** Sentry (recommended) vs Firebase Crashlytics
- **Analytics:** None for MVP, add after validation
- **Widgets:** Always include — they drive retention
- **Watch app:** Include if the app has a "glanceable" metric
- **Siri Shortcuts:** Always include — free discoverability

### Files That Should Be Templated

- `project.yml` — parameterize bundle ID, app name, targets
- `AquaLogApp.swift` → `{{AppName}}App.swift` — Sentry + RevenueCat init
- `StoreManager.swift` — just needs API key swap
- `NotificationManager.swift` — reusable as-is
- `HealthKitManager.swift` — reusable as-is
- `privacy-policy.html` — template with {{APP_NAME}}, {{EMAIL}}
- `terms-of-use.html` — template with {{APP_NAME}}, {{EMAIL}}
- `aso.json` — template structure
