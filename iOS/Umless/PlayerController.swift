//
//  PlayerController.swift
//  Umless
//

import AVFoundation
import Observation

/// Owns the preview player and publishes the playhead.
///
/// Deliberately not `VideoPlayer` from AVKit: Umless needs its own transport
/// bar so filler markers can live on the scrubber, and AVKit's built-in
/// controls would sit on top of it.
@MainActor
@Observable
final class PlayerController {

    let player = AVPlayer()

    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var isPlaying = false
    /// Filler spans drawn on the scrubber.
    private(set) var markers: [Filler] = []
    /// The marker the playhead is currently inside, if any.
    ///
    /// Published separately from `currentTime` so the list and the marker layer
    /// can highlight without re-rendering on every tick — this changes a
    /// handful of times a minute, `currentTime` thirty times a second.
    private(set) var activeMarkerID: Filler.ID?

    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?

    init() {
        player.actionAtItemEnd = .pause
        // ~30 Hz: smooth for the playhead without redrawing the timeline more
        // often than the display does.
        let interval = CMTime(seconds: 1.0 / 30, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self else { return }
                let seconds = time.seconds
                self.currentTime = seconds
                self.isPlaying = self.player.rate != 0
                let active = self.markers.first { seconds >= $0.start && seconds <= $0.end }?.id
                if active != self.activeMarkerID { self.activeMarkerID = active }
            }
        }
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
    }

    func load(asset: AVAsset, duration: Double) {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        self.duration = duration
        currentTime = 0
        isPlaying = false
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.isPlaying = false }
            }
    }

    func unload() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        markers = []
        activeMarkerID = nil
        duration = 0
        currentTime = 0
        isPlaying = false
    }

    func setMarkers(_ markers: [Filler]) {
        self.markers = markers
        let now = currentTime
        activeMarkerID = markers.first { now >= $0.start && now <= $0.end }?.id
    }

    // MARK: Transport

    func play() {
        // Restart rather than sit at the end doing nothing.
        if duration > 0, currentTime >= duration - 0.05 {
            seek(to: 0)
        }
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func seek(to seconds: Double) {
        let clamped = min(max(0, seconds), max(0, duration))
        currentTime = clamped
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// Jump to a moment and start playing from it — what clicking a marker does.
    /// Backs up slightly so you hear the run-in rather than landing mid-word.
    func playFrom(_ seconds: Double, leadIn: Double = 0.35) {
        seek(to: seconds - leadIn)
        play()
    }

    func step(by seconds: Double) {
        seek(to: currentTime + seconds)
    }
}
