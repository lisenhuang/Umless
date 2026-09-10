//
//  ExportRoundTripTests.swift
//  UmlessTests
//
//  The promise the app makes is that the export is the same shape as the
//  input. These tests generate a fixture, cut it, and read the result back.
//

import AVFoundation
import CoreMedia
import Testing
@testable import Umless

@Suite(.serialized, .timeLimit(.minutes(3)))
struct ExportRoundTripTests {

    @Test func exportPreservesResolutionFrameRateAndRotation() async throws {
        // 29.97 fps on purpose: a rate that only survives if it is actually
        // carried through, rather than rounded to 30 somewhere.
        let fixture = try await VideoFixture.make(
            width: 1280, height: 720,
            frameDuration: CMTime(value: 1001, timescale: 30_000),
            seconds: 3,
            transform: CGAffineTransform(rotationAngle: .pi / 2))
        defer { try? FileManager.default.removeItem(at: fixture) }

        let source = try await SourceVideo.load(url: fixture)
        #expect(source.codedSize == CGSize(width: 1280, height: 720))
        #expect(abs(source.frameRate - 29.97) < 0.02)

        // Cut a second out of the middle.
        let plan = CutPlan.make(fillers: [1.0...2.0], padding: 0,
                                duration: source.durationSeconds,
                                frameRate: Double(source.frameRate))
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("umless-out-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: output) }

        try await VideoExporter.export(source: source, plan: plan, to: output)

        let result = try await SourceVideo.load(url: output)
        #expect(result.codedSize == source.codedSize, "resolution must match the input")
        #expect(result.codec == source.codec)
        #expect(result.hasAudio)

        // Frame cadence is the thing that must match exactly: the output plays
        // at the source's rate, frame for frame.
        #expect(abs(result.frameDuration.seconds - source.frameDuration.seconds) < 1e-6,
                "frames must stay \(source.frameDuration.seconds)s apart, got \(result.frameDuration.seconds)s")

        // `nominalFrameRate` is frames divided by duration, so a single frame
        // landing either side of the cut moves it by 1/duration — half a frame
        // per second on a clip this short. Allowed for explicitly rather than
        // asserted tightly, because it measures the average and not the rate
        // the file declares.
        let slack = 1.5 / max(1, plan.outputDuration)
        #expect(abs(Double(result.frameRate) - Double(source.frameRate)) < slack,
                "nominal rate \(result.frameRate) vs \(source.frameRate)")

        // Rotation rides as track metadata, so the displayed size stays portrait.
        #expect(abs(result.displaySize.width - source.displaySize.width) < 1)
        #expect(abs(result.displaySize.height - source.displaySize.height) < 1)

        // One second removed from three, within a frame either way.
        let expected = source.durationSeconds - 1.0
        #expect(abs(result.durationSeconds - expected) < 0.1,
                "expected ~\(expected)s, got \(result.durationSeconds)s")
    }

    @Test func exportWithSeveralCutsShortensByTheirTotal() async throws {
        let fixture = try await VideoFixture.make(
            width: 640, height: 480,
            frameDuration: CMTime(value: 1, timescale: 30),
            seconds: 4,
            transform: .identity)
        defer { try? FileManager.default.removeItem(at: fixture) }

        let source = try await SourceVideo.load(url: fixture)
        let plan = CutPlan.make(fillers: [0.5...0.9, 2.0...2.4, 3.2...3.6], padding: 0.05,
                                duration: source.durationSeconds,
                                frameRate: Double(source.frameRate))
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("umless-out-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: output) }

        try await VideoExporter.export(source: source, plan: plan, to: output)

        let result = try await SourceVideo.load(url: output)
        #expect(result.codedSize == CGSize(width: 640, height: 480))
        #expect(abs(result.durationSeconds - plan.outputDuration) < 0.1)

        // Frame *cadence* rather than `nominalFrameRate`, which is frames
        // divided by duration: stitching four segments can land a frame either
        // side of a boundary, which moves that average on a clip this short
        // without changing the rate the file actually plays at.
        let track = try #require(try await AVURLAsset(url: output)
            .loadTracks(withMediaType: .video).first)
        let frameDuration = try await track.load(.minFrameDuration)
        #expect(abs(frameDuration.seconds - 1.0 / 30) < 0.001,
                "frames should still be 1/30 apart, got \(frameDuration.seconds)")
        #expect(abs(result.frameRate - 30) < 1.0)
    }

    @Test func exportingAnEmptyPlanFails() async throws {
        let fixture = try await VideoFixture.make(
            width: 320, height: 240,
            frameDuration: CMTime(value: 1, timescale: 30),
            seconds: 2, transform: .identity)
        defer { try? FileManager.default.removeItem(at: fixture) }

        let source = try await SourceVideo.load(url: fixture)
        let plan = CutPlan.make(fillers: [0.0...2.0], padding: 0,
                                duration: source.durationSeconds, frameRate: 30)
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("umless-empty-\(UUID().uuidString).mp4")

        await #expect(throws: UmlessError.self) {
            try await VideoExporter.export(source: source, plan: plan, to: output)
        }
    }

    @Test func audioExtractionYieldsSixteenKilohertzMono() async throws {
        let fixture = try await VideoFixture.make(
            width: 320, height: 240,
            frameDuration: CMTime(value: 1, timescale: 30),
            seconds: 3, transform: .identity)
        defer { try? FileManager.default.removeItem(at: fixture) }

        let asset = AVURLAsset(url: fixture)
        let samples = try await AudioExtractor.monoSamples(from: asset)
        // 3 s at 16 kHz, allowing for encoder priming at the head.
        #expect(abs(samples.count - 3 * 16_000) < 16_000 / 4)
        #expect(samples.contains { $0 != 0 }, "the fixture tone should not decode to silence")
    }
}

