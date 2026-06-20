import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var runner: DiagnosticRunner

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("System Check")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                        Text("Verify the local tools and workspace folders needed for review, assembly, and reframing.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button {
                        runner.run()
                    } label: {
                        Label(runner.isRunning ? "Checking" : "Run Check", systemImage: "stethoscope")
                    }
                    .disabled(runner.isRunning)
                }

                HStack(spacing: 10) {
                    Button {
                        runner.openWorkspaceFolder()
                    } label: {
                        Label("Workspace", systemImage: "folder")
                    }

                    Button {
                        runner.openVideosFolder()
                    } label: {
                        Label("Videos", systemImage: "film.stack")
                    }

                    Button {
                        runner.openAudioLibraryFolder()
                    } label: {
                        Label("Audio", systemImage: "waveform")
                    }
                }

                StudioPanel(
                    title: "Privacy Rule",
                    subtitle: "This project does not bundle accounts, private access material, or private production assets."
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        RuleLine(icon: "desktopcomputer", title: "Local first", detail: "Review notes, manifests, and reframing run on files you choose on your Mac.")
                        RuleLine(icon: "key.slash", title: "No bundled access material", detail: "VIDMARK STUDIO does not ship provider access files or account-specific configuration.")
                        RuleLine(icon: "checkmark.seal", title: "Review-gated output", detail: "Mark issues by timecode, export notes, then assemble or reframe only approved media.")
                    }
                }

                if let report = runner.report {
                    StudioPanel(title: "Latest Check", subtitle: "Generated \(report.generatedAt)") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                            ForEach(report.checks) { check in
                                DiagnosticStatusCard(check: check)
                            }
                        }
                    }
                }

                StudioPanel(title: "Check Output", subtitle: "No account data are collected.") {
                    ScrollView {
                        Text(runner.log)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(10)
                    }
                    .frame(minHeight: 220)
                    .background(Color.black.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(24)
        }
    }
}

private struct RuleLine: View {
    var icon: String
    var title: String
    var detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(StudioTheme.accent)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(detail)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DiagnosticStatusCard: View {
    var check: DiagnosticCheck

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(check.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(check.status)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.14))
                    .clipShape(Capsule())
            }

            Text(check.detail)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !check.next.isEmpty {
                Text(check.next)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(statusColor.opacity(0.22))
        )
    }

    private var statusColor: Color {
        switch check.status {
        case "connected":
            StudioTheme.green
        case "not-created":
            StudioTheme.gold
        default:
            StudioTheme.red
        }
    }
}
