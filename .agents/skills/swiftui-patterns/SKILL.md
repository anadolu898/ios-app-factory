---
name: swiftui-patterns
description: When refactoring SwiftUI views, improving code organization, or auditing view performance. Provides patterns for view composition, MVVM architecture, reusable components, and performance optimization. Based on Thomas Ricouard's (Dimillian) iOS architecture patterns.
metadata:
  version: 1.0.0
  source: Adapted from Dimillian/Skills
---

# SwiftUI Patterns & Architecture

Reusable architecture patterns for production SwiftUI apps. Use alongside `swiftui-pro` and `swiftui-expert`.

## View Composition

### The 50-Line Rule
If a view body exceeds ~50 lines, extract subviews. But extract SMART:
- Extract by **semantic meaning**, not arbitrary size
- Extracted views should be **self-contained** — they receive data, not parent state
- Use `@ViewBuilder` functions for small, tightly-coupled sections
- Use separate `struct` views for reusable or independently-testable components

### Pattern: Feature View + Subviews
```
FeatureView.swift          (orchestrator — assembles subviews, owns state)
├── FeatureHeaderView.swift  (receives data via init)
├── FeatureListView.swift    (receives data + actions via init)
└── FeatureEmptyView.swift   (static or minimal data)
```

### Pattern: ViewModifier for Cross-Cutting Concerns
```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
```

## MVVM Architecture

### ViewModel Pattern (iOS 17+)
```swift
@Observable
final class FeatureViewModel {
    // Published state
    var items: [Item] = []
    var isLoading = false
    var error: AppError?

    // Dependencies (injected)
    private let repository: ItemRepository

    init(repository: ItemRepository = .shared) {
        self.repository = repository
    }

    // Actions
    @MainActor
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await repository.fetchAll()
        } catch {
            self.error = .from(error)
        }
    }
}
```

### Rules
- ViewModels are `@Observable` classes, NOT structs
- Mark with `@MainActor` if they update UI state
- Inject dependencies via init (for testability)
- Views own their ViewModel via `@State`
- Child views receive ViewModel data through init parameters, NOT the whole ViewModel

## Navigation Architecture

### Coordinator Pattern
```swift
@Observable
final class AppRouter {
    var path = NavigationPath()

    enum Destination: Hashable {
        case detail(Item)
        case settings
        case paywall
    }

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
```

Use in the root view:
```swift
@State private var router = AppRouter()

NavigationStack(path: $router.path) {
    HomeView()
        .navigationDestination(for: AppRouter.Destination.self) { destination in
            switch destination {
            case .detail(let item): DetailView(item: item)
            case .settings: SettingsView()
            case .paywall: PaywallView()
            }
        }
}
.environment(router)
```

## Reusable Component Patterns

### Loading State Container
```swift
struct AsyncContentView<Content: View, T>: View {
    let state: LoadingState<T>
    @ViewBuilder let content: (T) -> Content

    var body: some View {
        switch state {
        case .idle: Color.clear
        case .loading: ProgressView()
        case .loaded(let data): content(data)
        case .error(let error): ContentUnavailableView { /* error UI */ }
        }
    }
}
```

### Conditional Modifier
```swift
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }
}
```
Use sparingly — prefer separate `@ViewBuilder` branches for clarity.

## Performance Audit Checklist

When reviewing a SwiftUI view for performance:

1. **Body recomputation**: Is `body` doing work beyond building the view tree?
   - Move data fetching to `.task {}`
   - Move formatting to computed properties or formatters

2. **List performance**: Are lists using `LazyVStack`/`LazyHStack`?
   - Ensure unique `id` on each element
   - Avoid complex views inside lazy stacks — extract to separate structs

3. **Image loading**: Are images loaded efficiently?
   - Use `AsyncImage` with placeholder
   - Resize before display: `.resizable().aspectRatio(contentMode: .fill).frame().clipped()`
   - Cache with a proper image pipeline for network images

4. **Animation performance**: Are animations correctly scoped?
   - Always use `value:` parameter with `.animation()`
   - Prefer `withAnimation` for state-driven changes
   - Avoid animating layout-triggering properties (frame size) — prefer transforms

5. **Memory**: Are there retain cycles?
   - Use `[weak self]` in closures stored as properties
   - `.task {}` and button actions don't need `[weak self]` — SwiftUI manages their lifecycle

## View Refactoring Steps

When asked to refactor a SwiftUI view:

1. **Identify the view's responsibilities** — data, layout, interaction, navigation
2. **Extract ViewModel** if the view manages state + logic (not for pure display views)
3. **Extract subviews** by semantic meaning (header, list, empty state, actions)
4. **Extract shared styling** into `ViewModifier` or `extension View`
5. **Verify** — each extracted piece should be understandable in isolation
6. **Test** — ViewModel logic should be testable without SwiftUI

## Related Skills

- For core SwiftUI rules: `swiftui-pro`
- For advanced framework patterns: `swiftui-expert`
- For quality checks: `design-check`
