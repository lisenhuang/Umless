//
//  UmlessApp.swift
//  Umless
//

import AVFoundation
import SwiftUI

@main
struct UmlessApp: App {

    @State private var appearance = Appearance.shared

    init() {
        // Resolve the language before anything can ask for a string. Error
        // messages are built off the main actor and would otherwise read from
        // whatever localization the system happened to pick for the bundle.
        _ = Localization.shared

        // Give the audio session a category before anything plays. With none,
        // iOS uses `.soloAmbient`, which the ring/silent switch mutes — so a
        // silenced phone previewed the cut without any sound, and the one thing
        // the user is reviewing is what the audio sounds like across a join.
        // `.playback` is the category for media the user deliberately asked to
        // hear, and it ignores the switch.
        //
        // Only the category is set here, never `setActive`. Setting a category
        // does not stop anyone else's audio; AVPlayer activates the session
        // itself when playback actually starts, so opening Umless no longer
        // interrupts whatever the user was already listening to.
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.theme.colorScheme)
        }
    }
}
