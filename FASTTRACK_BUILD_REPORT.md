# FastTrack — Build Report
## Development Progress, Decisions, and Compound Fixes (April 2–4, 2026)

This document captures the full development history of FastTrack: every architectural decision, every code review finding, and the recurring patterns that emerged across 7 phases. The goal is to make every future app build faster and cleaner by front-loading these lessons.

---

## App Overview

**FastTrack** is an intermittent fasting timer for iOS targeting users frustrated with overpriced, underbuilt competitors (Zero, Simple, Fastic — $60–70/yr behind heavy paywalls).

**Positioning:** Apple-native depth + fair pricing ($34.99/yr vs $60–70/yr competitors)  
**Free tier:** 16:8 protocol, 7-day history, full timer  
**Pro tier:** All protocols, unlimited history, analytics, premium widgets  
**Bundle ID:** `com.rightbehind.fasttrack`

**Tech stack:** SwiftUI + SwiftData + StoreKit 2 (native) + WidgetKit + ActivityKit + AppIntents

---

## Phase Timing (Actual)

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | SwiftData models + fasting engine | ✅ Complete |
| Phase 2 | Core timer UI | ✅ Complete |
| Phase 3 | Onboarding (7 screens) | ✅ Complete |
| Phase 4 | Paywall & monetization | ✅ Complete |
| Phase 5 | History & analytics | ✅ Complete |
| Phase 6 | Widgets & Live Activities | ✅ Complete |
| Phase 7 | Settings & polish | ✅ Complete |
| Phase 8 | Quality gate & App Store submission | 🚧 Pending |

**Total code review findings across 7 phases:** 67 (todos 013–067)  
- 🔴 P1 Critical: ~13 (blocked launch)
- 🟡 P2 Important: ~32
- 🔵 P3 Polish: ~22

---

## Architecture Decisions (What to Reuse)

### 1. Data Layer: App Group Hybrid

**Pattern:** Hot state in App Group `UserDefaults`, full history in SwiftData.

| Data | Storage | Rationale |
|------|---------|-----------|
| Active fast start time | App Group `UserDefaults` | Instant read in widgets, no SwiftData load |
| `isPro` entitlement | App Group `UserDefaults` | Checked on every launch, can't wait for SwiftData |
| Selected fasting protocol | App Group `UserDefaults` | Needed by widgets + AppIntents |
| Completed fasts (history) | SwiftData | Queryable, relational, sortable |
| Weight entries | SwiftData | Historical records |
| Streak state | SwiftData `@Model` | Needs protection logic; authoritative model |

**Key rule:** App Group `UserDefaults` is the hot path. SwiftData is the record of truth. Never read SwiftData in widget timeline providers or AppIntents.

### 2. No Background Timer

The app persists `startDate` on fast start and computes elapsed time on foreground. Widgets use `Text(date, style: .timer)` — Apple renders the countdown, zero CPU cost, always accurate even after termination.

**Avoid:** Background `Timer`, background tasks, `BGProcessingTask` for a simple countdown. Persist start time; compute on wake.

### 3. Streak as a Separate `@Model`

**Why not computed:** Widgets need streak count instantly (no history scan). Streak protection logic (grace periods) must be centralized in `StreakManager`, not recalculated by anyone who needs the number.

**Pattern:**
```swift
@Model final class Streak {
    var currentCount: Int
    var lastFastDate: Date
    var protectionUsedThisWeek: Bool
}
```

Anything that needs the streak reads `Streak.currentCount`. No recomputation anywhere else. (Violating this caused Finding 045 — infinite loop in analytics.)

### 4. Enum Storage as String Raw Values

Store all enums in SwiftData models as `String` raw values. This enables `#Predicate` filtering, graceful fallback for unknown values post-schema evolution, and migration safety.

```swift
// In @Model:
var protocolTypeRaw: String = FastingProtocol.sixteen8.rawValue
var protocolType: FastingProtocol {
    get { FastingProtocol(rawValue: protocolTypeRaw) ?? .sixteen8 }
    set { protocolTypeRaw = newValue.rawValue }
}
```

