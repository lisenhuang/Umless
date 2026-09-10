//
//  AppModel.swift
//  Umless
//

import AVFoundation
import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers
import Uhm

@MainActor
@Observable
final class AppModel {

    enum Stage: Equatable {
        case empty
        case openingVideo
        case extractingAudio(Double)
        case analyzing(Double)
        case reviewing
        case exporting(Double)

        var isBusy: Bool {
            if case .reviewing = self { return false }
            if case .empty = self { return false }
            return true
        }

        /// The same step of the pipeline, however far through it is.
        func isSamePhase(as other: Stage) -> Bool {
            switch (self, other) {
            case (.empty, .empty), (.openingVideo, .openingVideo), (.reviewing, .reviewing),
                 (.extractingAudio, .extractingAudio), (.analyzing, .analyzing),
                 (.exporting, .exporting):
                true
            default:
                false
            }
        }
    }

    // MARK: Input

    private(set) var source: SourceVideo?
    private(set) var stage: Stage = .empty
    var errorMessage: String?
    private(set) var exportedURL: URL?

    /// Every filler the model found at its loosest threshold. The list the user
    /// sees is this, filtered by `sensitivity`.
    private(set) var allFillers: [Filler] = []
    /// Fillers the user has explicitly unticked, so they survive a sensitivity
    /// change rather than being silently re-enabled.
    private var mutedIDs: Set<Filler.ID> = []

    // MARK: Controls

    var sensitivity: Uhm.Bias = .balanced {
        didSet {
            player.setMarkers(visibleFillers)
            recomputePlan()
        }
    }
    /// Extra seconds trimmed either side of each filler, to take the breath with it.
    var padding: Double = 0.04 {
        didSet {
            recomputePlan()
            if previewsCut { Task { await refreshCutPreview() } }
        }
    }
    /// When on, the player shows the edit instead of the original.
    var previewsCut = false {
        didSet { Task { await refreshCutPreview() } }
    }

    let player = PlayerController()
    private let analyzer = FillerAnalyzer()
    private var work: Task<Void, Never>?
    /// Identifies the run in flight, so a report that arrives late can be told
    /// apart from a live one. See `beginRun()`.
    private var runToken = 0
    /// Held for as long as the video is open. A file chosen through the open
    /// panel or a drag is only readable inside its security scope, and both the
    /// player and the export read it long after opening finishes.
    ///
    /// `nonisolated(unsafe)` so `deinit` — which runs outside the main actor —
    /// can release the scope. Every other access is on the main actor, and at
    /// deinit nothing else holds a reference.
    @ObservationIgnored
    private nonisolated(unsafe) var scopedURL: URL?

    // MARK: Derived

    /// Fillers above the current confidence threshold.
    var visibleFillers: [Filler] {
        let threshold = sensitivity.minConfidence
        return allFillers.filter { $0.confidence >= threshold }
    }

    /// The ones that will actually be cut: visible and not unticked.
    var activeFillers: [Filler] {
        visibleFillers.filter { !mutedIDs.contains($0.id) }
    }

    /// The current edit. Stored rather than computed: the views read it several
    /// times per render pass, and rebuilding it there would re-sort and re-merge
    /// every filler thirty times a second while the video plays.
    private(set) var plan = CutPlan.make(fillers: [], padding: 0, duration: 0, frameRate: 30)

    private func recomputePlan() {
        plan = CutPlan.make(
            fillers: activeFillers.map(\.range),
            padding: padding,
            duration: source?.durationSeconds ?? 0,
            frameRate: Double(source?.frameRate ?? 30))
    }

    func isEnabled(_ filler: Filler) -> Bool { !mutedIDs.contains(filler.id) }

    /// The fillers the user has unticked, for drawing them as "kept" on the bar.
    var disabledIDs: Set<Filler.ID> { mutedIDs }

    func setEnabled(_ enabled: Bool, for filler: Filler) {
        if enabled { mutedIDs.remove(filler.id) } else { mutedIDs.insert(filler.id) }
        recomputePlan()
        player.setMarkers(visibleFillers)
        if previewsCut { Task { await refreshCutPreview() } }
    }

    func setAllEnabled(_ enabled: Bool) {
        mutedIDs = enabled ? [] : Set(visibleFillers.map(\.id))
        recomputePlan()
        player.setMarkers(visibleFillers)
        if previewsCut { Task { await refreshCutPreview() } }
    }

    // MARK: Stage reporting

    /// Cancels whatever was running and mints the token for what replaces it.
    ///
    /// Progress is produced on the exporter's and the analyzer's own queues and
    /// has to hop to the main actor to land, so a report can arrive after the
    /// work that produced it is over — including the last one an export sends,
    /// which is emitted a moment before the export call returns. Applied
    /// blindly, that late report puts a finished stage back on screen, and
    /// since the progress overlay is driven by the stage, the overlay comes
    /// back up over an app with nothing left to do and stays there. Every
    /// report carries the token of the run it came from and is dropped once
    /// that token is stale.
    private func beginRun() -> Int {
        work?.cancel()
        runToken &+= 1
        return runToken
    }

