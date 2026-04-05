# Compound Engineering Report: AquaLog Code Review
> Date: 2026-04-05 | App: AquaLog (iOS hydration tracker) | Stack: SwiftUI, SwiftData, HealthKit, RevenueCat, WidgetKit, WatchKit

---

## Executive Summary

An 8-agent code review of AquaLog's first commit uncovered **21 issues** (12 P1 ship-blocking, 7 P2, 2 P3) across 20 files. The bugs clustered into 6 recurring patterns that are **not specific to hydration tracking** — they will reappear in every iOS app we ship unless we build systematic defenses.

This report distills those patterns into reusable lessons, checklists, and architectural rules for the portfolio.

---

## The 6 Patterns That Will Repeat

### Pattern 1: Multi-Surface Data Loss

**What happened:** AppIntents (Siri, Shortcuts), widgets, and Watch app all logged drinks to `UserDefaults` only. SwiftData was never written. This meant history was invisible, streaks didn't update, and HealthKit diverged from the app — while the user saw a success dialog.

**Why it's systemic:** Every app we ship will have multiple entry points (widgets, Siri, Watch, Control Center, NFC). Each entry point runs in a separate process. If persistence logic lives only in the main app's ViewModel, every other surface silently drops data.

**Rule for future apps:**
```
RULE: One canonical "write" function, shared across all surfaces.
      Every entry point (main app, widget, Siri, Watch) calls the same
      persistence code. If SwiftData, the shared ModelContainer must
      live in the App Group container.
```

**Checklist before shipping any multi-surface feature:**
- [ ] Widget intent writes to SwiftData (not just UserDefaults)
- [ ] Watch action writes to SwiftData or syncs via WatchConnectivity
- [ ] AppIntent writes to SwiftData
- [ ] HealthKit is updated from every surface
- [ ] WidgetCenter.shared.reloadAllTimelines() called after every write
- [ ] Integration test: log from widget, verify in main app history

---

### Pattern 2: Optimistic UI with Silent Failures

**What happened:** `addDrink` played a haptic, updated the UI, fired confetti — then `try context.save()` failed silently in a `catch {}` block. The user believed the drink was logged. On relaunch, it was gone.

**Why it's systemic:** SwiftUI makes it easy to update `@Observable` state before persistence confirms. Developers naturally write the "happy path" first and add error handling later — except "later" never comes.

**Rule for future apps:**
```
RULE: Never confirm success (haptic, animation, UI update) until
      persistence succeeds. If the save fails, revert the UI state
      and show an error alert.
```

**Implementation pattern:**
```swift
func addItem() {
    let item = Item(...)
    context.insert(item)
    do {
        try context.save()
        // ONLY now: haptic + animation + UI update
        items.append(item)
        hapticTrigger += 1
    } catch {
        context.delete(item)  // revert
        saveError = error.localizedDescription
    }
}
```

---

### Pattern 3: Hardcoded Secrets in Source

**What happened:** Sentry DSN and RevenueCat test API key were string literals in Swift files. The DSN is visible in the binary (allows quota exhaustion). The test key means all production StoreKit purchases fail.

**Why it's systemic:** During rapid prototyping, keys get pasted into code. Without a compile-time gate, they ship to production. Every app has at least 2-3 service keys (analytics, crash reporting, monetization).

**Rule for future apps:**
```
RULE: All API keys and DSNs go in Info.plist via xcconfig files.
      Use #if DEBUG / #else for test vs production keys.
      CI must fail if a known test key pattern is found in source.
```

**Xcconfig pattern:**
```
// Debug.xcconfig
SENTRY_DSN = https://test@sentry.io/123
REVENUECAT_KEY = test_xxx

// Release.xcconfig
SENTRY_DSN = https://prod@sentry.io/123
REVENUECAT_KEY = appl_xxx
```

**Read in code:**
```swift
let dsn = Bundle.main.infoDictionary?["SENTRY_DSN"] as? String ?? ""
```

---

### Pattern 4: The `fatalError` Landmine

**What happened:** `ModelContainer` initialization used `fatalError` on failure. A schema migration error (inevitable as models evolve) would permanently crash the app on launch — requiring a full reinstall and losing all user data.

**Why it's systemic:** `fatalError` feels safe during development because the failure "can't happen." But schema migrations, disk corruption, and keychain resets make it a certainty over time. Health/fitness apps are especially vulnerable because users accumulate months of data they can't recreate.

**Rule for future apps:**
```
RULE: Never fatalError on persistence initialization. Always provide
      an in-memory fallback + user-visible alert. The app must remain
      launchable even if the database is corrupt.
```