### 5. Navigation: Per-Tab NavigationStack

Tab-based apps: each tab owns its own `NavigationStack` with a `NavigationPath`. No global `AppRouter`. Deep links set `selectedTab` and push onto the relevant path.

**Do not use:** A single global `AppRouter` for tab apps. It creates unnecessary coupling and makes sheet/deep-link coordination harder.

### 6. Feature Gating: `GatedContent` View (Not Modifier)

```swift
struct GatedContent<Content: View, Locked: View>: View {
    let isPro: Bool
    @ViewBuilder var content: () -> Content
    @ViewBuilder var locked: () -> Locked
}
```

**Why not a ViewModifier:** Modifiers that intercept taps or replace content break SwiftUI's gesture system. A wrapper view with an `if/else` is composable, testable, and doesn't interfere with gestures.

**Every locked branch must have an upgrade CTA** — a locked view with no "Upgrade" button is a conversion leak. (Finding 043 caught this in Analytics.)

### 7. `@Observable` + Stored Properties for UI State

All view models use `@Observable` macro (iOS 17+). All UI-reactive properties must be **stored** properties, not computed. Computed properties 2+ levels deep break SwiftUI reactivity (same lesson from AquaLog).

```swift
@Observable
final class FastingEngine {
    var isActive: Bool = false          // ✅ stored
    var progress: Double = 0.0          // ✅ stored — recomputed explicitly
    var currentZone: FastingZone = .fed // ✅ stored
    
    func tick() {
        // Recalculate and assign stored properties
        progress = computeProgress()
        currentZone = computeZone()
    }
}
```

---

## Phase-by-Phase Key Learnings

### Phase 1: Data Models & Core Engine

**What to do first:**
1. Define all enums before models (protocol types, states, zones)
2. Design App Group `UserDefaults` extension as the first file (`UserDefaults+Shared.swift`)
3. Create test suite at Phase 1 — 17 tests from the start caught regressions in every subsequent phase

**Critical bugs found:**

**Bug 013 — Capture observable state BEFORE mutations that invalidate it**
```swift
// ❌ Wrong: endFast() sets activeFast = nil, so progress returns 0
fastingEngine.endFast(...)
if fastingEngine.progress >= 1.0 { showCompletionSheet = true }

// ✅ Correct: capture before
let wasCompleted = fastingEngine.progress >= 1.0
fastingEngine.endFast(...)
if wasCompleted { showCompletionSheet = true }
```
**Rule:** If a mutation invalidates the state you're about to read, capture it first.

**Bug 014 — `@State` in App struct must be injected or removed**

Any `@State private var X` in `@main App` that isn't passed to `.environment()` is an orphan. Grep for `@State private var` in app entry point after every session.

**Bug 015 — No `DispatchQueue.main.asyncAfter` in Swift 6 code**
```swift
// ❌ Violates strict concurrency
DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { ... }

// ✅ Correct
Task { @MainActor in
    try? await Task.sleep(for: .seconds(0.15))
    trigger.toggle()
}
```

**Bug 016 — No `import UIKit` in SwiftUI views (iOS 17+)**
- Haptics: use `.sensoryFeedback()` modifier with `@State` bool trigger
- Accessibility announcements: use `AccessibilityNotification.Announcement(...).post()`
- UIKit is acceptable in `@MainActor` service classes, never in views

**Bug 018 — User preferences need `didSet` writer + `init()` reader**
```swift
var selectedProtocol: FastingProtocol = .sixteen8 {
    didSet { UserDefaults.shared.selectedProtocolRaw = selectedProtocol.rawValue }
}
init() {
    if let raw = UserDefaults.shared.selectedProtocolRaw,
       let proto = FastingProtocol(rawValue: raw) {
        selectedProtocol = proto
    }
}
```
Any `@Observable` property that should survive app termination needs both halves.

---

### Phase 2: Timer UI

