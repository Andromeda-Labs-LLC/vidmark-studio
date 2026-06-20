import SwiftUI

struct AudioRulesView: View {
    @ObservedObject var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StudioPanel(title: "Audio Library", subtitle: store.audioLibraryURL.path) {
                    HStack {
                        Button {
                            store.chooseAudioLibrary()
                        } label: {
                            Label("Choose Library", systemImage: "folder")
                        }
                        Spacer()
                    }
                }

                StudioPanel(
                    title: "Mix Rules",
                    subtitle: "Visuals cut cleanly. Audio stays gentle."
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle("Hard visual cuts only", isOn: $store.assembly.videoCutsOnly)
                            .disabled(true)
                        Toggle("No video transitions or filters", isOn: .constant(!store.assembly.allowVideoTransitions && !store.assembly.allowFilters))
                            .disabled(true)
                        Toggle("Speed changes require a reviewer mark", isOn: $store.assembly.speedCorrectionRequiresReviewerMark)
                            .disabled(true)
                        Toggle("No human vocalizations", isOn: $store.assembly.noHumanVocalizations)
                            .disabled(true)

                        Divider()

                        VStack(alignment: .leading) {
                            Text("Audio fade/crossfade: \(store.assembly.audioFadeMs) ms")
                                .foregroundStyle(.secondary)
                            Slider(
                                value: Binding(
                                    get: { Double(store.assembly.audioFadeMs) },
                                    set: { store.assembly.audioFadeMs = Int($0) }
                                ),
                                in: 180...800,
                                step: 10
                            )
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Target loudness")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("LUFS", value: $store.assembly.targetLUFS, format: .number.precision(.fractionLength(1)))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 90)
                            }
                            VStack(alignment: .leading) {
                                Text("True peak")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("dBTP", value: $store.assembly.truePeakDb, format: .number.precision(.fractionLength(1)))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 90)
                            }
                            Spacer()
                        }
                    }
                }

                StudioPanel(title: "Filename Tags", subtitle: "Use these tags when building the local audio library.") {
                    Text("""
                    Environment: city, old-town, garden, alpine, forest, harbor, seaside, rain, snow, industrial, station, tunnel, crossing

                    Train/action: rail-clicks, electric-hum, steam-soft, freight, passenger, tram, cogwheel, funicular, bell-soft, switch, gate

                    Mood: soft, soothing, distant, gentle, no-voices, loop

                    Example:
                    city_old-town_garden_rail-clicks_electric-hum_soft_no-voices_loop_60s.wav
                    """)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                }
            }
            .padding(20)
        }
    }
}
