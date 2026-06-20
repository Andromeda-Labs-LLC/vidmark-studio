import Foundation

struct EpisodeSidecar: Codable, Equatable {
    var episodeID = "VID-0000"
    var workingTitle = "Untitled Video Review Project"
    var slug = "untitled-video-review-project"
    var primaryLocation = ""
    var realWorldAnchors = ""
    var season = ""
    var weather = ""
    var timeOfDay = ""
    var lightingStyle = "natural, realistic exposure"
    var modelScale = "production-ready video assets"
    var cameraLanguage = "varied shot sizes with clear subject continuity"
    var vehicleVocabulary = ""
    var allowedVehicleVariety = ""
    var disallowedVehicles = ""
    var routeSetPieces = ""
    var openingHandPlan = ""
    var shotModuleCount = 21
    var targetMasterDurationSeconds = 180
    var shortsCandidatesDesired = 3
    var audioBedTags = "soft, rights-safe, normalized, no harsh peaks"
    var spotEffectTags = ""
    var thumbnailHookIdeas = ""
    var knownRisks = ""
    var reviewerNotes = ""

    var folderName: String {
        "\(episodeID)_\(slug)"
    }
}

extension EpisodeSidecar {
    static let masterBackbone = """
    VIDMARK STUDIO helps creators plan, review, annotate, and assemble video production assets before publishing. Treat every project as review-gated: clips should be inspected, marked, fixed, and approved before the final master leaves the studio.

    Core rules: keep the subject readable from the first frame; avoid dead air; preserve coherent lighting, color, camera language, and continuity across a project; use hard visual cuts unless a project explicitly asks for transitions; keep audio gentle, rights-safe, normalized, and free of jarring peaks; reserve speed correction for reviewer-approved fixes only; document retakes by timecode so an agent or editor can replace the smallest possible section.

    Planning rule: create a structured shot plan before generation or editing. Vary shot scale, camera movement, subject detail, and scene purpose so the final video has momentum instead of repetition.

    Output goal: a reviewed 16:9 master assembled from approved modules, plus vertical short candidates derived from the approved master.
    """

    var episodePrompt: String {
        """
        \(Self.masterBackbone)

        # Episode Sidecar

        Episode ID: \(episodeID)
        Working title: \(workingTitle)
        Project location/world/context: \(primaryLocation)
        Real-world anchors, source references, or continuity rules: \(realWorldAnchors)
        Season: \(season)
        Weather: \(weather)
        Time of day: \(timeOfDay)
        Lighting style: \(lightingStyle)
        Production style: \(modelScale)
        Camera language: \(cameraLanguage)
        Vehicle vocabulary: \(vehicleVocabulary)
        Allowed vehicle variety: \(allowedVehicleVariety)
        Disallowed vehicles/styles: \(disallowedVehicles)
        Route/set-piece list: \(routeSetPieces)
        Opening plan: \(openingHandPlan)
        Shot module count: \(shotModuleCount)
        Target master duration: \(targetMasterDurationSeconds) seconds
        Shorts candidates desired: \(shortsCandidatesDesired)
        Audio bed tags: \(audioBedTags)
        Spot effect tags: \(spotEffectTags)
        Thumbnail hook ideas: \(thumbnailHookIdeas)
        Known risks: \(knownRisks)
        Reviewer notes: \(reviewerNotes)

        Create a numbered shot plan with \(shotModuleCount) distinct 16:9 prompts or review modules. Keep the same project world coherent while varying scene purpose, camera distance, visual density, and motion.
        """
    }
}
