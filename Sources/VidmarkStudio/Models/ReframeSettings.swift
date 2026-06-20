import Foundation

enum ReframeMode: String, CaseIterable, Identifiable {
    case smart
    case center
    case planOnly = "plan-only"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smart: "Smart"
        case .center: "Center"
        case .planOnly: "Plan Only"
        }
    }
}

enum ReframeQuality: String, CaseIterable, Identifiable {
    case draft
    case standard
    case high
    case archival

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draft: "Draft"
        case .standard: "Standard"
        case .high: "High"
        case .archival: "Archival"
        }
    }
}

struct ReframeSettings {
    var mode: ReframeMode = .smart
    var quality: ReframeQuality = .standard
    var aspect: String = "9:16"
    var width: Int = 1080
    var height: Int = 1920
    var duration: Double = 20
    var candidates: Int = 3
    var sampleFPS: Double = 2
    var analysisWidth: Int = 320
}
