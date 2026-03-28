import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    private var settings: UserSettings? {
        allSettings.first
    }

    private static let goalPresets = [1500, 2000, 2500, 3000, 3500]
    private static let reminderIntervalOptions = [30, 60, 90, 120]

    var body: some View {
        NavigationStack {
            List {
                goalSection
                unitSection
                reminderSection
                premiumSection
                aboutSection
            }
            .navigationTitle(String(localized: "Settings"))
        }
        .onAppear(perform: ensureSettings)
    }

    // MARK: - Goal Section

    private var goalSection: some View {
        Section {
            if let settings {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "Daily Goal"))
                        Spacer()
                        Text(settings.dailyGoalML.volumeString(unitSystem: settings.unitSystem))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        String(localized: "Daily goal: \(settings.dailyGoalML.volumeString(unitSystem: settings.unitSystem))")
                    )

                    Picker(String(localized: "Goal"), selection: Binding(
                        get: { settings.dailyGoalML },
                        set: { newValue in
                            settings.dailyGoalML = newValue
                            try? modelContext.save()
                        }
                    )) {
                        ForEach(Self.goalPresets, id: \.self) { preset in
                            Text(preset.volumeString(unitSystem: settings.unitSystem))
                                .tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel(String(localized: "Select daily goal amount"))
                }
            }
        } header: {
            Text(String(localized: "Hydration Goal"))
        }
    }

    // MARK: - Unit Section

    private var unitSection: some View {
        Section {
            if let settings {
                Picker(String(localized: "Unit"), selection: Binding(
                    get: { settings.unitSystem },
                    set: { newValue in
                        settings.unitSystem = newValue
                        try? modelContext.save()
                    }
                )) {
                    Text(String(localized: "Metric (mL)")).tag("metric")
                    Text(String(localized: "Imperial (oz)")).tag("imperial")
                }
                .accessibilityLabel(String(localized: "Measurement unit"))
            }
        } header: {
            Text(String(localized: "Display"))
        }
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        Section {
            if let settings {
                Toggle(
                    String(localized: "Reminders"),
                    isOn: Binding(
                        get: { settings.reminderEnabled },
                        set: { newValue in
                            settings.reminderEnabled = newValue
                            try? modelContext.save()
                            handleReminderToggle(enabled: newValue, settings: settings)
                        }
                    )
                )
                .accessibilityLabel(String(localized: "Enable hydration reminders"))

                if settings.reminderEnabled {
                    Picker(String(localized: "Interval"), selection: Binding(
                        get: { settings.reminderIntervalMinutes },
                        set: { newValue in
                            settings.reminderIntervalMinutes = newValue
                            try? modelContext.save()
                            rescheduleReminders(settings: settings)
                        }
                    )) {
                        ForEach(Self.reminderIntervalOptions, id: \.self) { minutes in
                            if minutes < 60 {
                                Text(String(localized: "Every \(minutes) min")).tag(minutes)
                            } else {
                                let hours = minutes / 60
                                Text(String(localized: "Every \(hours) hours")).tag(minutes)
                            }
                        }
                    }
                    .accessibilityLabel(String(localized: "Reminder interval"))
                }
            }
        } header: {
            Text(String(localized: "Reminders"))
        }
    }

    // MARK: - Premium Section

    @State private var showPaywall = false

    private var premiumSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Label(String(localized: "AquaLog Pro"), systemImage: "star.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    if StoreManager.shared.isPremium {
                        Text(String(localized: "Active"))
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text(String(localized: "Upgrade"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor, in: Capsule())
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .accessibilityLabel(String(localized: "AquaLog Pro subscription"))

            Button(String(localized: "Restore Purchases")) {
                Task { await StoreManager.shared.restorePurchases() }
            }
            .accessibilityLabel(String(localized: "Restore previous purchases"))
        } header: {
            Text(String(localized: "Premium"))
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text(String(localized: "Version"))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                String(localized: "App version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
            )

            Button {
                hasCompletedOnboarding = false
            } label: {
                Label(String(localized: "Replay Onboarding"), systemImage: "arrow.counterclockwise")
            }
            .accessibilityLabel(String(localized: "Replay onboarding screens"))
        } header: {
            Text(String(localized: "About"))
        }
    }

    // MARK: - Helpers

    private func ensureSettings() {
        if allSettings.isEmpty {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }

    private func handleReminderToggle(enabled: Bool, settings: UserSettings) {
        if enabled {
            Task {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    await NotificationManager.shared.scheduleReminders(
                        intervalMinutes: settings.reminderIntervalMinutes,
                        startHour: settings.reminderStartHour,
                        endHour: settings.reminderEndHour
                    )
                } else {
                    await MainActor.run {
                        settings.reminderEnabled = false
                        try? modelContext.save()
                    }
                }
            }
        } else {
            NotificationManager.shared.cancelAllReminders()
        }
    }

    private func rescheduleReminders(settings: UserSettings) {
        Task {
            await NotificationManager.shared.scheduleReminders(
                intervalMinutes: settings.reminderIntervalMinutes,
                startHour: settings.reminderStartHour,
                endHour: settings.reminderEndHour
            )
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
