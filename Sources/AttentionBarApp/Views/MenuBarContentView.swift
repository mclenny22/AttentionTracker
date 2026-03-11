import AppKit
import AttentionBarKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var engine: TrackingEngine

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let window = engine.currentWindow(at: now)
            let totals = engine.totalsForCurrentWindow(at: now)
            let maxValue = max(totals.values.max() ?? 0, 1)

            VStack(alignment: .leading, spacing: 16) {
                header(window: window)
                activeSessionCard(now: now)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(AttentionCategory.allCases) { category in
                        CategoryChipButton(
                            category: category,
                            isActive: engine.currentCategory == category
                        ) {
                            engine.activate(category, at: now)
                        }
                    }
                }

                Divider()
                    .overlay(Palette.divider)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Time This Window")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.mutedText)

                    ForEach(AttentionCategory.allCases) { category in
                        SummaryRow(
                            category: category,
                            duration: totals[category, default: 0],
                            maxDuration: maxValue
                        )
                    }
                }

                if let error = engine.lastErrorMessage {
                    Text(error)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.error)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let fileName = engine.lastExportedFileURL?.lastPathComponent {
                    Text("Last CSV: \(fileName)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.mutedText)
                }

                HStack(spacing: 10) {
                    Button("Open CSV Folder") {
                        engine.openExportsFolder()
                    }
                    .buttonStyle(SecondaryActionButtonStyle())

                    Button("Quit") {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
            }
            .padding(16)
            .frame(width: 372)
            .background(
                LinearGradient(
                    colors: [Palette.backgroundTop, Palette.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private func header(window: ReportWindow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text("Attention")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
                Spacer()
                Text("Closes 20:00")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Palette.badgeBackground)
                    .foregroundStyle(Palette.badgeText)
                    .clipShape(Capsule())
            }

            Text(windowDescription(window))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.mutedText)
        }
    }

    private func activeSessionCard(now: Date) -> some View {
        let activeCategory = engine.currentCategory
        let title = activeCategory?.displayName ?? "Not Tracking"
        let subtitle = activeCategory?.descriptionText ?? "Choose what has your attention right now."
        let elapsed = engine.currentSessionStartDate.map { now.timeIntervalSince($0) } ?? 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(activeCategory?.accentColor ?? Palette.inactiveDot)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.primaryText)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(Palette.mutedText)
                Text(AttentionDurationFormatter.positionalString(from: elapsed))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Palette.cardBorder, lineWidth: 1)
                )
        )
    }

    private func windowDescription(_ window: ReportWindow) -> String {
        "\(window.start.formatted(date: .abbreviated, time: .shortened)) to \(window.end.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct CategoryChipButton: View {
    let category: AttentionCategory
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.displayName)
                        .font(.system(size: 12, weight: isActive ? .semibold : .medium, design: .rounded))
                        .foregroundStyle(Palette.primaryText)
                        .lineLimit(1)
                    Text(category.shortDescription)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.mutedText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Circle()
                    .fill(category.accentColor)
                    .frame(width: 10, height: 10)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isActive ? category.accentColor.opacity(0.18) : Palette.chipBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(isActive ? category.accentColor.opacity(0.5) : Palette.chipBorder, lineWidth: 1)
                    )
                    .shadow(color: isActive ? category.accentColor.opacity(0.18) : Palette.shadow, radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SummaryRow: View {
    let category: AttentionCategory
    let duration: TimeInterval
    let maxDuration: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(category.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.primaryText)

                Spacer()

                Text(AttentionDurationFormatter.positionalString(from: duration))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.mutedText)
            }

            GeometryReader { proxy in
                let ratio = CGFloat(duration / maxDuration)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Palette.progressTrack)
                    Capsule()
                        .fill(category.accentColor)
                        .frame(width: duration > 0 ? max(6, proxy.size.width * ratio) : 0)
                }
            }
            .frame(height: 7)
        }
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Palette.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(configuration.isPressed ? Palette.buttonPressed : Palette.buttonBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Palette.chipBorder, lineWidth: 1)
                    )
            )
    }
}

private enum Palette {
    static let backgroundTop = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let backgroundBottom = Color(red: 0.91, green: 0.95, blue: 0.92)
    static let cardBackground = Color.white.opacity(0.78)
    static let cardBorder = Color.white.opacity(0.7)
    static let chipBackground = Color.white.opacity(0.9)
    static let chipBorder = Color.black.opacity(0.05)
    static let badgeBackground = Color(red: 0.90, green: 0.97, blue: 0.92)
    static let badgeText = Color(red: 0.19, green: 0.45, blue: 0.29)
    static let buttonBackground = Color.white.opacity(0.75)
    static let buttonPressed = Color.white.opacity(0.92)
    static let primaryText = Color(red: 0.22, green: 0.22, blue: 0.22)
    static let mutedText = Color(red: 0.39, green: 0.40, blue: 0.42)
    static let divider = Color.black.opacity(0.07)
    static let shadow = Color.black.opacity(0.06)
    static let progressTrack = Color.black.opacity(0.06)
    static let error = Color(red: 0.66, green: 0.16, blue: 0.16)
    static let inactiveDot = Color.black.opacity(0.12)
}

extension AttentionCategory {
    var accentColor: Color {
        switch self {
        case .creation:
            Color(red: 0.43, green: 0.88, blue: 0.41)
        case .consumption:
            Color(red: 0.98, green: 0.72, blue: 0.29)
        case .logistics:
            Color(red: 0.45, green: 0.63, blue: 0.94)
        case .connection:
            Color(red: 0.93, green: 0.46, blue: 0.57)
        case .exploration:
            Color(red: 0.55, green: 0.56, blue: 0.95)
        case .recovery:
            Color(red: 0.37, green: 0.76, blue: 0.70)
        }
    }

    var menuBarSymbol: String {
        switch self {
        case .creation:
            "pencil.tip.crop.circle"
        case .consumption:
            "book.closed.circle"
        case .logistics:
            "tray.full.circle"
        case .connection:
            "bubble.left.and.bubble.right.circle"
        case .exploration:
            "binoculars.circle"
        case .recovery:
            "leaf.circle"
        }
    }

    var shortDescription: String {
        switch self {
        case .creation:
            "Make"
        case .consumption:
            "Scroll"
        case .logistics:
            "Admin"
        case .connection:
            "People"
        case .exploration:
            "Research"
        case .recovery:
            "Rest"
        }
    }
}
