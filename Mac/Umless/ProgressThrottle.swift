//
//  ProgressThrottle.swift
//  Umless
//

import Foundation

/// Coalesces a fine-grained progress signal into occasional, monotonic updates.
///
/// The pipelines report progress per sample buffer — thousands of times over a
/// long video — and every report otherwise hops to the main actor to nudge a
/// bar a few hundred pixels wide. This drops the updates that would not be
/// visible, and guarantees the bar never runs backwards when reports arrive
/// out of order from different queues.
nonisolated final class ProgressThrottle: @unchecked Sendable {
    private let lock = NSLock()
    private let step: Double
    private let report: @Sendable (Double) -> Void
    private var highWater = -1.0

    /// - Parameter step: Minimum advance worth reporting. The default is finer
    ///   than one pixel on any realistic progress bar.
    init(step: Double = 0.004, report: @escaping @Sendable (Double) -> Void) {
        self.step = step
        self.report = report
    }

    /// Report a fraction in `0...1`. Cheap to call at any rate.
    func send(_ fraction: Double) {
        guard fraction.isFinite else { return }
        let clamped = min(1, max(0, fraction))
        let advanced = lock.withLock { () -> Bool in
            guard clamped > highWater + step else { return false }
            highWater = clamped
            return true
        }
        if advanced { report(clamped) }
    }

    /// A `send` that always gets through — for the final 1.0.
    func finish() {
        lock.withLock { highWater = 1 }
        report(1)
    }
}
