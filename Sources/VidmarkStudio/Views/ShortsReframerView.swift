import SwiftUI

struct ShortsReframerView: View {
    @ObservedObject var store: StudioStore
    @ObservedObject var runner: ReframerRunner
    @State private var outputURL: URL?
    @State private var settings = ReframeSettings()

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    StudioPanel(title: "Source", subtitle: store.masterVideoURL?.path ?? "No master selected") {
                        HStack {
                            Button {
                                store.chooseMasterVideo()
                                syncOutput()
                            } label: {
                                Label("Choose Master", systemImage: "film")
                            }
                            Button {
                                chooseOutput()
                            } label: {
                                Label("Output Folder", systemImage: "folder")
                            }
                            Spacer()
                        }
                    }

                    StudioPanel(title: "Shorts Candidates", subtitle: "Derived from the approved widescreen master.") {
                        Picker("Mode", selection: $settings.mode) {
                            ForEach(ReframeMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        Picker("Quality", selection: $settings.quality) {
                            ForEach(ReframeQuality.allCases) { quality in
                                Text(quality.title).tag(quality)
                            }
                        }

                        HStack {
                            numericField("Width", value: $settings.width)
                            numericField("Height", value: $settings.height)
                        }

                        VStack(alignment: .leading) {
                            Text("Duration: \(Int(settings.duration)) sec")
                                .foregroundStyle(.secondary)
                            Slider(value: $settings.duration, in: 15...60, step: 1)
                        }
                        Stepper("Candidates: \(settings.candidates)", value: $settings.candidates, in: 1...6)
                    }

                    Button {
                        run()
                    } label: {
                        Label(runner.isRunning ? "Running" : "Generate Shorts", systemImage: runner.isRunning ? "hourglass" : "crop")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.masterVideoURL == nil || runner.isRunning)
                }
                .padding(20)
            }
            .frame(width: 380)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Reframer Log")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Button {
                        runner.openOutputFolder()
                    } label: {
                        Label("Open Output", systemImage: "arrow.up.forward.app")
                    }
                    .disabled(runner.lastOutputFolder == nil)
                }

                TextEditor(text: $runner.log)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.quaternary)
                    )
            }
            .padding(20)
        }
        .onAppear(perform: syncOutput)
    }

    private func syncOutput() {
        if let master = store.masterVideoURL {
            outputURL = ProjectPaths.defaultOutputFolder(for: master)
        }
    }

    private func run() {
        guard let input = store.masterVideoURL else { return }
        let output = outputURL ?? ProjectPaths.defaultOutputFolder(for: input)
        outputURL = output
        runner.run(input: input, output: output, settings: settings)
    }

    private func chooseOutput() {
        let panel = NSOpenPanel()
        panel.title = "Choose Shorts Output Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = outputURL ?? store.episodeFolderURL ?? ProjectPaths.videosRoot
        if panel.runModal() == .OK, let url = panel.url {
            outputURL = url
        }
    }

    private func numericField(_ title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: value, formatter: NumberFormatter.integer)
                .textFieldStyle(.roundedBorder)
                .frame(width: 110)
        }
    }
}
