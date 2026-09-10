//
//  AudioExtractor.swift
//  Umless
//
//  Pulls a video's audio out as the 16 kHz mono Float32 the Uhm model wants.
//

import AVFoundation

/// Decodes the audio track of a video straight into the sample buffer the
/// model consumes — no intermediate file, and the downmix/resample happens
/// inside AVFoundation's audio mix rather than in our own DSP.
nonisolated enum AudioExtractor {
    /// The rate Uhm runs at. Feeding it 16 kHz here means the SDK's internal
    /// resampler is a no-op.
    static let sampleRate = 16_000

    static func monoSamples(
        from asset: AVAsset,
        progress: @Sendable (Double) -> Void = { _ in }
    ) async throws -> [Float] {
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
            throw UmlessError.noAudioTrack
        }
        let duration = try await asset.load(.duration).seconds

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderAudioMixOutput(audioTracks: [track], audioSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: Double(sampleRate),
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ])
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { throw UmlessError.readFailed("audio output rejected") }
        reader.add(output)
        guard reader.startReading() else {
            throw UmlessError.readFailed(reader.error?.localizedDescription ?? "unknown")
        }

        var samples: [Float] = []
        if duration > 0 {
            samples.reserveCapacity(Int(duration * Double(sampleRate)))
        }

        while let buffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            guard let blockBuffer = CMSampleBufferGetDataBuffer(buffer) else { continue }
            let length = CMBlockBufferGetDataLength(blockBuffer)
            let count = length / MemoryLayout<Float>.size
            if count > 0 {
                // Append straight into the array's own storage: one copy out of
                // the block buffer instead of a temporary plus a second append.
                let oldCount = samples.count
                samples.append(contentsOf: repeatElement(0, count: count))
                samples.withUnsafeMutableBufferPointer { buf in
                    _ = CMBlockBufferCopyDataBytes(
                        blockBuffer, atOffset: 0, dataLength: length,
                        destination: buf.baseAddress! + oldCount)
                }
            }
            CMSampleBufferInvalidate(buffer)
            if duration > 0 {
                progress(min(1, Double(samples.count) / (duration * Double(sampleRate))))
            }
        }

        if reader.status == .failed {
            throw UmlessError.readFailed(reader.error?.localizedDescription ?? "unknown")
        }
        progress(1)
        return samples
    }
}
