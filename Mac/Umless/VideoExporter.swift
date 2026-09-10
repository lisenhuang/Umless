//
//  VideoExporter.swift
//  Umless
//
//  Stitches the kept ranges back together and re-encodes them into a file with
//  the same shape as the input.
//

import AVFoundation
import CoreMedia
import VideoToolbox

/// Writes the cut-down video.
///
/// The composition does the cutting; a reader/writer pair does the encoding.
/// That split is deliberate: `AVAssetExportSession`'s presets pick their own
/// output dimensions, whereas driving `AVAssetWriter` directly lets every
/// format decision be copied off the source — width and height from the coded
/// dimensions, frame rate from the track, rotation as track metadata, and the
/// colour tags verbatim.
///
/// Passthrough (no re-encode) is not an option here: filler cuts land at
/// arbitrary times, and a passthrough export can only cut on key frames, which
/// would leave the "um" in.
nonisolated enum VideoExporter {

    static func export(
        source: SourceVideo,
        plan: CutPlan,
        to outputURL: URL,
        progress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws {
        guard !plan.keepRanges.isEmpty else { throw UmlessError.nothingLeft }

        let composition = try await makeComposition(source: source, plan: plan)

        // MARK: Reader over the stitched composition

        let reader = try AVAssetReader(asset: composition)
        guard let videoTrack = try await composition.loadTracks(withMediaType: .video).first else {
            throw UmlessError.noVideoTrack
        }
        let pixelFormat = source.isHighBitDepth
            ? kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
            : kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        let videoOutput = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat])
        videoOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(videoOutput) else { throw UmlessError.readFailed("video output rejected") }
        reader.add(videoOutput)

        var audioOutput: AVAssetReaderAudioMixOutput?
        if let audioTrack = try await composition.loadTracks(withMediaType: .audio).first {
            let output = AVAssetReaderAudioMixOutput(audioTracks: [audioTrack], audioSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: source.audioSampleRate,
                AVNumberOfChannelsKey: source.audioChannels,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false,
            ])
            output.alwaysCopiesSampleData = false
            if reader.canAdd(output) {
                reader.add(output)
                audioOutput = output
            }
        }

        // MARK: Writer configured from the source's own numbers

        try? FileManager.default.removeItem(at: outputURL)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: source.outputFileType)

        let videoInput = AVAssetWriterInput(
            mediaType: .video, outputSettings: source.videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = false
        // Rotation travels as track metadata, exactly as it did on the source,
        // so the picture is never re-rendered into a different orientation.
        videoInput.transform = source.preferredTransform
        guard writer.canAdd(videoInput) else { throw UmlessError.writeFailed("video input rejected") }
        writer.add(videoInput)

        var audioInput: AVAssetWriterInput?
        if audioOutput != nil {
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: source.audioSampleRate,
                AVNumberOfChannelsKey: source.audioChannels,
                AVEncoderBitRateKey: source.audioChannels > 1 ? 256_000 : 128_000,
            ])
            input.expectsMediaDataInRealTime = false
            if writer.canAdd(input) {
                writer.add(input)
                audioInput = input
            }
        }

        guard reader.startReading() else {
            throw UmlessError.readFailed(reader.error?.localizedDescription ?? "unknown")
        }
        guard writer.startWriting() else {
            throw UmlessError.writeFailed(writer.error?.localizedDescription ?? "unknown")
        }
        writer.startSession(atSourceTime: .zero)

        // MARK: Pump

        // Progress is measured against the output timeline: the video pump
        // reports the presentation time of each sample it writes.
        let total = max(0.001, plan.outputDuration)
        let tracker = ProgressThrottle { progress(min(0.99, $0)) }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await pump(output: videoOutput, into: videoInput, label: "video") { pts in
                        tracker.send(pts / total)
                    }
                }
                if let audioOutput, let audioInput {
                    group.addTask {
                        try await pump(output: audioOutput, into: audioInput, label: "audio")
                    }
                }
                try await group.waitForAll()
            }
        } catch {
            reader.cancelReading()
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: outputURL)
            throw error
        }

        if reader.status == .failed {
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: outputURL)
            throw UmlessError.readFailed(reader.error?.localizedDescription ?? "unknown")
        }

        await writer.finishWriting()
        if writer.status != .completed {
            try? FileManager.default.removeItem(at: outputURL)
            throw UmlessError.writeFailed(writer.error?.localizedDescription ?? "unknown")
        }
        progress(1)
    }

    // MARK: - Composition

    /// Also used to preview the edit before exporting, so the preview and
    /// the export are always the same cut.
    static func makeComposition(
        source: SourceVideo, plan: CutPlan
    ) async throws -> AVComposition {
        let composition = AVMutableComposition()
        guard let srcVideo = try await source.asset.loadTracks(withMediaType: .video).first else {
            throw UmlessError.noVideoTrack
        }
        let srcAudio = try await source.asset.loadTracks(withMediaType: .audio).first

        guard let dstVideo = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw UmlessError.writeFailed("could not create a video track")
        }
        let dstAudio = srcAudio == nil ? nil : composition.addMutableTrack(
            withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        // Boundaries as whole frames, in integer ticks — see
        // `SourceVideo.frameDuration` for why this doesn't go through seconds.
        let frame = source.frameDuration
        func atFrameBoundary(_ seconds: Double) -> CMTime {
            guard frame.isValid, frame.seconds > 0 else {
                return CMTime(seconds: seconds, preferredTimescale: source.videoTimeScale)
            }
            let index = (seconds / frame.seconds).rounded()
            return CMTimeMultiply(frame, multiplier: Int32(max(0, min(Double(Int32.max), index))))
        }

        var cursor = CMTime.zero
        for keep in plan.keepRanges {
            let range = CMTimeRange(start: atFrameBoundary(keep.lowerBound),
                                    end: atFrameBoundary(keep.upperBound))
            guard range.duration > .zero else { continue }
            try dstVideo.insertTimeRange(range, of: srcVideo, at: cursor)
            if let dstAudio, let srcAudio {
                try dstAudio.insertTimeRange(range, of: srcAudio, at: cursor)
            }
            cursor = cursor + range.duration
        }
        // Kept so the composition previews upright; the export re-applies it on
        // the writer input rather than relying on this.
        dstVideo.preferredTransform = source.preferredTransform
        return composition.copy() as! AVComposition
    }

    // MARK: - Sample pumping

    /// Drains one reader output into one writer input.
    ///
    /// The append happens inside the `requestMediaDataWhenReady` callback
    /// rather than in an `AsyncStream` the caller pulls from. That callback
    /// runs only while the input actually wants more data, which is what
    /// applies back pressure; a stream in between would decouple reading from
    /// encoding and pull the whole decoded video into memory first.
    private static func pump(
        output: AVAssetReaderOutput,
        into input: AVAssetWriterInput,
        label: String,
        onSample: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        let queue = DispatchQueue(label: "com.lisenhuang.Umless.export.\(label)")
        let gate = ResumeOnce()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                gate.arm(continuation)
                input.requestMediaDataWhenReady(on: queue) {
                    while input.isReadyForMoreMediaData {
                        // The writer may have been torn down by the other
                        // track failing; stop touching it if so.
                        if gate.isFinished { return }
                        guard let buffer = output.copyNextSampleBuffer() else {
                            input.markAsFinished()
                            gate.finish(.success(()))
                            return
                        }
                        let pts = CMSampleBufferGetPresentationTimeStamp(buffer).seconds
                        guard input.append(buffer) else {
                            input.markAsFinished()
                            gate.finish(.failure(UmlessError.writeFailed("\(label) sample rejected")))
                            return
                        }
                        onSample?(pts)
                    }
                }
            }
        } onCancel: {
            gate.finish(.failure(CancellationError()))
        }
    }

    /// Resumes its continuation exactly once, from whichever of the writer
    /// callback or a cancellation reaches it first.
    private final class ResumeOnce: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<Void, Error>?
        private var finished = false

        var isFinished: Bool { lock.withLock { finished } }

        func arm(_ continuation: CheckedContinuation<Void, Error>) {
            lock.lock()
            guard !finished else {
                // Cancelled before the callback was even installed.
                lock.unlock()
                continuation.resume(throwing: CancellationError())
                return
            }
            self.continuation = continuation
            lock.unlock()
        }

        func finish(_ result: Result<Void, Error>) {
            lock.lock()
            guard !finished else { return lock.unlock() }
            finished = true
            let pending = continuation
            continuation = nil
            lock.unlock()
            pending?.resume(with: result)
        }
    }

}

