import Foundation

public struct CSVReportBuilder: Sendable {
    public let reportingCalendar: ReportingCalendar

    public init(reportingCalendar: ReportingCalendar = ReportingCalendar()) {
        self.reportingCalendar = reportingCalendar
    }

    public func totals(
        for sessions: [AttentionSession],
        in window: ReportWindow,
        openSessionsUntil referenceEnd: Date
    ) -> [AttentionCategory: TimeInterval] {
        let range = DateInterval(start: window.start, end: window.end)
        var totals = Dictionary(uniqueKeysWithValues: AttentionCategory.allCases.map { ($0, 0.0) })

        for session in sessions {
            let duration = session.overlapDuration(in: range, defaultEnd: referenceEnd)
            guard duration > 0 else {
                continue
            }
            totals[session.category, default: 0] += duration
        }

        return totals
    }

    public func fileName(for window: ReportWindow) -> String {
        "attention-\(dateLabel(for: window.end)).csv"
    }

    public func csvString(for window: ReportWindow, totals: [AttentionCategory: TimeInterval]) -> String {
        let reportDate = dateLabel(for: window.end)
        let start = isoTimestamp(for: window.start)
        let end = isoTimestamp(for: window.end)

        var rows = ["report_date,window_start,window_end,category,total_seconds,total_minutes,total_hhmmss"]

        for category in AttentionCategory.allCases {
            let total = totals[category, default: 0]
            let totalSeconds = max(0, Int(total.rounded()))
            let totalMinutes = String(format: "%.2f", total / 60)
            let hhmmss = AttentionDurationFormatter.positionalString(from: total)
            rows.append([
                reportDate,
                start,
                end,
                category.displayName,
                String(totalSeconds),
                totalMinutes,
                hhmmss,
            ].joined(separator: ","))
        }

        return rows.joined(separator: "\n") + "\n"
    }

    private func dateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = reportingCalendar.calendar
        formatter.timeZone = reportingCalendar.calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func isoTimestamp(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = reportingCalendar.calendar.timeZone
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
