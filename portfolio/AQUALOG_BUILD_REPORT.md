# AquaLog — Build Report
## Development Progress, Decisions, and Compound Fixes (March 28 – April 14, 2026)

This document captures the full development history of AquaLog: every architectural decision, every code review finding, and the recurring patterns that emerged across 8 phases. The goal is to make every future app build faster and cleaner by front-loading these lessons.

---

## App Overview

**AquaLog** is an iOS hydration tracker targeting users frustrated with overengineered, gamified competitors (Waterllama — 148K reviews, $183K/day; WaterMinder — 32K reviews, $40K/day).

**Positioning:** Clean, simple water tracker that just works — science-backed hydration intelligence without the noise  
**Free tier:** Basic water tracking, 1 widget (small), daily goal, 6 free beverages  
**Premium tier:** 23+ beverages with full nutrition data, caffeine tracker, alcohol calculator, health timeline, weekly body report, CSV export  
**Bundle ID:** `com.rightbehind.aqualog`

**Tech stack:** SwiftUI + SwiftData + HealthKit + StoreKit 2 + RevenueCat + WidgetKit + WatchKit + ActivityKit + AppIntents + Sentry

**Pricing:**
- Monthly: $3.99/month (7-day free trial)
- Yearly: $29.99/year (7-day free trial)
- Lifetime: $49.99

---

## Phase Timing (Actual)

| Phase | Description | Status | Planned | Actual |
|-------|-------------|--------|---------|--------|
| Phase 0 | Market research (Appeeky + competitor analysis) | ✅ Complete | 2 hrs | 30 min |
| Phase 1 | Core MVP (SwiftData models + dashboard + logging) | ✅ Complete | 4 hrs | 2 hrs |
| Phase 2 | Intelligence engine (5 services: nutrients, caffeine, alcohol, hydration calc, insights) | ✅ Complete | 4 hrs | 3 hrs |
| Phase 3 | Multi-surface (widgets, Watch, AppIntents, Live Activity, Control Center) | ✅ Complete | 3 hrs | 2 hrs |
| Phase 4 | Onboarding + paywall + monetization | ✅ Complete | 2 hrs | 1.5 hrs |
| Phase 5 | 8-agent code review + bug fixes (21 issues found, 12 fixed) | ✅ Complete | — | 4 hrs |
| Phase 6 | QA testing session (10 bugs fixed) + TestFlight validation | ✅ Complete | 2 hrs | 3 hrs |
| Phase 7 | Premium gating fix + juice options + build bump | ✅ Complete | — | 1 hr |
| Phase 8 | App Store submission + ASO + launch | 🚧 Pending | 2 hrs | — |
| **Total** | | | **19 hrs** | **17 hrs** |

**Total code review findings:** 21 (12 P1 critical, 7 P2 important, 2 P3 polish)  
**Total QA bugs fixed:** 10  
**Total commits:** 15  
**Total PRs:** 6

---

## Architecture Decisions (What to Reuse)

### 1. Data Layer: SwiftData + App Group Container

**Pattern:** SwiftData `ModelContainer` in the App Group container as single source of truth. All surfaces (main app, widgets, Siri, Watch, Control Center) share the same container.

| Data | Storage | Rationale |
|------|---------|-----------|
| Water log entries | SwiftData (`WaterLog`) | Queryable, relational, sortable |
| User settings & goals | SwiftData (`UserSettings`) | Profile data with complex types |
| Premium status | RevenueCat (authoritative) + UserDefaults (cache) | Server-side truth, offline fallback |
| Widget hot state | App Group UserDefaults | Instant read in widget timeline providers |

**Key rule:** SwiftData is the record of truth. UserDefaults is a hot-path cache. Never store authorization state (premium) only in local storage — jailbroken devices can flip SQLite fields. RevenueCat entitlement is the source of truth; UserDefaults is a cache for offline grace.

### 2. Beverage Database: Start with Full Data Model

