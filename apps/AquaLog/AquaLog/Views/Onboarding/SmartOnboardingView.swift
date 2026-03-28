import SwiftUI
import SwiftData

struct SmartOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var step = 0
    @State private var gender: HydrationCalculator.Gender = .other
    @State private var age: Double = 30
    @State private var weightKg: Double = 70
    @State private var activityLevel: HydrationCalculator.ActivityLevel = .moderate
    @State private var wakeUpTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? .now
    @State private var bedTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? .now
    @State private var isPregnant = false
    @State private var isBreastfeeding = false
    @State private var unitSystem = "metric"
    @State private var calculatedGoal = 2500
    @State private var showResult = false
    @State private var remindersEnabled = true
    @State private var reminderInterval = 60

    private let totalSteps = 7

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.cyan.opacity(0.04), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Content
                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    bodyStep.tag(1)
                    activityStep.tag(2)
                    scheduleStep.tag(3)
                    resultStep.tag(4)
                    remindersStep.tag(5)
                    quickLogTipStep.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: step)

                // Bottom button
                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps), height: 6)
                    .animation(.spring(response: 0.4), value: step)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.breathe)

            VStack(spacing: 12) {
                Text(String(localized: "Smart Hydration"))
                    .font(.largeTitle.bold())

                Text(String(localized: "We'll ask a few questions to calculate your perfect daily hydration goal — personalized to your body, lifestyle, and climate."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // AI badge
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                Text(String(localized: "Powered by health research"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.08))
            )

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 1: Body Info

    private var bodyStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                stepHeader(
                    icon: "figure.stand",
                    title: String(localized: "About You"),
                    subtitle: String(localized: "Your body composition affects how much water you need")
                )

                // Gender
                VStack(alignment: .leading, spacing: 10) {
                    Text(String(localized: "Gender"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ForEach(HydrationCalculator.Gender.allCases, id: \.rawValue) { g in
                            Button {
                                gender = g
                            } label: {
                                Text(g.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(gender == g ? Color.blue : Color(.systemGray6))
                                    )
                                    .foregroundStyle(gender == g ? .white : .primary)
                            }
                            .accessibilityAddTraits(gender == g ? .isSelected : [])
                        }
                    }
                }

                // Age
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(String(localized: "Age"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(age))")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.blue)
                    }

                    Slider(value: $age, in: 12...90, step: 1)
                        .tint(.blue)
                        .accessibilityLabel(String(localized: "Age: \(Int(age))"))
                }

                // Weight
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(String(localized: "Weight"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()

                        Picker("", selection: $unitSystem) {
                            Text("kg").tag("metric")
                            Text("lbs").tag("imperial")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }

                    HStack {
                        Text(weightDisplayString)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText())
                        Spacer()
                    }

                    Slider(
                        value: $weightKg,
                        in: 30...200,
                        step: unitSystem == "metric" ? 1 : 0.453592
                    )
                    .tint(.blue)
                    .accessibilityLabel(String(localized: "Weight: \(weightDisplayString)"))
                }

                // Pregnancy (show for female gender)
                if gender == .female {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle(String(localized: "Pregnant"), isOn: $isPregnant)
                            .tint(.blue)
                        Toggle(String(localized: "Breastfeeding"), isOn: $isBreastfeeding)
                            .tint(.blue)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    // MARK: - Step 2: Activity

    private var activityStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                stepHeader(
                    icon: "figure.run",
                    title: String(localized: "Activity Level"),
                    subtitle: String(localized: "Active people lose more water through sweat and need to drink more")
                )

                VStack(spacing: 10) {
                    ForEach(HydrationCalculator.ActivityLevel.allCases, id: \.rawValue) { level in
                        Button {
                            activityLevel = level
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: activityIcon(for: level))
                                    .font(.title3)
                                    .frame(width: 32)
                                    .foregroundStyle(activityLevel == level ? .white : .blue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.displayName)
                                        .font(.subheadline.weight(.semibold))
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundStyle(activityLevel == level ? .white.opacity(0.8) : .secondary)
                                }

                                Spacer()

                                if activityLevel == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(activityLevel == level
                                          ? LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                          : LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .foregroundStyle(activityLevel == level ? .white : .primary)
                        }
                        .accessibilityAddTraits(activityLevel == level ? .isSelected : [])
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    // MARK: - Step 3: Schedule

    private var scheduleStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                stepHeader(
                    icon: "clock.fill",
                    title: String(localized: "Your Schedule"),
                    subtitle: String(localized: "We'll spread reminders across your waking hours")
                )

                VStack(spacing: 20) {
                    // Wake up time
                    HStack {
                        Label(String(localized: "Wake Up"), systemImage: "sunrise.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)

                        Spacer()

                        DatePicker("", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(0.08))
                    )

                    // Bedtime
                    HStack {
                        Label(String(localized: "Bedtime"), systemImage: "moon.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.indigo)

                        Spacer()

                        DatePicker("", selection: $bedTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.indigo.opacity(0.08))
                    )
                }

                // Info card
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(String(localized: "We'll also check your local weather each morning and adjust your goal if it's hot or humid."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.yellow.opacity(0.06))
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    // MARK: - Step 4: Result

    private var resultStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // AI badge
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text(String(localized: "Your Personalized Goal"))
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.blue.opacity(0.1)))

            // Big number
            Text(calculatedGoal.volumeString(unitSystem: unitSystem))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                )
                .contentTransition(.numericText())

            Text(String(localized: "per day"))
                .font(.title3)
                .foregroundStyle(.secondary)

            // Explanation
            Text(HydrationCalculator.shared.explanationText(
                weightKg: weightKg,
                gender: gender,
                age: Int(age),
                activityLevel: activityLevel,
                climate: .temperate,
                goalML: calculatedGoal
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            // Breakdown cards
            HStack(spacing: 12) {
                infoCard(icon: "drop.fill", value: "\(Int(Double(calculatedGoal) / Double(awakeHours())))", unit: String(localized: "mL/hr"), label: String(localized: "Hourly"))
                infoCard(icon: "cup.and.saucer.fill", value: "\(calculatedGoal / 250)", unit: String(localized: "glasses"), label: String(localized: "~250mL each"))
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .onAppear {
            calculateGoal()
        }
    }

    // MARK: - Step 5: Reminders

    private var remindersStep: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.bounce, options: .repeating.speed(0.5))

            VStack(spacing: 12) {
                Text(String(localized: "Stay on Track"))
                    .font(.largeTitle.bold())

                Text(String(localized: "Get gentle reminders throughout the day so you never forget to drink."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Reminder toggle
            VStack(spacing: 16) {
                Toggle(isOn: $remindersEnabled) {
                    Label(String(localized: "Drink Reminders"), systemImage: "drop.fill")
                        .font(.subheadline.weight(.medium))
                }
                .tint(.blue)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                )

                if remindersEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Remind me every"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        Picker(String(localized: "Interval"), selection: $reminderInterval) {
                            Text(String(localized: "30 min")).tag(30)
                            Text(String(localized: "1 hour")).tag(60)
                            Text(String(localized: "1.5 hours")).tag(90)
                            Text(String(localized: "2 hours")).tag(120)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray6))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 24)
            .animation(.easeInOut(duration: 0.3), value: remindersEnabled)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 6: Quick Log Tip

    private var quickLogTipStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.bounce, options: .repeating.speed(0.5))

            VStack(spacing: 12) {
                Text(String(localized: "Log Without Opening the App"))
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(String(localized: "We know it's hard to remember to log every drink. That's why we made it effortless."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 14) {
                tipRow(
                    icon: "widget.small.badge.plus",
                    color: .blue,
                    title: String(localized: "Home Screen Widget"),
                    subtitle: String(localized: "Tap the + button right from your home screen — one tap, done")
                )

                tipRow(
                    icon: "island.toprounding",
                    color: .cyan,
                    title: String(localized: "Dynamic Island"),
                    subtitle: String(localized: "Your progress lives at the top of your screen all day")
                )

                tipRow(
                    icon: "switch.2",
                    color: .purple,
                    title: String(localized: "Control Center"),
                    subtitle: String(localized: "Swipe down, tap the water drop — logged in under 2 seconds")
                )

                tipRow(
                    icon: "applewatch",
                    color: .green,
                    title: String(localized: "Apple Watch"),
                    subtitle: String(localized: "Log from your wrist without reaching for your phone")
                )
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }

    private func tipRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Components

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            Text(title)
                .font(.title2.bold())

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private func infoCard(icon: String, value: String, unit: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(unit)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.blue.opacity(0.06))
        )
    }

    private var bottomButton: some View {
        Button {
            if step < totalSteps - 1 {
                withAnimation { step += 1 }
            } else {
                completeOnboarding()
            }
        } label: {
            Text(step == 0 ? String(localized: "Let's Go")
                 : step == totalSteps - 1 ? String(localized: "Start Tracking")
                 : String(localized: "Continue"))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .sensoryFeedback(.impact(flexibility: .solid), trigger: step)
    }

    // MARK: - Helpers

    private var weightDisplayString: String {
        if unitSystem == "imperial" {
            return String(format: "%.0f lbs", weightKg * 2.20462)
        }
        return String(format: "%.0f kg", weightKg)
    }

    private func activityIcon(for level: HydrationCalculator.ActivityLevel) -> String {
        switch level {
        case .sedentary: "figure.seated.seatbelt"
        case .light: "figure.walk"
        case .moderate: "figure.run"
        case .active: "figure.highintensity.intervaltraining"
        case .veryActive: "figure.strengthtraining.traditional"
        }
    }

    private func awakeHours() -> Int {
        let wakeComps = Calendar.current.dateComponents([.hour], from: wakeUpTime)
        let bedComps = Calendar.current.dateComponents([.hour], from: bedTime)
        let wake = wakeComps.hour ?? 7
        let bed = bedComps.hour ?? 23
        return max(bed - wake, 10)
    }

    private func calculateGoal() {
        calculatedGoal = HydrationCalculator.shared.calculateDailyGoal(
            weightKg: weightKg,
            gender: gender,
            age: Int(age),
            activityLevel: activityLevel,
            climate: .temperate,
            isPregnant: isPregnant,
            isBreastfeeding: isBreastfeeding
        )
    }

    private func completeOnboarding() {
        let wakeComps = Calendar.current.dateComponents([.hour, .minute], from: wakeUpTime)
        let bedComps = Calendar.current.dateComponents([.hour, .minute], from: bedTime)

        let startHour = wakeComps.hour ?? 7
        let endHour = bedComps.hour ?? 23

        let settings = UserSettings(
            dailyGoalML: calculatedGoal,
            unitSystem: unitSystem,
            reminderEnabled: remindersEnabled,
            reminderIntervalMinutes: reminderInterval,
            reminderStartHour: startHour,
            reminderEndHour: endHour,
            hasCompletedOnboarding: true,
            isPremium: false,
            weightKg: weightKg,
            age: Int(age),
            gender: gender.rawValue,
            activityLevel: activityLevel.rawValue,
            wakeUpHour: startHour,
            wakeUpMinute: wakeComps.minute ?? 0,
            bedtimeHour: endHour,
            bedtimeMinute: bedComps.minute ?? 0,
            isPregnant: isPregnant,
            isBreastfeeding: isBreastfeeding
        )
        settings.aiCalculatedGoalML = calculatedGoal

        modelContext.insert(settings)
        try? modelContext.save()

        // Request notification permission and schedule reminders
        if remindersEnabled {
            Task {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    await NotificationManager.shared.scheduleReminders(
                        intervalMinutes: reminderInterval,
                        startHour: startHour,
                        endHour: endHour
                    )
                }
            }
        }

        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    SmartOnboardingView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
