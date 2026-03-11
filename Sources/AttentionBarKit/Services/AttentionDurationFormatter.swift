import Foundation

public enum AttentionDurationFormatter {
    public static func positionalString(from interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    public static func compactString(from interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        switch (hours, minutes) {
        case (0, 0):
            return "0m"
        case (0, _):
            return "\(minutes)m"
        case (_, 0):
            return "\(hours)h"
        default:
            return "\(hours)h \(minutes)m"
        }
    }
}
