import CoreLocation

/// Lightweight location manager for weather-based hydration adjustments
/// Only requests "when in use" — checks once per day for weather
@MainActor
final class LocationManager: NSObject, @unchecked Sendable {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override private init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // City-level is fine
        manager.delegate = self
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    /// Request location permission if not yet determined
    func requestPermissionIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    /// Get current location (one-shot)
    func getCurrentLocation() async -> CLLocation? {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }

        return await withCheckedContinuation { cont in
            continuation = cont
            manager.requestLocation()
        }
    }

    /// Fetch weather-adjusted climate for the user's location
    func fetchClimate() async -> (climate: HydrationCalculator.Climate, adjustmentML: Int) {
        guard let location = await getCurrentLocation() else {
            return (.temperate, 0)
        }

        let climate = await HydrationCalculator.shared.fetchWeatherAdjustment(for: location)
        return (climate, climate.additionalML)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            continuation?.resume(returning: locations.first)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(returning: nil)
            continuation = nil
        }
    }
}
