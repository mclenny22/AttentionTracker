import Foundation

public enum AttentionCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case creation
    case consumption
    case logistics
    case connection
    case exploration
    case recovery

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .creation:
            "Creation"
        case .consumption:
            "Consumption"
        case .logistics:
            "Logistics"
        case .connection:
            "Connection"
        case .exploration:
            "Exploration"
        case .recovery:
            "Recovery"
        }
    }

    public var descriptionText: String {
        switch self {
        case .creation:
            "Designing, writing, building something"
        case .consumption:
            "Reading feeds, watching videos, scrolling"
        case .logistics:
            "Email, invoices, scheduling, admin"
        case .connection:
            "Calls, messages, collaboration"
        case .exploration:
            "Research, curiosity rabbit holes"
        case .recovery:
            "Walking, resting, music, doing nothing"
        }
    }
}
