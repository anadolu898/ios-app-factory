---
name: swiftui-pro
description: When building or modifying SwiftUI views, state management, navigation, or animations. Auto-invoked during Phase 2 development. Prevents deprecated API usage, enforces accessibility, catches performance anti-patterns, and ensures iOS 17+/18+ best practices. Based on Paul Hudson's SwiftUI Pro methodology.
metadata:
  version: 1.0.0
  source: Adapted from twostraws/swiftui-agent-skill
---

# SwiftUI Pro

You are an expert SwiftUI developer targeting iOS 17+ (iOS 18+ preferred). Follow these rules strictly when writing or reviewing SwiftUI code.

## State Management

- Use `@Observable` macro (NOT `ObservableObject` / `@Published` / `@StateObject`)
- Use `@State` for view-local state, `@Environment` for shared dependencies
- Use `@Bindable` when passing `@Observable` objects to child views that need bindings
- NEVER use `@ObservedObject` — it's the old pattern
- Use `@AppStorage` for UserDefaults-backed state
- Use `@Query` for SwiftData fetch requests (NOT `@FetchRequest`)

## Navigation

- Use `NavigationStack` with `navigationDestination(for:)` (NOT deprecated `NavigationView` or `NavigationLink(destination:)`)
- Use type-safe navigation with `NavigationPath`
- Use `@Environment(\.dismiss)` to dismiss (NOT `presentationMode`)
- For sheets/alerts, use `Bool` or `Identifiable` bindings

## Data Persistence

- Use SwiftData with `@Model` macro (NOT Core Data for new projects)
- Use `@Query` for fetching, `modelContext.insert()` for saving
- Use `#Predicate` macro for type-safe queries (NOT NSPredicate)
- Define `ModelContainer` at the app level via `.modelContainer(for:)`

## Layout & Styling

- Use `ViewThatFits` for adaptive layouts
- Use `ContentUnavailableView` for empty states (iOS 17+)
- Use `containerRelativeFrame` for proportional sizing
- Prefer `.font(.title2)` semantic styles over `.font(.system(size:))`
- Use `Color.accentColor` and semantic colors (NOT hardcoded hex in views)
- Support Dynamic Type — never set fixed font sizes without `.minimumScaleFactor`
- Always support Dark Mode — use semantic colors from asset catalog

## Performance

- Use `@Observable` — it tracks property access granularly (better than `@Published`)
- Mark expensive computed properties with explicit caching
- Use `LazyVStack` / `LazyHStack` for scrollable lists (NOT `VStack` in `ScrollView`)
- Use `.task {}` for async work (NOT `.onAppear` with Task {})
- Cancel tasks properly — `.task` handles this automatically
- Avoid `GeometryReader` when possible — use `containerRelativeFrame` or `ViewThatFits`

## Concurrency

- Swift strict concurrency must be enabled
- Use `async/await` everywhere (NOT Combine publishers)
- Use `@MainActor` on view models and UI-updating code
- Use `Task {}` only in `.task {}` modifier or button actions
- Handle cancellation with `try Task.checkCancellation()` in long operations

## Accessibility

- EVERY interactive element needs an accessibility label
- Use `.accessibilityLabel()` for custom labels
- Use `.accessibilityHint()` for non-obvious actions
- Group related elements with `.accessibilityElement(children: .combine)`
- Support VoiceOver navigation order with `.accessibilitySortPriority()`
- Test with VoiceOver enabled — not just labels, but flow

## StoreKit 2

- Use `Product.products(for:)` to fetch products
- Use `product.purchase()` for purchases
- Use `Transaction.currentEntitlements` to check active subscriptions
- Use `Transaction.updates` for real-time transaction monitoring
- Always implement restore purchases
- NEVER use original StoreKit APIs

## Common Mistakes to Avoid

- NEVER use `#available(iOS 17, *)` checks when minimum target is iOS 17+
- NEVER use deprecated `NavigationView`, `NavigationLink(destination:)`
- NEVER use `List { ForEach }` when you just need `List(items)`
- NEVER use `.onAppear { Task { } }` — use `.task { }` instead
- NEVER force unwrap (`!`) except in `#Preview`
- NEVER use `AnyView` — use `@ViewBuilder` or concrete types
- NEVER hardcode strings — use `String(localized:)` for all user-facing text
- NEVER use `Color.red` / `Color.blue` as primary colors — use asset catalog colors

## Related Skills

- For ASO and marketing: `aso-audit`, `metadata-optimization`
- For monetization setup: `monetization-strategy`, `subscription-lifecycle`
- For quality verification: `design-check`
