import Foundation

struct DiagnosticReport: Codable {
    var generatedAt: String
    var checks: [DiagnosticCheck]

    var markdown: String {
        var lines = [
            "# VIDMARK STUDIO System Check",
            "",
            "- Generated: \(generatedAt)",
            "",
            "| Check | Status | Detail | Next |",
            "| --- | --- | --- | --- |"
        ]

        for check in checks {
            lines.append("| \(check.name) | \(check.status) | \(check.detail) | \(check.next) |")
        }

        return lines.joined(separator: "\n")
    }
}

struct DiagnosticCheck: Codable, Identifiable, Hashable {
    var name: String
    var status: String
    var detail: String
    var next: String

    var id: String { name }

    var isReady: Bool {
        status == "connected"
    }
}
