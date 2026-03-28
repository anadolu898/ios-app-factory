import Testing
@testable import AquaLog

@Test func waterLogCreation() {
    let log = WaterLog(amount: 250, beverageType: "water")
    #expect(log.amount == 250)
    #expect(log.beverageType == "water")
}

@Test func userSettingsDefaults() {
    let settings = UserSettings()
    #expect(settings.dailyGoalML == 2500)
    #expect(settings.unitSystem == "metric")
    #expect(settings.hasCompletedOnboarding == false)
}

@Test func volumeFormatting() {
    #expect(250.volumeString() == "250 mL")
    #expect(1500.volumeString() == "1.5 L")
    #expect(250.volumeString(unitSystem: "imperial") == "8.5 oz")
}
