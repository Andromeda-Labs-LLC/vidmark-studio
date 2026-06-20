import SwiftUI

struct EpisodeSetupView: View {
    @ObservedObject var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StudioPanel(
                    title: "Episode Sidecar",
                    subtitle: "The sidecar changes per video; the master backbone stays fixed."
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 14) {
                            labeledField("Episode ID", text: $store.sidecar.episodeID)
                            labeledField("Slug", text: $store.sidecar.slug)
                        }
                        labeledField("Working title", text: $store.sidecar.workingTitle)
                        HStack(alignment: .top, spacing: 14) {
                            labeledField("Location/world", text: $store.sidecar.primaryLocation)
                            labeledField("Season", text: $store.sidecar.season)
                        }
                        HStack(alignment: .top, spacing: 14) {
                            labeledField("Weather", text: $store.sidecar.weather)
                            labeledField("Time of day", text: $store.sidecar.timeOfDay)
                        }
                        labeledField("Vehicle vocabulary", text: $store.sidecar.vehicleVocabulary)
                    }

                    HStack(spacing: 12) {
                        Stepper("Modules: \(store.sidecar.shotModuleCount)", value: $store.sidecar.shotModuleCount, in: 18...30)
                        Stepper("Master: \(store.sidecar.targetMasterDurationSeconds)s", value: $store.sidecar.targetMasterDurationSeconds, in: 150...300, step: 10)
                        Spacer()
                        Button {
                            store.createEpisodeFolder()
                        } label: {
                            Label("Create Folder", systemImage: "folder.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                StudioPanel(title: "Episode Folder", subtitle: store.episodeRootForDisplay) {
                    HStack {
                        Button {
                            store.chooseEpisodeFolder()
                        } label: {
                            Label("Choose Folder", systemImage: "folder")
                        }
                        Button {
                            try? store.saveSidecar()
                        } label: {
                            Label("Save Sidecar", systemImage: "square.and.arrow.down")
                        }
                        Spacer()
                    }
                }

                StudioPanel(title: "Notes And Risks", subtitle: "These feed the episode-specific prompt layer.") {
                    VStack(alignment: .leading, spacing: 10) {
                        labeledEditor("Route/set pieces", text: $store.sidecar.routeSetPieces, height: 78)
                        labeledEditor("Allowed vehicle variety", text: $store.sidecar.allowedVehicleVariety, height: 62)
                        labeledEditor("Known risks", text: $store.sidecar.knownRisks, height: 62)
                        labeledEditor("Reviewer notes", text: $store.sidecar.reviewerNotes, height: 70)
                    }
                }
            }
            .padding(20)
        }
    }

    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func labeledEditor(_ title: String, text: Binding<String>, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .frame(height: height)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