**Lesson learned the hard way.** Started with a simple `Beverage` enum (8 cases), then needed a comprehensive `NutrientDatabase` with 23+ beverages including caffeine, sugar, alcohol, hydration factors, and calorie data. Had to build a `displayInfo(for:)` bridge between the two.

**Rule:** Start with the data model you'll need at scale. If you know you'll have 20+ items with rich metadata, don't start with an enum — start with a struct database.

**Final pattern:**
```swift
struct NutrientDatabase {
    struct BeverageProfile {
        let id: String
        let category: Category
        let displayName: String
        let icon: String
        let caffeineMgPer250mL: Double
        let sugarGramsPer250mL: Double
        let alcoholABV: Double
        let hydrationFactor: Double
        let caloriesPer250mL: Double
        let isFree: Bool
    }
    
    static let beverages: [BeverageProfile] = [...]
    private static let beveragesByID: [String: BeverageProfile] = // O(1) lookup
}
```

### 3. AppIntents as Universal Foundation

Build AppIntents first — they power widgets, Control Center, Siri, Shortcuts, and Action Button for free. One `LogDrinkIntent` drives all surfaces. Same lesson confirmed in FastTrack.

### 4. Net Hydration Intelligence

The key differentiator. Every beverage's hydration impact is calculated factoring in:
- **Base hydration factor** (milk = 1.04, water = 1.0, espresso = 0.75, spirits = 0.10)
- **Sugar processing cost** (~1 mL water per gram of sugar metabolized)
- **Alcohol dehydration** (each gram of ethanol causes ~10 mL extra fluid loss)
- **Caffeine diuretic effect** (mild, only significant above ~300mg/day)

This calculation runs in `NutrientDatabase.netHydration()` and feeds the AddDrinkSheet's "Hydration Intelligence" section — showing users the real impact of their drinks.

### 5. Premium Feature Gating: Defense in Depth

After discovering that premium beverages could be added without paying (lock icon was purely cosmetic), we implemented three layers:

```
Layer 1: Beverage grid tap → showPaywall (intercept at selection)
Layer 2: "Add" button → "Unlock" button (intercept at submission)  
Layer 3: isValid guard → disabled state (safety net)
```

**Pattern (reusable):**
```swift
// In beverage grid
Button {
    if !profile.isFree && !StoreManager.shared.isPremium {
        showPaywall = true  // Layer 1: intercept
    } else {
        selectedProfile = profile
    }
}

// In toolbar
Button(needsPremium ? String(localized: "Unlock") : String(localized: "Add")) {
    if needsPremium {
        showPaywall = true  // Layer 2: redirect
    } else {
        onAdd(amountValue, selectedProfile.id, note)
        dismiss()
    }
}
.disabled(!isValidAmount)  // Layer 3: safety net
```

**Rule for future apps:** Never rely on cosmetic indicators (lock icons, grayed-out text) as the only premium gate. Always block the action. Show the paywall on tap — every locked interaction is a conversion opportunity.

### 6. Smart Category Auto-Select

When switching beverage categories, auto-select the first *accessible* item (free for non-premium users):

```swift
let inCategory = NutrientDatabase.beverages(in: cat)
if let first = inCategory.first(where: { $0.isFree || StoreManager.shared.isPremium })
    ?? inCategory.first {
    selectedProfile = first
}
```

Without this, switching to "Soda" or "Alcohol" category silently lands on a locked beverage with the Add button disabled and no explanation.

### 7. `@Observable` + Stored Properties for UI State

All view models use `@Observable` macro (iOS 17+). Computed properties 2+ levels deep break SwiftUI reactivity. Always use stored properties updated explicitly.

```swift
@Observable
final class DashboardViewModel {
    var todayEntries: [WaterLog] = []     // ✅ stored
    var totalIntake: Int = 0               // ✅ stored — recomputed explicitly
    var progress: Double = 0.0             // ✅ stored
    
    func recalculate() {
        totalIntake = todayEntries.reduce(0) { $0 + $1.amount }
        progress = Double(totalIntake) / Double(dailyGoal)
    }
}
```

