import AppKit
import Foundation

@MainActor
final class ReframerRunner: ObservableObject {
    @Published var isRunning = false
    @Published var log = "Choose a widescreen master to begin."
    @Published var lastOutputFolder: URL?

    func run(input: URL, output: URL, settings: ReframeSettings) {
        guard !isRunning else { return }
        guard let engine = ProjectPaths.engineScriptURL() else {
            log = "Could not find the local reframer engine."
            return
        }

        isRunning = true
        lastOutputFolder = output
        log = "Starting VIDMARK STUDIO Reframer...\n"

        let args: [String] = [
            "python3",
            engine.path,
            input.path,
            "--output-dir", output.path,
            "--mode", settings.mode.rawValue,
            "--aspect", settings.aspect,
            "--width", String(settings.width),
            "--height", String(settings.height),
            "--duration", String(format: "%.1f", settings.duration),
            "--candidates", String(settings.candidates),
            "--quality", settings.quality.rawValue,
            "--sample-fps", String(format: "%.1f", settings.sampleFPS),
            "--analysis-width", String(settings.analysisWidth)
        ]

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args
        process.environment = [
            "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "PYTHONUNBUFFERED": "1"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                self?.log.append(text)
            }
        }

        process.terminationHandler = { [weak self] completed in
            Task { @MainActor in
                pipe.fileHandleForReading.readabilityHandler = nil
                self?.isRunning = false
                if completed.terminationStatus == 0 {
                    self?.log.append("\nFinished. Shorts candidates and report are in:\n\(output.path)\n")
                } else {
                    self?.log.append("\nReframer stopped with status \(completed.terminationStatus).\n")
                }
            }
        }

        do {
            try process.run()
        } catch {
            isRunning = false
            log.append("Launch failed: \(error.localizedDescription)\n")
        }
    }

    func openOutputFolder() {
        guard let lastOutputFolder else { return }
        NSWorkspace.shared.open(lastOutputFolder)
    }
}
