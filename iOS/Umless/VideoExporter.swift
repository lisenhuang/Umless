//
//  VideoExporter.swift
//  Umless
//
//  Stitches the kept ranges back together and re-encodes them into a file with
//  the same shape as the input.
//

import AVFoundation
import AudioToolbox
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
        var audioFormat: AudioFormat?
        if let audioTrack = try await composition.loadTracks(withMediaType: .audio).first {
            let format = await AudioFormat(track: audioTrack, source: source)
            let output = AVAssetReaderAudioMixOutput(
                audioTracks: [audioTrack], audioSettings: format.decodeSettings)
            output.alwaysCopiesSampleData = false
            if reader.canAdd(output) {
                reader.add(output)
                audioOutput = output
                audioFormat = format
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
        if let audioFormat {
            let input = AVAssetWriterInput(
                mediaType: .audio, outputSettings: audioFormat.encodeSettings)
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
                    try await pump(output: videoOutput, into: videoInput, label: "video",
                                   writerError: { writer.error }) { pts in
                        tracker.send(pts / total)
                    }
                }
                if let audioOutput, let audioInput {
                    group.addTask {
                        try await pump(output: audioOutput, into: audioInput, label: "audio",
                                       writerError: { writer.error })
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
        writerError: @escaping @Sendable () -> Error?,
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
                            // A false return only says the append failed; the
                            // reason lives on the writer, and the cancel that
                            // follows this throws it away. Read it here, while
                            // it still exists, so the user sees why.
                            let reason = writerError().map { "\($0.localizedDescription) (\(label))" }
                                ?? "\(label) sample rejected"
                            gate.finish(.failure(UmlessError.writeFailed(reason)))
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

// MARK: - Audio format

/// The single audio configuration used at both ends of the export: what the
/// reader decodes the composition to, and what the writer encodes back out.
///
/// One type on purpose. The two settings dictionaries have to agree, and a
/// disagreement is not reported where it is made — `canAdd` still returns true
/// and `startWriting` still succeeds, and the export only fails on the first
/// `append`, by which point the reason has to be dug out of the writer.
private struct AudioFormat {
    let sampleRate: Double
    let channels: Int
    /// The source's own channel layout, which AAC requires above stereo.
    let layout: Data?

    init(track: AVAssetTrack, source: SourceVideo) async {
        let sourceChannels = max(1, source.audioChannels)
        // Only fetched where it is needed. Mono and stereo the encoder infers,
        // and a source layout can describe the *encoded* channels rather than
        // the decoded ones, so trusting it below three channels risks
        // contradicting a channel count that is already known to be right.
        let layout = sourceChannels > 2
            ? (try? await track.load(.formatDescriptions))?.first.flatMap(Self.channelLayout)
            : nil

        // AAC will not encode more than two channels without being told how
        // they are arranged. A file that arrives multichannel but layout-less
        // folds down to stereo rather than being handed to the encoder in a
        // shape it refuses.
        self.channels = sourceChannels > 2 && layout == nil ? 2 : sourceChannels
        self.layout = layout
        // A rate of zero would otherwise be carried straight into the encoder.
        self.sampleRate = source.audioSampleRate >= 8_000 ? source.audioSampleRate : 48_000
    }

    /// Signed 16-bit, interleaved — deliberately, and not the float PCM that
    /// would otherwise be the natural choice for an intermediate.
    ///
    /// iOS encodes AAC in hardware, and that encoder takes packed Int16 and
    /// nothing else: give it Float32 and every `append` on the audio input
    /// returns false. The simulator, which encodes in software, accepts either,
    /// which is why the round-trip tests never caught this and only exports on
    /// a real device failed.
    var decodeSettings: [String: Any] {
        var settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
        if let layout { settings[AVChannelLayoutKey] = layout }
        return settings
    }

    var encodeSettings: [String: Any] {
        var settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderBitRateKey: bitRate,
        ]
        if let layout { settings[AVChannelLayoutKey] = layout }
        return settings
    }

    /// 128 kbps a channel, or the closest the encoder will actually take.
    ///
    /// What AAC-LC accepts narrows sharply as the sample rate drops — 256 kbps
    /// is fine for 44.1 kHz stereo and refused at 22.05 — and the refusal
    /// arrives as a failed `append` part-way through an export, not as a
    /// rejected configuration. The limits do not follow a formula worth
    /// guessing at, so ask the encoder for its own list and take the best entry
    /// that fits under the target.
    private var bitRate: Int {
        let target = channels > 1 ? 256_000 : 128_000
        let applicable = Self.applicableBitRates(sampleRate: sampleRate, channels: channels)
        guard let lowest = applicable.first else { return min(target, 64_000 * channels) }
        return applicable.last { $0 <= target } ?? lowest
    }

    /// Bit rates this build's AAC encoder will accept for this exact rate and
    /// channel count, ascending. Empty if it cannot be asked.
    private static func applicableBitRates(sampleRate: Double, channels: Int) -> [Int] {
        var destination = AudioStreamBasicDescription(
            mSampleRate: sampleRate, mFormatID: kAudioFormatMPEG4AAC, mFormatFlags: 0,
            mBytesPerPacket: 0, mFramesPerPacket: 1024, mBytesPerFrame: 0,
            mChannelsPerFrame: UInt32(channels), mBitsPerChannel: 0, mReserved: 0)
        var source = AudioStreamBasicDescription(
            mSampleRate: sampleRate, mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: UInt32(2 * channels), mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(2 * channels), mChannelsPerFrame: UInt32(channels),
            mBitsPerChannel: 16, mReserved: 0)

        var converter: AudioConverterRef?
        guard AudioConverterNew(&source, &destination, &converter) == noErr,
              let converter else { return [] }
        defer { AudioConverterDispose(converter) }

        var size: UInt32 = 0
        guard AudioConverterGetPropertyInfo(
            converter, kAudioConverterApplicableEncodeBitRates, &size, nil) == noErr,
            size > 0 else { return [] }
        var ranges = [AudioValueRange](
            repeating: AudioValueRange(), count: Int(size) / MemoryLayout<AudioValueRange>.size)
        guard AudioConverterGetProperty(
            converter, kAudioConverterApplicableEncodeBitRates, &size, &ranges) == noErr
        else { return [] }
        return ranges.map { Int($0.mMaximum) }.filter { $0 > 0 }.sorted()
    }

    private static func channelLayout(_ description: CMFormatDescription) -> Data? {
        var size = 0
        guard let layout = CMAudioFormatDescriptionGetChannelLayout(description, sizeOut: &size),
              size > 0 else { return nil }
        return Data(bytes: layout, count: size)
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