### 8. Navigation: Per-Tab NavigationStack

Tab-based apps: each tab owns its own `NavigationStack`. No global `AppRouter`. Deep links set `selectedTab` and push onto the relevant path. (Same decision as FastTrack — confirmed as the right pattern for tab apps.)

---

## The 6 Critical Bug Patterns (from 8-Agent Code Review)

These patterns are **not specific to hydration tracking** — they will reappear in every iOS app. Full details in `docs/COMPOUND_REPORT.md`.

### Pattern 1: Multi-Surface Data Loss

**What happened:** Widgets, Watch, and AppIntents only wrote to UserDefaults, bypassing SwiftData. History was invisible, streaks didn't update, HealthKit diverged.

**Rule:** One canonical write function (e.g., `LogDrinkService`), shared across all surfaces. Every entry point calls the same persistence code through the App Group container.

### Pattern 2: Optimistic UI with Silent Failures

**What happened:** `addDrink` played haptic, updated UI, fired confetti — then `try context.save()` failed silently in a `catch {}` block.

**Rule:** Never confirm success (haptic, animation, UI update) until persistence succeeds. Revert UI on error.

### Pattern 3: Hardcoded Secrets in Source

**What happened:** Sentry DSN and RevenueCat test API key were string literals in Swift files.

**Rule:** All API keys in Info.plist via xcconfig. `#if DEBUG / #else` for test vs production. CI must fail if test key patterns are found in source.

### Pattern 4: The `fatalError` Landmine

**What happened:** `ModelContainer` init used `fatalError`. A schema migration error would permanently crash the app, requiring reinstall and losing all data.

**Rule:** Never `fatalError` on persistence init. Always provide in-memory fallback + user alert + Sentry capture.

### Pattern 5: Security Assumptions About On-Device Data

**What happened:** Three issues — `isPremium` in SwiftData (bypassable on jailbreak), Sentry `attachScreenshot = true` (captures health data), AppIntents accept unbounded input (poisoning HealthKit).

**Rules:**
1. Auth state from server (RevenueCat), not local storage
2. Health data never leaves device via crash reporting screenshots
3. All external input validated and clamped: `max(1, min(raw, 2000))`

### Pattern 6: Concurrency Hazards in Singletons

**What happened:** `LocationManager` CheckedContinuation could resume twice if both `didUpdateLocations` and `didFailWithError` fired. Runtime crash: "SWIFT TASK CONTINUATION MISUSE."

**Rule:** Nil out continuation BEFORE resuming. Guard against concurrent requests. Extract a `resume()` helper for exactly-once semantics.

---

## Phase-by-Phase Key Learnings

### Phase 0: Market Research (30 min)

**Tools used:** Appeeky MCP (`aso_full_audit`, `get_keyword_suggestions`), web search for competitor analysis.

**Key findings:**
- "water tracker" keyword: volume 82, difficulty medium — sweet spot
- Competitor weakness: Waterllama users complain about "too many cute features, not enough function"; WaterMinder users want "simpler, cleaner"
- Market gap: No competitor does science-backed hydration intelligence (net hydration, caffeine half-life, alcohol dehydration math)

**ASO metadata (final):**
- Title: "AquaLog - Water Tracker" (25 chars)
- Subtitle: "Hydration & Drink Reminder" (26 chars)
- Keywords: water, tracker, hydration, drink, reminder, daily, intake, goal, health, log, widget, habit, counter, record, fit (97 chars)

**Rule:** Appeeky + 30 minutes of competitor 1-star review mining gives you everything you need. Don't over-research — validate in market.

### Phase 1: Core MVP (2 hrs)

**What was built:** SwiftData models (`WaterLog`, `UserSettings`), `DashboardView` with animated progress ring, `AddDrinkSheet`, `HistoryView` with weekly charts.