**What worked well:**
- `TimelineView(.periodic(every: 1))` over `Timer.publish()` — only the content closure re-evaluates, not the entire view body
- `Circle().trim().stroke()` for progress ring — fully declarative, animatable with `.animation(.linear, value: progress)`
- Haptic milestone celebrations: `Int` milestone trigger + `.symbolEffect(.bounce)` auto-resets (don't use `Bool` — it doesn't re-fire if already true)

**Key rule — Accessibility labels use `String(localized:defaultValue:)`:**
```swift
// ❌ Raw string interpolation (not localized)
.accessibilityLabel("Protocol: \(proto.displayName). Tap to change")

// ✅ Localized with runtime value in defaultValue only
.accessibilityLabel(String(
    localized: "accessibility.header.protocol",
    defaultValue: "Selected protocol: \(proto.displayName). Tap to change"
))
```
**Gotcha:** The `key:` parameter is `StaticString` — no runtime interpolation. Only `defaultValue` accepts it.

---

### Phase 3: Onboarding

**Navigation pattern:** `ZStack` + `switch` on current step. Do NOT use `TabView(.page)` — users can swipe freely, breaking required linear progression.

**Animation with `accessibilityReduceMotion`:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

withAnimation(reduceMotion ? .none : .spring()) {
    // animate
}
```
Every animation site must check this. Apple may flag it in accessibility audits.

**GCD → structured concurrency in views:**
```swift
// ❌ GCD in SwiftUI view
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { step += 1 }

// ✅ Structured, cancellable, Swift 6 safe
.task {
    try? await Task.sleep(for: .milliseconds(500))
    step += 1
}
```
`.task { }` is automatically cancelled when the view disappears. GCD is not.

**`@Bindable` is for write bindings only.** If you only read from a view model in a child view, pass it as a regular `let` property. `@Bindable` on a read-only reference is misleading and wasteful.

**Error handling on SwiftData saves:**
```swift
// ❌ Silent failure — user stuck on onboarding forever
try? modelContext.save()

// ✅ Show error + allow retry
do {
    try modelContext.save()
} catch {
    saveError = error
}
// Bound to .alert(error: $saveError)
```

---

### Phase 4: Paywall & Monetization

**This phase had 2 P1 launch blockers.** Both are common StoreKit 2 mistakes.

**Bug 026 — StoreKit listener lifetime (most common StoreKit 2 mistake)**

`async let _ = listenForTransactionUpdates()` creates a child task cancelled when the function returns. Background renewals, family sharing, and Ask to Buy were silently dropped.

```swift
// ❌ Cancelled when configure() returns
func configure() async {
    async let _ = listenForTransactionUpdates()
}

// ✅ Lifetime tied to the object
private var listenerTask: Task<Void, Never>?

func configure() async {
    listenerTask = Task { await listenForTransactionUpdates() }
}
deinit { listenerTask?.cancel() }
```
**Reference:** WWDC22 Session 10007. Apple's own StoreKit 2 samples use stored `Task` property.

**Bug 027 — No hardcoded social proof at launch**

Hardcoded "Loved by 10,000+ fasters" / "Join 50,000+ users" violated App Store Guideline 2.3.7 and would cause rejection. Remove entirely until you have real data. Never ship fabricated numbers.

**Bug 028 — Service layer owns schedulers (not views)**

`NotificationScheduler` was inside `PaywallView`, so `StoreManager` couldn't cancel trial nurture on background purchase. Rule: anything a service needs to call belongs in the service layer, not in a view.

```swift
@Observable final class StoreManager {
    private let notificationScheduler = NotificationScheduler() // owned here
    
