# SwiftUI Conventions

Enforced conventions for all SwiftUI code in this repository.

## File Organization

```
AppName/
├── App/
│   ├── AppNameApp.swift           # @main entry point
│   └── AppRouter.swift            # Navigation coordinator
├── Models/
│   ├── Item.swift                 # @Model SwiftData models
│   └── Enums/                     # App-specific enums
├── ViewModels/
│   └── FeatureViewModel.swift     # @Observable view models
├── Views/
│   ├── Screens/                   # Full-screen views
│   │   ├── HomeView.swift
│   │   ├── DetailView.swift
│   │   └── SettingsView.swift
│   ├── Components/                # Reusable view components
│   │   ├── CardView.swift
│   │   └── EmptyStateView.swift
│   ├── Onboarding/                # Onboarding flow
│   └── Paywall/                   # Paywall screen(s)
├── Services/
│   ├── StoreManager.swift         # StoreKit 2 + RevenueCat
│   └── NotificationManager.swift
├── Extensions/
│   └── View+Extensions.swift
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.xcstrings
└── Widget/                        # WidgetKit extension
```

## Naming Conventions

- Views: `FeatureNameView` (e.g., `HomeView`, `SettingsView`)
- ViewModels: `FeatureNameViewModel` (e.g., `HomeViewModel`)
- Models: Plain nouns (e.g., `WaterEntry`, `HydrationGoal`)
- Services: `FeatureNameManager` or `FeatureNameService`
- Extensions: `Type+Feature.swift` (e.g., `Date+Formatting.swift`)

## Import Order

```swift
import SwiftUI
import SwiftData
// Other Apple frameworks (alphabetical)
import StoreKit
import WidgetKit
// Third-party (alphabetical)
import RevenueCatUI
import Sentry
```

## Preview Convention

Every view file MUST have a `#Preview` at the bottom:

```swift
#Preview {
    FeatureView()
        .modelContainer(for: [Item.self], inMemory: true)
}
```

For views requiring sample data, create a static preview helper on the model:

```swift
extension Item {
    static var preview: Item {
        Item(name: "Sample", date: .now)
    }
}
```

## Localization

ALL user-facing strings use `String(localized:)`:

```swift
Text(String(localized: "home.greeting"))       // Preferred
Text("home.greeting", tableName: "Localizable") // Alternative
```

NEVER use raw strings in UI: `Text("Hello")` — always localize.

## Error Handling

- Define app-specific errors conforming to `LocalizedError`
- Present errors via `.alert(error:)`
- Log errors to Sentry: `SentrySDK.capture(error: error)`
- User-facing messages must be helpful, not technical

## Git Conventions

- One feature per commit
- Conventional commits: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`
- PR description includes: what changed, why, how to test
