import SwiftUI

/// Reusable onboarding template — 3-4 screens max
/// Customize: pages content, accent color, completion action
struct OnboardingView: View {
    let pages: [OnboardingPage]
    let accentColor: Color
    let onComplete: () -> Void

    @State private var currentPage = 0

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(accentColor)
                            .symbolEffect(.bounce, value: currentPage == index)

                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(.title.bold())
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
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)

            // Bottom button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(accentColor)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            if currentPage < pages.count - 1 {
                Button("Skip") {
                    onComplete()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 16)
            } else {
                Color.clear.frame(height: 40)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

// MARK: - Usage Example
/*
OnboardingView(
    pages: [
        OnboardingPage(
            icon: "drop.fill",
            title: "Track Your Hydration",
            subtitle: "Log every drink with a single tap and see your daily progress"
        ),
        OnboardingPage(
            icon: "bell.fill",
            title: "Smart Reminders",
            subtitle: "Get gentle nudges throughout the day to stay hydrated"
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "See Your Progress",
            subtitle: "Weekly and monthly insights to build better habits"
        )
    ],
    accentColor: .blue,
    onComplete: {
        // Mark onboarding complete, navigate to main view
    }
)
*/
