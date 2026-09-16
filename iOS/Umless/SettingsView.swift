//
//  SettingsView.swift
//  Umless
//

import StoreKit
import SwiftUI

/// Presented as a sheet from the main screen.
struct SettingsView: View {
    @State private var localization = Localization.shared
    @State private var appearance = Appearance.shared
    @Environment(\.dismiss) private var dismiss

    private static let vendor = URL(string: "https://desertant.com")!

    @State private var updateState = UpdateState.idle
    @Environment(\.openURL) private var openURL

    private enum UpdateState: Equatable {
        case idle, checking, upToDate, available(String), failed
    }

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
                    Button {
                        Task { await checkForUpdate() }
                    } label: {
                        LabeledContent(loc("Check for Updates")) { updateStatus }
                    }
                    .disabled(updateState == .checking)

                    Link(loc("Write a Review"), destination: ReleaseCheck.writeReviewURL)
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

    @ViewBuilder private var updateStatus: some View {
        switch updateState {
        case .idle: EmptyView()
        case .checking: ProgressView().controlSize(.small)
        case .upToDate: Text(loc("Up to date")).foregroundStyle(.secondary)
        case .failed: Text(loc("Couldn’t reach the App Store.")).foregroundStyle(.secondary)
        case .available(let version):
            Label(version, systemImage: "arrow.down.circle.fill").foregroundStyle(.tint)
        }
    }

    /// Checking is explicit here, unlike the quiet check at launch: the user
    /// pressed a button and is owed an answer either way, including "up to
    /// date", which the launch check never says out loud.
    private func checkForUpdate() async {
        updateState = .checking
        switch await ReleaseCheck.latest() {
        case .updateAvailable(let version):
            updateState = .available(version)
            openURL(ReleaseCheck.productPageURL)
        case .upToDate:
            updateState = .upToDate
        case .unknown:
            updateState = .failed
        }
    }
}

#Preview {
    SettingsView()
}