**Architecture decisions made upfront:**
1. SwiftData in App Group container (for future widget access)
2. `@Observable` view models with stored properties
3. Per-tab `NavigationStack`
4. All user-facing strings via `String(localized:)`

**Key learning — Progress ring rendering:**
`AngularGradient` on progress ring looked wrong at small fill percentages (<15%). Switched to `LinearGradient`. **Rule:** Always test visual components at extreme values (0%, 5%, 50%, 100%).

### Phase 2: Intelligence Engine (3 hrs)

**5 services built:**
1. `NutrientDatabase` — 23 beverages with caffeine, sugar, alcohol, hydration factors, calories
2. `CaffeineTracker` — Half-life decay curve, sleep impact analysis
3. `AlcoholCalculator` — BAC estimation, dehydration impact, recovery time
4. `HydrationCalculator` — Personalized goals based on weight, gender, climate
5. `HealthInsightsGenerator` — Weekly trends, personalized insights

**Key decision — All pure Swift, no API dependencies:** Every calculation runs locally. No network calls, no loading states, no API costs. The intelligence IS the product.

**Net hydration formula (the differentiator):**
```
netML = (volume × hydrationFactor) - sugarProcessingCost - alcoholDehydration
sugarProcessingCost = sugarGrams × 1.0 mL
alcoholDehydration = alcoholGrams × 10.0 mL
waterDebt = max(0, volume - netML)
```

### Phase 3: Multi-Surface (2 hrs)

**Built:** 3 widget sizes (small/medium/lock screen), Control Center widget (iOS 18), Watch app + complication, AppIntents (Siri/Shortcuts), Live Activity.

**AppIntents first, everything else is free.** One `LogDrinkIntent` powers:
- Home Screen widget tap → logs 250mL water
- Control Center widget → logs 250mL water
- Siri: "Log a glass of water" → logs via intent
- Shortcuts app → automation triggers

**Widget timer display:** Use `Text(date, style: .timer)` for countdowns — Apple renders it, zero CPU cost, always accurate even after app termination.

**Critical bug found later (Pattern 1):** Widget intents only wrote to UserDefaults, not SwiftData. Caught in code review, not in testing. **Rule:** Integration test after building any multi-surface feature: log from widget, verify in main app history.

### Phase 4: Onboarding + Paywall (1.5 hrs)

**Onboarding:** 3-page `SmartOnboardingView` — welcome, feature highlight, goal setup.

**Paywall:** `PaywallView` with RevenueCat integration. 6 premium features advertised:
1. Health Timeline
2. Alcohol Calculator
3. Caffeine Tracker
4. Weekly Body Report
5. Export Data (CSV)
6. 23+ Beverages with full nutrition data

**RevenueCat setup:**
- Project: RightBehind
- Entitlement: "premium"
- Products: monthly ($3.99), yearly ($29.99), lifetime ($49.99)
- API key in `StoreManager` (should be in xcconfig — Pattern 3 finding)

### Phase 5: Code Review (4 hrs)

**8-agent review uncovered 21 issues across 20 files.** This was the highest-ROI phase — estimated 40-80 hours of production firefighting prevented.

| Category | Count |
|----------|-------|
| Data loss | 5 |
| Security | 5 |
| Reliability | 4 |
| Performance | 3 |
| Standards | 3 |
| Testing | 1 |

**12 P1 issues fixed in first PR** (317 lines added, 110 removed).

**Key insight:** The 6 patterns that emerged are portable to every iOS app. They're documented in `docs/COMPOUND_REPORT.md` and should be checked against at the start of every new project.

### Phase 6: QA Testing + TestFlight (3 hrs)

**10 bugs fixed in QA session.** Then TestFlight upload validation errors:

**TestFlight rejection lessons (now in `templates/TESTFLIGHT_CHECKLIST.md`):**

