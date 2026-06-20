import Foundation

enum StudioSection: String, CaseIterable, Identifiable {
    case episode
    case prompts
    case review
    case audio
    case assembly
    case shorts
    case diagnostics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .episode: "Episode"
        case .prompts: "Prompts"
        case .review: "Review"
        case .audio: "Audio"
        case .assembly: "Assembly"
        case .shorts: "Shorts"
        case .diagnostics: "System Check"
        }
    }

    var detail: String {
        switch self {
        case .episode: "Sidecar and folder"
        case .prompts: "ChatGPT image batches"
        case .review: "Timecode marks"
        case .audio: "Fades and loudness"
        case .assembly: "Manifest export"
        case .shorts: "Smart reframing"
        case .diagnostics: "Local tools"
        }
    }

    var systemImage: String {
        switch self {
        case .episode: "square.stack.3d.up"
        case .prompts: "text.badge.sparkles"
        case .review: "scope"
        case .audio: "waveform"
        case .assembly: "timeline.selection"
        case .shorts: "rectangle.portrait.on.rectangle.portrait"
        case .diagnostics: "stethoscope"
        }
    }
}
