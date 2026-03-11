import XCTest
@testable import AttentionBarKit

final class CSVReportBuilderTests: XCTestCase {
    func testTotalsUseOnlyOverlapInsideWindow() {
        let calendar = Self.makeCalendar()
        let reportingCalendar = ReportingCalendar(calendar: calendar)
        let builder = CSVReportBuilder(reportingCalendar: reportingCalendar)

        let window = ReportWindow(
            start: Self.date("2026-03-09T20:00:00Z"),
            end: Self.date("2026-03-10T20:00:00Z")
        )

        let sessions = [
            AttentionSession(
                category: .creation,
                startedAt: Self.date("2026-03-09T19:00:00Z"),
                endedAt: Self.date("2026-03-09T21:00:00Z")
            ),
            AttentionSession(
                category: .consumption,
                startedAt: Self.date("2026-03-10T07:00:00Z"),
                endedAt: Self.date("2026-03-10T07:30:00Z")
            ),
            AttentionSession(
                category: .creation,
                startedAt: Self.date("2026-03-10T19:30:00Z"),
                endedAt: Self.date("2026-03-10T21:00:00Z")
            ),
        ]

        let totals = builder.totals(for: sessions, in: window, openSessionsUntil: window.end)

        XCTAssertEqual(Int(totals[.creation, default: 0]), 5400)
        XCTAssertEqual(Int(totals[.consumption, default: 0]), 1800)
        XCTAssertEqual(Int(totals[.logistics, default: 0]), 0)
    }

    func testCSVIncludesAllCategories() {
        let builder = CSVReportBuilder(reportingCalendar: ReportingCalendar(calendar: Self.makeCalendar()))
        let window = ReportWindow(
            start: Self.date("2026-03-09T20:00:00Z"),
            end: Self.date("2026-03-10T20:00:00Z")
        )

        let csv = builder.csvString(
            for: window,
            totals: [.creation: 3600]
        )

        XCTAssertTrue(csv.contains("Creation,3600,60.00,01:00:00"))
        XCTAssertTrue(csv.contains("Recovery,0,0.00,00:00:00"))
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