1. **`CODE_SIGN_IDENTITY = "iPhone Developer"` hardcoded** → Forces development signing even during archive. Remove it; let automatic signing pick the right identity.
2. **Widget extension missing `DEVELOPMENT_TEAM`** → Add explicitly to each target's Debug and Release configs.
3. **`CFBundleDisplayName` missing in widget Info.plist** → Extensions with `GENERATE_INFOPLIST_FILE = NO` need it in their actual plist.
4. **iPad orientations** → Must include all 4 orientations if `TARGETED_DEVICE_FAMILY` includes iPad.
5. **App icon with alpha channel** → Flatten with PIL: open as RGBA, paste onto white RGB, save.
6. **Sentry dSYM warning** → Non-blocking. "Upload Symbols Failed" for Sentry.framework is just about Sentry's own symbolication.

**Build number lesson:** Build 6 rejected with `ITMS-90189` (duplicate). Must increment `CURRENT_PROJECT_VERSION` before every archive. Use `agvtool new-version -all N`.

### Phase 7: Premium Gating Fix (1 hr)

**Bug:** Premium beverages (espresso, latte, green tea, herbal tea, smoothie, diet soda, energy drink) could be added without paying. The lock icon was purely cosmetic — tapping a locked beverage selected it, and the Add button worked.

