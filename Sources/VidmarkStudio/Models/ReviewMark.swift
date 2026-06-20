import Foundation

enum ReviewCategory: String, Codable, CaseIterable, Identifiable {
    case videoArtifact
    case audioIssue
    case tooSlow
    case tooLoud
    case trim
    case thumbnail
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .videoArtifact: "Video artifact"
        case .audioIssue: "Audio issue"
        case .tooSlow: "Too slow"
        case .tooLoud: "Too loud"
        case .trim: "Trim"
        case .thumbnail: "Thumbnail"
        case .other: "Other"
        }
    }
}

enum ReviewAction: String, Codable, CaseIterable, Identifiable {
    case replaceClip
    case replaceAudio
    case lowerVolume
    case trimStart
    case trimEnd
    case modestSpeedCorrection
    case regenerateThumbnail
    case noteOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .replaceClip: "Replace clip"
        case .replaceAudio: "Replace audio"
        case .lowerVolume: "Lower volume"
        case .trimStart: "Trim start"
        case .trimEnd: "Trim end"
        case .modestSpeedCorrection: "Speed +10-20%"
        case .regenerateThumbnail: "New thumbnail"
        case .noteOnly: "Note only"
        }
    }
}

struct ReviewMark: Identifiable, Codable, Equatable {
    var id = UUID()
    var timecodeSeconds: Double
    var durationSeconds: Double = 5
    var category: ReviewCategory = .videoArtifact
    var action: ReviewAction = .replaceClip
    var note = ""
    var speedMultiplier: Double = 1.0
    var volumeDeltaDb: Double = 0
    var createdAt = Date()
}

enum TimecodeFormatter {
    static func string(_ seconds: Double) -> String {
        let clamped = max(0, seconds)
        let totalFrames = Int((clamped * 24).rounded())
        let frames = totalFrames % 24
        let totalSeconds = totalFrames / 24
        let secs = totalSeconds % 60
        let mins = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600
        if hours > 0 {
            return String(format: "%d:%02d:%02d:%02d", hours, mins, secs, frames)
        }
        return String(format: "%02d:%02d:%02d", mins, secs, frames)
    }
}