    /// Moves `token`'s run on to its next step, if that run is still current.
    private func advance(_ token: Int, to stage: Stage) {
        guard token == runToken else { return }
        self.stage = stage
    }

    /// Applies a progress report — dropped unless its run is current *and*
    /// still in the step the report describes.
    private func report(_ token: Int, _ progress: Stage) {
        guard token == runToken, stage.isSamePhase(as: progress) else { return }
        stage = progress
    }

    /// The last word from `token`'s run: nothing that run reports afterwards
    /// lands, including whatever is already queued up behind this.
    private func finish(_ token: Int, at stage: Stage) {
        guard token == runToken else { return }
        runToken &+= 1
        self.stage = stage
    }

    // MARK: Opening

    static let readableTypes: [UTType] = [.movie, .quickTimeMovie, .mpeg4Movie, .video]

    func open(url: URL) {
        let token = beginRun()
        releaseScope()
        if url.startAccessingSecurityScopedResource() { scopedURL = url }
        exportedURL = nil
        errorMessage = nil
        work = Task { await run(url: url, token: token) }
    }

    private func releaseScope() {
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
    }

    deinit {
        // Deinit may land on any thread, but nothing else can reach the model
        // at this point, so releasing the scope directly is safe.
        scopedURL?.stopAccessingSecurityScopedResource()
    }

    func reset() {
        _ = beginRun()
        releaseScope()
        player.unload()
        source = nil
        allFillers = []
        mutedIDs = []
        recomputePlan()
        exportedURL = nil
        errorMessage = nil
        previewsCut = false
        stage = .empty
    }

    private func run(url: URL, token: Int) async {
        do {
            advance(token, to: .openingVideo)
            let video = try await SourceVideo.load(url: url)
            guard video.hasAudio else { throw UmlessError.noAudioTrack }
            source = video
            allFillers = []
            mutedIDs = []
            recomputePlan()
            player.load(asset: video.asset, duration: video.durationSeconds)

            guard analyzer.isModelReady else { throw UmlessError.modelMissing }

            advance(token, to: .extractingAudio(0))
            let extracting = ProgressThrottle { [weak self] f in
                Task { @MainActor in self?.report(token, .extractingAudio(f)) }
            }
            let samples = try await AudioExtractor.monoSamples(from: video.asset, progress: extracting.send)
            try Task.checkCancellation()

            advance(token, to: .analyzing(0))
            let analyzing = ProgressThrottle { [weak self] f in
                Task { @MainActor in self?.report(token, .analyzing(f)) }
            }
            let fillers = try await analyzer.analyze(samples: samples, progress: analyzing.send)
            try Task.checkCancellation()

            allFillers = fillers
            recomputePlan()
            player.setMarkers(visibleFillers)
            finish(token, at: .reviewing)
        } catch is CancellationError {
            // Superseded by another open, or reset — leave the UI to the new run.
        } catch {
            guard token == runToken else { return }
            errorMessage = error.localizedDescription
            finish(token, at: source == nil ? .empty : .reviewing)
        }
    }

    // MARK: Preview

    /// Swaps the player between the original and the edit. The cut preview is
    /// the same composition the exporter builds, so what plays here is what
    /// gets written.
    private func refreshCutPreview() async {
        guard let source else { return }
        let wasPlaying = player.isPlaying
        let plan = self.plan
        let wasAt = player.currentTime
        if previewsCut {
            guard !plan.keepRanges.isEmpty else { return }
            guard let composition = try? await VideoExporter.makeComposition(source: source, plan: plan)
            else { return }
            player.load(asset: composition, duration: plan.outputDuration)
            player.setMarkers([])
            // Land on the same moment of the video, not back at the start.
            player.seek(to: plan.outputTime(forSourceTime: wasAt))
        } else {
            player.load(asset: source.asset, duration: source.durationSeconds)
            player.setMarkers(visibleFillers)
            player.seek(to: plan.sourceTime(forOutputTime: wasAt))
        }
        if wasPlaying { player.play() }
    }

    // MARK: Export

    var suggestedFilename: String {
        guard let source else { return "Umless.mp4" }
        let stem = source.url.deletingPathExtension().lastPathComponent
        return "\(stem) (umless).\(source.url.pathExtension.isEmpty ? "mp4" : source.url.pathExtension)"
    }

    func export(to destination: URL) {
        guard let source else { return }
        let plan = self.plan
        let token = beginRun()
        errorMessage = nil
        exportedURL = nil
        player.pause()
        work = Task {
            do {
                advance(token, to: .exporting(0))
                let exporting = ProgressThrottle { [weak self] f in
                    Task { @MainActor in self?.report(token, .exporting(f)) }
                }
                try await VideoExporter.export(source: source, plan: plan, to: destination,
                                               progress: exporting.send)
                guard token == runToken else { return }
                exportedURL = destination
                finish(token, at: .reviewing)
            } catch is CancellationError {
                finish(token, at: .reviewing)
            } catch {
                guard token == runToken else { return }
                errorMessage = error.localizedDescription
                finish(token, at: .reviewing)
            }
        }
    }

    func cancelWork() {
        _ = beginRun()
        stage = source == nil ? .empty : .reviewing
    }
}