**Fix:** Three-layer defense (see Architecture Decision #5 above).

**Also fixed:**
- Orange Juice icon: `carrot.fill` → `waterbottle.fill` (wrong SF Symbol)
- Added 5 new premium juice options: Apple Juice, Grape Juice, Cranberry Juice, Lemonade, Pineapple Juice
- Smart category auto-select (see Architecture Decision #6)

---

## Cross-Phase Recurring Bug Patterns

### Pattern A: Cosmetic-Only Feature Gating (Phases 4, 7)

Lock icons, grayed text, and disabled states that don't actually prevent the action. Found twice:
1. Premium beverages selectable despite lock icon
2. Category auto-select landing on locked items with no explanation

**Rule:** Every locked feature must intercept the action AND present the paywall. Cosmetic indicators supplement but never replace behavioral gates.

### Pattern B: Silent Error Swallowing (Phases 1, 5)

`try?` and empty `catch {}` blocks on user-critical paths (saves, fetches) that silently lose data.

**Rule:** All user-initiated saves and SwiftData fetches use explicit `do/catch` + Sentry capture + `.alert(error:)`.

### Pattern C: Enum vs Database Evolution (Phases 1, 2, 7)

Started with `Beverage` enum (8 cases), evolved to `NutrientDatabase` (23+ profiles), had to maintain backward compatibility via `displayInfo(for:)` bridge.

**Rule:** If the domain has >10 items or rich metadata, start with a struct database from day one. Enums are for fixed, small sets.

### Pattern D: TestFlight Validation Surprises (Phase 6)

Every issue in Phase 6 was invisible during local development. They only surfaced at archive/upload time.

**Rule:** Run the TestFlight checklist before the first archive of any new app. Most validation errors only appear at upload, not at build.

---

## Services Inventory (13 Core Services)

| Service | Purpose | Reusable? |
|---------|---------|-----------|
| `StoreManager` | RevenueCat subscription handling | ✅ Swap product IDs |
| `HealthKitManager` | Apple Health read/write | ✅ As-is |
| `NotificationManager` | Local push notifications | ✅ As-is |
| `SmartNotificationManager` | Adaptive reminder timing | ⚠️ App-specific logic |
| `NutrientDatabase` | 23+ beverage profiles with nutrition | ⚠️ Domain-specific |
| `HydrationCalculator` | Personalized hydration goals | ⚠️ Domain-specific |
| `CaffeineTracker` | Caffeine half-life tracking | ⚠️ Domain-specific |
| `AlcoholCalculator` | Dehydration + BAC estimation | ⚠️ Domain-specific |
| `HealthInsightsGenerator` | Weekly analytics + insights | ⚠️ App-specific |
| `LiveActivityManager` | Dynamic Island + Lock Screen | ✅ Pattern reusable |
| `LocationManager` | Temperature-based adjustments | ✅ Pattern reusable |
| `WorkoutDetector` | Activity recognition | ⚠️ Domain-specific |
| `AppIntents` | Siri + Shortcuts + widget actions | ✅ Pattern reusable |

---

## Screens Inventory (9 Main Screens)

| Screen | Tab | Features |
|--------|-----|----------|
| `DashboardView` | Dashboard | Animated progress ring, quick-add buttons, today's drink log |
| `AddDrinkSheet` | (Sheet) | Category filter, beverage grid with premium gating, hydration intelligence, amount picker |
| `HistoryView` | Analytics | Weekly bar charts, daily breakdown, trend analysis |
| `CaffeineChartView` | Analytics | Caffeine intake visualization, half-life decay |
| `HealthTimelineView` | Analytics | Comprehensive health event timeline |
| `BodyReportView` | Analytics | Body metrics, hydration analysis |
| `AlcoholImpactView` | Analytics | Dehydration analysis, BAC, recovery time |
| `SettingsView` | Settings | Goals, units, reminders, premium upsell, export |
| `SmartOnboardingView` | (Modal) | 3-page welcome, goal picker, unit selection |
| `PaywallView` | (Sheet) | Premium features, pricing tiers, trial CTA |

**Components:**
- `ProgressRingView` — Custom animated circular progress indicator
- `LegalTextView` — Privacy/terms disclaimers
- `MainTabView` — Tab navigation container (Dashboard/Analytics/Settings)

---

## Widget & Watch Targets

**Home Screen Widgets (WidgetKit):**
- Small: Progress ring + percentage
- Medium: Progress ring + intake/goal + quick-add button
- Lock Screen: Circular gauge (iOS 16+)

**Control Center Widget (iOS 18):**
- Water drop icon + 1-tap quick log

**Apple Watch (watchOS 10+):**
- `WatchDashboardView` — Simplified hydration UI with large "+" button
- `WatchComplication` — Progress ring + current intake on watch face

**Live Activity:**
- Dynamic Island compact/expanded showing hydration progress
- Lock Screen Live Activity with progress bar

---

## Pre-Launch Checklist (Built from All Phases)

### Data Integrity
- [ ] Every entry point (main app, widget, Siri, Watch) writes to shared SwiftData
- [ ] No silent `catch {}` blocks on save/delete operations
- [ ] UserDefaults is a cache, not source of truth for user data
- [ ] `fatalError` never used in persistence initialization
- [ ] Schema migration strategy documented and tested

### Security & Privacy
- [ ] No API keys hardcoded as string literals (use xcconfig/Info.plist)
- [ ] DEBUG and RELEASE use different service keys
- [ ] Crash reporting does NOT capture screenshots of health data
- [ ] Authorization state from RevenueCat, not local database
- [ ] All external input (Siri, Shortcuts, widgets) validated and clamped
- [ ] `PrivacyInfo.xcprivacy` accurately reflects data usage

### Premium Gating
- [ ] Every locked feature intercepts the action (not just shows an icon)
- [ ] Tapping a locked item presents `PaywallView`
- [ ] Category/list auto-select never lands on a locked item for free users
- [ ] Add/submit buttons redirect to paywall when premium is required
- [ ] Premium state cached in UserDefaults for offline grace

### Reliability
- [ ] Persistence init has graceful fallback (in-memory store)
- [ ] Offline mode tested: premium features work without network
- [ ] CheckedContinuation wrappers have exactly-once resume semantics

### Performance
- [ ] SwiftData queries use date predicates (no unbounded full-table loads)
- [ ] Computed properties in views captured as `let`, not recomputed per render
- [ ] DateFormatters are static/cached

### Accessibility & Standards
- [ ] Every interactive element has `.accessibilityLabel()`
- [ ] Dynamic Type supported (no hardcoded sizes without `.minimumScaleFactor`)
- [ ] Dark Mode tested on every screen
- [ ] All user-facing strings via `String(localized:)`

### TestFlight Upload
- [ ] No hardcoded `CODE_SIGN_IDENTITY` — let automatic signing work
- [ ] `DEVELOPMENT_TEAM` set on every target (main app + extensions)
- [ ] `CFBundleDisplayName` in all extension Info.plists
- [ ] iPad orientations include all 4
- [ ] App icon has no alpha channel (`sips -g hasAlpha`)
- [ ] Build number incremented (`agvtool new-version -all N`)

---

## File Organization Reference

```
AquaLog/
├── App/
│   └── AquaLogApp.swift              # @main, Sentry + RevenueCat init
├── Models/
│   ├── BeverageType.swift             # Legacy enum + NutrientDatabase bridge
│   ├── WaterLog.swift                 # @Model — drink entries
│   ├── UserSettings.swift             # @Model — goals, units, preferences
│   └── HydrationActivityAttributes.swift  # Live Activity data
├── ViewModels/
│   └── DashboardViewModel.swift       # @Observable, stored properties
├── Views/
│   ├── Screens/
│   │   ├── DashboardView.swift        # Main hydration dashboard
│   │   ├── HistoryView.swift          # Weekly charts + daily breakdown
│   │   ├── SettingsView.swift         # Goals, reminders, premium
│   │   ├── CaffeineChartView.swift    # Caffeine visualization
│   │   ├── HealthTimelineView.swift   # Health event timeline
│   │   ├── BodyReportView.swift       # Body metrics
│   │   └── AlcoholImpactView.swift    # Alcohol dehydration analysis
│   ├── Components/
│   │   ├── ProgressRingView.swift     # Animated circular progress
│   │   └── LegalTextView.swift        # Privacy/terms text
│   ├── Dashboard/
│   │   └── MainTabView.swift          # Tab navigation
│   ├── Onboarding/
│   │   └── SmartOnboardingView.swift  # 3-page onboarding
│   └── Paywall/
│       └── PaywallView.swift          # Premium subscription UI
├── Services/                          # 13 services (see inventory above)
├── Extensions/
│   ├── Date+Helpers.swift
│   └── Int+Volume.swift
├── Resources/
│   └── Assets.xcassets/
├── AquaLogWatch/                      # watchOS target
├── AquaLogWidgets/                    # Widget + Live Activity extension
└── AquaLogTests/
```

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Swift files | 49 (36 main, 3 watch, 4 widgets, 1 test, 5 templates) |
| Lines of code | ~2,300 (main app) |
| App size | 2.8 MB |
| Services | 13 |
| Screens | 9 main + 4 sub-screens |
| Beverage profiles | 28 (6 free, 22 premium) |
| Code review issues | 21 (12 P1, 7 P2, 2 P3) |
| QA bugs fixed | 10 |
| PRs merged | 6 |
| TestFlight builds | 7 |
| Development time | ~17 hours across 2 weeks |
| Estimated firefighting prevented | 40-80 hours |

---

## Comparison with FastTrack Build

| Aspect | AquaLog | FastTrack |
|--------|---------|-----------|
| Category | Health & Fitness (hydration) | Health & Fitness (fasting) |
| Phase count | 8 (informal → structured) | 8 formal phases |
| Development time | ~17 hrs | TBD |
| Code review structure | Post-hoc 8-agent review | Per-phase structured review |
| Bug tracking | Compound report + QA session | Numbered todos (013-067) |
| Domain complexity | Medium (nutrient calculations) | Medium (timer + zones) |
| Widget pattern | AppIntents first ✅ | AppIntents first ✅ (confirmed) |
| Timer pattern | N/A (CRUD app) | `startDate` persistence + `Text(date, style: .timer)` |
| Paywall | RevenueCat | Native StoreKit 2 |
| Premium gating | Defense-in-depth (3 layers) | `GatedContent` wrapper view |
| Strict concurrency | Partially addressed | Fully addressed |
| Onboarding | 3-page `SmartOnboardingView` | 7-screen `ZStack/switch` |
| Test coverage | Minimal (noted as P1) | 17 tests from Phase 1 |
| Key differentiator | Net hydration intelligence | Zone-aware fasting science |

---

## Templates to Carry Forward

These files from AquaLog are reusable with minimal changes:

| File | Reuse Level |
|------|-------------|
| `StoreManager.swift` | Full reuse — swap product IDs and API key |
| `HealthKitManager.swift` | Full reuse — swap HealthKit data types |
| `NotificationManager.swift` | Full reuse — swap notification content |
| `LiveActivityManager.swift` | Pattern — swap activity attributes |
| `AppIntents.swift` | Pattern — swap intent parameters and persistence calls |
| `PaywallView.swift` | Pattern — swap feature list and pricing |
| `SmartOnboardingView.swift` | Pattern — swap pages and goal setup |
| `ProgressRingView.swift` | Full reuse — configurable colors and progress |
| `AddDrinkSheet.swift` premium gating | Pattern — 3-layer defense applicable to any gated content |
| `NutrientDatabase.swift` structure | Pattern — static database with O(1) lookup and category filtering |

---

## What to Decide Before Writing Code (Updated)

Run through these decisions at the start of every new app:

1. **Data model at scale.** Will you have 10+ items with rich metadata? → Start with a struct database, not an enum.
2. **Multi-surface from day one?** → Plan App Group container + shared persistence function before writing any view.
3. **Premium gating strategy.** → Defense-in-depth: intercept action + redirect to paywall + disable button as safety net. Never cosmetic-only.
4. **StoreKit 2 native or RevenueCat?** → RevenueCat recommended for faster iteration. Design `StoreManager` interface to be swappable regardless.
5. **What's the intelligence angle?** → Pure Swift calculations that run locally differentiate without API costs. (AquaLog: net hydration. FastTrack: fasting zones.)
6. **Notification permission timing?** → After first value event, not during onboarding.
7. **TestFlight checklist.** → Run `templates/TESTFLIGHT_CHECKLIST.md` before first archive. Every item was invisible during local development.

---

## Remaining Work Before Launch

| # | Task | Priority | Effort |
|---|------|----------|--------|
| 1 | Streak logic correctness (stale reads, midnight edge) | P1 | 2-3h |
| 2 | Remaining silent save failures (revert UI on error) | P1 | 1-2h |
| 3 | Unit test coverage for business logic | P1 | 8-16h |
| 4 | Bounded SwiftData queries in 4 views | P1 | 2-3h |
| 5 | UIKit usage + force unwraps in production code | P1 | 1-2h |
| 6 | Accessibility labels + Localizable.xcstrings | P2 | 3-4h |
| 7 | PrivacyInfo.xcprivacy accuracy | P2 | 1h |
| 8 | 4 views missing ViewModels (MVVM violation) | P2 | 4-6h |
| 9 | Performance micro-optimizations (DateFormatter, MainActor) | P3 | 2h |
| 10 | Dead code cleanup + file organization | P3 | 3-4h |
| 11 | App Store submission + ASO campaign setup | P1 | 2h |

---

## Key Takeaway

> **The fastest way to ship reliable iOS apps is to get two things right on day one: the persistence architecture and the premium gating.** AquaLog's bugs split cleanly into data-not-flowing-through-a-canonical-path and gates-that-don't-actually-gate. Fix the architecture, block the actions, and the entire class of bugs disappears.

The 6 bug patterns and the premium gating defense-in-depth pattern documented here are portable. Copy the pre-launch checklist into every new project. Run an 8-agent review before every submission. Compound the lessons.

---

*Generated April 14, 2026. Covers Phases 0–7, 15 commits, 6 PRs. Phase 8 (App Store submission + launch marketing) pending.*
