import AppKit
import Foundation

@MainActor
final class DiagnosticRunner: ObservableObject {
    @Published var isRunning = false
    @Published var log = "Run the system check to verify local video tools."
    @Published var report: DiagnosticReport?

    func run() {
        guard !isRunning else { return }

        isRunning = true

        let checks = [
            toolCheck("FFmpeg", binary: "ffmpeg", next: "Install FFmpeg to assemble, transcode, and export videos."),
            toolCheck("FFprobe", binary: "ffprobe", next: "Install FFmpeg to inspect media duration, dimensions, and audio streams."),
            toolCheck("Python 3", binary: "python3", next: "Install Python 3 to run local analysis helpers."),
            toolCheck("Swift", binary: "swift", next: "Install Xcode command line tools to build the macOS app."),
            fileCheck("Reframer engine", url: ProjectPaths.engineScriptURL(), next: "Build the app bundle or run from the project root."),
            fileCheck("Assembly engine", url: ProjectPaths.studioAssemblerScriptURL(), next: "Build the app bundle or run from the project root."),
            folderCheck("Workspace root", url: ProjectPaths.workspaceRoot, next: "Create the workspace folders from the app.")
        ]

        let generatedAt = ISO8601DateFormatter().string(from: Date())
        let newReport = DiagnosticReport(generatedAt: generatedAt, checks: checks)
        report = newReport
        log = newReport.markdown
        isRunning = false
    }

    func openWorkspaceFolder() {
        openOrCreate(ProjectPaths.workspaceRoot)
    }

    func openVideosFolder() {
        openOrCreate(ProjectPaths.videosRoot)
    }

    func openAudioLibraryFolder() {
        openOrCreate(ProjectPaths.audioLibraryRoot)
    }

    private func openOrCreate(_ url: URL) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            NSWorkspace.shared.open(url)
        } catch {
            log = "Could not open \(url.path): \(error.localizedDescription)"
        }
    }

    private func toolCheck(_ name: String, binary: String, next: String) -> DiagnosticCheck {
        if let path = which(binary) {
            return DiagnosticCheck(name: name, status: "connected", detail: path, next: "")
        }
        return DiagnosticCheck(name: name, status: "missing", detail: "\(binary) was not found on PATH.", next: next)
    }

    private func fileCheck(_ name: String, url: URL?, next: String) -> DiagnosticCheck {
        guard let url else {
            return DiagnosticCheck(name: name, status: "missing", detail: "File not found.", next: next)
        }
        return DiagnosticCheck(name: name, status: "connected", detail: url.path, next: "")
    }

    private func folderCheck(_ name: String, url: URL, next: String) -> DiagnosticCheck {
        let exists = FileManager.default.fileExists(atPath: url.path)
        return DiagnosticCheck(
            name: name,
            status: exists ? "connected" : "not-created",
            detail: exists ? url.path : "\(url.path) does not exist yet.",
            next: exists ? "" : next
        )
    }

    private func which(_ binary: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [binary]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return path.isEmpty ? nil : path
        } catch {
            return nil
        }
    }
}
