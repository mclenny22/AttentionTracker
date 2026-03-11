import Foundation

public final class TrackingStore {
    public let stateDirectory: URL
    public let stateURL: URL
    public let exportDirectory: URL

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        stateDirectory: URL? = nil,
        exportDirectory: URL? = nil
    ) {
        let fileManager = FileManager.default
        let resolvedStateDirectory = stateDirectory ?? Self.defaultStateDirectory(fileManager: fileManager)
        let resolvedExportDirectory = exportDirectory ?? Self.defaultExportDirectory(fileManager: fileManager)

        self.stateDirectory = resolvedStateDirectory
        self.stateURL = resolvedStateDirectory.appendingPathComponent("tracking-state.json", isDirectory: false)
        self.exportDirectory = resolvedExportDirectory

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        try? fileManager.createDirectory(at: resolvedStateDirectory, withIntermediateDirectories: true, attributes: nil)
        try? fileManager.createDirectory(at: resolvedExportDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    public func loadSnapshot() throws -> TrackingSnapshot {
        guard FileManager.default.fileExists(atPath: stateURL.path) else {
            return TrackingSnapshot()
        }

        let data = try Data(contentsOf: stateURL)
        return try decoder.decode(TrackingSnapshot.self, from: data)
    }

    public func saveSnapshot(_ snapshot: TrackingSnapshot) throws {
        try FileManager.default.createDirectory(at: stateDirectory, withIntermediateDirectories: true, attributes: nil)
        let data = try encoder.encode(snapshot)
        try data.write(to: stateURL, options: .atomic)
    }

    public func exportReport(
        window: ReportWindow,
        totals: [AttentionCategory: TimeInterval],
        reportBuilder: CSVReportBuilder
    ) throws -> URL {
        try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true, attributes: nil)
        let fileURL = exportDirectory.appendingPathComponent(reportBuilder.fileName(for: window), isDirectory: false)
        let csv = reportBuilder.csvString(for: window, totals: totals)
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private static func defaultStateDirectory(fileManager: FileManager) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        return base.appendingPathComponent("AttentionBar", isDirectory: true)
    }

    private static func defaultExportDirectory(fileManager: FileManager) -> URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents", isDirectory: true)
        return base.appendingPathComponent("Attention Reports", isDirectory: true)
    }
}
