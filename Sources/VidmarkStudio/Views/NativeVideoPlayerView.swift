import AVKit
import SwiftUI

struct NativeVideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    var fullScreenTrigger: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .floating
        view.videoGravity = .resizeAspect
        view.showsFrameSteppingButtons = true
        view.showsFullScreenToggleButton = true
        view.allowsPictureInPicturePlayback = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }

        if fullScreenTrigger != context.coordinator.lastFullScreenTrigger {
            context.coordinator.lastFullScreenTrigger = fullScreenTrigger
            guard fullScreenTrigger > 0, let screen = nsView.window?.screen else { return }
            nsView.enterFullScreenMode(screen, withOptions: nil)
        }
    }

    final class Coordinator {
        var lastFullScreenTrigger = 0
    }
}
