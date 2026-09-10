//
//  SourceVideo.swift
//  Umless
//
//  Everything about the input file that the export has to reproduce exactly:
//  coded pixel dimensions, frame rate, rotation, colour tags and codec.
//

import AVFoundation
import CoreMedia

/// A video the user picked, plus the format facts the exporter needs to match.
///
/// Read once, up front: every number here is something `VideoExporter` copies
/// onto the output so the exported file is the same shape as the input.
nonisolated struct SourceVideo: Sendable, Identifiable {
    let id = UUID()
    let url: URL
    let asset: AVURLAsset

    /// Coded pixel dimensions, before `preferredTransform` is applied. These
    /// are what the encoder is configured with; rotation rides along as
    /// metadata rather than being baked into the pixels.
    let codedSize: CGSize
    /// Rotation/flip stored on the source track, carried to the output track
    /// verbatim so the video is not re-oriented by the round trip.
    let preferredTransform: CGAffineTransform
    /// Frame rate reported by the source track. Reproduced on the output.
    let frameRate: Float
    /// The video track's own timescale — 30000 for 29.97 fps material, where
    /// the *asset's* duration timescale is often only 1000.
    let videoTimeScale: CMTimeScale
    /// Exact duration of one frame, as the rational the track declares
    /// (1001/30000 for 29.97 fps, never the lossy 0.0333…).
    ///
    /// Cut boundaries are whole multiples of this, in integer ticks. Routing a
    /// boundary through `Double` seconds instead lands it a tick either side of
    /// the real frame edge, which shows up as a duplicated frame at the join.
    let frameDuration: CMTime
    /// Source video bit rate; the export targets it so quality tracks the input.
    let videoDataRate: Float
    /// `.hevc` / `.h264` / … chosen to match the source codec.
    let codec: AVVideoCodecType
    /// True when the source is a >8-bit encode, which changes the pixel format
    /// the decoder is asked for and the profile the encoder is given.
    let isHighBitDepth: Bool
    /// Colour primaries / transfer function / YCbCr matrix from the source
    /// format description, so the export is not silently re-tagged.
    let colorProperties: [String: String]?
    let duration: CMTime
    let hasAudio: Bool
    /// The rate and channel count the audio **decodes to**, which is not always
    /// what the track's format description advertises.
    ///
    /// That description carries the *encoded* format, and for anything built on
    /// a base layer it describes the base: HE-AAC reports half the real sample
    /// rate (spectral band replication supplies the rest), HE-AAC v2 also
    /// reports half the channels (parametric stereo supplies the rest). Taking
    /// those numbers at face value resamples the export to half rate — and
    /// hands the encoder a bit rate that is legal at 44.1 kHz but refused at
    /// 22.05, which surfaces as a failed export rather than a rejected setting.
    let audioSampleRate: Double
    let audioChannels: Int

    var displaySize: CGSize {
        let r = CGRect(origin: .zero, size: codedSize).applying(preferredTransform)
        return CGSize(width: abs(r.width), height: abs(r.height))
    }

    var durationSeconds: Double { duration.seconds }

    /// Human-readable summary shown in the sidebar ("1920 × 1080 · 29.97 fps · HEVC").
    var formatSummary: String {
        let size = "\(Int(displaySize.width)) × \(Int(displaySize.height))"
        let fps = String(format: "%.4g fps", frameRate)
        return "\(size) · \(fps) · \(codec.humanName)"
    }

    static func load(url: URL) async throws -> SourceVideo {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw UmlessError.noVideoTrack
        }
        let (duration, transform, nominalRate, dataRate, formats, timeScale) = try await (
            asset.load(.duration),
            videoTrack.load(.preferredTransform),
            videoTrack.load(.nominalFrameRate),
            videoTrack.load(.estimatedDataRate),
            videoTrack.load(.formatDescriptions),
            videoTrack.load(.naturalTimeScale)
        )
        let minFrameDuration = try await videoTrack.load(.minFrameDuration)
        guard let format = formats.first else { throw UmlessError.noVideoTrack }

        let dims = CMVideoFormatDescriptionGetDimensions(format)
        let subType = CMFormatDescriptionGetMediaSubType(format)
        let bits = CMFormatDescriptionGetExtension(
            format, extensionKey: kCMFormatDescriptionExtension_BitsPerComponent) as? Int ?? 8

        // Some containers report 0 for nominalFrameRate; fall back to the
        // track's own minimum frame duration before giving up on 30.
        var fps = nominalRate
        if !(fps > 0) {
            fps = minFrameDuration.isValid && minFrameDuration.seconds > 0
                ? Float(1.0 / minFrameDuration.seconds) : 30
        }
        let scale = timeScale > 0 ? timeScale : 600
        // Derived from the same `fps` that `CutPlan` snaps with, expressed in
        // the track's own timescale — 1001/30000 for 29.97. Deliberately not
        // the track's `minFrameDuration`: the two can disagree (a file can
        // declare 1/30 while its frames actually sit 1001/30000 apart), and if
        // the cut planner and the exporter round on different values the joins
        // drift by a fraction of a frame. Falls back to the declared duration
        // if the rate is unusable.
        let ticks = (Double(scale) / Double(fps)).rounded()
        let frameDuration = ticks >= 1
            ? CMTime(value: CMTimeValue(ticks), timescale: scale)
            : minFrameDuration

        let audioTrack = try await asset.loadTracks(withMediaType: .audio).first
        var sampleRate = 48_000.0
        var channels = 2
        if let audioTrack {
            // What the decoder produces, in preference to what the track says
            // it will — see `decodedAudioFormat`.
            if let decoded = decodedAudioFormat(of: asset, track: audioTrack) {
                (sampleRate, channels) = decoded
            } else if let desc = try await audioTrack.load(.formatDescriptions).first,
                      let basic = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee,
                      basic.mSampleRate > 0 {
                sampleRate = basic.mSampleRate
                channels = Int(basic.mChannelsPerFrame)
            }
        }

        return SourceVideo(
            url: url,
            asset: asset,
            codedSize: CGSize(width: Int(dims.width), height: Int(dims.height)),
            preferredTransform: transform,
            frameRate: fps,
            videoTimeScale: scale,
            frameDuration: frameDuration,
            videoDataRate: dataRate,
            codec: AVVideoCodecType(matching: subType),
            isHighBitDepth: bits > 8,
            colorProperties: format.colorProperties,
            duration: duration,
            hasAudio: audioTrack != nil,
            audioSampleRate: sampleRate,
            audioChannels: max(1, channels)
        )
    }
}

