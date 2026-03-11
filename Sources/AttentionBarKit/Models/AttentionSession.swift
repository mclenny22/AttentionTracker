import Foundation

public struct AttentionSession: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let category: AttentionCategory
    public var startedAt: Date
    public var endedAt: Date?

    public init(
        id: UUID = UUID(),
        category: AttentionCategory,
        startedAt: Date,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.category = category
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    public var isOpen: Bool {
        endedAt == nil
    }

    public func ending(at date: Date) -> AttentionSession {
        var copy = self
        copy.endedAt = max(startedAt, date)
        return copy
    }

    public func restarting(at date: Date) -> AttentionSession {
        AttentionSession(category: category, startedAt: max(startedAt, date))
    }

    public func overlapDuration(in range: DateInterval, defaultEnd: Date) -> TimeInterval {
        let effectiveEnd = min(endedAt ?? defaultEnd, range.end)
        let effectiveStart = max(startedAt, range.start)
        guard effectiveEnd > effectiveStart else {
            return 0
        }
        return effectiveEnd.timeIntervalSince(effectiveStart)
    }
}
