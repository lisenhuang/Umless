//
//  UmlessApp.swift
//  Umless
//

import SwiftUI

@main
struct UmlessApp: App {

    @State private var appearance = Appearance.shared

    init() {
        // Resolve the language before anything can ask for a string. Error
        // messages are built off the main actor and would otherwise read from
        // whatever localization the system happened to pick for the bundle.
        _ = Localization.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearance.theme.colorScheme)
        }
    }
}
