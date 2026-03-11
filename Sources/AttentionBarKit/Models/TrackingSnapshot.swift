import Foundation

public struct TrackingSnapshot: Codable, Sendable {
    public var finishedSessions: [AttentionSession]
    public var currentSession: AttentionSession?
    public var lastExportedBoundary: Date?
    public var lastExportedFilePath: String?
    public var lastSavedAt: Date?

    public init(
        finishedSessions: [AttentionSession] = [],
        currentSession: AttentionSession? = nil,
        lastExportedBoundary: Date? = nil,
        lastExportedFilePath: String? = nil,
        lastSavedAt: Date? = nil
    ) {
        self.finishedSessions = finishedSessions
        self.currentSession = currentSession
        self.lastExportedBoundary = lastExportedBoundary
        self.lastExportedFilePath = lastExportedFilePath
        self.lastSavedAt = lastSavedAt
    }
}
