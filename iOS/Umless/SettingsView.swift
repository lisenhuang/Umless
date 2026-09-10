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
                    Text(loc("Runs entirely on your device — nothing is uploaded."))
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
