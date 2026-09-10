//
//  UmlessApp.swift
//  Umless
//
//  Created by Eason Smith on 10/09/2026.
//

import SwiftUI

@main
struct UmlessApp: App {

    // The Settings window is a separate scene, so the preference has to be
    // applied to each one rather than once at the root.
    @State private var appearance = Appearance.shared

    init() {
        // Resolve the language before anything can ask for a string. Error
        // messages are built off the main actor and would otherwise read from
        // whatever localization macOS happened to pick for the bundle.
        _ = Localization.shared
    }

    var body: some Scene {
        Window("Umless", id: "main") {
            ContentView()
                .preferredColorScheme(appearance.theme.colorScheme)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        // Gives the app the standard Settings… (⌘,) item.
        Settings {
            SettingsView()
                .preferredColorScheme(appearance.theme.colorScheme)
        }
    }
}
