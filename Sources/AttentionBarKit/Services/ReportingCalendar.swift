import Foundation

public struct ReportingCalendar: Sendable {
    public let calendar: Calendar
    public let cutoffHour: Int
    public let cutoffMinute: Int

    public init(
        calendar: Calendar = .autoupdatingCurrent,
        cutoffHour: Int = 20,
        cutoffMinute: Int = 0
    ) {
        self.calendar = calendar
        self.cutoffHour = cutoffHour
        self.cutoffMinute = cutoffMinute
    }

    public func mostRecentBoundary(onOrBefore date: Date) -> Date {
        let sameDayBoundary = boundary(on: date)
        if date >= sameDayBoundary {
            return sameDayBoundary
        }

        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
            return sameDayBoundary
        }
        return boundary(on: previousDay)
    }

    public func nextBoundary(after boundary: Date) -> Date {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: boundary) else {
            return boundary
        }
        return self.boundary(on: nextDay)
    }

    public func currentWindow(at date: Date) -> ReportWindow {
        let start = mostRecentBoundary(onOrBefore: date)
        let end = nextBoundary(after: start)
        return ReportWindow(start: start, end: end)
    }

    public func windowsDue(after lastBoundary: Date, upTo now: Date) -> [ReportWindow] {
        var windows: [ReportWindow] = []
        var start = lastBoundary
        var next = nextBoundary(after: start)

        while next <= now {
            windows.append(ReportWindow(start: start, end: next))
            start = next
            next = nextBoundary(after: start)
        }

        return windows
    }

    private func boundary(on date: Date) -> Date {
        calendar.date(
            bySettingHour: cutoffHour,
            minute: cutoffMinute,
            second: 0,
            of: date
        ) ?? date
    }
}
