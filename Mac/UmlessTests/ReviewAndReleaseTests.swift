//
//  ReviewAndReleaseTests.swift
//  UmlessTests
//
//  The two decisions behind the rating prompt and the update banner.
//

import Foundation
import Testing
@testable import Umless

@MainActor
struct ReviewPromptTests {

    /// A throwaway defaults domain, so a test never reads or writes the real one.
    private func scratch() -> UserDefaults {
        let name = "umless.tests.\(UUID().uuidString)"
        UserDefaults().removePersistentDomain(forName: name)
        return UserDefaults(suiteName: name)!
    }

    @Test func asksOnlyOnTheThirdFinishedVideo() {
        let defaults = scratch()
        #expect(ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0") == false)
        #expect(ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0") == false)
        #expect(ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0") == true)
    }

    @Test func doesNotAskAgainOnTheSameVersion() {
        let defaults = scratch()
        for _ in 0..<3 { _ = ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0") }
        // Already asked on 1.0; more exports must not ask again.
        #expect(ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0") == false)
        #expect(ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0") == false)
    }

    @Test func asksOnceMoreAfterAnUpdate() {
        let defaults = scratch()
        for _ in 0..<3 { _ = ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0") }
        // A new build earns one more ask, and only one.
        #expect(ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.1") == true)
        #expect(ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.1") == false)
    }

    @Test func countSurvivesAcrossVersions() {
        let defaults = scratch()
        _ = ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0")
        _ = ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.0")
        // Third overall, even though the version changed part-way.
        #expect(ReviewPrompt.recordFinishedVideo(in: defaults, version: "1.1") == true)
    }
}

struct ReleaseCheckTests {

    @Test(arguments: [
        ("1.1", "1.0", true),
        ("1.0", "1.0", false),
        ("1.0", "1.1", false),
        // The case a string comparison gets wrong: 10 sorts below 9 as text.
        ("1.0.10", "1.0.9", true),
        ("1.0.9", "1.0.10", false),
        ("2.0", "1.9.9", true),
    ])
    func comparesVersionsNumerically(candidate: String, installed: String, newer: Bool) {
        #expect(ReleaseCheck.isNewer(candidate, than: installed) == newer)
    }

    @Test func storeLinksCarryTheAppID() {
        #expect(ReleaseCheck.productPageURL.absoluteString.contains(ReleaseCheck.appStoreID))
        #expect(ReleaseCheck.writeReviewURL.absoluteString.contains("action=write-review"))
    }
}