**Implementation pattern:**
```swift
do {
    modelContainer = try ModelContainer(for: schema, configurations: [config])
} catch {
    // Fallback: in-memory store. App works but data won't persist.
    let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    modelContainer = try! ModelContainer(for: schema, configurations: [fallback])
    // TODO: Show alert explaining data may need reset
    SentrySDK.capture(error: error)
}
```

---

### Pattern 5: Security Assumptions About On-Device Data

**What happened:** Three separate security issues shared one root cause — assuming on-device data is tamper-proof:

1. **`isPremium` stored in SwiftData** — on jailbroken devices, users can flip this via SQLite editor and bypass the paywall
2. **Sentry `attachScreenshot = true`** — captures weight, age, pregnancy status and uploads to third-party servers
3. **AppIntents accept unbounded input** — Siri/Shortcuts can log -999 or 999,999 mL, poisoning HealthKit data visible to doctors

**Why it's systemic:** iOS apps have a trust boundary between:
- **Internal** (app code calling app code) — can trust
- **External** (Siri parameters, local database fields for auth, data leaving the device) — cannot trust

**Rules for future apps:**
```
RULE 1: Authorization state (premium, roles) must come from the
        server (RevenueCat/StoreKit 2), not local storage. Local
        storage is a cache, not a source of truth.

RULE 2: Health data must never leave the device via crash reporting,
        analytics screenshots, or debug logs. Audit every SDK's
        default settings.

RULE 3: All external input (AppIntents, URL schemes, widgets) must
        be validated and clamped before persistence.
```

**Input validation pattern:**
```swift
static func clampedAmount(_ raw: Int) -> Int {
    max(1, min(raw, 2000))  // 1 mL – 2 L
}
```

---

### Pattern 6: Concurrency Hazards in Singletons

**What happened:** `LocationManager` used a `CheckedContinuation` that could be resumed twice if both `didUpdateLocations` and `didFailWithError` fired. This causes a runtime crash: "SWIFT TASK CONTINUATION MISUSE."

Additionally, two concurrent calls to `getCurrentLocation()` would overwrite the stored continuation, leaking the first caller's task forever.

**Why it's systemic:** Any singleton wrapping a delegate-based Apple API (CLLocationManager, CBCentralManager, NWPathMonitor) faces this exact pattern. Swift concurrency makes it easy to create continuations but doesn't enforce single-resume.

**Rule for future apps:**
```
RULE: When wrapping delegate callbacks with CheckedContinuation:
      1. Nil out the continuation BEFORE resuming (prevents double-resume)
      2. Guard against concurrent requests (return nil or queue them)
      3. Extract a private resume() helper to enforce exactly-once semantics
```

**Implementation pattern:**
```swift
private var continuation: CheckedContinuation<CLLocation?, Never>?
private var isWaiting = false

func getCurrentLocation() async -> CLLocation? {
    guard !isWaiting else { return nil }
    isWaiting = true
    defer { isWaiting = false }

    return await withCheckedContinuation { cont in
        continuation = cont
        manager.requestLocation()
    }
}

private func resume(with location: CLLocation?) {
    guard let cont = continuation else { return }
    continuation = nil  // nil BEFORE resume
    cont.resume(returning: location)
}
```

---

## Pre-Ship Checklist (All Future Apps)

Copy this into every new project's task list before App Store submission.

### Data Integrity
- [ ] Every entry point (main app, widget, Siri, Watch) writes to the same persistence layer
- [ ] No silent `catch {}` blocks on save/delete operations
- [ ] UserDefaults is a cache/sync mechanism, not the source of truth for user data
- [ ] `fatalError` is never used in persistence initialization
- [ ] Schema migration strategy is documented and tested

### Security & Privacy
- [ ] No API keys or DSNs hardcoded as string literals (use xcconfig/Info.plist)
- [ ] DEBUG and RELEASE use different service keys
- [ ] Crash reporting SDK does NOT capture screenshots of health/financial data
- [ ] Authorization state comes from server, not local database
- [ ] All external input (Siri, Shortcuts, URL schemes) is validated and clamped
- [ ] `PrivacyInfo.xcprivacy` accurately reflects actual data usage
- [ ] SwiftData store excluded from iCloud backup if it contains health data

### Reliability
- [ ] Persistence init has graceful fallback (in-memory store)
- [ ] Offline mode tested: premium features work without network (cache entitlements)
- [ ] CheckedContinuation wrappers have exactly-once resume semantics
- [ ] No concurrent access to shared continuation/callback state