// MARK: - Format matching

private nonisolated extension SourceVideo {
    var outputFileType: AVFileType {
        codec.isProRes ? .mov : (url.pathExtension.lowercased() == "mov" ? .mov : .mp4)
    }

    /// Encoder settings derived entirely from the source, so the export comes
    /// back the same size, at the same rate, with the same colour.
    var videoOutputSettings: [String: Any] {
        var settings: [String: Any] = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: Int(codedSize.width),
            AVVideoHeightKey: Int(codedSize.height),
        ]
        if let colorProperties {
            settings[AVVideoColorPropertiesKey] = colorProperties
        }
        // ProRes is a fixed-quality codec and rejects a bit-rate target.
        guard !codec.isProRes else { return settings }

        var compression: [String: Any] = [
            AVVideoAverageBitRateKey: Int(targetBitRate),
            AVVideoExpectedSourceFrameRateKey: Int(frameRate.rounded()),
            // A key frame roughly every 2 s: standard for delivery files, and
            // it keeps seeking responsive in whatever the user opens this in.
            AVVideoMaxKeyFrameIntervalKey: max(1, Int(frameRate.rounded()) * 2),
            AVVideoAllowFrameReorderingKey: true,
        ]
        if codec == .hevc, isHighBitDepth {
            compression[AVVideoProfileLevelKey] = kVTProfileLevel_HEVC_Main10_AutoLevel as String
        } else if codec == .h264 {
            compression[AVVideoProfileLevelKey] = AVVideoProfileLevelH264HighAutoLevel
        }
        settings[AVVideoCompressionPropertiesKey] = compression
        return settings
    }

    /// Aim at the source's own bit rate — the export should not visibly differ
    /// from the input — with a floor for containers that under-report it.
    var targetBitRate: Double {
        let pixels = codedSize.width * codedSize.height
        let bitsPerPixel = codec == .hevc ? 0.07 : 0.10
        let floor = pixels * Double(max(frameRate, 1)) * bitsPerPixel
        return max(Double(videoDataRate), floor)
    }
}