// MARK: - Fixture

/// Writes a throwaway H.264 + AAC movie. Self-contained, so the tests depend on
/// neither a checked-in binary nor an external tool.
///
/// Both tracks are driven by `requestMediaDataWhenReady` rather than by polling
/// `isReadyForMoreMediaData` from the outside. Polling looks equivalent and is
/// not: an input that has gone un-ready may never be re-evaluated until the
/// writer calls back, so a polling loop stalls part-way through at random. The
/// callback form also handles interleaving on its own, so the two tracks need
/// no lockstep between them.
enum VideoFixture {

    static func make(
        width: Int, height: Int, frameDuration: CMTime, seconds: Double,
        transform: CGAffineTransform
    ) async throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("umless-fixture-\(UUID().uuidString).mp4")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let fps = Double(frameDuration.timescale) / Double(frameDuration.value)

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: width * height * 4,
                AVVideoExpectedSourceFrameRateKey: Int(fps.rounded()),
                AVVideoMaxKeyFrameIntervalKey: Int(fps.rounded()),
            ],
        ])
        videoInput.expectsMediaDataInRealTime = false
        videoInput.transform = transform
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
            ])
        writer.add(videoInput)

        let sampleRate = 44_100.0
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 96_000,
        ])
        audioInput.expectsMediaDataInRealTime = false
        writer.add(audioInput)

        guard writer.startWriting() else {
            throw writer.error ?? UmlessError.writeFailed("fixture: startWriting")
        }
        writer.startSession(atSourceTime: .zero)

        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate, channels: 1, interleaved: false)
        else { throw UmlessError.writeFailed("fixture: audio format") }

        let frameCount = Int(seconds * fps)
        let audioFrames = Int(seconds * sampleRate)
        let videoState = PumpState()
        let audioState = PumpState()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await drive(videoInput, state: videoState, label: "video") {
                    guard videoState.index < frameCount else { return false }
                    let buffer = try pixelBuffer(width: width, height: height,
                                                 frame: videoState.index, of: frameCount)
                    let pts = CMTimeMultiply(frameDuration, multiplier: Int32(videoState.index))
                    guard adaptor.append(buffer, withPresentationTime: pts) else {
                        throw writer.error ?? UmlessError.writeFailed("fixture: video append")
                    }
                    videoState.index += 1
                    return true
                }
            }
            group.addTask {
                try await drive(audioInput, state: audioState, label: "audio") {
                    guard audioState.index < audioFrames else { return false }
                    let frames = min(4096, audioFrames - audioState.index)
                    let sample = try toneSample(format: format, frames: frames,
                                                startFrame: audioState.index,
                                                phase: &audioState.phase)
                    guard audioInput.append(sample) else {
                        throw writer.error ?? UmlessError.writeFailed("fixture: audio append")
                    }
                    audioState.index += frames
                    return true
                }
            }
            try await group.waitForAll()
        }

        await writer.finishWriting()
        guard writer.status == .completed else {
            throw writer.error ?? UmlessError.writeFailed("fixture: finishWriting")
        }
        return url
    }

    /// Feeds one input from `next` until it reports no more data. `next`
    /// returns false when the track is complete.
    private static func drive(_ input: AVAssetWriterInput, state: PumpState, label: String,
                              next: @escaping () throws -> Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            state.arm(continuation)
            input.requestMediaDataWhenReady(on: DispatchQueue(label: "fixture.\(label)")) {
                while input.isReadyForMoreMediaData {
                    do {
                        guard try next() else {
                            input.markAsFinished()
                            return state.finish(.success(()))
                        }
                    } catch {
                        input.markAsFinished()
                        return state.finish(.failure(error))
                    }
                }
            }
        }
    }

    /// Per-track cursor plus a resume-once continuation. Only ever touched from
    /// its input's own serial callback queue, except `finish`, which is guarded.
    private final class PumpState: @unchecked Sendable {
        var index = 0
        var phase = 0.0

        private let lock = NSLock()
        private var continuation: CheckedContinuation<Void, Error>?
        private var finished = false

        func arm(_ continuation: CheckedContinuation<Void, Error>) {
            lock.lock()
            guard !finished else { lock.unlock(); return continuation.resume() }
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

    /// A flat frame whose colour tracks the frame index. Filled with one
    /// `memset` rather than per-pixel writes — a debug-build pixel loop over a
    /// 720p frame is slow enough to dominate the whole test run.
    private static func pixelBuffer(width: Int, height: Int, frame: Int, of total: Int) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA,
                            [kCVPixelBufferCGImageCompatibilityKey: true] as CFDictionary, &buffer)
        guard let buffer else { throw UmlessError.writeFailed("fixture: pixel buffer") }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else {
            throw UmlessError.writeFailed("fixture: pixel buffer address")
        }
        let value = Int32(32 + (frame * 180 / max(1, total)))
        memset(base, value, CVPixelBufferGetBytesPerRow(buffer) * height)
        return buffer
    }

    private static func toneSample(format: AVAudioFormat, frames: Int,
                                   startFrame: Int, phase: inout Double) throws -> CMSampleBuffer {
        guard let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))
        else { throw UmlessError.writeFailed("fixture: pcm buffer") }
        pcm.frameLength = AVAudioFrameCount(frames)
        let increment = 2 * Double.pi * 440 / format.sampleRate
        if let channel = pcm.floatChannelData?[0] {
            for i in 0..<frames {
                channel[i] = Float(sin(phase) * 0.25)
                phase += increment
            }
        }
        let time = CMTime(value: CMTimeValue(startFrame), timescale: CMTimeScale(format.sampleRate))
        guard let sample = pcm.sampleBuffer(at: time) else {
            throw UmlessError.writeFailed("fixture: sample buffer")
        }
        return sample
    }
}