    func handle(_ transaction: Transaction) async {
        isPro = true
        notificationScheduler.cancelTrialNurture() // called atomically
        await transaction.finish()
    }
}
```

**Bug 029 — No `URL(string:)!` force unwraps**

Extract all static URLs to `enum AppConstants.AppURL` with optional (not force-unwrapped) values:
```swift
enum AppConstants {
    enum AppURL {
        static let terms = URL(string: "https://example.com/terms")  // Optional<URL>
    }
}
// At call site:
if let url = AppConstants.AppURL.terms { Link("Terms", destination: url) }
```

**Bug 031 — Never use `debugDescription` in accessibility labels**

`product.subscription?.subscriptionPeriod.unit.debugDescription` produces raw enum names, not user-facing text. Use `product.displayPrice` — StoreKit's already-localized, formatted string.

**Bug 033 — Never hardcode prices in notifications**

`"Upgrade for $34.99/year"` is wrong for non-USD storefronts and stale if the price changes. Use price-agnostic copy: `"Your free trial ends soon — upgrade to keep your progress."`

**What to pre-decide:**
- Native StoreKit 2 or RevenueCat SDK? FastTrack chose native first; API was designed for a clean swap to RevenueCat later. This is valid if you design the service interface correctly.
- `isPro` must be cached in App Group `UserDefaults` at first launch. Never check entitlement status on the main thread at app startup.

---

### Phase 5: History & Analytics

**This phase had the most findings (18) and the most severe performance bugs.**

**Bug 034/045/047 — Single source of truth for streak**

Do NOT recompute streak from analytics data. `Streak.currentCount` maintained by `StreakManager` is the authoritative value. Reading it is one line. Reimplementing streak logic creates a loop with edge cases (infinite loops on corrupted data, midnight resets, 90-day cap).

```swift
// In AnalyticsView — just query the model
@Query private var streaks: [Streak]
private var currentStreak: Int { streaks.first?.currentCount ?? 0 }
```

**Bug 038 — O(n²) calendar rendering (cached lookup sets)**

Calendar grids call `hasFast(on:)` 62 times per render (31 cells × view + accessibility). With 500 fasts and linear search, that's 31,000 comparisons per render pass.

```swift
// ❌ Computed every access — O(n) per cell
var fastDays: Set<DateComponents> { Set(fasts.map { ... }) }

// ✅ Built once when data changes — O(1) lookup
private(set) var fastDays: Set<DateComponents> = []

func updateFasts(_ newFasts: [Fast]) {
    fasts = newFasts
    fastDays = Set(newFasts.compactMap {
        Calendar.current.dateComponents([.year, .month, .day], from: $0.startDate)
    })
}
```
**Rule:** Any grid or list doing per-cell lookups needs a pre-built `Set` or `Dictionary`, updated via `.onChange(of:)`, not recomputed per render.

**Bug 039 — `@ModelActor` is serial; `async let` doesn't parallelize**

`async let` on the same `@ModelActor` queues all tasks behind the same lock. Time = sum of all fetches, not the fastest. Use a single fetch + pure aggregation functions:

```swift
// ❌ Three fetches, zero parallelism
async let weekly = actor.fetchWeekly()
async let zones = actor.fetchZones()
async let activity = actor.fetchActivity()

// ✅ One fetch, three pure functions
func computeAll() throws -> (weekly, zones, activity) {
    let fasts = try modelContext.fetch(descriptor)
    return (
        computeWeeklyStats(from: fasts),
        computeZoneDistribution(from: fasts),
        computeDayActivity(from: fasts)
    )
}
```

**Bug 040 — Every `Task` that updates state must be stored and cancelled**

```swift
// ❌ Leaked task — runs after view model is released
func loadData() {
    Task.detached { await self.fetchAnalytics() }
}

// ✅ Owned, cancellable
nonisolated(unsafe) private var loadTask: Task<Void, Never>?
deinit { loadTask?.cancel() }

func loadData() {
    loadTask?.cancel()
    loadTask = Task { @MainActor [weak self] in ... }
}
```

**Bug 041 — Never `try?` SwiftData fetches in production paths**

`try?` converts failures into empty arrays. Users see "Not Enough Data" with no idea their data failed to load. Always use explicit `do/catch` + Sentry capture + `.alert`:

```swift
do {
    let result = try await actor.computeAll()
} catch {
    SentrySDK.capture(error: error)
    self.error = error  // bound to .alert in the view
}
```

**Bug 042 — Average of averages is not the true mean**

Mean of per-week averages is not the mean across all fasts. An active week (6 fasts) and a light week (1 fast) contribute equally, inflating the average for irregular fasters. Always compute from the full dataset.

**Bug 046 — No computed `var` in `View` accessed multiple times per render**

If a value is set at `init` time or updated infrequently, store it as `let`:

```swift
// ❌ Computed on every body evaluation
private var weeks: [[DayActivity?]] { buildWeeks() }

