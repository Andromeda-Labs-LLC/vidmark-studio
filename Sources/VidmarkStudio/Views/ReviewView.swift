import AVFoundation
import SwiftUI

struct ReviewView: View {
    @ObservedObject var store: StudioStore
    @StateObject private var clock = PlayerClock()
    @State private var player = AVPlayer()
    @State private var showMarkSheet = false
    @State private var isTheaterMode = false
    @State private var fullScreenTrigger = 0

    var body: some View {
        HStack(spacing: 0) {
            reviewDeck
                .padding(20)

            if !isTheaterMode {
                Divider()
                marksPanel
                    .frame(width: 360)
                    .padding(20)
            }
        }
        .onAppear(perform: loadMaster)
        .onChange(of: store.masterVideoURL) {
            loadMaster()
        }
        .sheet(isPresented: $showMarkSheet) {
            ReviewMarkSheet(
                initialTime: clock.currentTime,
                onSave: { mark in
                    store.addReviewMark(mark)
                }
            )
        }
    }

    private var reviewDeck: some View {
        VStack(alignment: .leading, spacing: 14) {
            reviewHeader
            videoSurface
            transportControls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reviewHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reviewer Notes")
                    .font(.system(size: 18, weight: .semibold))
                Text("Mark timecoded problems for agents to replace, trim, remix, or gently speed-correct.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.chooseMasterVideo()
            } label: {
                Label("Choose Master", systemImage: "film")
            }

            Button {
                store.exportReviewPackage()
            } label: {
                Label("Export", systemImage: "square.and.arrow.down")
            }
            .disabled(store.reviewMarks.isEmpty)

            Button {
                isTheaterMode.toggle()
            } label: {
                Label(
                    isTheaterMode ? "Show Marks" : "Theater",
                    systemImage: isTheaterMode ? "sidebar.right" : "rectangle.expand.vertical"
                )
            }
            .disabled(store.masterVideoURL == nil)

            Button {
                showMarkSheet = true
            } label: {
                Label("Add Mark", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.masterVideoURL == nil)
        }
    }

    private var videoSurface: some View {
        ZStack {
            if store.masterVideoURL == nil {
                ContentUnavailableView(
                    "No Master Selected",
                    systemImage: "film",
                    description: Text("Choose the episode master to begin review.")
                )
            } else {
                NativeVideoPlayerView(player: player, fullScreenTrigger: fullScreenTrigger)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: isTheaterMode ? 620 : 430)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
    }

    private var transportControls: some View {
        HStack(spacing: 14) {
            Button {
                player.seek(to: .zero)
                player.play()
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            .disabled(store.masterVideoURL == nil)

            Button {
                player.pause()
            } label: {
                Label("Pause", systemImage: "pause.fill")
            }
            .disabled(store.masterVideoURL == nil)

            Button {
                showMarkSheet = true
            } label: {
                Label("Mark \(TimecodeFormatter.string(clock.currentTime))", systemImage: "mappin.and.ellipse")
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.masterVideoURL == nil)

            Button {
                fullScreenTrigger += 1
            } label: {
                Label("Full Screen", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .disabled(store.masterVideoURL == nil)

            Spacer()

            Text(TimecodeFormatter.string(clock.currentTime))
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(StudioTheme.gold)
        }
    }

    private var marksPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Marks")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button {
                    store.exportReviewPackage()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.down")
                }
                .disabled(store.reviewMarks.isEmpty)
            }

            if store.reviewMarks.isEmpty {
                ContentUnavailableView(
                    "No Marks Yet",
                    systemImage: "checkmark.seal",
                    description: Text("Add a mark when something feels off.")
                )
            } else {
                List {
                    ForEach(store.reviewMarks) { mark in
                        Button {
                            seek(to: mark.timecodeSeconds)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(TimecodeFormatter.string(mark.timecodeSeconds))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(StudioTheme.accent)
                                    Spacer()
                                    Text(mark.action.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(mark.category.title)
                                    .font(.subheadline.weight(.semibold))
                                if !mark.note.isEmpty {
                                    Text(mark.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: store.deleteReviewMarks)
                }
            }
        }
    }

    private func loadMaster() {
        guard let url = store.masterVideoURL else {
            player.pause()
            player.replaceCurrentItem(with: nil)
            return
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        clock.attach(to: player)
    }

    private func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        player.play()
    }
}

struct ReviewMarkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mark: ReviewMark
    var onSave: (ReviewMark) -> Void

    init(initialTime: Double, onSave: @escaping (ReviewMark) -> Void) {
        self._mark = State(initialValue: ReviewMark(timecodeSeconds: initialTime))
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Review Mark")
                .font(.title3.weight(.semibold))

            HStack {
                Text("Timecode")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(TimecodeFormatter.string(mark.timecodeSeconds))
                    .font(.system(.body, design: .monospaced).weight(.semibold))
            }

            Picker("Problem", selection: $mark.category) {
                ForEach(ReviewCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }

            Picker("Fix", selection: $mark.action) {
                ForEach(ReviewAction.allCases) { action in
                    Text(action.title).tag(action)
                }
            }

            HStack {
                Stepper("Duration: \(mark.durationSeconds, specifier: "%.1f")s", value: $mark.durationSeconds, in: 1...30, step: 0.5)
                Spacer()
            }

            if mark.action == .modestSpeedCorrection {
                VStack(alignment: .leading) {
                    Text("Speed: \(mark.speedMultiplier, specifier: "%.2f")x")
                        .foregroundStyle(.secondary)
                    Slider(value: $mark.speedMultiplier, in: 1.05...1.20, step: 0.01)
                }
            }

            if mark.action == .lowerVolume || mark.action == .replaceAudio {
                VStack(alignment: .leading) {
                    Text("Volume change: \(mark.volumeDeltaDb, specifier: "%.1f") dB")
                        .foregroundStyle(.secondary)
                    Slider(value: $mark.volumeDeltaDb, in: -12...0, step: 0.5)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $mark.note)
                    .frame(height: 110)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save Mark") {
                    onSave(mark)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 460)
    }
}

@MainActor
final class PlayerClock: ObservableObject {
    @Published var currentTime: Double = 0
    private var observerHandle: Any?
    private weak var player: AVPlayer?

    func attach(to player: AVPlayer) {
        detach()
        self.player = player
        observerHandle = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.20, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds.isFinite ? time.seconds : 0
            }
        }
    }

    func detach() {
        if let observerHandle, let player {
            player.removeTimeObserver(observerHandle)
        }
        observerHandle = nil
        player = nil
    }
}
