---
name: swiftui-expert
description: When implementing advanced SwiftUI patterns including animations, Swift Charts, widgets, App Intents, or complex state architecture. Complements swiftui-pro with deeper coverage of iOS 17/18 framework integrations. Based on Antoine van der Lee's SwiftUI Expert methodology.
metadata:
  version: 1.0.0
  source: Adapted from AvdLee/SwiftUI-Agent-Skill
---

# SwiftUI Expert

Advanced SwiftUI patterns for iOS 17+/18+ apps. Use alongside `swiftui-pro` for complete coverage.

## Animations

### Correct Patterns
- Use `withAnimation(.spring(duration: 0.3, bounce: 0.2)) { }` for state-driven animations
- Use `.animation(.easeInOut, value: someState)` for view-level animations (always specify `value:`)
- Use `.contentTransition(.numericText())` for number changes
- Use `.transition(.asymmetric(insertion:, removal:))` for appear/disappear
- Use `PhaseAnimator` for multi-step sequences
- Use `KeyframeAnimator` for complex, timeline-based animations

### Anti-Patterns
- NEVER use `.animation(.default)` without `value:` parameter — causes performance issues
- NEVER animate in `body` recomputation — use explicit `withAnimation` or `.animation(value:)`
- Prefer `.matchedGeometryEffect` for shared element transitions between views

## Swift Charts

- Use `Chart { }` with `BarMark`, `LineMark`, `AreaMark`, `PointMark`
- Compose marks for combined charts (e.g., `LineMark` + `AreaMark` for filled line)
- Use `.foregroundStyle(by: .value())` for automatic color differentiation
- Use `chartXAxis { }` / `chartYAxis { }` for custom axis formatting
- Use `chartOverlay { }` for interactive touch handling
- Use `SectorMark` for pie/donut charts (iOS 17+)
- Always provide accessibility via `.accessibilityLabel()` on data points

## WidgetKit

- Use `TimelineProvider` with `getSnapshot` and `getTimeline`
- Use `AppIntentTimelineProvider` for configurable widgets (iOS 17+)
- Use `.containerBackground(for: .widget) { }` for widget backgrounds (iOS 17+)
- Support all widget families needed: `.systemSmall`, `.systemMedium`, `.accessoryCircular`, `.accessoryRectangular`
- Use `@Environment(\.widgetFamily)` to adapt layout per size
- Keep timeline entries lightweight — no network calls in timeline provider
- Use `WidgetCenter.shared.reloadAllTimelines()` after data changes in the app
- Test with StandBy mode and Lock Screen placements

## App Intents & Shortcuts

- Use `AppIntent` protocol for Shortcuts and Siri integration
- Use `AppShortcutsProvider` to surface shortcuts in Spotlight
- Use `@Parameter` for intent parameters with proper titles and descriptions
- Implement `.perform()` as async — return `.result(value:)` or `.result(dialog:)`
- Use `IntentDialog` for voice feedback
- Use `AppEntity` for data types exposed to intents

## SwiftData Patterns

- Use `@Model` with `@Attribute(.unique)` for unique constraints
- Use `@Relationship` with cascade delete rules
- Use `#Predicate` with compound conditions: `#Predicate<Item> { $0.name.contains(search) && !$0.isArchived }`
- Use `FetchDescriptor` with `fetchLimit` and `sortBy` for efficient queries
- Use `@Query(sort:, order:, animation:)` for sorted, animated lists
- Implement `ModelActor` for background data operations
- Use `DefaultMigrationPlan` when evolving schema between versions

## iOS 18+ Patterns

- Use `@Entry` macro for custom `EnvironmentValues`
- Use `TabView` with `.tabViewStyle(.sidebarAdaptable)` for adaptive tabs (iPad sidebar)
- Use `MeshGradient` for rich gradient backgrounds
- Use `ScrollView { }.scrollPosition(id:)` for programmatic scroll control
- Use `.containerRelativeFrame` with `count` and `span` for grid-like layouts
- Use `ControlWidget` for Control Center widgets (iOS 18+)

## Haptics & Sensory Feedback

- Use `SensoryFeedback` modifier: `.sensoryFeedback(.impact, trigger: value)`
- Map feedback to actions: `.success` for completions, `.warning` for destructive actions, `.selection` for picks
- Don't overuse — haptics should feel intentional, not constant

## Error Handling Patterns

```swift
// Use typed throws (Swift 6)
enum AppError: LocalizedError {
    case networkUnavailable
    case dataCorrupted

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: String(localized: "error.network")
        case .dataCorrupted: String(localized: "error.data")
        }
    }
}

// In views — use .alert with error presentation
@State private var error: AppError?

.alert(isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } }), error: error) { _ in
    Button(String(localized: "button.ok")) { }
} message: { error in
    Text(error.recoverySuggestion ?? "")
}
```

## Testing

- Use `@Test` macro for Swift Testing (NOT XCTest for new tests)
- Use `#expect()` instead of `XCTAssertEqual`
- Use `@Suite` for test grouping
- Use `.tags()` for filtering test runs
- Test view models by testing state changes, not view rendering
- Use `ModelContainer(for:, configurations: .init(isStoredInMemoryOnly: true))` for SwiftData tests

## Related Skills

- For core SwiftUI rules: `swiftui-pro`
- For UI patterns and refactoring: `swiftui-patterns`
- For quality checks: `design-check`