// ✅ Computed once in init
private let weeks: [[DayActivity?]]
init(activity: [DayActivity]) {
    self.activity = activity
    self.weeks = buildWeeks(from: activity)
}
```

**Bug 049 — Calendar cells must have 44pt hit area**

Visual size can be smaller, but the touch target must be ≥44pt:
```swift
CalendarDayCell(...)
    .frame(minHeight: 44)
    .contentShape(Rectangle())
```

---

### Phase 6: Widgets & Live Activities

**AppIntents architecture:** Same pattern as AquaLog — build AppIntents first; they power widgets, Control Center, and eventually Siri for free.

**Timer display:** Always use `Text(date, style: .timer)` for countdowns in widgets and Live Activities. System-rendered, zero CPU cost, accurate after termination.

**Bug 052 — Widget intent stop must set a "was stopped" flag**

`ToggleFastIntent` stopping the fast wrote to UserDefaults, but when the app foregrounded it called `recalculateFromPersistence()` which found no SwiftData record and restarted the fast as if nothing happened.

Fix: Add `activeFastWasManuallyStopped` flag to App Group `UserDefaults`. `recalculateFromPersistence()` checks this flag before restoring state.

**Bug 053 — Widget intent start must have a backfill path**

When the widget intent starts a fast, `FastingEngine.recalculateFromPersistence()` must handle the case where UserDefaults has a start time but no SwiftData `Fast` record (because the record is created by the app, not the intent). Add a "create ghost fast" backfill path.

**Bug 056 — Register deep link URL scheme in Info.plist**

`fasttrack://` links from widgets (pro upgrade CTA) did nothing because `CFBundleURLTypes` was missing from `Info.plist`. Add this in `project.yml` for every app using deep links.

**Bug 057 — Live Activity dismissal requires two steps**

Calling `.end(dismissalPolicy: .immediate)` dismisses the Live Activity before the user sees the completion state. The correct sequence:
1. Call `activity.update(...)` with a "completed" content state
2. Call `activity.end(..., dismissalPolicy: .after(Date.now + 3))` — let it show for 3 seconds

**Duplicate logic between intent types:** `ToggleFastIntent` and `ToggleFastControlIntent` had identical toggle logic. Extract to a shared `performToggle()` function referenced by both.

---

### Phase 7: Settings & Polish

**Notification permission timing:** Request after first completed fast, not during onboarding. Users who have experienced the app's value are far more likely to grant permission.

