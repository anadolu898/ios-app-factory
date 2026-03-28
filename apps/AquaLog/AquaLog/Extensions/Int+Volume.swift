import Foundation

extension Int {
    /// Formats milliliters for display based on unit system
    func volumeString(unitSystem: String = "metric") -> String {
        if unitSystem == "imperial" {
            let oz = Double(self) / 29.5735
            if oz >= 10 {
                return String(format: "%.0f oz", oz)
            }
            return String(format: "%.1f oz", oz)
        }
        if self >= 1000 {
            return String(format: "%.1f L", Double(self) / 1000.0)
        }
        return "\(self) mL"
    }
}
