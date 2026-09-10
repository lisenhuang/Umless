//
//  BundledModelTests.swift
//  UmlessTests
//
//  The model ships inside the app rather than being downloaded, so these
//  check that it is actually there and actually runs.
//

import AVFoundation
import Testing
@testable import Umless

@Suite(.serialized, .timeLimit(.minutes(3)))
struct BundledModelTests {

    @Test func theModelIsInsideTheAppBundle() throws {
        let directory = try #require(FillerAnalyzer.bundledModelDirectory,
                                     "UhmModel.bundle is missing from the app")
        let fm = FileManager.default
        var isDirectory: ObjCBool = false

        // The two things the SDK looks for by name.
        #expect(fm.fileExists(atPath: directory + "/uhm.mlmodelc", isDirectory: &isDirectory))
        #expect(isDirectory.boolValue, "uhm.mlmodelc must stay a compiled-model directory")
        #expect(fm.fileExists(atPath: directory + "/UhmLabel.mlmodel"),
                "the type labeler must stay a .mlmodel, not be compiled by Xcode")

        // Weights, not an LFS pointer or a truncated download.
        let weights = directory + "/uhm.mlmodelc/weights/weight.bin"
        let size = try fm.attributesOfItem(atPath: weights)[.size] as? Int ?? 0
        #expect(size > 40_000_000, "weight.bin looks truncated at \(size) bytes")
    }

    @Test func theAnalyzerReportsReadyWithoutANetwork() {
        #expect(FillerAnalyzer().isModelReady)
    }

    @Test func silenceProducesNoFillers() async throws {
        let analyzer = FillerAnalyzer()
        let samples = [Float](repeating: 0, count: 3 * AudioExtractor.sampleRate)
        let fillers = try await analyzer.analyze(samples: samples) { _ in }
        #expect(fillers.isEmpty)
    }

    /// End to end on real (synthesized) speech: proves the bundled Core ML
    /// model loads and runs inference, and reports what it heard.
    @Test func runsInferenceOnSpeech() async throws {
        let samples = try await SpeechFixture.samples(
            saying: "So, um, I was thinking, uh, maybe we should just ship it.")
        #expect(samples.count > AudioExtractor.sampleRate, "fixture should be over a second long")

        let analyzer = FillerAnalyzer()
        var sawProgress = false
        let fillers = try await analyzer.analyze(samples: samples) { _ in sawProgress = true }
        #expect(sawProgress, "analyze should report progress")

        // Every span the model returns must be well formed and inside the clip.
        let duration = Double(samples.count) / Double(AudioExtractor.sampleRate)
        for filler in fillers {
            #expect(filler.start >= 0 && filler.end <= duration + 0.1)
            #expect(filler.end > filler.start)
            #expect(filler.confidence >= FillerAnalyzer.captureThreshold)
        }
        print("Uhm heard \(fillers.count) filler(s) in \(String(format: "%.2f", duration))s: "
              + fillers.map { "\($0.label)@\($0.start.timecode)" }.joined(separator: ", "))
    }
}

/// Renders text to 16 kHz mono speech in-process. `AVSpeechSynthesizer`
/// rather than shelling out to `say`, because the test runs inside the host
/// app's sandbox.
enum SpeechFixture {
    /// - Note: Retried, because the first synthesis after a cold boot can come
    ///   back with nothing at all: the voice has not finished loading, `write`
    ///   completes without handing over a single buffer, and the fixture is
    ///   empty through no fault of the code under test. The attempt itself is
    ///   what warms the voice up, so a second one succeeds.
    static func samples(saying text: String) async throws -> [Float] {
        for attempt in 0..<3 {
            let samples = await synthesize(text)
            if !samples.isEmpty { return samples }
            try? await Task.sleep(for: .seconds(Double(attempt) + 0.5))
        }
        return []
    }

    private static func synthesize(_ text: String) async -> [Float] {
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        // A named voice rather than the system default, which depends on the
        // device's language settings and on a simulator may not exist at all.
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            ?? AVSpeechSynthesisVoice.speechVoices().first

        let sink = BufferSink()
        let (collected, rate) = await withCheckedContinuation { continuation in
            sink.arm(continuation)
            synthesizer.write(utterance) { buffer in
                guard let pcm = buffer as? AVAudioPCMBuffer else { return }
                // A zero-length buffer is the synthesizer signalling the end.
                guard pcm.frameLength > 0 else { return sink.finish() }
                // Read the rate off the buffer rather than assuming one.
                sink.append(pcm.monoFloatSamples(), rate: pcm.format.sampleRate)
            }
            // The end-of-stream buffer is not guaranteed on every release, so
            // a watchdog finishes with whatever arrived rather than hanging.
            Task {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                sink.finish()
            }
        }
        guard !collected.isEmpty else { return [] }
        return resample(collected, from: rate, to: Double(AudioExtractor.sampleRate))
    }

    /// Accumulates the synthesizer's buffers and resumes exactly once, from
    /// whichever of the end-of-stream buffer or the watchdog arrives first.
    private final class BufferSink: @unchecked Sendable {
        private let lock = NSLock()
        private var samples: [Float] = []
        private var rate = 22_050.0
        private var continuation: CheckedContinuation<([Float], Double), Never>?
        private var finished = false

        func arm(_ continuation: CheckedContinuation<([Float], Double), Never>) {
            lock.withLock { self.continuation = continuation }
        }

        func append(_ new: [Float], rate: Double) {
            lock.withLock {
                guard !finished else { return }
                samples.append(contentsOf: new)
                self.rate = rate
            }
        }

        func finish() {
            lock.lock()
            guard !finished, let pending = continuation else { return lock.unlock() }
            finished = true
            continuation = nil
            let result = (samples, rate)
            lock.unlock()
            pending.resume(returning: result)
        }
    }

    private static func resample(_ input: [Float], from: Double, to: Double) -> [Float] {
        guard from != to, from > 0 else { return input }
        let ratio = to / from
        let count = Int(Double(input.count) * ratio)
        return (0..<count).map { i in
            let position = Double(i) / ratio
            let low = Int(position)
            let high = min(low + 1, input.count - 1)
            let t = Float(position - Double(low))
            return input[low] * (1 - t) + input[high] * t
        }
    }
}

private extension AVAudioPCMBuffer {
    /// Mono Float32 samples regardless of the buffer's own format.
    func monoFloatSamples() -> [Float] {
        let frames = Int(frameLength)
        if let data = floatChannelData {
            return Array(UnsafeBufferPointer(start: data[0], count: frames))
        }
        if let data = int16ChannelData {
            return (0..<frames).map { Float(data[0][$0]) / 32_768 }
        }
        return []
    }
}
