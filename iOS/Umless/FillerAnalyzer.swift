//
//  FillerAnalyzer.swift
//  Umless
//
//  Wrapper around the Uhm on-device model.
//

import Foundation
import Uhm

/// One detected filler, plus the identity the UI needs to toggle it.
nonisolated struct Filler: Identifiable, Hashable, Sendable {
    let id = UUID()
    let start: Double
    let end: Double
    let confidence: Double
    let kind: Uhm.FillerType?

    var duration: Double { end - start }
    var range: ClosedRange<Double> { start...max(start, end) }

    /// What to call it in the list.
    ///
    /// The sounds themselves stay as written — an "um" is an "um" in any
    /// interface language. Only `other`, the model's "it's a filler but I'm
    /// not sure which" bucket, becomes a translated word.
    var label: String {
        switch kind {
        case .uh: "uh"
        case .um: "um"
        case .hmm: "hmm"
        case .and: "and"
        case .other, nil: LocalizationCore.string("filler")
        }
    }
}

/// Runs Uhm over extracted audio.
///
/// Detection always runs at the model's loosest threshold and the results are
/// filtered by confidence afterwards. Inference is the expensive step, so
/// running it once and re-filtering in the UI makes the sensitivity control
/// instant instead of a re-analysis.
nonisolated final class FillerAnalyzer: @unchecked Sendable {
    /// The Core ML model shipped inside the app.
    ///
    /// Pointing `Uhm` at a directory that already holds the platform's files
    /// makes it adopt them in place: nothing is downloaded, nothing is written,
    /// and the app works offline and on first launch. The folder is a `.bundle`
    /// so it is copied into the app wrapper verbatim rather than being run
    /// through Xcode's Core ML compiler.
    static let bundledModelDirectory: String? =
        Bundle.main.url(forResource: "UhmModel", withExtension: "bundle")?.path

    // Default compute units (`.all`) let Core ML pick the Neural Engine.
    private let uhm = Uhm(directory: bundledModelDirectory, quality: .auto)

    /// The threshold everything is detected at; the UI never shows less than this.
    static let captureThreshold = Uhm.Bias.recall.minConfidence

    /// False only if the app wrapper was built or tampered with without the
    /// model — there is no download to fall back on.
    var isModelReady: Bool {
        Self.bundledModelDirectory != nil && uhm.isDownloaded()
    }

    func analyze(
        samples: [Float],
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> [Filler] {
        let options = Uhm.Options(
            bias: .recall,
            includeTypes: true,
            minConfidence: Self.captureThreshold,
            minDurationSec: 0.12)
        let result = try await uhm.analyze(
            samples: samples,
            sampleRate: AudioExtractor.sampleRate,
            options: options,
            progressHandler: progress)
        return result.fillers.map {
            Filler(start: $0.start, end: $0.end, confidence: $0.confidence, type: $0.type)
        }
    }
}

private nonisolated extension Filler {
    init(start: Double, end: Double, confidence: Double, type: Uhm.FillerType?) {
        self.init(start: start, end: end, confidence: confidence, kind: type)
    }
}

@MainActor
extension Uhm.Bias {
    var displayName: String {
        switch self {
        case .precision: loc("Only obvious ones")
        case .balanced: loc("Balanced")
        case .recall: loc("Catch everything")
        }
    }

    var detail: String {
        switch self {
        case .precision: loc("Fewest false alarms — safest for a hands-off cut.")
        case .balanced: loc("The model’s default trade-off.")
        case .recall: loc("Flags more, including some that aren’t fillers.")
        }
    }
}
