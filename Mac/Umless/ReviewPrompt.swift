//
//  ReviewPrompt.swift
//  Umless
//
//  Decides when asking the user for a rating is reasonable.
//

import Foundation

/// Counts the videos the user actually got out of the app, and says when to ask
/// for a rating.
///
/// Deliberately not on the first save. Someone who has finished three videos has
/// had what they came for and is a fair person to ask; someone mid-way through
/// their first export has not seen a result yet and is being interrupted, not
/// asked. What counts as "finished" is the platform's own idea of delivered —
/// on iOS a video that reached Photos, on macOS a file written where the user
/// pointed the save panel — so each side records its own moment.
///
/// The system dialog is rate-limited by App Store policy to a few prompts a year
/// and is silently ignored past that, so this decides only when it is worth
/// *trying*. It also asks at most once per version: the version that triggered a
/// prompt is remembered, so a heavy user is not asked again on every third
/// export.
@MainActor
enum ReviewPrompt {

    /// Finished videos before the first ask.
    private static let threshold = 3

    private static let countKey = "reviewPrompt.finishedVideos"
    private static let askedVersionKey = "reviewPrompt.askedInVersion"

    /// Records one finished video and reports whether this is the moment to ask.
    ///
    /// Recording and deciding are one call on purpose: they must not get out of
    /// step, and every call site wants both.
    @discardableResult
    static func recordFinishedVideo(
        in defaults: UserDefaults = .standard,
        version: String = ReleaseCheck.installedVersion
    ) -> Bool {
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)

        guard count >= threshold else { return false }
        // One ask per version, however many videos follow.
        guard defaults.string(forKey: askedVersionKey) != version else { return false }
        defaults.set(version, forKey: askedVersionKey)
        return true
    }
}
