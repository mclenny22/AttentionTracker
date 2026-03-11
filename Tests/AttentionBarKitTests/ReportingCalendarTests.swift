import XCTest
@testable import AttentionBarKit

final class ReportingCalendarTests: XCTestCase {
    func testMostRecentBoundaryBeforeCutoffUsesPreviousDay() {
        let reportingCalendar = ReportingCalendar(calendar: Self.makeCalendar())
        let date = Self.date("2026-03-10T10:30:00Z")

        let boundary = reportingCalendar.mostRecentBoundary(onOrBefore: date)

        XCTAssertEqual(boundary, Self.date("2026-03-09T20:00:00Z"))
    }

    func testMostRecentBoundaryAfterCutoffUsesSameDay() {
        let reportingCalendar = ReportingCalendar(calendar: Self.makeCalendar())
        let date = Self.date("2026-03-10T20:30:00Z")

        let boundary = reportingCalendar.mostRecentBoundary(onOrBefore: date)

        XCTAssertEqual(boundary, Self.date("2026-03-10T20:00:00Z"))
    }

    func testWindowsDueReturnsMissedDailyWindows() {
        let reportingCalendar = ReportingCalendar(calendar: Self.makeCalendar())
        let lastBoundary = Self.date("2026-03-08T20:00:00Z")
        let now = Self.date("2026-03-10T21:00:00Z")

        let windows = reportingCalendar.windowsDue(after: lastBoundary, upTo: now)

        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(windows[0], ReportWindow(
            start: Self.date("2026-03-08T20:00:00Z"),
            end: Self.date("2026-03-09T20:00:00Z")
        ))
        XCTAssertEqual(windows[1], ReportWindow(
            start: Self.date("2026-03-09T20:00:00Z"),
            end: Self.date("2026-03-10T20:00:00Z")
        ))
    }

    private static func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso)!
    }
}