private nonisolated func decodedAudioFormat(
    of asset: AVAsset, track: AVAssetTrack
) -> (sampleRate: Double, channels: Int)? {
    guard let reader = try? AVAssetReader(asset: asset) else { return nil }
    // Deliberately no rate and no channel count in the settings: left to
    // choose, the decoder reports what it really produces, which is the
    // number we are after.
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false,
    ])
    guard reader.canAdd(output) else { return nil }
    reader.add(output)
    guard reader.startReading() else { return nil }
    defer { reader.cancelReading() }

    guard let buffer = output.copyNextSampleBuffer(),
          let description = CMSampleBufferGetFormatDescription(buffer),
          let basic = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee,
          basic.mSampleRate > 0, basic.mChannelsPerFrame > 0
    else { return nil }
    return (basic.mSampleRate, Int(basic.mChannelsPerFrame))
}

nonisolated extension AVVideoCodecType {
    /// The encoder codec that matches a source's media subtype. Anything
    /// exotic (ProRes variants aside) re-encodes as HEVC, which is the safest
    /// modern default for arbitrary input.
    init(matching subType: FourCharCode) {
        switch subType {
        case kCMVideoCodecType_H264: self = .h264
        case kCMVideoCodecType_HEVC, kCMVideoCodecType_HEVCWithAlpha: self = .hevc
        case kCMVideoCodecType_AppleProRes422: self = .proRes422
        case kCMVideoCodecType_AppleProRes422HQ: self = .proRes422HQ
        case kCMVideoCodecType_AppleProRes422LT: self = .proRes422LT
        case kCMVideoCodecType_AppleProRes422Proxy: self = .proRes422Proxy
        case kCMVideoCodecType_AppleProRes4444: self = .proRes4444
        default: self = .hevc
        }
    }

    var humanName: String {
        switch self {
        case .h264: "H.264"
        case .hevc: "HEVC"
        case .proRes422, .proRes422HQ, .proRes422LT, .proRes422Proxy, .proRes4444: "ProRes"
        default: rawValue
        }
    }

    /// ProRes is size-insensitive to the bit-rate key and rejects it, so the
    /// exporter skips compression tuning for these.
    var isProRes: Bool {
        switch self {
        case .proRes422, .proRes422HQ, .proRes422LT, .proRes422Proxy, .proRes4444: true
        default: false
        }
    }
}

nonisolated extension CMFormatDescription {
    /// Source colour tags in the shape `AVVideoColorPropertiesKey` wants, or
    /// nil when the source carries an incomplete set (AVFoundation rejects a
    /// partial dictionary, so it is all three or none).
    var colorProperties: [String: String]? {
        func ext(_ key: CFString) -> String? {
            CMFormatDescriptionGetExtension(self, extensionKey: key) as? String
        }
        guard let primaries = ext(kCMFormatDescriptionExtension_ColorPrimaries),
              let transfer = ext(kCMFormatDescriptionExtension_TransferFunction),
              let matrix = ext(kCMFormatDescriptionExtension_YCbCrMatrix)
        else { return nil }
        return [
            AVVideoColorPrimariesKey: primaries,
            AVVideoTransferFunctionKey: transfer,
            AVVideoYCbCrMatrixKey: matrix,
        ]
    }
}
