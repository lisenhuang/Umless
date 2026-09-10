//
//  CutPlan.swift
//  Umless
//
//  Turns "these fillers, with this much padding" into the ranges to keep.
//

import CoreMedia
import Foundation

/// The edit decision list: which spans of the source survive into the export.
///
/// Built purely from the enabled fillers, so it recomputes instantly whenever
/// the user toggles one or drags the padding slider — the preview and the
/// export always read the same plan.
nonisolated struct CutPlan: Sendable {
    /// Spans being cut, merged and frame-aligned. Drawn on the scrubber.
    let removals: [ClosedRange<Double>]
    /// Spans being kept, in order. What the exporter stitches together.
    let keepRanges: [ClosedRange<Double>]
    let sourceDuration: Double

    var removedDuration: Double { removals.reduce(0) { $0 + ($1.upperBound - $1.lowerBound) } }
    var outputDuration: Double { max(0, sourceDuration - removedDuration) }
    var isEmpty: Bool { removals.isEmpty }

    /// - Parameters:
    ///   - fillers: The spans the user left enabled.
    ///   - padding: Extra seconds trimmed off each side of every filler, to
    ///     catch the breath that usually rides along with it.
    ///   - frameRate: Used to quantise every boundary to a whole frame, so the
    ///     joins land between frames instead of halfway through one.
    static func make(
        fillers: [ClosedRange<Double>],
        padding: Double,
        duration: Double,
        frameRate: Double
    ) -> CutPlan {
        guard duration > 0 else {
            return CutPlan(removals: [], keepRanges: [], sourceDuration: 0)
        }
        let fps = frameRate > 0 ? frameRate : 30
        func snap(_ t: Double) -> Double {
            (t * fps).rounded() / fps
        }

        // Pad, clamp to the video, quantise, drop anything that padded down to
        // nothing.
        let padded = fillers
            .map { snap(max(0, $0.lowerBound - padding))...snap(min(duration, $0.upperBound + padding)) }
            .filter { $0.upperBound > $0.lowerBound }
            .sorted { $0.lowerBound < $1.lowerBound }

        // Merge overlaps so two fillers a hair apart become one cut rather than
        // one cut, one surviving frame, and another cut.
        var merged: [ClosedRange<Double>] = []
        for range in padded {
            if let last = merged.last, range.lowerBound <= last.upperBound {
                merged[merged.count - 1] = last.lowerBound...max(last.upperBound, range.upperBound)
            } else {
                merged.append(range)
            }
        }

        // Keep ranges are the complement. A keep shorter than a single frame
        // would contribute no picture, so it is dropped.
        let minKeep = 1.0 / fps
        var keeps: [ClosedRange<Double>] = []
        var cursor = 0.0
        for cut in merged {
            if cut.lowerBound - cursor >= minKeep { keeps.append(cursor...cut.lowerBound) }
            cursor = cut.upperBound
        }
        if duration - cursor >= minKeep { keeps.append(cursor...duration) }

        return CutPlan(removals: merged, keepRanges: keeps, sourceDuration: duration)
    }

    /// Maps a source timestamp onto the exported timeline — where a moment
    /// ends up once everything before it has been cut away.
    func outputTime(forSourceTime t: Double) -> Double {
        var elapsed = 0.0
        for keep in keepRanges {
            if t < keep.lowerBound { return elapsed }
            if t <= keep.upperBound { return elapsed + (t - keep.lowerBound) }
            elapsed += keep.upperBound - keep.lowerBound
        }
        return elapsed
    }

    /// The inverse: where a moment in the exported timeline came from in the
    /// source. Used to hold the playhead steady when the preview switches
    /// between the original and the edit.
    func sourceTime(forOutputTime t: Double) -> Double {
        var elapsed = 0.0
        for keep in keepRanges {
            let length = keep.upperBound - keep.lowerBound
            if t <= elapsed + length { return keep.lowerBound + (t - elapsed) }
            elapsed += length
        }
        return keepRanges.last?.upperBound ?? 0
    }
}
