//
//  SettingsView.swift
//  Umless
//

import SwiftUI

/// The Settings window (⌘,). One setting so far: which language to show.
struct SettingsView: View {
    @State private var localization = Localization.shared
    @State private var appearance = Appearance.shared

    var body: some View {
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
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    SettingsView()
}