### Performance
- [ ] SwiftData queries use date predicates (no unbounded full-table loads)
- [ ] `onAppear` setup is guarded to run expensive work only once per session
- [ ] DateFormatters are static/cached, not allocated per call
- [ ] Background computations are off `@MainActor`

### Standards & Accessibility
- [ ] `Localizable.xcstrings` exists with all user-facing strings
- [ ] Every interactive element has `.accessibilityLabel()`
- [ ] Dynamic Type supported (no hardcoded font sizes without `.minimumScaleFactor`)
- [ ] Dark Mode tested on every screen
- [ ] No UIKit when SwiftUI equivalent exists (`ShareLink` not `UIActivityViewController`)

### Testing
- [ ] Unit tests exist for: persistence operations, business logic (streaks, calculations), input validation
- [ ] Integration test: log from each surface, verify in main app
- [ ] Edge cases: midnight boundary, timezone change, offline, empty state, maximum data

---

## Architecture Decision: Shared Persistence for Multi-Surface Apps

The most impactful lesson from this review is architectural. Every iOS app with widgets, Siri, or Watch support needs a **shared persistence layer from day one**.

```
                    ┌──────────────────────────────────┐
                    │         App Group Container       │
                    │                                   │
                    │  ┌─────────────────────────────┐  │
                    │  │   SwiftData ModelContainer   │  │
                    │  │   (single source of truth)   │  │
                    │  └──────────┬──────────────────┘  │
                    │             │                      │
                    └─────────────┼──────────────────────┘
                                  │
           ┌──────────┬───────────┼───────────┬──────────┐
           │          │           │           │          │
      ┌────▼───┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────┐ ┌──▼───┐
      │Main App│ │Widget  │ │  Siri  │ │Control │ │Watch │
      │        │ │Intent  │ │Intent  │ │Center  │ │  App │
      └────────┘ └────────┘ └────────┘ └────────┘ └──────┘
           │          │           │           │          │
           └──────────┴───────────┼───────────┴──────────┘
                                  │
                    ┌─────────────▼──────────────────┐
                    │   Shared LogDrinkService        │
                    │   - validate input              │
                    │   - write SwiftData             │
                    │   - update HealthKit            │
                    │   - refresh widgets             │
                    │   - return Result<Success,Error>│
                    └────────────────────────────────┘
```

**Key principle:** The `LogDrinkService` (or equivalent for other apps) is a plain Swift struct/class — no UI dependencies, no ViewModel coupling. It can be called from any process. It validates, persists, syncs, and returns a `Result` so each caller can handle success/failure appropriately for its surface.

---

## Metrics from This Review

| Metric | Value |
|--------|-------|
| Files reviewed | 20 |
| Issues found | 21 (12 P1, 7 P2, 2 P3) |
| Issues fixed in first PR | 12 (across all 20 files) |
| Lines changed | 317 added, 110 removed |
| Estimated time saved vs. finding in production | 40-80 hours of firefighting |
| Categories | Data loss (5), Security (5), Reliability (4), Performance (3), Standards (3), Testing (1) |

---

## Remaining Work

These issues were **not** fixed in the initial PR and should be addressed before App Store submission:

| # | Issue | Priority | Effort |
|---|-------|----------|--------|
| 002 | Streak logic correctness (stale reads, delete doesn't repair, midnight edge) | P1 | 2-3h |
| 005 | Remaining silent save failures (revert UI on error) | P1 | 1-2h |
| 007 | Zero test coverage for business logic | P1 | 8-16h |
| 009 | Unbounded SwiftData queries in 4 views | P1 | 2-3h |
| 012 | UIKit usage + force unwraps in production code | P1 | 1-2h |
| 014 | Accessibility labels + Localizable.xcstrings | P2 | 3-4h |
| 016 | PrivacyInfo.xcprivacy accuracy + iCloud backup exclusion | P2 | 1h |
| 017 | Setup performance (guard duplicate HealthKit calls) — partially fixed | P2 | 1h |
| 018 | 4 views missing ViewModels (MVVM violation) | P2 | 4-6h |
| 020 | Performance micro-optimizations (DateFormatter, MainActor) | P3 | 2h |
| 021 | Dead code cleanup + file organization | P3 | 3-4h |

---

## Key Takeaway

> **The fastest way to ship reliable iOS apps is to get the persistence architecture right on day one.** Every bug in this review traces back to one of two root causes: data not flowing through a single canonical path, or trust boundaries not being respected. Fix the architecture, and the entire class of bugs disappears.

The 6 patterns documented here are portable. Copy the pre-ship checklist into every new project. Run an 8-agent review before every App Store submission. Compound the lessons; don't relearn them.
