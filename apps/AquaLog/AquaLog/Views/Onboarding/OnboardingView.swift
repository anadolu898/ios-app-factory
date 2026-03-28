import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var selectedGoal: Int = 2500

    @Environment(\.modelContext) private var modelContext

    private static let goalPresets = [1500, 2000, 2500, 3000, 3500]

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        (
            "drop.fill",
            String(localized: "Track Your Hydration"),
            String(localized: "Log every drink with a single tap. Stay on top of your daily water intake effortlessly.")
        ),
        (
            "bell.badge.fill",
            String(localized: "Smart Reminders"),
            String(localized: "Get gentle nudges throughout the day so you never forget to stay hydrated.")
        ),
        (
            "chart.bar.fill",
            String(localized: "See Your Progress"),
            String(localized: "Beautiful charts and streaks help you build a healthy hydration habit over time.")
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    onboardingPage(page: page)
                        .tag(index)
                }

                goalPickerPage
                    .tag(pages.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            bottomControls
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Onboarding Page

    private func onboardingPage(page: (icon: String, title: String, subtitle: String)) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor, Color.blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Goal Picker Page

    private var goalPickerPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text(String(localized: "Set Your Daily Goal"))
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Text(String(localized: "How much water do you want to drink each day?"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Goal picker
            VStack(spacing: 16) {
                ForEach(Self.goalPresets, id: \.self) { goal in
                    Button {
                        selectedGoal = goal
                    } label: {
                        HStack {
                            Text(goal.volumeString(unitSystem: "metric"))
                                .font(.title3.weight(.medium))

                            Spacer()

                            if selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    selectedGoal == goal
                                        ? Color.accentColor.opacity(0.12)
                                        : Color(.systemGray6)
                                )
                        )
                        .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(
                        String(localized: "\(goal.volumeString(unitSystem: "metric")) daily goal")
                    )
                    .accessibilityAddTraits(selectedGoal == goal ? .isSelected : [])
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0...pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .accessibilityHidden(true)

            // Button
            Button {
                if currentPage < pages.count {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage < pages.count
                     ? String(localized: "Continue")
                     : String(localized: "Get Started"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .accessibilityLabel(
                currentPage < pages.count
                    ? String(localized: "Continue to next page")
                    : String(localized: "Complete setup and get started")
            )

            if currentPage < pages.count {
                Button {
                    withAnimation {
                        currentPage = pages.count
                    }
                } label: {
                    Text(String(localized: "Skip"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(String(localized: "Skip to goal setup"))
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Complete

    private func completeOnboarding() {
        // Save the selected goal
        let settings = UserSettings(dailyGoalML: selectedGoal)
        modelContext.insert(settings)
        try? modelContext.save()

        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
