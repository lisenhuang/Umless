//
//  SettingsView.swift
//  Umless
//

import SwiftUI

/// Presented as a sheet from the main screen.
struct SettingsView: View {
    @State private var localization = Localization.shared
    @State private var appearance = Appearance.shared
    @Environment(\.dismiss) private var dismiss

    private static let vendor = URL(string: "https://desertant.com")!

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(loc("Appearance"), selection: $appearance.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker(loc("Language"), selection: $localization.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }

                Section {
                    LabeledContent(loc("Filler detection"), value: "Uhm · on-device")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loc("Runs entirely on your device — nothing is uploaded."))
                        // Naming Desert Ant Labs is a condition of the model's
                        // licence. A settings footer is the placement its
                        // attribution guide asks for, and the least obtrusive
                        // one that still counts.
                        Link(loc("Uhm model by Desert Ant Labs"), destination: Self.vendor)
                    }
                }
            }
            .navigationTitle(loc("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("Done")) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