private extension AVAudioPCMBuffer {
    /// Wraps the PCM buffer as a `CMSampleBuffer` the writer input can take.
    func sampleBuffer(at time: CMTime) -> CMSampleBuffer? {
        var formatDescription: CMAudioFormatDescription?
        var asbd = format.streamDescription.pointee
        guard CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault, asbd: &asbd, layoutSize: 0, layout: nil,
            magicCookieSize: 0, magicCookie: nil, extensions: nil,
            formatDescriptionOut: &formatDescription) == noErr,
            let formatDescription else { return nil }

        var sampleBuffer: CMSampleBuffer?
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: CMTimeScale(format.sampleRate)),
            presentationTimeStamp: time, decodeTimeStamp: .invalid)
        guard CMSampleBufferCreate(
            allocator: kCFAllocatorDefault, dataBuffer: nil, dataReady: false,
            makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDescription,
            sampleCount: CMItemCount(frameLength), sampleTimingEntryCount: 1,
            sampleTimingArray: &timing, sampleSizeEntryCount: 0, sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer) == noErr, let sampleBuffer else { return nil }

        guard CMSampleBufferSetDataBufferFromAudioBufferList(
            sampleBuffer, blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault, flags: 0,
            bufferList: audioBufferList) == noErr else { return nil }
        // Created with `dataReady: false`, so the data has to be declared ready
        // now that it is attached — the writer silently never drains it
        // otherwise, and the input stops accepting samples.
        guard CMSampleBufferSetDataReady(sampleBuffer) == noErr else { return nil }
        return sampleBuffer
    }
}
