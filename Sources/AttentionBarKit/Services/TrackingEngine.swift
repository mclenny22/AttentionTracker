import AppKit
import Combine
import Foundation

public final class TrackingEngine: ObservableObject {
    @Published public private(set) var snapshot: TrackingSnapshot
    @Published public private(set) var lastErrorMessage: String?

    public let store: TrackingStore
    public let reportingCalendar: ReportingCalendar
    public let reportBuilder: CSVReportBuilder

    private var boundaryTimer: Timer?
    private var heartbeatTimer: Timer?
    private var observers: [NSObjectProtocol] = []

    public init(
        store: TrackingStore = TrackingStore(),
        reportingCalendar: ReportingCalendar = ReportingCalendar()
    ) {
        self.store = store
        self.reportingCalendar = reportingCalendar
        self.reportBuilder = CSVReportBuilder(reportingCalendar: reportingCalendar)
        self.snapshot = (try? store.loadSnapshot()) ?? TrackingSnapshot()

        if let path = snapshot.lastExportedFilePath {
            self.lastExportedFileURL = URL(fileURLWithPath: path)
        }

        performSafely {
            let now = Date()
            let recovered = recoverDanglingSession(now: now)
            let bootstrapped = ensureBaselineBoundary(now: now)
            let exported = try processPendingExports(now: now)

            if recovered || bootstrapped || exported {
                try persistSnapshot(at: now)
            }
        }

        startTimers()
        observeLifecycleEvents()
    }

    deinit {
        boundaryTimer?.invalidate()
        heartbeatTimer?.invalidate()
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    public private(set) var lastExportedFileURL: URL?

    public var currentCategory: AttentionCategory? {
        snapshot.currentSession?.category
    }

    public var exportDirectoryURL: URL {
        store.exportDirectory
    }

    public var currentSessionStartDate: Date? {
        snapshot.currentSession?.startedAt
    }

    public func activate(_ category: AttentionCategory, at now: Date = Date()) {
        performSafely {
            _ = ensureBaselineBoundary(now: now)
            _ = try processPendingExports(now: now)

            if snapshot.currentSession?.category == category {
                let changed = closeCurrentSession(at: now)
                if changed {
                    try persistSnapshot(at: now)
                }
                scheduleBoundaryTimer(from: now)
                return
            }

            closeCurrentSession(at: now)
            snapshot.currentSession = AttentionSession(category: category, startedAt: now)
            try persistSnapshot(at: now)
            scheduleBoundaryTimer(from: now)
        }
    }

    public func pauseTracking(at now: Date = Date()) {
        performSafely {
            _ = ensureBaselineBoundary(now: now)
            _ = try processPendingExports(now: now)
            let changed = closeCurrentSession(at: now)
            if changed {
                try persistSnapshot(at: now)
            }
            scheduleBoundaryTimer(from: now)
        }
    }

    public func currentWindow(at now: Date = Date()) -> ReportWindow {
        reportingCalendar.currentWindow(at: now)
    }

    public func totalsForCurrentWindow(at now: Date = Date()) -> [AttentionCategory: TimeInterval] {
        let window = currentWindow(at: now)
        return reportBuilder.totals(
            for: allSessions,
            in: window,
            openSessionsUntil: now
        )
    }

    public func openExportsFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([exportDirectoryURL])
    }

    private var allSessions: [AttentionSession] {
        if let current = snapshot.currentSession {
            return snapshot.finishedSessions + [current]
        }
        return snapshot.finishedSessions
    }

    private func observeLifecycleEvents() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let defaultCenter = NotificationCenter.default

