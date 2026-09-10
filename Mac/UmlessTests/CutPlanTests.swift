//
//  CutPlanTests.swift
//  UmlessTests
//

import Testing
@testable import Umless

struct CutPlanTests {

    private let fps = 100.0  // 10 ms frames keep the arithmetic readable

    @Test func keepsTheGapsBetweenFillers() {
        let plan = CutPlan.make(fillers: [2.0...2.5, 6.0...6.4], padding: 0,
                                duration: 10, frameRate: fps)
        #expect(plan.removals.count == 2)
        #expect(plan.keepRanges.count == 3)
        #expect(abs(plan.removedDuration - 0.9) < 1e-9)
        #expect(abs(plan.outputDuration - 9.1) < 1e-9)
    }

    @Test func paddingWidensEachCutOnBothSides() {
        let plan = CutPlan.make(fillers: [3.0...3.2], padding: 0.05,
                                duration: 10, frameRate: fps)
        #expect(plan.removals.count == 1)
        #expect(abs(plan.removals[0].lowerBound - 2.95) < 1e-9)
        #expect(abs(plan.removals[0].upperBound - 3.25) < 1e-9)
    }

    @Test func mergesCutsThatPaddingPushesTogether() {
        // 1.0-1.2 and 1.3-1.5 are 0.1 apart; 0.08 of padding each side closes it.
        let plan = CutPlan.make(fillers: [1.0...1.2, 1.3...1.5], padding: 0.08,
                                duration: 10, frameRate: fps)
        #expect(plan.removals.count == 1)
        #expect(abs(plan.removals[0].lowerBound - 0.92) < 1e-9)
        #expect(abs(plan.removals[0].upperBound - 1.58) < 1e-9)
    }

    @Test func clampsToTheEndsOfTheVideo() {
        let plan = CutPlan.make(fillers: [0.0...0.3, 9.8...10.0], padding: 0.5,
                                duration: 10, frameRate: fps)
        #expect(plan.removals.first?.lowerBound == 0)
        #expect(plan.removals.last?.upperBound == 10)
        #expect(plan.keepRanges.count == 1)
    }

    @Test func aCutCoveringEverythingLeavesNothingToExport() {
        let plan = CutPlan.make(fillers: [0.0...10.0], padding: 0,
                                duration: 10, frameRate: fps)
        #expect(plan.keepRanges.isEmpty)
        #expect(plan.outputDuration == 0)
    }

    @Test func noFillersMeansOneUntouchedKeepRange() {
        let plan = CutPlan.make(fillers: [], padding: 0.1, duration: 10, frameRate: fps)
        #expect(plan.isEmpty)
        #expect(plan.keepRanges == [0.0...10.0])
        #expect(plan.outputDuration == 10)
    }

    @Test func boundariesLandOnWholeFrames() {
        // 24 fps: a boundary at 1.037 s must snap to a multiple of 1/24.
        let plan = CutPlan.make(fillers: [1.037...1.702], padding: 0,
                                duration: 10, frameRate: 24)
        for bound in [plan.removals[0].lowerBound, plan.removals[0].upperBound] {
            let frames = bound * 24
            #expect(abs(frames - frames.rounded()) < 1e-9)
        }
    }

    @Test func mapsSourceTimeOntoTheExportedTimeline() {
        let plan = CutPlan.make(fillers: [2.0...3.0], padding: 0, duration: 10, frameRate: fps)
        #expect(plan.outputTime(forSourceTime: 1.0) == 1.0)   // before the cut
        #expect(plan.outputTime(forSourceTime: 2.5) == 2.0)   // inside it
        #expect(plan.outputTime(forSourceTime: 5.0) == 4.0)   // after it
    }
}