**Review prompt pattern:**
1. Sentiment gate first: "Are you enjoying FastTrack?" → "Love it!" or "Not really"
2. Only `SKStoreReviewController.requestReview()` on "Love it!"
3. "Not really" → feedback form (don't send negative users to the App Store)
4. Caps: 2 prompts per app version, 3 per calendar year

**Bug 059 — Zone transition notifications: add call sites after implementing the notification method**

`FastingEngine.scheduleZoneNotification()` was implemented but never called. Add call sites in `triggerZoneTransitionEffects()` and `recalculateFromPersistence()`. Implementing a method without adding its call sites is a common oversight — always search for call sites immediately after writing a new method.

**Bug 062 — `FastingEngine` mutable public state → `private(set)`**

UI-trigger flags (`shouldShowZoneTransitionEffect`, `shouldShowCompletionSheet`) were publicly mutable. Views could accidentally set them, bypassing the engine's control logic. Mark `private(set)` and expose consume methods:

```swift
private(set) var shouldShowZoneTransitionEffect = false
func consumeZoneTransitionEffect() { shouldShowZoneTransitionEffect = false }
```

**Bug 065 — Settings notification prefs use `@AppStorage`, not `@State`**

`@State` copies the UserDefaults value at init — it goes stale if the value changes from another path (e.g., the notification scheduler updates the setting). `@AppStorage` is a live binding to UserDefaults.

```swift
// ❌ Stale copy
@State private var zoneNotificationsEnabled = UserDefaults.shared.zoneNotificationsEnabled

// ✅ Live binding
@AppStorage("zoneNotificationsEnabled") private var zoneNotificationsEnabled = true
```

**Bug 066 — Review prompt missing annual cap**

`SKStoreReviewController` only shows the system dialog ~3 times/year regardless, but you should track your own cap to avoid spamming at the app level. Store `lastReviewPromptYear` and reset count each calendar year.

**Bug 067 — Notification auth status goes stale after foreground**

The OS can revoke notification permission while the app is in the background. Refresh `UNUserNotificationCenter.current().notificationSettings()` whenever `scenePhase` changes to `.active`.

---

## Cross-Phase Recurring Bug Patterns

These same bugs appeared in multiple phases. Front-load awareness of these patterns.

### Pattern 1: Task Lifetime Bugs (Appeared in Phases 3, 4, 5)

The most common bug class across all phases. Any async work not owned by a stable stored property will be cancelled or leaked.

| Phase | Manifestation | Fix |
|-------|--------------|-----|
| Phase 3 | `DispatchQueue.main.asyncAfter` (GCD — not cancellable, violates Swift 6) | `.task { try? await Task.sleep(...) }` |
| Phase 4 | `async let _ = listenForTransactionUpdates()` (cancelled when function returns) | Stored `Task<Void, Never>?` property, cancelled in `deinit` |
| Phase 5 | `Task.detached { }` not stored (runs after view model released) | Stored `nonisolated(unsafe) private var loadTask`, cancelled in `deinit` |

**Rule:** Every long-lived `Task` must be a stored property. Every `Task` writing to `@Observable` state must be stored and cancelled in `deinit`.

### Pattern 2: Design System Bypass Under Time Pressure (Phases 4, 5)

Raw system colors, force-unwrapped URLs, UIKit color initializers — all introduced during implementation under time pressure, not caught until review.

**Pre-commit grep commands to run on every PR:**
```bash
grep -rn 'URL(string:)!' Sources/         # force-unwrapped URLs
grep -rn 'Color(\.' Sources/Views/        # UIKit color initializer in views
grep -rn '\.orange\|\.red\|\.blue\|\.green' Sources/Views/  # raw system colors
grep -rn 'import UIKit' Sources/Views/    # UIKit in SwiftUI views
```

### Pattern 3: Duplicate Sources of Truth (Phases 4, 5)

State with two owners will eventually diverge.

| Phase | Duplicate state | Fix |
|-------|----------------|-----|
| Phase 4 | `isPro` written in multiple places | Single owner: `StoreManager` |
| Phase 5 | Streak recomputed in analytics instead of reading `Streak.currentCount` | Single owner: `StreakManager` + `Streak.currentCount` |

**Rule:** Before computing a derived value, check if a maintained model already stores it. If `StreakManager` maintains `Streak.currentCount`, nothing else should compute streak count.

### Pattern 4: Silent Error Swallowing (Phases 3, 5)

`try?` in user-critical paths (onboarding save, analytics fetch) converts errors into empty/wrong states. Users are stuck with no explanation.

**Rule:** All user-initiated saves and all SwiftData fetches that drive UI use explicit `do/catch` + Sentry capture + `.alert(error:)`.

### Pattern 5: Accessibility Label Quality (Phases 1, 2, 4, 5)

Raw strings, `debugDescription`, unlocalized interpolations, and `Optional(...)` leak into accessibility labels. Found in every phase.

**Quick checklist:**
- VoiceOver on the paywall: does every product read its localized price aloud?
- No `debugDescription` / `description` as label values
- No `Optional(...)` in spoken text
- All interactive elements (buttons, toggles, custom controls) have explicit `.accessibilityLabel()`
- `String(localized:key:defaultValue:)` — only `defaultValue` accepts runtime interpolation

---

## Pre-Launch Checklist (Built from All Phase Reviews)

Run this before every PR merge and before App Store submission.

### Concurrency
- [ ] Every long-lived `Task` is a stored property cancelled in `deinit`
- [ ] No `DispatchQueue.main.asyncAfter` — use `Task { @MainActor in }` + `Task.sleep(for:)`
- [ ] No `async let` on a single `@ModelActor` — use single fetch + pure functions
- [ ] No `Task.detached` without a stored reference
- [ ] No `try?` on user-critical SwiftData operations — use `do/catch`

### StoreKit 2
- [ ] Transaction listener stored as `Task<Void, Never>?` property, cancelled in `deinit`
- [ ] `isPro` cached in App Group `UserDefaults` — synchronous check at launch, no delay
- [ ] No hardcoded prices in notifications — use price-agnostic copy or `Product.displayPrice`
- [ ] No hardcoded user/review counts (App Store Guideline 2.3.7)
- [ ] Close button immediately visible on paywall (App Store 3.1.1 compliance)

### Design System
- [ ] `grep -rn 'URL(string:)!'` outside `#Preview` returns zero matches
- [ ] `grep -rn 'Color(\.'` in Views/ returns zero matches
- [ ] No `.orange`, `.red`, `.blue` or other raw system colors in view code — use asset catalog
- [ ] `grep -rn 'import UIKit'` in Views/ returns zero matches

### Performance
- [ ] No computed `var` in `View` structs accessed multiple times per render — capture as `let`
- [ ] Grid/list lookup sets (`fastDays`, etc.) are stored `Set`/`Dictionary`, updated via `.onChange(of:)`
- [ ] `@Query`-filtered data not re-filtered in view model properties (double filter)
- [ ] `@ModelActor` aggregation uses single fetch + pure functions

### Architecture
- [ ] Every `@State private var` in `@main App` struct is either injected via `.environment()` or removed
- [ ] Schedulers and shared subsystems owned by service layer, not by views
- [ ] No state recomputed where a maintained model property already exists
- [ ] User preferences in `@Observable` services have `didSet` writer + `init()` reader pairing

### Accessibility
- [ ] All interactive elements have `.accessibilityLabel()` using `String(localized:defaultValue:)`
- [ ] No `debugDescription` or `description` in accessibility labels
- [ ] Calendar/grid touch targets: `.frame(minHeight: 44).contentShape(Rectangle())`
- [ ] Every animation site checks `@Environment(\.accessibilityReduceMotion)`
- [ ] VoiceOver pass on paywall: every product reads localized price correctly

### Monetization
- [ ] Every `GatedContent` locked branch has a visible "Upgrade to Pro" → `PaywallView` button
- [ ] Every limit banner (history limit, etc.) is interactive — tapping presents `PaywallView`
- [ ] Notification permission requested post-first-value (after first fast), not during onboarding
- [ ] Review prompt: sentiment-gated, 2/version + 3/year cap, scenePhase-refreshed notification status

### Widgets & Live Activities
- [ ] Timer display uses `Text(date, style: .timer)` — not manual countdown
- [ ] Widget intent stop sets "was manually stopped" flag — prevents app restart on foreground
- [ ] Widget intent start has backfill path for UserDefaults-only state (no SwiftData record yet)
- [ ] Deep link URL scheme registered in `project.yml` / `Info.plist`
- [ ] Live Activity dismissal: update to completed state first, then `.end(dismissalPolicy: .after(3))`

---

## File Organization Reference

```
AppName/
├── App/
│   ├── AppNameApp.swift          # @main, environment injection, scenePhase observer
│   └── AppRouter.swift           # Only if complex deep linking is needed
├── Models/
│   ├── Enums/                    # Protocol/state enums with String raw values
│   └── EntityName.swift          # @Model — no import SwiftUI, no #Preview
├── ViewModels/
│   └── FeatureViewModel.swift    # @Observable, stored properties, loadTask property, deinit cancel
├── Views/
│   ├── Screens/                  # Full-screen views
│   ├── Components/               # Reusable components — every file has #Preview
│   ├── Onboarding/               # ZStack/switch navigation, not TabView.page
│   └── Paywall/                  # Custom StoreKit view
├── Services/
│   ├── CoreEngine.swift          # Single source of truth for domain state
│   ├── StoreManager.swift        # Transaction listener as stored Task property
│   └── NotificationScheduler.swift # Owned by StoreManager, not views
├── Shared/                       # App Group types — Widget and main app both import
│   ├── UserDefaults+Shared.swift # All App Group keys in one place
│   ├── AppIntents/               # ToggleIntent — one intent powers widgets + Control Center
│   └── LiveActivityAttributes.swift
├── Extensions/
│   └── Type+Feature.swift        # Never put extensions in ViewModels/ or Views/
├── Resources/
│   └── Assets.xcassets           # AccentColor, BackgroundPrimary, BackgroundSecondary,
│                                 # TextPrimary, TextSecondary, Success, Warning, Error
└── Widget/
    ├── Widgets.swift             # @main WidgetBundle
    ├── Provider.swift            # Zone-transition-based entries, not fixed intervals
    └── Views/                   # Small/medium/large/lock screen families
```

---

## What to Decide Before Writing Code

Run through these decisions at the start of every new app — changing them mid-build is expensive:

1. **Is there a "hot state" that widgets and AppIntents need?** → Plan App Group `UserDefaults` schema on Day 1
2. **Does the app have a timer/countdown?** → Use `startDate` persistence + `Text(date, style: .timer)`. Never background timers.
3. **Does the app have a streak or running counter?** → Make it a separate `@Model`. One owner (`StreakManager`). Everything reads `model.count`.
4. **StoreKit 2 native or RevenueCat?** → If RevenueCat, install it first. If native, design the `StoreManager` interface to be swappable. Either way, `isPro` in App Group `UserDefaults`, listener as stored `Task`.
5. **What are the fasting protocol equivalents?** → Define enums with `String` raw values before models. Design `@Model` computed property wrappers immediately.
6. **Notification permission timing?** → Post-first value event (after first fast, first log, first completion), not during onboarding.
7. **Review prompt timing?** → After a positive event (streak milestone, completion celebration). Sentiment-gate it.

---

## Comparison with AquaLog Build

| Aspect | AquaLog | FastTrack |
|--------|---------|-----------|
| Phase count | ~4 informal | 8 formal phases |
| Code review structure | Post-hoc | Structured per-phase review with findings docs |
| Bug tracking | Ad-hoc | Numbered todos (013–067) |
| Timer pattern | Not applicable (CRUD) | `startDate` persistence + `Text(date, style: .timer)` |
| Widget pattern | AppIntents first | AppIntents first (confirmed: this is the right order) |
| Strict concurrency | Partially addressed | Fully addressed (all GCD removed) |
| Streak pattern | Not applicable | Separate `@Model` + `StreakManager` (O(1) widget access) |
| Onboarding | Informal | 7-screen structured flow, `ZStack/switch` pattern |
| Paywall | RevenueCat | Native StoreKit 2 (RevenueCat-compatible interface) |
| Test suite | Not mentioned | 17 tests from Phase 1 |
| Social proof | Not mentioned | Removed entirely — App Store 2.3.7 risk |

---

## Templates to Carry Forward

These files from FastTrack are reusable with minimal changes:

| File | What to reuse |
|------|--------------|
| `UserDefaults+Shared.swift` | Pattern — App Group keys with computed accessors |
| `StoreManager.swift` | Full reuse — swap product IDs and entitlement name |
| `NotificationScheduler.swift` | Pattern — owned by StoreManager, not views |
| `GatedContent.swift` | Full reuse — feature gating view wrapper |
| `AppConstants.swift` | Pattern — URL constants, safe optional init |
| `View+ReviewHelpers.swift` | Full reuse — sentiment-gated review prompt |
| `project.yml` | Template — parameterize bundle ID, app name, URL scheme |
| `ToggleFastIntent.swift` | Pattern — `@MainActor`, App Group read/write, backfill path |
| Phase 1 test suite structure | Pattern — 4 suites: enums, models, services, managers |

---

*Generated April 4, 2026. Covers Phases 1–7 (todos 013–067). Phase 8 (quality gate + submission) pending.*