        observers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillSleep()
            }
        )

        observers.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleDidWake()
            }
        )

        observers.append(
            defaultCenter.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleWillTerminate()
            }
        )
    }

    private func startTimers() {
        scheduleBoundaryTimer(from: Date())

        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.handleHeartbeat()
        }
        heartbeatTimer?.tolerance = 5
    }

    private func scheduleBoundaryTimer(from now: Date) {
        boundaryTimer?.invalidate()
        let nextBoundary = currentWindow(at: now).end
        let interval = max(1, nextBoundary.timeIntervalSince(now))

        boundaryTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleBoundaryReached()
        }
        boundaryTimer?.tolerance = 1
    }

    private func handleBoundaryReached() {
        performSafely {
            let now = Date()
            _ = ensureBaselineBoundary(now: now)
            let exported = try processPendingExports(now: now)
            if exported {
                try persistSnapshot(at: now)
            }
            scheduleBoundaryTimer(from: now)
        }
    }

    private func handleHeartbeat() {
        performSafely {
            let now = Date()
            let bootstrapped = ensureBaselineBoundary(now: now)
            let exported = try processPendingExports(now: now)

            if snapshot.currentSession != nil || bootstrapped || exported {
                try persistSnapshot(at: now)
            }

            if exported {
                scheduleBoundaryTimer(from: now)
            }
        }
    }

    private func handleWillSleep() {
        pauseTracking(at: Date())
    }

    private func handleDidWake() {
        performSafely {
            let now = Date()
            let bootstrapped = ensureBaselineBoundary(now: now)
            let exported = try processPendingExports(now: now)
            if bootstrapped || exported {
                try persistSnapshot(at: now)
            }
            scheduleBoundaryTimer(from: now)
        }
    }

    private func handleWillTerminate() {
        pauseTracking(at: Date())
    }

    private func recoverDanglingSession(now: Date) -> Bool {
        guard let current = snapshot.currentSession else {
            return false
        }

        let safeEnd = max(current.startedAt, min(now, snapshot.lastSavedAt ?? current.startedAt))
        if safeEnd > current.startedAt {
            snapshot.finishedSessions.append(current.ending(at: safeEnd))
        }
        snapshot.currentSession = nil
        return true
    }

    private func ensureBaselineBoundary(now: Date) -> Bool {
        guard snapshot.lastExportedBoundary == nil else {
            return false
        }
        snapshot.lastExportedBoundary = reportingCalendar.mostRecentBoundary(onOrBefore: now)
        return true
    }

    private func processPendingExports(now: Date) throws -> Bool {
        guard let lastBoundary = snapshot.lastExportedBoundary else {
            return false
        }

        var currentBoundary = lastBoundary
        var exportedAny = false

        for window in reportingCalendar.windowsDue(after: currentBoundary, upTo: now) {
            splitOpenSession(at: window.end)

            let totals = reportBuilder.totals(
                for: allSessions,
                in: window,
                openSessionsUntil: window.end
            )
            let exportURL = try store.exportReport(
                window: window,
                totals: totals,
                reportBuilder: reportBuilder
            )

            snapshot.lastExportedBoundary = window.end
            snapshot.lastExportedFilePath = exportURL.path
            lastExportedFileURL = exportURL
            pruneFinishedSessions(beforeOrAt: window.end)
            currentBoundary = window.end
            exportedAny = true
        }

        if exportedAny, snapshot.lastExportedBoundary != currentBoundary {
            snapshot.lastExportedBoundary = currentBoundary
        }

        return exportedAny
    }

    @discardableResult
    private func closeCurrentSession(at now: Date) -> Bool {
        guard let current = snapshot.currentSession else {
            return false
        }

        snapshot.finishedSessions.append(current.ending(at: now))
        snapshot.currentSession = nil
        return true
    }

    private func splitOpenSession(at boundary: Date) {
        guard let current = snapshot.currentSession else {
            return
        }
        guard current.startedAt < boundary else {
            return
        }

        snapshot.finishedSessions.append(current.ending(at: boundary))
        snapshot.currentSession = current.restarting(at: boundary)
    }

    private func pruneFinishedSessions(beforeOrAt boundary: Date) {
        snapshot.finishedSessions.removeAll { session in
            guard let endedAt = session.endedAt else {
                return false
            }
            return endedAt <= boundary
        }
    }

    private func persistSnapshot(at now: Date) throws {
        snapshot.lastSavedAt = now
        try store.saveSnapshot(snapshot)
    }

    private func performSafely(_ operation: () throws -> Void) {
        do {
            try operation()
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }
}
