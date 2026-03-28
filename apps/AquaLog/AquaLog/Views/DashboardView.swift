import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @State private var showingAddDrink = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    progressSection

                    if let weatherMsg = viewModel.weatherMessage {
                        weatherBanner(weatherMsg)
                    }

                    if let workout = viewModel.workoutAdvice {
                        workoutBanner(workout)
                    }

                    insightsSection

                    if let caffeineStatus = viewModel.caffeineStatus {
                        caffeineWarningBanner(caffeineStatus)
                    }

                    quickAddSection
                    recentLogsSection
                }
                .padding()
            }
            .navigationTitle(String(localized: "AquaLog"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddDrink = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel(String(localized: "Add custom drink"))
                }
            }
            .sheet(isPresented: $showingAddDrink) {
                AddDrinkSheet { amount, beverageType, note in
                    viewModel.addDrink(amount: amount, beverageType: beverageType, note: note)
                }
            }
            .onAppear {
                viewModel.setup(modelContext: modelContext)
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 16) {
            ZStack {
                ProgressRingView(
                    progress: viewModel.todayProgress,
                    lineWidth: 22,
                    size: 200
                )

                VStack(spacing: 4) {
                    Text(viewModel.percentageText)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.numericText())
                        .accessibilityLabel(
                            String(localized: "\(viewModel.percentageText) of daily goal")
                        )

                    if viewModel.goalReached {
                        Label(
                            String(localized: "Goal Reached!"),
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
                }
            }
            .padding(.top, 8)

            Text(viewModel.progressText)
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityLabel(
                    String(localized: "Intake: \(viewModel.progressText)")
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Weather Banner

    private func weatherBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sun.max.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Workout Banner

    private func workoutBanner(_ advice: WorkoutDetector.WorkoutHydrationAdvice) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "figure.run")
                .foregroundStyle(.green)
            Text(advice.message)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Streak
            insightCard(
                icon: "flame.fill", iconColor: .orange,
                value: "\(viewModel.currentStreak)",
                label: String(localized: "Day Streak"),
                sublabel: viewModel.longestStreak > 0 ? String(localized: "Best: \(viewModel.longestStreak)") : nil
            )
            .accessibilityLabel(
                String(localized: "\(viewModel.currentStreak) day streak, best \(viewModel.longestStreak)")
            )

            // Caffeine
            insightCard(
                icon: "mug.fill", iconColor: caffeineColor,
                value: "\(Int(viewModel.todayCaffeineMG))",
                label: String(localized: "mg Caffeine"),
                sublabel: String(localized: "of \(Int(CaffeineInfo.dailyLimitMG))mg limit")
            )
            .accessibilityLabel(
                String(localized: "\(Int(viewModel.todayCaffeineMG)) milligrams caffeine")
            )

            // Sugar
            insightCard(
                icon: "cube.fill", iconColor: .pink,
                value: String(format: "%.0f", viewModel.todaySugarGrams),
                label: String(localized: "g Sugar"),
                sublabel: viewModel.todaySugarGrams > 50 ? String(localized: "Above recommended") : nil
            )
            .accessibilityLabel(
                String(localized: "\(Int(viewModel.todaySugarGrams)) grams sugar today")
            )

            // Net Hydration
            let netPercent = viewModel.dailyGoal > 0 ? Int(Double(viewModel.todayTotal) / Double(viewModel.dailyGoal) * 100) : 0
            insightCard(
                icon: "drop.halffull", iconColor: .cyan,
                value: "\(netPercent)%",
                label: String(localized: "Net Hydration"),
                sublabel: nil
            )
            .accessibilityLabel(
                String(localized: "\(netPercent) percent net hydration")
            )
        }
    }

    private func insightCard(icon: String, iconColor: Color, value: String, label: String, sublabel: String?) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let sublabel {
                Text(sublabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }

    private func caffeineWarningBanner(_ status: (message: String, severity: CaffeineInfo.CaffeineSeverity)) -> some View {
        HStack(spacing: 10) {
            Image(systemName: status.severity == .critical ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundStyle(status.severity == .critical ? .red : .orange)
            Text(status.message)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(status.severity == .critical ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
    }

    private var caffeineColor: Color {
        if viewModel.todayCaffeineMG >= CaffeineInfo.dailyLimitMG {
            return .red
        } else if viewModel.todayCaffeineMG >= CaffeineInfo.warningThresholdMG {
            return .orange
        }
        return .brown
    }

    // MARK: - Quick Add Section

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Quick Add"))
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(Beverage.water.quickAmounts, id: \.self) { amount in
                    Button {
                        viewModel.addDrink(amount: amount)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .font(.title3)
                            Text(amount.volumeString(unitSystem: viewModel.unitSystem))
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.accentColor.opacity(0.12))
                        )
                        .foregroundStyle(Color.accentColor)
                    }
                    .accessibilityLabel(
                        String(localized: "Add \(amount.volumeString(unitSystem: viewModel.unitSystem))")
                    )
                }
            }
        }
    }

    // MARK: - Recent Logs Section

    private var recentLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Today's Drinks"))
                    .font(.headline)
                Spacer()
                Text(String(localized: "\(viewModel.todayLogs.count) entries"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.todayLogs.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.todayLogs, id: \.id) { log in
                        logRow(log)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(String(localized: "No drinks logged yet today"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(String(localized: "Tap a quick add button or + to get started"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .accessibilityElement(children: .combine)
    }

    private func logRow(_ log: WaterLog) -> some View {
        let info = Beverage.displayInfo(for: log.beverageType)

        return HStack(spacing: 12) {
            Image(systemName: info.icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(info.name)
                    .font(.subheadline.weight(.medium))
                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(log.amount.volumeString(unitSystem: viewModel.unitSystem))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .contextMenu {
            Button(role: .destructive) {
                viewModel.deleteDrink(log)
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "\(info.name), \(log.amount.volumeString(unitSystem: viewModel.unitSystem)) at \(log.timestamp.formatted(date: .omitted, time: .shortened))")
        )
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
